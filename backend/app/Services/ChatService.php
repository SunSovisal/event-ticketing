<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\Event;
use App\Models\User;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;

class ChatService
{
    public const REFUSAL_MESSAGE = 'I can only help with ITC campus events and app FAQs: upcoming events, locations, spots left, how to sign in, save an event, reserve a ticket, or find your QR ticket. Please ask about those.';

    public const REFUSAL_MESSAGE_KM = 'ជំនួយ — មានកម្មវិធីអ្វីខ្លះ? — របៀបកក់សំបុត្រ? — សំបុត្រ QR នៅឯណា? — របៀបរក្សាទុកកម្មវិធី?';

    /**
     * @param  list<array{role: string, content: string}>  $history
     * @return array{reply: string, refused: bool, remaining_today: int, events: list<array<string, mixed>>}
     */
    public function reply(User $user, string $message, array $history = [], string $locale = 'en'): array
    {
        $message = trim($message);
        if ($message === '') {
            throw new ApiException('VALIDATION_ERROR', 'Message is required.', 422);
        }

        $locale = $this->normalizeLocale($locale);
        $remaining = $this->assertWithinDailyLimit($user);

        if ($this->isClearlyOffTopic($message)) {
            $this->consumeDailyQuota($user);

            return [
                'reply' => $this->refusalMessage($locale),
                'refused' => true,
                'remaining_today' => max(0, $remaining - 1),
                'events' => [],
            ];
        }

        $events = $this->loadUpcomingEvents();
        $systemPrompt = $this->buildSystemPrompt($events, $locale);
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
        }

        $cardEvents = [];
        if (! $refused) {
            $cardEvents = $this->eventsForCards($message, $reply, $events);
            if ($cardEvents !== []) {
                $reply = $this->stripEventListMarkdown($reply, $locale);
            }
        }

        $this->consumeDailyQuota($user);

        return [
            'reply' => $reply,
            'refused' => $refused,
            'remaining_today' => max(0, $remaining - 1),
            'events' => $cardEvents,
        ];
    }

    private function assertWithinDailyLimit(User $user): int
    {
        $limit = max(1, (int) config('services.openrouter.daily_limit', 30));
        $used = (int) Cache::get($this->dailyCacheKey($user), 0);
        $remaining = $limit - $used;

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
            'hi', 'hello', 'hey', 'thanks', 'thank you', 'សួស្តី', 'អរគុណ',
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
     */
    private function buildSystemPrompt($events, string $locale = 'en'): string
    {
        $eventsBlock = $this->formatEventsContext($events);
        $faqBlock = $this->faqCopy();
        $refusal = $this->refusalMessage($locale);
        $languageRule = $locale === 'kh'
            ? <<<'LANG'
LANGUAGE (strict):
- The mobile app is in Khmer.
- Reply entirely in Khmer (ភាសាខ្មែរ): every sentence, greeting, and explanation.
- Keep official event titles as written in EVENT DATA; translate times/locations/spots into Khmer.
- Even if the user question is English, still answer in Khmer.
LANG
            : <<<'LANG'
LANGUAGE (strict):
- The mobile app is in English.
- Reply entirely in English.
- Even if the user question is Khmer, still answer in English.
LANG;

        return <<<PROMPT
You are the GoITC campus event assistant for the Institute of Technology of Cambodia (ITC).

{$languageRule}

SCOPE (strict):
- Answer ONLY questions about: (1) published upcoming campus events in the EVENT DATA below, and (2) app FAQs in the FAQ section below.
- If the user asks anything else (homework, general knowledge, coding, news, personal advice, etc.), reply with exactly this sentence:
{$refusal}
- Never invent events, times, locations, or ticket availability. If an event is not in EVENT DATA, say you do not have that event listed.
- Never claim you reserved, cancelled, saved, or checked someone in. You cannot perform actions — only explain how the user can do them in the app.
- Keep answers short (1–3 sentences).

FORMAT (important):
- Use plain sentences only. No markdown. No bullet lists. No asterisks. No numbered lists.
- When the user asks what events are upcoming / available, reply with ONE short intro sentence only. Do NOT enumerate events — the mobile app shows event cards separately.
- When answering about one specific event, include the key facts in short sentences (title, when, where, spots) without lists.

FAQ:
{$faqBlock}

EVENT DATA (published upcoming; use this as ground truth):
{$eventsBlock}
PROMPT;
    }

    private function faqCopy(): string
    {
        return <<<'FAQ'
Q: How do I sign in?
A: Open Profile and sign in with email/password, Google, or phone SMS. Guests can browse events but must sign in to reserve tickets or save events.

Q: How do I browse events?
A: Use the Home tab to see published upcoming campus events. Open an event for details (time, location, capacity, description).

Q: How do I save an event?
A: Sign in, open an event, and tap Save. Saved events appear under Profile → Saved events.

Q: How do I reserve a ticket?
A: Sign in, open a published event that still has spots, and reserve. Each user gets one ticket per event while spots remain.

Q: Where is my ticket / QR code?
A: Open the Tickets tab. Your valid ticket shows a QR code used for door check-in.

Q: What happens at check-in?
A: Bring your QR ticket. An admin scans it at the door during the event check-in window. You cannot check yourself in from chat.

Q: How do I update my profile?
A: Open Profile → edit name, email, and campus fields (student ID, department, year). Settings has language and appearance options.

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
            $starts = optional($event->starts_at)?->toIso8601String() ?? 'unknown';
            $ends = optional($event->ends_at)?->toIso8601String() ?? 'n/a';
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
        if ($events->isEmpty()) {
            return [];
        }

        $haystack = Str::lower($message.' '.$reply);

        if ($this->wantsEventList($message)) {
            return $events->take(8)->map(fn (Event $event) => $this->eventCardPayload($event))->values()->all();
        }

        $matched = $events->filter(function (Event $event) use ($haystack) {
            $title = Str::lower((string) $event->title);

            return $title !== '' && str_contains($haystack, $title);
        });

        if ($matched->isEmpty()) {
            return [];
        }

        return $matched->take(5)->map(fn (Event $event) => $this->eventCardPayload($event))->values()->all();
    }

    private function wantsEventList(string $message): bool
    {
        $lower = Str::lower($message);

        return (bool) preg_match(
            '/\b(events?|upcoming|schedule|what(\'s| is| are)?\s+on|spots?\s+left|available|this\s+week|campus\s+events?)\b/u',
            $lower,
        );
    }

    /**
     * @return array<string, mixed>
     */
    private function eventCardPayload(Event $event): array
    {
        return [
            'id' => $event->id,
            'title' => $event->title,
            'starts_at' => $event->starts_at?->utc()->toIso8601String(),
            'ends_at' => $event->ends_at?->utc()->toIso8601String(),
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
                    'temperature' => 0.3,
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
