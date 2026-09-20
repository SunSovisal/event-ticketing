<?php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;

class CheckInRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'ticket_code' => ['required', 'string', 'max:64'],
            'method' => ['sometimes', 'in:qr,manual'],
        ];
    }

    public function ticketCode(): string
    {
        return (string) $this->validated('ticket_code');
    }

    public function checkInMethod(): string
    {
        return (string) ($this->validated('method') ?? 'qr');
    }
}
