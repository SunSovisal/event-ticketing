<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\Event;
use App\Models\InboxNotification;
use App\Models\NotificationRead;
use App\Models\User;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Support\Collection;
use Illuminate\Support\Str;

class InboxNotificationService
{
    public const LIST_LIMIT = 50;

    public function recordEventPublished(Event $event): InboxNotification
    {
        try {
            return InboxNotification::query()->create([
                'type' => InboxNotification::TYPE_EVENT_PUBLISHED,
                'title' => InboxNotification::TITLE_EVENT_PUBLISHED,
                'body' => $event->title,
                'event_id' => $event->id,
                'data' => [
                    'type' => InboxNotification::TYPE_EVENT_PUBLISHED,
                    'event_id' => (string) $event->id,
                ],
            ]);
        } catch (UniqueConstraintViolationException) {
            return InboxNotification::query()
                ->where('type', InboxNotification::TYPE_EVENT_PUBLISHED)
                ->where('event_id', $event->id)
                ->firstOrFail();
        }
    }

    /**
     * @return Collection<int, InboxNotification>
     */
    public function listFor(?User $user): Collection
    {
        return InboxNotification::query()
            ->withReadFlag($user)
            ->orderByDesc('created_at')
            ->limit(self::LIST_LIMIT)
            ->get();
    }

    public function unreadCountFor(?User $user): int
    {
        if ($user === null) {
            return 0;
        }

        return InboxNotification::query()
            ->whereDoesntHave(
                'reads',
                fn ($reads) => $reads->where('user_id', $user->id),
            )
            ->count();
    }

    public function markRead(string $id, User $user): InboxNotification
    {
        $notification = InboxNotification::query()->find($id);

        if ($notification === null) {
            throw new ApiException('NOT_FOUND', 'Notification not found.', 404);
        }

        try {
            NotificationRead::query()->create([
                'user_id' => $user->id,
                'notification_id' => $notification->id,
                'read_at' => now(),
            ]);
        } catch (UniqueConstraintViolationException) {
            // Already read — treat as success.
        }

        return $this->present($notification->id, $user);
    }

    public function markAllRead(User $user): void
    {
        $unreadIds = InboxNotification::query()
            ->whereDoesntHave(
                'reads',
                fn ($reads) => $reads->where('user_id', $user->id),
            )
            ->pluck('id');

        if ($unreadIds->isEmpty()) {
            return;
        }

        $now = now();
        NotificationRead::query()->insert(
            $unreadIds->map(fn (string $id) => [
                'id' => (string) Str::uuid(),
                'user_id' => $user->id,
                'notification_id' => $id,
                'read_at' => $now,
            ])->all(),
        );
    }

    private function present(string $id, User $user): InboxNotification
    {
        return InboxNotification::query()
            ->withReadFlag($user)
            ->findOrFail($id);
    }
}
