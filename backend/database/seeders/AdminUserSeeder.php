<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class AdminUserSeeder extends Seeder
{
    public function run(): void
    {
        User::updateOrCreate(
            ['email' => 'admin@itc.edu.kh'],
            [
                'firebase_uid' => 'pending-' . Str::uuid(),
                'name' => 'ITC Admin',
                'is_admin' => true,
            ]
        );
    }
}