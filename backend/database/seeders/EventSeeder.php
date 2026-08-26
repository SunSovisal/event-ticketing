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
            'category' => 'Workshop',
            'capacity' => 50,
        ]);

        Event::factory()->published()->create([
            'title' => 'Open Source Meetup',
            'description' => 'Lightning talks from student contributors and a guided GitHub workflow demo.',
            'starts_at' => now()->addDays(10)->setTime(16, 0),
            'location_label' => 'Building B - Room 204',
            'category' => 'Meetup',
            'capacity' => 60,
        ]);

        Event::factory()->published()->create([
            'title' => 'ITC Football Friendly',
            'description' => 'Casual 7-a-side match on the campus field. Bring indoor or turf shoes.',
            'starts_at' => now()->addDays(6)->setTime(17, 0),
            'location_label' => 'Campus football field',
            'category' => 'Sports',
            'capacity' => 28,
        ]);

        Event::factory()->published()->create([
            'title' => 'Campus career fair',
            'description' => 'Meet employers hiring ITC students for internships and full-time roles.',
            'starts_at' => now()->addDays(14)->setTime(9, 0),
            'location_label' => 'Building A - Hall',
            'category' => 'Career',
            'capacity' => 80,
        ]);

        Event::factory()->create([
            'title' => 'New student orientation (draft)',
            'description' => 'Campus walkthrough and faculty intros. Not visible on Home until published.',
            'starts_at' => now()->addDays(20)->setTime(9, 0),
            'location_label' => 'Building A - Room 101',
            'category' => 'Academic',
            'capacity' => 120,
        ]);
    }
}
