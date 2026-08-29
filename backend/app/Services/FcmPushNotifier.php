<?php

namespace App\Services;

use App\Contracts\PushNotifier;
use App\Models\Event;
use Kreait\Firebase\Contract\Messaging;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification;
use Throwable;

class FcmPushNotifier implements PushNotifier
{
    public const TOPIC = 'events_published';

    public function __construct(private Messaging $messaging) {}

    public function notifyEventPublished(Event $event): void
    {
        $message = CloudMessage::new()
            ->withTopic(self::TOPIC)
            ->withNotification(Notification::create(
                'New event at ITC',
                $event->title,
            ))
            ->withData([
                'type' => 'event_published',
                'event_id' => (string) $event->id,
            ])
            ->withAndroidConfig([
                'collapse_key' => 'event-published-'.$event->id,
                'priority' => 'high',
                'notification' => [
                    'channel_id' => 'events_published',
                ],
            ]);

        try {
            $this->messaging->send($message);
        } catch (Throwable $e) {
            report($e);
            throw $e;
        }
    }
}
