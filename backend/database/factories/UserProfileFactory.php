<?php

namespace Database\Factories;

use App\Models\User;
use App\Models\UserProfile;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<UserProfile>
 */
class UserProfileFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'student_id' => fake()->unique()->numerify('e########'),
            'department' => fake()->randomElement(['GIC', 'GEE', 'GCA', 'GGI']),
            'year' => fake()->numberBetween(1, 4),
        ];
    }
}
