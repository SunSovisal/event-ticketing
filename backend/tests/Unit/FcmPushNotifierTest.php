<?php

namespace Tests\Unit;

use App\Models\Event;
use App\Services\FcmPushNotifier;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Kreait\Firebase\Contract\Messaging;
use Kreait\Firebase\Messaging\CloudMessage;
use Mockery;
use Tests\TestCase;

class FcmPushNotifierTest extends TestCase
{
    use RefreshDatabase;

    public function test_sends_a_topic_message_for_the_event(): void
    {
        $event = Event::factory()->published()->create([
            'title' => 'Campus open day',
        ]);

        $messaging = Mockery::mock(Messaging::class);
        $messaging->shouldReceive('send')
            ->once()
            ->with(Mockery::on(function (CloudMessage $message) use ($event) {
                $payload = $message->jsonSerialize();

                return ($payload['topic'] ?? null) === FcmPushNotifier::TOPIC
                    && ($payload['data']['event_id'] ?? null) === $event->id
                    && ($payload['data']['type'] ?? null) === 'event_published'
                    && ($payload['notification']['title'] ?? null) === 'New event at ITC'
                    && ($payload['notification']['body'] ?? null) === 'Campus open day';
            }));

        (new FcmPushNotifier($messaging))->notifyEventPublished($event);
    }
}
