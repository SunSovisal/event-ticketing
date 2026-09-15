<?php

namespace Tests\Unit;

use App\Services\ChatService;
use ReflectionMethod;
use Tests\TestCase;

class ChatServiceTest extends TestCase
{
    public function test_hi_is_a_greeting_not_off_topic(): void
    {
        $this->assertTrue($this->invoke('isGreeting', 'HI'));
        $this->assertTrue($this->invoke('isGreeting', 'hi!'));
        $this->assertTrue($this->invoke('isGreeting', 'Hello'));
        $this->assertTrue($this->invoke('isGreeting', 'សួស្តី'));
        $this->assertFalse($this->invoke('isGreeting', 'Is there any workout event'));
        $this->assertFalse($this->invoke('isClearlyOffTopic', 'HI'));
        $this->assertFalse($this->invoke('isEventSearch', 'HI'));
    }

    public function test_how_to_save_an_event_does_not_request_event_cards(): void
    {
        $this->assertFalse($this->invoke('wantsEventList', 'How do I save an event?'));
        $this->assertTrue($this->invoke('isAppHowToQuestion', 'How do I save an event?'));
        $this->assertTrue($this->invoke('isAppHowToQuestion', 'របៀបរក្សាទុកកម្មវិធី?'));
    }

    public function test_upcoming_and_spots_questions_still_request_event_cards(): void
    {
        $this->assertTrue($this->invoke('wantsEventList', 'What events are coming up?'));
        $this->assertTrue($this->invoke('wantsEventList', 'Which events still have spots?'));
        $this->assertTrue($this->invoke('wantsEventList', 'មានកម្មវិធីអ្វីខ្លះ?'));
    }

    public function test_qr_ticket_question_gets_tickets_shortcut_not_reserve(): void
    {
        $this->assertTrue($this->invoke('wantsTicketsShortcut', 'Where is my QR ticket?'));
        $this->assertTrue($this->invoke('wantsTicketsShortcut', 'សំបុត្រ QR នៅឯណា?'));
        $this->assertFalse($this->invoke('wantsTicketsShortcut', 'How do I reserve a ticket?'));
        $this->assertSame(
            [['type' => 'tickets']],
            $this->invoke('navigationActions', 'Where is my QR ticket?'),
        );
    }

    public function test_check_in_profile_and_sign_out_are_how_to_only(): void
    {
        $this->assertTrue($this->invoke('isAppHowToQuestion', 'How does QR check-in work?'));
        $this->assertTrue($this->invoke('isAppHowToQuestion', 'How do I update my profile?'));
        $this->assertTrue($this->invoke('isAppHowToQuestion', 'How do I sign out?'));
        $this->assertFalse($this->invoke('wantsEventList', 'How does QR check-in work?'));
        $this->assertFalse($this->invoke('wantsEventList', 'How do I update my profile?'));
    }

    public function test_workout_search_does_not_treat_football_as_a_gym_event(): void
    {
        $this->assertFalse($this->invoke('isClearlyOffTopic', 'Is there any workout event'));
        $this->assertTrue($this->invoke('isEventSearch', 'Is there any workout event'));

        $events = $this->sampleEvents();
        $matched = $this->invoke('eventsMatchingSearch', 'Is there any workout event', $events);
        $this->assertCount(0, $matched);
    }

    public function test_ai_search_matches_bootcamp_not_career_fair(): void
    {
        $matched = $this->invoke('eventsMatchingSearch', 'Is there any AI event', $this->sampleEvents());
        $this->assertCount(1, $matched);
        $this->assertSame('AI Bootcamp', $matched->first()->title);
    }

    public function test_football_search_matches_sports_event(): void
    {
        $matched = $this->invoke('eventsMatchingSearch', 'Is there any football event', $this->sampleEvents());
        $this->assertCount(1, $matched);
        $this->assertSame('ITC Football Friendly', $matched->first()->title);
    }

    private function sampleEvents()
    {
        return collect([
            new \App\Models\Event([
                'title' => 'Campus Career Fair',
                'description' => 'Meet employers hiring ITC students.',
                'location_label' => 'Building A - Hall',
                'category' => 'Career',
            ]),
            new \App\Models\Event([
                'title' => 'ITC Football Friendly',
                'description' => 'Casual 7-a-side on the campus field.',
                'location_label' => 'Campus football field',
                'category' => 'Sports',
            ]),
            new \App\Models\Event([
                'title' => 'AI Bootcamp',
                'description' => 'Intro to using large language models for campus projects.',
                'location_label' => 'Building C - Lab 2',
                'category' => 'Workshop',
            ]),
        ]);
    }

    private function invoke(string $method, mixed ...$args): mixed
    {
        $ref = new ReflectionMethod(ChatService::class, $method);

        return $ref->invoke(new ChatService, ...$args);
    }
}
