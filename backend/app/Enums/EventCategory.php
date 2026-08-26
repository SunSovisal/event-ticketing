<?php

namespace App\Enums;

enum EventCategory: string
{
    case Workshop = 'Workshop';
    case Meetup = 'Meetup';
    case Academic = 'Academic';
    case Sports = 'Sports';
    case Club = 'Club';
    case Career = 'Career';
    case Social = 'Social';
    case General = 'General';

    /**
     * @return list<string>
     */
    public static function values(): array
    {
        return array_column(self::cases(), 'value');
    }
}
