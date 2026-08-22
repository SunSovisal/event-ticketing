<?php

namespace Database\Seeders;

use App\Models\Event;
use Illuminate\Database\Seeder;

class EventSeeder extends Seeder
{
    public function run(): void
    {
        Event::factory()->published()->create([
            'title' => 'Intro to Flutter Workshop',
            'description' => 'Hands-on session covering Flutter widgets, navigation, and calling the ITC Events API.',
            'starts_at' => now()->addDays(3)->setTime(14, 0),
            'location_label' => 'Building A - Room 304',
            'capacity' => 50,
        ]);

        Event::factory()->published()->create([
            'title' => 'Open Source Meetup',
            'description' => 'Lightning talks from student contributors and a guided GitHub workflow demo.',
            'starts_at' => now()->addDays(10)->setTime(16, 0),
            'location_label' => 'Building B - Room 204',
            'capacity' => 60,
        ]);

        Event::factory()->create([
            'title' => 'New student orientation (draft)',
            'description' => 'Campus walkthrough and faculty intros. Not visible on Home until published.',
            'starts_at' => now()->addDays(20)->setTime(9, 0),
            'location_label' => 'Building A - Room 101',
            'capacity' => 120,
        ]);
    }
}
