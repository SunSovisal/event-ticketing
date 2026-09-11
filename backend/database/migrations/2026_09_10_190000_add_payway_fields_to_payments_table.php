<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('payments', function (Blueprint $table) {
            $table->string('payway_tran_id', 20)->nullable()->unique()->after('qr_md5');
            $table->text('aba_deeplink')->nullable()->after('payway_tran_id');
        });
    }

    public function down(): void
    {
        Schema::table('payments', function (Blueprint $table) {
            $table->dropColumn(['payway_tran_id', 'aba_deeplink']);
        });
    }
};
