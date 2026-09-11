<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'postmark' => [
        'key' => env('POSTMARK_API_KEY'),
    ],

    'resend' => [
        'key' => env('RESEND_API_KEY'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env('SLACK_BOT_USER_OAUTH_TOKEN'),
            'channel' => env('SLACK_BOT_USER_DEFAULT_CHANNEL'),
        ],
    ],

    'cloudinary' => [
        'cloud_name' => env('CLOUDINARY_CLOUD_NAME'),
        'api_key' => env('CLOUDINARY_API_KEY'),
        'api_secret' => env('CLOUDINARY_API_SECRET'),
    ],

    'openrouter' => [
        'key' => env('OPENROUTER_API_KEY'),
        'base_url' => env('OPENROUTER_BASE_URL', 'https://openrouter.ai/api/v1'),
        'model' => env('OPENROUTER_MODEL', 'google/gemini-2.5-flash'),
        'max_tokens' => (int) env('OPENROUTER_MAX_TOKENS', 512),
        'daily_limit' => (int) env('CHAT_DAILY_LIMIT', 30),
    ],

    'bakong' => [
        'account_id' => env('BAKONG_ACCOUNT_USERNAME'),
        'account_name' => env('BAKONG_ACCOUNT_NAME'),
        'merchant_city' => env('BAKONG_MERCHANT_CITY', 'PHNOM PENH'),
        'access_token' => env('BAKONG_ACCESS_TOKEN'),
        'base_url' => env('BAKONG_BASE_API_URL', env('BAKONG_PROD_BASE_API_URL', 'https://api-bakong.nbc.gov.kh/v1')),
        'qr_ttl_seconds' => (int) env('BAKONG_QR_TTL_SECONDS', 300),
        'grace_seconds' => (int) env('BAKONG_GRACE_SECONDS', 300),
        'daily_limit' => (int) env('BAKONG_DAILY_LIMIT', 100),
        'min_check_seconds' => (int) env('BAKONG_MIN_CHECK_SECONDS', 20),
    ],

    'payway' => [
        'merchant_id' => env('PAYWAY_MERCHANT_ID'),
        'api_key' => env('PAYWAY_API_KEY'),
        'base_url' => env('PAYWAY_BASE_URL', 'https://checkout-sandbox.payway.com.kh'),
        'qr_template' => env('PAYWAY_QR_TEMPLATE', 'template3_color'),
        'sandbox' => filter_var(
            env('PAYWAY_SANDBOX', str_contains((string) env('PAYWAY_BASE_URL', 'sandbox'), 'sandbox')),
            FILTER_VALIDATE_BOOLEAN,
        ),
    ],

];
