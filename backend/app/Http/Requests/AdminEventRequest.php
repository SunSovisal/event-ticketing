<?php

namespace App\Http\Requests;

use App\Enums\EventCategory;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class AdminEventRequest extends FormRequest
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
            'title' => ['required', 'string', 'max:120'],
            'description' => ['required', 'string'],
            'starts_at' => ['required', 'date'],
            'ends_at' => ['nullable', 'date', 'after:starts_at'],
            'location_label' => ['required', 'string', 'max:120'],
            'category' => ['required', 'string', Rule::in(EventCategory::values())],
            'capacity' => ['required', 'integer', 'min:1', 'max:500'],
            'price_amount' => ['nullable', 'numeric', 'min:0', 'max:999999.99'],
            'price_currency' => ['nullable', 'string', Rule::in(['USD', 'KHR'])],
        ];
    }

    /**
     * @return array{title: string, description: string, starts_at: mixed, ends_at: mixed, location_label: string, category: string, capacity: int, price_amount: string, price_currency: string}
     */
    public function eventAttributes(): array
    {
        $validated = $this->validated();
        $currency = strtoupper((string) ($validated['price_currency'] ?? 'USD'));
        $amount = $validated['price_amount'] ?? 0;

        return [
            'title' => $validated['title'],
            'description' => $validated['description'],
            'starts_at' => $validated['starts_at'],
            'ends_at' => $validated['ends_at'] ?? null,
            'location_label' => $validated['location_label'],
            'category' => $validated['category'],
            'capacity' => (int) $validated['capacity'],
            'price_amount' => $amount,
            'price_currency' => $currency,
        ];
    }

    protected function prepareForValidation(): void
    {
        $merge = [];

        foreach (['title', 'description', 'location_label', 'category'] as $field) {
            if ($this->exists($field) && is_string($this->input($field))) {
                $merge[$field] = trim($this->input($field));
            }
        }

        if ($merge !== []) {
            $this->merge($merge);
        }
    }

    public function withValidator($validator): void
    {
        $validator->after(function ($validator): void {
            $amount = $this->input('price_amount');
            $currency = strtoupper((string) $this->input('price_currency', 'USD'));

            if ($amount === null || $amount === '') {
                return;
            }

            if ($currency === 'KHR' && (float) $amount > 0 && floor((float) $amount) != (float) $amount) {
                $validator->errors()->add('price_amount', 'KHR amounts must be whole riel.');
            }
        });
    }
}
