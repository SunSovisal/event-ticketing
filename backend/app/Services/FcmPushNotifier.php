<?php

namespace App\Services;

use App\Contracts\PushNotifier;
use App\Models\Event;
use App\Models\InboxNotification;
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
        $data = [
            'type' => 'event_published',
            'event_id' => (string) $event->id,
        ];
        $inboxId = InboxNotification::query()
            ->where('type', InboxNotification::TYPE_EVENT_PUBLISHED)
            ->where('event_id', $event->id)
            ->value('id');
        if (is_string($inboxId) && $inboxId !== '') {
            $data['notification_id'] = $inboxId;
        }

        $message = CloudMessage::new()
            ->withTopic(self::TOPIC)
            ->withNotification(Notification::create(
                InboxNotification::TITLE_EVENT_PUBLISHED,
                $event->title,
            ))
            ->withData($data)
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
