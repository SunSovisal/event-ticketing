<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('notifications', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('type', 40);
            $table->string('title', 160);
            $table->text('body');
            $table->foreignUuid('event_id')->nullable()->constrained('events')->nullOnDelete();
            $table->json('data');
            $table->timestamp('created_at');

            $table->unique(['type', 'event_id']);
            $table->index('created_at');
        });

        Schema::create('notification_reads', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignUuid('notification_id')->constrained('notifications')->cascadeOnDelete();
            $table->timestamp('read_at');

            $table->unique(['user_id', 'notification_id']);
            $table->index(['user_id', 'read_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('notification_reads');
        Schema::dropIfExists('notifications');
    }
};
