<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

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
            'capacity' => ['required', 'integer', 'min:1', 'max:500'],
        ];
    }

    /**
     * @return array{title: string, description: string, starts_at: mixed, ends_at: mixed, location_label: string, capacity: int}
     */
    public function eventAttributes(): array
    {
        $validated = $this->validated();

        return [
            'title' => $validated['title'],
            'description' => $validated['description'],
            'starts_at' => $validated['starts_at'],
            'ends_at' => $validated['ends_at'] ?? null,
            'location_label' => $validated['location_label'],
            'capacity' => (int) $validated['capacity'],
        ];
    }

    protected function prepareForValidation(): void
    {
        $merge = [];

        foreach (['title', 'description', 'location_label'] as $field) {
            if ($this->exists($field) && is_string($this->input($field))) {
                $merge[$field] = trim($this->input($field));
            }
        }

        if ($merge !== []) {
            $this->merge($merge);
        }
    }
}
