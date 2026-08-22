<?php

namespace Database\Factories;

use App\Models\Event;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Event>
 */
class EventFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'title' => fake()->sentence(4),
            'description' => fake()->paragraph(),
            'starts_at' => now()->addDays(7)->startOfHour(),
            'ends_at' => null,
            'location_label' => 'Building A - Room 204',
            'capacity' => 50,
            'status' => 'draft',
            'image_url' => null,
            'image_public_id' => null,
        ];
    }

    public function published(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'published',
        ]);
    }

    public function cancelled(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'cancelled',
        ]);
    }

    public function ended(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'published',
            'starts_at' => now()->subHours(5),
            'ends_at' => now()->subHours(3),
        ]);
    }
}
