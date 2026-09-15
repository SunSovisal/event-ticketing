<?php

namespace Database\Seeders;

use App\Models\Event;
use Illuminate\Database\Seeder;

class EventSeeder extends Seeder
{
    public function run(): void
    {
        // Wall-clock hours are Cambodia time (UTC+7), matching APP_TIMEZONE.
        // Home features the soonest published start, so Build Night must stay first.
        $buildNightStart = now()->addMinutes(75);

        Event::factory()->published()->paid('0.01', 'USD')->create([
            'title' => 'ITC Coding Day',
            'description' => 'Bring a laptop. We will build a small Flutter screen, call the events API, and wrap with a short Q&A. Entry is a token fee so we can confirm KHQR checkout before doors open.',
            'starts_at' => $buildNightStart,
            'ends_at' => $buildNightStart->copy()->addHours(2),
            'location_label' => 'Building A - Hall',
            'category' => 'Workshop',
            'capacity' => 40,
        ]);

        Event::factory()->published()->create([
            'title' => 'Intro to Flutter Workshop',
            'description' => 'Beginner session on widgets, navigation, and calling a REST API from Flutter. Laptops required. One seat per student.',
            'starts_at' => now()->addDays(2)->setTime(14, 0),
            'ends_at' => now()->addDays(2)->setTime(16, 0),
            'location_label' => 'Building A - Room 304',
            'category' => 'Workshop',
            'capacity' => 50,
        ]);

        Event::factory()->published()->create([
            'title' => 'ITC Football Friendly',
            'description' => 'Casual 7-a-side on the campus field. Bring turf or indoor shoes. Limited to two teams plus substitutes.',
            'starts_at' => now()->addDays(3)->setTime(17, 0),
            'ends_at' => now()->addDays(3)->setTime(19, 0),
            'location_label' => 'Campus football field',
            'category' => 'Sports',
            'capacity' => 28,
        ]);

        Event::factory()->published()->create([
            'title' => 'IT Gathering',
            'description' => 'Lightning talks from student contributors, then a guided GitHub workflow. Come with a repo you want feedback on, or just listen.',
            'starts_at' => now()->addDays(5)->setTime(16, 0),
            'ends_at' => now()->addDays(5)->setTime(18, 0),
            'location_label' => 'Building B - Room 204',
            'category' => 'Meetup',
            'capacity' => 60,
        ]);

        Event::factory()->published()->create([
            'title' => 'Campus Career Fair',
            'description' => 'Meet employers hiring ITC students for internships and full-time roles. Bring a printed CV and your student ID.',
            'starts_at' => now()->addDays(7)->setTime(9, 0),
            'ends_at' => now()->addDays(7)->setTime(16, 0),
            'location_label' => 'Building A - Hall',
            'category' => 'Career',
            'capacity' => 80,
        ]);

        Event::factory()->published()->create([
            'title' => 'AI Bootcamp',
            'description' => 'Two-hour intro to using large language models for campus projects. We will cover prompting, a small demo app, and what not to submit as coursework. Laptops required.',
            'starts_at' => now()->addDays(8)->setTime(15, 0),
            'ends_at' => now()->addDays(8)->setTime(17, 0),
            'location_label' => 'Building C - Lab 2',
            'category' => 'Workshop',
            'capacity' => 45,
        ]);

        Event::factory()->create([
            'title' => 'New Student Orientation',
            'description' => 'Campus walkthrough, faculty intros, and how to use ITC Events for tickets and check-in. Not on Home until published.',
            'starts_at' => now()->addDays(10)->setTime(9, 0),
            'ends_at' => now()->addDays(10)->setTime(12, 0),
            'location_label' => 'Building A - Room 101',
            'category' => 'Academic',
            'capacity' => 120,
        ]);
    }
}
