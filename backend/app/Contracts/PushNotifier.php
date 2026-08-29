<?php

namespace App\Contracts;

use App\Models\Event;

interface PushNotifier
{
    public function notifyEventPublished(Event $event): void;
}
