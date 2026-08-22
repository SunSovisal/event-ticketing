<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('check_in_attempts', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('scanned_by')->constrained('users');
            $table->foreignUuid('ticket_id')->nullable()->constrained('tickets');
            $table->foreignUuid('event_id')->nullable()->constrained('events');
            $table->string('scanned_code', 64);
            $table->string('method');
            $table->string('result');
            $table->timestamp('created_at');

            $table->index(['ticket_id', 'created_at']);
            $table->index(['event_id', 'created_at']);
            $table->index(['scanned_by', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('check_in_attempts');
    }
};
