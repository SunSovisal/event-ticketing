<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('tickets', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('event_id')->constrained('events');
            $table->foreignUuid('user_id')->constrained('users');
            $table->string('ticket_code')->unique();
            $table->string('status');
            $table->timestamp('checked_in_at')->nullable();
            $table->foreignUuid('checked_in_by')->nullable()->constrained('users');
            $table->timestamps();

            $table->unique(['event_id', 'user_id']);
            $table->index(['user_id', 'created_at']);
            $table->index(['event_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('tickets');
    }
};
