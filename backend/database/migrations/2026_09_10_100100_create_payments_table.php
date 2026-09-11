<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('payments', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('event_id')->constrained('events');
            $table->foreignUuid('user_id')->constrained('users');
            $table->foreignUuid('ticket_id')->nullable()->constrained('tickets');
            $table->decimal('amount', 12, 2);
            $table->string('currency', 3);
            $table->string('status');
            $table->text('qr_code');
            $table->string('qr_md5', 32)->unique();
            $table->timestamp('qr_expires_at');
            $table->string('bakong_hash')->nullable();
            $table->string('from_account_id', 100)->nullable();
            $table->string('to_account_id', 100)->nullable();
            $table->timestamp('paid_at')->nullable();
            $table->timestamps();

            $table->unique(['event_id', 'user_id']);
            $table->index(['event_id', 'status']);
            $table->index(['qr_expires_at', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payments');
    }
};
