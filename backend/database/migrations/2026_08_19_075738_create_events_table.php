<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('events', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('title', 120);
            $table->text('description');
            $table->timestamp('starts_at');
            $table->timestamp('ends_at')->nullable();
            $table->string('location_label', 120);
            $table->unsignedSmallInteger('capacity');
            $table->string('status');
            $table->string('image_url')->nullable();
            $table->string('image_public_id')->nullable();
            $table->timestamps();

            $table->index(['status', 'starts_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('events');
    }
};
