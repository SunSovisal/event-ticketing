<?php

namespace App\Enums;

enum PaymentMethod: string
{
    case Khqr = 'khqr';
    case AbaPay = 'aba_pay';

    /**
     * @return list<string>
     */
    public static function values(): array
    {
        return array_column(self::cases(), 'value');
    }
}
