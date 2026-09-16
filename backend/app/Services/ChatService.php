<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\Event;
use App\Models\User;
use App\Support\AppDate;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;

class ChatService
{
    public const REFUSAL_MESSAGE = 'I can only help with ITC campus events and app FAQs: upcoming events, locations, spots left, how to sign in, save an event, reserve a ticket, or find your QR ticket. Please ask about those.';

    public const REFUSAL_MESSAGE_KM = 'ជំនួយ — មានកម្មវិធីអ្វីខ្លះ? — របៀបកក់សំបុត្រ? — សំបុត្រ QR នៅឯណា? — របៀបរក្សាទុកកម្មវិធី?';

    /**
     * @param  list<array{role: string, content: string}>  $history
     * @return array{reply: string, refused: bool, remaining_today: int, events: list<array<string, mixed>>, actions: list<array{type: string}>}
     */
    public function reply(User $user, string $message, array $history = [], string $locale = 'en'): array
    {
        $message = trim($message);
        if ($message === '') {
            throw new ApiException('VALIDATION_ERROR', 'Message is required.', 422);
        }

        $locale = $this->normalizeLocale($locale);
        $remaining = $this->assertWithinDailyLimit($user);

        if ($this->isClearlyOffTopic($message) && ! $this->isEventSearch($message) && ! $this->isGreeting($message)) {
            $this->consumeDailyQuota($user);

            return [
                'reply' => $this->refusalMessage($locale),
                'refused' => true,
                'remaining_today' => max(0, $remaining - 1),
                'events' => [],
                'actions' => [],
            ];
        }

        $events = $this->loadUpcomingEvents();
        $isSearch = $this->isEventSearch($message) && ! $this->isGreeting($message);
        $searchHits = $isSearch ? $this->eventsMatchingSearch($message, $events) : $events->take(0);
        $systemPrompt = $this->buildSystemPrompt($events, $locale, $searchHits, $isSearch);
        $messages = [
            ['role' => 'system', 'content' => $systemPrompt],
        ];

        foreach (array_slice($history, -4) as $turn) {
            $role = $turn['role'] ?? null;
            $content = trim((string) ($turn['content'] ?? ''));
            if (! in_array($role, ['user', 'assistant'], true) || $content === '') {
                continue;
            }
            $messages[] = ['role' => $role, 'content' => Str::limit($content, 500, '')];
        }

        $messages[] = ['role' => 'user', 'content' => Str::limit($message, 500, '')];

        $reply = $this->callOpenRouter($messages);
        $refused = $this->looksLikeActionClaim($reply);
        if ($refused) {
            $reply = $this->refusalMessage($locale);
        } elseif ($this->isCopiedRefusal($reply) && $this->isEventSearch($message) && ! $this->isGreeting($message)) {
            $refused = false;
            $reply = $this->eventSearchFallbackReply($message, $events, $locale);
        }

        $cardEvents = [];
        $actions = [];
        if (! $refused) {
            $cardEvents = $this->eventsForCards($message, $reply, $events);
            if ($cardEvents !== [] && ! $this->isAppHowToQuestion($message)) {
                $reply = $this->stripEventListMarkdown($reply, $locale);
            }
            $actions = $this->navigationActions($message);
        }

        $this->consumeDailyQuota($user);

        return [
            'reply' => $reply,
            'refused' => $refused,
            'remaining_today' => max(0, $remaining - 1),
            'events' => $cardEvents,
            'actions' => $actions,
        ];
    }

    private function remainingToday(User $user): int
    {
        $limit = max(1, (int) config('services.openrouter.daily_limit', 30));
        $used = (int) Cache::get($this->dailyCacheKey($user), 0);

        return max(0, $limit - $used);
    }

    private function assertWithinDailyLimit(User $user): int
    {
        $remaining = $this->remainingToday($user);

        if ($remaining <= 0) {
            throw new ApiException(
                'CHAT_DAILY_LIMIT',
                'Daily chat limit reached. Try again tomorrow.',
                429,
            );
        }

        return $remaining;
    }

    private function consumeDailyQuota(User $user): void
    {
        $key = $this->dailyCacheKey($user);
        if (! Cache::has($key)) {
            Cache::put($key, 1, now()->endOfDay());

            return;
        }

        Cache::increment($key);
    }

    private function dailyCacheKey(User $user): string
    {
        return 'chat:daily:'.$user->id.':'.now()->toDateString();
    }

    private function isGreeting(string $message): bool
    {
        $lower = Str::lower(trim($message));
        $lower = trim((string) preg_replace('/[\x{1F300}-\x{1FAFF}]/u', '', $lower));

        return (bool) preg_match(
            '/^(hi+|hii+|hello|hey+|yo|hiya|sup|howdy|good\s+(morning|afternoon|evening)|thanks|thank\s+you|thx|សួស្តី|អរគុណ)(\s+(there|bot|assistant))?[\s!.?]*$/u',
            $lower,
        );
    }

    private function isClearlyOffTopic(string $message): bool
    {
        $lower = Str::lower($message);

        $offTopicPatterns = [
            '/\b(homework|assignment|essay|thesis)\b/u',
            '/\b(write|generate)\s+(code|python|java|javascript|c\+\+|sql)\b/u',
            '/\b(who\s+won|election|politics|president)\b/u',
            '/\b(medical|diagnose|prescription|lawsuit|legal\s+advice)\b/u',
            '/\b(bitcoin|crypto|stock\s+tip|dating|girlfriend|boyfriend)\b/u',
            '/\b(recipe|cook|weather|capital\s+of)\b/u',
        ];

        foreach ($offTopicPatterns as $pattern) {
            if (preg_match($pattern, $lower) === 1) {
                return true;
            }
        }

        $onTopicHints = [
            'event', 'events', 'ticket', 'tickets', 'reserve', 'reservation', 'save',
            'saved', 'qr', 'check-in', 'check in', 'checkin', 'profile', 'sign in',
            'sign-in', 'login', 'capacity', 'spot', 'spots', 'location', 'where',
            'when', 'schedule', 'workshop', 'meetup', 'campus', 'itc', 'goitc',
            'faq', 'how do', 'how to', 'help', 'app', 'account', 'attend',
            'category', 'career', 'club', 'academic', 'sports', 'social',
            'sign out', 'sign-out', 'logout', 'log out',
            'workout', 'gym', 'fitness', 'football', 'soccer', 'sport',
            'workshop', 'meetup', 'bootcamp', 'fair', 'coding', 'flutter',
            'hi', 'hello', 'hey', 'thanks', 'thank you', 'សួស្តី', 'អរគុណ',
            'ចាកចេញ', 'កម្មវិធី', 'កីឡា', 'បាល់ទាត់',
        ];

        foreach ($onTopicHints as $hint) {
            if (str_contains($lower, $hint)) {
                return false;
            }
        }

        // Short greetings / vague help still allowed; longer messages without
        // event/app cues are treated as out of scope to save API calls.
        return Str::length($lower) > 40;
    }

    private function looksLikeActionClaim(string $reply): bool
    {
        $lower = Str::lower($reply);

        return (bool) preg_match(
            '/\b(i('."'".'?ve| have)?\s+(just\s+)?(reserved|booked|cancelled|checked\s*you\s*in|saved))\b/u',
            $lower,
        );
    }

    private function normalizeLocale(string $locale): string
    {
        $locale = strtolower(trim($locale));

        return in_array($locale, ['kh', 'km'], true) ? 'kh' : 'en';
    }

    private function refusalMessage(string $locale): string
    {
        return $locale === 'kh' ? self::REFUSAL_MESSAGE_KM : self::REFUSAL_MESSAGE;
    }

    /**
     * @param  \Illuminate\Support\Collection<int, Event>  $events
     * @param  \Illuminate\Support\Collection<int, Event>  $searchHits
     */
    private function buildSystemPrompt($events, string $locale = 'en', $searchHits = null, bool $isSearch = false): string
    {
        $eventsBlock = $this->formatEventsContext($events);
        $faqBlock = $this->faqCopy($locale);
        $languageRule = $locale === 'kh'
            ? <<<'LANG'
LANGUAGE:
- The app is in Khmer. Reply in natural spoken Khmer.
- Keep official event titles as written in EVENT DATA.
LANG
            : <<<'LANG'
LANGUAGE:
- The app is in English. Reply in natural conversational English.
LANG;

        $searchSection = '';
        if ($isSearch) {
            $hits = $searchHits === null || $searchHits->isEmpty()
                ? '(none)'
                : $this->formatEventsContext($searchHits);
            $searchSection = <<<SEARCHBLOCK

SEARCH HITS for this question (cards the app will show):
{$hits}
If SEARCH HITS is (none), say you do not see that kind of event upcoming. If it lists events, talk about those — not unrelated ones.

SEARCHBLOCK;
        }

        return <<<PROMPT
You are GoITC, a friendly AI chatbot for campus events at the Institute of Technology of Cambodia (ITC). Talk like a helpful classmate, not a policy document.

{$languageRule}

What you do:
- Chat about published upcoming campus events in EVENT DATA.
- Explain how to use the app (sign in, save, reserve, QR tickets, check-in, profile, sign out).
- Greet people. If they say hi / hello / thanks, greet them back in your own words and offer help. Never refuse a greeting.

How to talk:
- Be warm and brief. Greetings and event-search answers can be conversational.
- HOW-TO / NAVIGATION answers (reserve, save, QR ticket, sign in, sign out, check-in, profile) MUST use this layout with real line breaks. Never a single paragraph. Never "First... Then...":

To reserve a ticket:
1. Sign in
2. Home -> event with spots left -> Get ticket (or Pay now)

Each account gets one ticket per event while spots remain.

- Put each numbered step on its own line. Use " -> " between screens and buttons.
- Event list / "what's on": one short sentence. Do not enumerate events; cards appear under your message.
- Event search: one natural sentence about whether anything matches.
- No markdown: no **bold**, no *italics*, no # headings, no - or * bullets.

Hard limits:
- Never invent events, times, locations, or spots. EVENT DATA is ground truth.
- Never claim you reserved, saved, cancelled, or checked someone in. You only explain how they can do it in the app.
- If the question is clearly unrelated (homework, writing code, news, medical, dating, trivia), politely say you only help with ITC events and this app — in your own words, not a canned slogan.

App facts (use these steps; you may change the intro line, but keep the numbered " -> " layout):
{$faqBlock}
{$searchSection}
EVENT DATA (published upcoming):
{$eventsBlock}
PROMPT;
    }

    private function faqCopy(string $locale = 'en'): string
    {
        if ($locale === 'kh') {
            return <<<'FAQ'
Q: How do I sign in?
A: របៀបចូលគណនី:
1. ប្រវត្តិរូប
2. អ៊ីមែល/ពាក្យសម្ងាត់, Google, ឬ SMS

ភ្ញៀវអាចមើលកម្មវិធីបាន ប៉ុន្តែត្រូវចូលគណនីដើម្បីកក់សំបុត្រ ឬរក្សាទុក។

Q: How do I browse events?
A: ប្រើផ្ទាំង ទំព័រដើម ដើម្បីមើលកម្មវិធីនឹងមកដល់។ បើកកម្មវិធីមួយសម្រាប់ព័ត៌មានលម្អិត (ម៉ោង ទីកន្លែង ចំនួនកន្លែង ការពិពណ៌នា)។

Q: How do I save an event?
A: រក្សាទុកកម្មវិធី:
1. ចូលគណនី
2. ទំព័រដើម -> កម្មវិធី -> រូបចំណាំ
3. ប្រវត្តិរូប -> កម្មវិធីដែលបានរក្សាទុក

Q: How do I reserve a ticket?
A: របៀបកក់សំបុត្រ:
1. ចូលគណនី
2. ទំព័រដើម -> កម្មវិធីដែលនៅសល់កន្លែង -> យកសំបុត្រ (ឬ បង់ប្រាក់ឥឡូវ)

គណនីមួយបានសំបុត្រមួយក្នុងមួយកម្មវិធី ពេលនៅសល់កន្លែង។

Q: Where is my ticket / QR code?
A: សំបុត្រ QR នៅផ្ទាំង សំបុត្រ។
1. បើក សំបុត្រ
2. សំបុត្រ -> ការកក់របស់អ្នក
3. បង្ហាញកូដនៅមាត់ទ្វារ

Q: How do I sign out?
A: របៀបចាកចេញ:
1. បើកប្រវត្តិរូប
2. ប្រវត្តិរូប -> ចាកចេញ (ខាងក្រោមអេក្រង់)

Q: What happens at check-in?
A: របៀបចុះឈ្មោះ QR:
1. សំបុត្រ -> សំបុត្ររបស់អ្នក
2. បង្ហាញ QR នៅមាត់ទ្វារ

អ្នកគ្រប់គ្រងស្កេនវាក្នុងពេលចុះឈ្មោះ។ អ្នកមិនអាចចុះឈ្មោះដោយខ្លួនឯងពីការជជែកបានទេ។

Q: How do I update my profile?
A: របៀបកែប្រវត្តិរូប:
1. ប្រវត្តិរូប -> រូបខ្មៅដៃ (ឈ្មោះ អ៊ីមែល ព័ត៌មានសាលា)
2. ប្រវត្តិរូប -> រូបប្រអប់ធ្មេញ (ភាសា និងរូបរាង)

Q: Who can manage events / scan tickets?
A: មានតែគណនីអ្នកគ្រប់គ្រង។ អ្នកគ្រប់គ្រងប្រើឧបករណ៍ក្នុងប្រវត្តិរូបសម្រាប់គ្រប់គ្រងកម្មវិធី ម៉ាស៊ីនស្កេន និងចុះឈ្មោះដោយដៃ។ អ្នកចូលរួមធម្មតាមិនអាចបានទេ។

Q: What if an event is full?
A: កន្លែងនៅសល់ដល់សូន្យពេលសំបុត្រត្រឹមត្រូវ/បានចុះឈ្មោះពេញចំណុះ។ អ្នកមិនអាចកក់បានទេរហូតមានកន្លែងទំនេរ។

Q: Is this for ITC campus events only?
A: បាទ។ GoITC សម្រាប់ស្វែងរកកម្មវិធីក្នុងបរិវេណ ITC ការកក់ និងចុះឈ្មោះ — មិនមែនជាជំនួយការទូទៅទេ។
FAQ;
        }

        return <<<'FAQ'
Q: How do I sign in?
A: To sign in:
1. Profile
2. Email/password, Google, or phone SMS

Guests can browse events, but must sign in to save or reserve.

Q: How do I browse events?
A: Use the Home tab to see published upcoming campus events. Open an event for details (time, location, capacity, description).

Q: How do I save an event?
A: To save an event:
1. Sign in
2. Home -> Event -> Bookmark icon
3. Profile -> Saved events

Q: How do I reserve a ticket?
A: To reserve a ticket:
1. Sign in
2. Home -> event with spots left -> Get ticket (or Pay now)

Each account gets one ticket per event while spots remain.

Q: Where is my ticket / QR code?
A: Your QR ticket is on the Tickets tab.
1. Open Tickets
2. Tickets -> your booking
3. Show the QR at the door

Q: How do I sign out?
A: To sign out:
1. Open Profile
2. Profile -> Sign out (bottom of the screen)

Q: What happens at check-in?
A: To check in with QR:
1. Tickets -> your ticket
2. Show the QR at the door

An admin scans it during the event check-in window. You cannot check yourself in from chat.

Q: How do I update my profile?
A: To update your profile:
1. Profile -> pencil icon (name, email, campus fields)
2. Profile -> gear icon (language and appearance)

Q: Who can manage events / scan tickets?
A: Only admin accounts. Admins use Profile tools for manage events, scanner, and manual check-in. Regular attendees cannot.

Q: What if an event is full?
A: Spots remaining reach zero when capacity is filled by valid/checked-in tickets. You cannot reserve until a spot opens (if ever).

Q: Is this for ITC campus events only?
A: Yes. GoITC is for ITC campus event discovery, reservations, and check-in — not a general chatbot.
FAQ;
    }

    /**
     * @return \Illuminate\Support\Collection<int, Event>
     */
    private function loadUpcomingEvents()
    {
        return Event::query()
            ->publishedUpcoming()
            ->withTicketCounts()
            ->orderBy('starts_at')
            ->limit(15)
            ->get();
    }

    /**
     * @param  \Illuminate\Support\Collection<int, Event>  $events
     */
    private function formatEventsContext($events): string
    {
        if ($events->isEmpty()) {
            return '(No published upcoming events right now.)';
        }

        $lines = [];
        foreach ($events as $event) {
            $starts = AppDate::iso($event->starts_at) ?? 'unknown';
            $ends = AppDate::iso($event->ends_at) ?? 'n/a';
            $desc = Str::limit(trim((string) $event->description), 180, '…');
            $spots = $event->spotsRemaining();

            $lines[] = sprintf(
                '- [%s] %s | starts %s | ends %s | location: %s | category: %s | spots %d/%d | %s',
                $event->id,
                $event->title,
                $starts,
                $ends,
                $event->location_label,
                $event->category,
                $spots,
                $event->capacity,
                $desc,
            );
        }

        return implode("\n", $lines);
    }

    /**
     * @param  \Illuminate\Support\Collection<int, Event>  $events
     * @return list<array<string, mixed>>
     */
    private function eventsForCards(string $message, string $reply, $events): array
    {
        if ($events->isEmpty() || $this->isAppHowToQuestion($message)) {
            return [];
        }

        $searchMatches = $this->eventsMatchingSearch($message, $events);
        if ($searchMatches->isNotEmpty()) {
            return $searchMatches->take(5)->map(fn (Event $event) => $this->eventCardPayload($event))->values()->all();
        }

        $haystack = Str::lower($message.' '.$reply);

        if ($this->wantsEventList($message) && $this->searchTerms($message) === []) {
            return $events->take(8)->map(fn (Event $event) => $this->eventCardPayload($event))->values()->all();
        }

        $matched = $events->filter(function (Event $event) use ($haystack) {
            $title = Str::lower((string) $event->title);

            return $title !== '' && str_contains($haystack, $title);
        });

        if ($matched->isEmpty()) {
            if ($this->wantsEventList($message)) {
                return $events->take(8)->map(fn (Event $event) => $this->eventCardPayload($event))->values()->all();
            }

            return [];
        }

        return $matched->take(5)->map(fn (Event $event) => $this->eventCardPayload($event))->values()->all();
    }

    private function isCopiedRefusal(string $reply): bool
    {
        $normalized = Str::lower(trim($reply));

        return $normalized === Str::lower(self::REFUSAL_MESSAGE)
            || $normalized === Str::lower(self::REFUSAL_MESSAGE_KM)
            || str_contains($normalized, 'i can only help with itc campus events');
    }

    private function isEventSearch(string $message): bool
    {
        if ($this->isAppHowToQuestion($message)) {
            return false;
        }

        if ($this->wantsEventList($message)) {
            return true;
        }

        $lower = Str::lower($message);
        $mentionsEvents = (bool) preg_match(
            '/\b(event|events|workshop|meetup|bootcamp|fair|sports?|campus)\b/u',
            $lower,
        ) || (bool) preg_match('/កម្មវិធី|កីឡា/u', $message);
        $asksIfExists = (bool) preg_match(
            '/\b(is there|are there|any|looking for|do you have|find|search)\b/u',
            $lower,
        ) || (bool) preg_match('/មានកម្មវិធី|កម្មវិធីណា/u', $message);

        if ($mentionsEvents) {
            return true;
        }

        return $asksIfExists && $this->searchTerms($message) !== [];
    }

    /**
     * @param  \Illuminate\Support\Collection<int, Event>  $events
     */
    private function eventSearchFallbackReply(string $message, $events, string $locale): string
    {
        if ($this->eventsMatchingSearch($message, $events)->isNotEmpty()) {
            return $locale === 'kh'
                ? 'នេះជាកម្មវិធីដែលត្រូវនឹងការស្វែងរករបស់អ្នក។'
                : 'Here are upcoming campus events that match what you asked about.';
        }

        return $locale === 'kh'
            ? 'មិនមានកម្មវិធីបែបនោះក្នុងបញ្ជីនឹងមកដល់ទេ។'
            : 'I do not have that kind of event in the upcoming campus list right now.';
    }

    /**
     * @param  \Illuminate\Support\Collection<int, Event>  $events
     * @return \Illuminate\Support\Collection<int, Event>
     */
    private function eventsMatchingSearch(string $message, $events)
    {
        $terms = $this->expandSearchTerms($this->searchTerms($message));
        $lowerMessage = Str::lower($message);

        foreach ($this->searchSynonyms() as $key => $synonyms) {
            if (! $this->textContainsTerm($lowerMessage, $key)) {
                continue;
            }
            $terms[] = $key;
            foreach ($synonyms as $synonym) {
                $terms[] = $synonym;
            }
        }

        $terms = array_values(array_unique(array_filter($terms)));
        if ($terms === []) {
            return $events->take(0);
        }

        return $events->filter(function (Event $event) use ($terms) {
            $blob = Str::lower(trim(implode(' ', [
                (string) $event->title,
                (string) $event->description,
                (string) $event->category,
                (string) $event->location_label,
            ])));

            foreach ($terms as $term) {
                if ($this->textContainsTerm($blob, $term)) {
                    return true;
                }
            }

            return false;
        })->values();
    }

    private function textContainsTerm(string $haystack, string $term): bool
    {
        $term = Str::lower(trim($term));
        $haystack = Str::lower($haystack);
        if ($term === '') {
            return false;
        }

        $isKhmer = preg_match('/[\x{1780}-\x{17FF}]/u', $term) === 1;
        if ($isKhmer) {
            return str_contains($haystack, $term);
        }

        return (bool) preg_match('/\b'.preg_quote($term, '/').'\b/u', $haystack);
    }

    /**
     * @return list<string>
     */
    private function searchTerms(string $message): array
    {
        $lower = Str::lower($message);
        $lower = preg_replace('/[^\p{L}\p{N}\s]+/u', ' ', $lower) ?? $lower;
        $tokens = preg_split('/\s+/u', $lower, -1, PREG_SPLIT_NO_EMPTY) ?: [];
        $stop = [
            'is', 'there', 'any', 'a', 'an', 'the', 'event', 'events', 'upcoming',
            'campus', 'some', 'looking', 'for', 'about', 'with', 'do', 'you', 'have',
            'got', 'are', 'was', 'of', 'on', 'in', 'at', 'to', 'my', 'me', 'please',
            'can', 'i', 'we', 'find', 'show', 'list', 'available', 'coming', 'up',
            'still', 'itc', 'goitc', 'this', 'that', 'those', 'these', 'or', 'and',
            'what', 'which', 'when', 'where', 'how', 'does', 'kind', 'type',
            'មាន', 'កម្មវិធី', 'ទេ', 'ណា', 'អ្វី', 'ខ្លះ', 'នៅ', 'សល់',
        ];
        $synonyms = $this->searchSynonyms();

        $terms = [];
        foreach ($tokens as $token) {
            if (in_array($token, $stop, true)) {
                continue;
            }
            if (Str::length($token) < 3 && ! isset($synonyms[$token])) {
                continue;
            }
            $terms[] = $token;
        }

        return array_values(array_unique($terms));
    }

    /**
     * @param  list<string>  $terms
     * @return list<string>
     */
    private function expandSearchTerms(array $terms): array
    {
        $expanded = $terms;
        $synonyms = $this->searchSynonyms();
        foreach ($terms as $term) {
            foreach ($synonyms[$term] ?? [] as $synonym) {
                $expanded[] = $synonym;
            }
        }

        return array_values(array_unique($expanded));
    }

    /**
     * @return array<string, list<string>>
     */
    private function searchSynonyms(): array
    {
        return [
            'workout' => ['fitness', 'gym', 'exercise', 'training'],
            'workouts' => ['fitness', 'gym', 'exercise'],
            'gym' => ['fitness', 'workout', 'exercise'],
            'fitness' => ['workout', 'gym', 'exercise'],
            'exercise' => ['workout', 'fitness', 'gym'],
            'sport' => ['sports', 'football'],
            'sports' => ['sport', 'football'],
            'football' => ['sports', 'soccer'],
            'soccer' => ['football', 'sports'],
            'coding' => ['code', 'programming', 'flutter'],
            'code' => ['coding', 'programming'],
            'programming' => ['coding', 'flutter'],
            'flutter' => ['coding'],
            'job' => ['career', 'hiring', 'internship'],
            'jobs' => ['career', 'hiring', 'internship'],
            'career' => ['hiring', 'internship', 'employer'],
            'ai' => ['llm'],
            'music' => ['concert'],
            'ហាត់ប្រាណ' => ['workout', 'fitness', 'gym', 'exercise'],
            'កីឡា' => ['sports', 'football'],
            'បាល់ទាត់' => ['football', 'sports', 'soccer'],
        ];
    }

    private function wantsEventList(string $message): bool
    {
        if ($this->isAppHowToQuestion($message)) {
            return false;
        }

        $lower = Str::lower($message);

        return (bool) preg_match(
            '/\b((upcoming|campus)\s+events?|what(\'?s| is| are)?\s+(the\s+)?(upcoming\s+)?events?|which\s+events?|events?\s+(are\s+)?coming|spots?\s+left|have\s+spots|this\s+week|what(\'?s| is)\s+on)\b/u',
            $lower,
        ) || (bool) preg_match('/មានកម្មវិធីអ្វីខ្លះ|កម្មវិធីណានៅសល់|កន្លែងនៅសល់/u', $message);
    }

    private function isAppHowToQuestion(string $message): bool
    {
        $lower = Str::lower($message);

        return (bool) preg_match(
            '/\b(how\s+(do\s+i|to)\s+(save|reserve|book|sign\s*in|sign\s*out|log\s*in|log\s*out|update|edit|check)|'
            .'(save|saving)\s+(an?\s+)?event|saved\s+events?|'
            .'where(\s+is|\s+are)?\s+(my\s+)?(qr|ticket)|qr\s*(ticket|code|check)|'
            .'(sign|log)\s*out|(update|edit)\s+(my\s+)?profile|check[\s-]*in)\b/u',
            $lower,
        ) || (bool) preg_match(
            '/របៀប(កក់|រក្សាទុក|ចូល|កែ|ចាកចេញ)|សំបុត្រ\s*QR|QR\s*នៅ|ចុះឈ្មោះ|ចាកចេញ|កែប្រវត្តិរូប/u',
            $message,
        );
    }

    /**
     * @return list<array{type: string}>
     */
    private function navigationActions(string $message): array
    {
        if (! $this->wantsTicketsShortcut($message)) {
            return [];
        }

        return [['type' => 'tickets']];
    }

    private function wantsTicketsShortcut(string $message): bool
    {
        $lower = Str::lower($message);
        $looksLikeReserve = (bool) preg_match('/\b(reserv|book|get\s+(a\s+)?ticket|save\s+(an?\s+)?event)\b/u', $lower)
            || (bool) preg_match('/របៀបកក់|របៀបរក្សាទុក/u', $message);

        if ($looksLikeReserve && ! str_contains($lower, 'qr') && ! str_contains($message, 'QR')) {
            return false;
        }

        return (bool) preg_match(
            '/\b(where.*\b(qr|ticket)|qr\s*(ticket|code)|my\s+(qr\s+)?tickets?|tickets?\s+tab)\b/u',
            $lower,
        ) || (bool) preg_match('/សំបុត្រ\s*QR|QR\s*នៅ|សំបុត្រ\s+នៅ/u', $message);
    }

    /**
     * @return array<string, mixed>
     */
    private function eventCardPayload(Event $event): array
    {
        return [
            'id' => $event->id,
            'title' => $event->title,
            'starts_at' => AppDate::iso($event->starts_at),
            'ends_at' => AppDate::iso($event->ends_at),
            'location_label' => $event->location_label,
            'category' => $event->category,
            'capacity' => $event->capacity,
            'spots_remaining' => $event->spotsRemaining(),
            'status' => $event->status,
            'image_url' => $event->image_url,
        ];
    }

    private function stripEventListMarkdown(string $reply, string $locale = 'en'): string
    {
        $lines = preg_split('/\R/u', $reply) ?: [];
        $kept = [];

        foreach ($lines as $line) {
            $trimmed = trim($line);
            if ($trimmed === '') {
                continue;
            }
            // Drop markdown bullets / numbered event rows the model may still emit.
            if (preg_match('/^(\*|-|\d+\.)\s+/u', $trimmed) === 1) {
                continue;
            }
            $kept[] = preg_replace('/\*\*(.*?)\*\*/u', '$1', $trimmed) ?? $trimmed;
        }

        $clean = trim(implode(' ', $kept));
        if ($clean === '') {
            return $locale === 'kh'
                ? 'មានកម្មវិធីអ្វីខ្លះ?'
                : 'Here are the upcoming campus events.';
        }

        return $clean;
    }

    private function buildEventsContext(): string
    {
        return $this->formatEventsContext($this->loadUpcomingEvents());
    }

    /**
     * @param  list<array{role: string, content: string}>  $messages
     */
    private function callOpenRouter(array $messages): string
    {
        $key = config('services.openrouter.key');
        if (! is_string($key) || $key === '') {
            throw new ApiException(
                'CHAT_UNAVAILABLE',
                'Chat is not configured. Ask an admin to set OPENROUTER_API_KEY.',
                503,
            );
        }

        $baseUrl = rtrim((string) config('services.openrouter.base_url'), '/');
        $model = (string) config('services.openrouter.model');
        $maxTokens = max(64, (int) config('services.openrouter.max_tokens', 512));

        try {
            $response = Http::withToken($key)
                ->withHeaders([
                    'HTTP-Referer' => (string) config('app.url'),
                    'X-OpenRouter-Title' => (string) config('app.name'),
                ])
                ->timeout(30)
                ->acceptJson()
                ->post($baseUrl.'/chat/completions', [
                    'model' => $model,
                    'max_tokens' => $maxTokens,
                    'temperature' => 0.7,
                    'messages' => $messages,
                ]);
        } catch (\Throwable $e) {
            report($e);

            throw new ApiException(
                'CHAT_UPSTREAM_ERROR',
                'Could not reach the AI service. Try again shortly.',
                502,
            );
        }

        if (! $response->successful()) {
            $upstream = data_get($response->json(), 'error.message')
                ?? data_get($response->json(), 'error')
                ?? $response->body();

            logger()->warning('OpenRouter chat failed', [
                'status' => $response->status(),
                'model' => $model,
                'upstream' => is_string($upstream)
                    ? Str::limit($upstream, 500)
                    : json_encode($upstream),
            ]);

            throw new ApiException(
                'CHAT_UPSTREAM_ERROR',
                'The AI service returned an error. Try again shortly.',
                502,
            );
        }

        $content = data_get($response->json(), 'choices.0.message.content');
        if (! is_string($content) || trim($content) === '') {
            throw new ApiException(
                'CHAT_UPSTREAM_ERROR',
                'The AI service returned an empty reply.',
                502,
            );
        }

        return trim($content);
    }
}
