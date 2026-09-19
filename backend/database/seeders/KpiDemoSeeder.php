<?php

namespace Database\Seeders;

use App\Models\CheckInAttempt;
use App\Models\Event;
use App\Models\EventView;
use App\Models\Payment;
use App\Models\SavedEvent;
use App\Models\Ticket;
use App\Models\User;
use App\Models\UserProfile;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class KpiDemoSeeder extends Seeder
{
    public function run(): void
    {
        $admin = User::query()->where('is_admin', true)->first()
            ?? User::factory()->admin()->create([
                'email' => 'kpi-admin@itc.edu.kh',
                'name' => 'KPI Admin',
            ]);

        $departments = ['GIC', 'GEE', 'GCA', 'GGG', 'GIM'];
        $names = [
            'Sok Dara',
            'Lin Chea',
            'Pich Sopha',
            'Chan Sophea',
            'Sun Visal',
            'Tep Makara',
            'Kim Sokha',
            'Narun Sreypov',
            'Hun Vanna',
            'Mao Rattana',
            'Seng Bora',
            'Uk Sokhom',
            'Chamroeun Phally',
            'Vannak Sokheng',
            'Lim Sovann',
            'Nguon Chantra',
            'Pol Sreynoun',
            'Tem Sophean',
            'Siem Reaksmey',
            'Huot Monorom',
            'Khat Sokhla',
            'Yim Panhnha',
            'Phan Sovannary',
            'Keo Vicheka',
        ];
        $attendees = collect($names)->map(function (string $name, int $index) use ($departments) {
            $attendee = User::query()->firstOrCreate(
                ['email' => 'student'.($index + 1).'@student.itc.edu.kh'],
                [
                    'firebase_uid' => 'kpi-demo-'.($index + 1),
                    'name' => $name,
                    'is_admin' => false,
                    'is_active' => true,
                ],
            );
            $attendee->update(['name' => $name]);

            UserProfile::query()->updateOrCreate(
                ['user_id' => $attendee->id],
                [
                    'student_id' => null,
                    'department' => $departments[$index % count($departments)],
                    'year' => ($index % 4) + 1,
                ],
            );

            return $attendee;
        });

        // Past events are KPI-only (EventSeeder only creates upcoming ones).
        $pastPaid = $this->pastPublishedEvent(
            title: 'Spring Hack Night',
            category: 'Workshop',
            location: 'Building A - Hall',
            capacity: 40,
            daysAgo: 6,
            startHour: 16,
            endHour: 18,
            paid: true,
        );
        $pastCareer = $this->pastPublishedEvent(
            title: 'August Career Meetup',
            category: 'Career',
            location: 'Building A - Hall',
            capacity: 80,
            daysAgo: 12,
            startHour: 9,
            endHour: 16,
        );
        $pastSports = $this->pastPublishedEvent(
            title: 'Inter-faculty Football',
            category: 'Sports',
            location: 'Campus football field',
            capacity: 28,
            daysAgo: 20,
            startHour: 17,
            endHour: 19,
        );

        $upcomingWorkshop = $this->existingEvent('Intro to Flutter Workshop');
        $upcomingMeetup = $this->existingEvent('IT Gathering');
        $upcomingCodingDay = $this->existingEvent('ITC Coding Day');

        $this->firstOrCreateCancelledClubNight();

        $this->seedAttendance($pastPaid, $attendees->take(24), $admin, paid: true, checkInShare: 0.76);
        $this->seedAttendance($pastCareer, $attendees->take(24), $admin, paid: false, checkInShare: 0.72);
        $this->seedAttendance($pastSports, $attendees->take(22), $admin, paid: false, checkInShare: 0.8);
        if ($upcomingWorkshop !== null) {
            $this->seedAttendance($upcomingWorkshop, $attendees->take(18), $admin, paid: false, checkInShare: 0);
        }
        if ($upcomingMeetup !== null) {
            $this->seedAttendance($upcomingMeetup, $attendees->take(12), $admin, paid: false, checkInShare: 0);
        }
        if ($upcomingCodingDay !== null) {
            $this->seedAttendance($upcomingCodingDay, $attendees->take(10), $admin, paid: true, checkInShare: 0);
        }
    }

    /**
     * @param  \Illuminate\Support\Collection<int, User>  $attendees
     */
    private function seedAttendance(
        Event $event,
        $attendees,
        User $admin,
        bool $paid,
        float $checkInShare,
    ): void {
        $checkInCount = (int) floor($attendees->count() * $checkInShare);

        foreach ($attendees->values() as $index => $attendee) {
            if (Ticket::query()->where('event_id', $event->id)->where('user_id', $attendee->id)->exists()) {
                continue;
            }
            $issuedAt = $event->starts_at->copy()->subDays(rand(1, 8))->setTime(rand(9, 20), rand(0, 59));
            $checkedIn = $index < $checkInCount;
            $ticket = Ticket::factory()->create([
                'event_id' => $event->id,
                'user_id' => $attendee->id,
                'status' => $checkedIn ? 'checked_in' : 'valid',
                'checked_in_at' => $checkedIn
                    ? $event->starts_at->copy()->addMinutes(rand(-90, 80))
                    : null,
                'checked_in_by' => $checkedIn ? $admin->id : null,
            ]);
            Ticket::query()->whereKey($ticket->id)->update(['created_at' => $issuedAt]);

            if ($paid) {
                $qr = '000201'.Str::lower(Str::random(40));
                Payment::factory()->paid()->create([
                    'event_id' => $event->id,
                    'user_id' => $attendee->id,
                    'ticket_id' => $ticket->id,
                    'amount' => $event->price_amount,
                    'currency' => $event->price_currency,
                    'method' => $index % 4 === 0 ? 'aba_pay' : 'khqr',
                    'qr_code' => $qr,
                    'qr_md5' => md5($qr),
                    'paid_at' => $issuedAt->copy()->addMinutes(8),
                ]);
            }

            if ($index % 3 === 0) {
                SavedEvent::query()->firstOrCreate([
                    'user_id' => $attendee->id,
                    'event_id' => $event->id,
                ]);
            }

            EventView::query()->create([
                'event_id' => $event->id,
                'user_id' => $attendee->id,
            ]);
            EventView::query()->create([
                'event_id' => $event->id,
                'user_id' => null,
            ]);

            if ($checkedIn) {
                CheckInAttempt::query()->create([
                    'scanned_by' => $admin->id,
                    'ticket_id' => $ticket->id,
                    'event_id' => $event->id,
                    'scanned_code' => $ticket->ticket_code,
                    'method' => 'qr',
                    'result' => 'success',
                    'created_at' => $ticket->checked_in_at ?? now(),
                ]);
            } elseif ($index % 7 === 0) {
                CheckInAttempt::query()->create([
                    'scanned_by' => $admin->id,
                    'ticket_id' => $ticket->id,
                    'event_id' => $event->id,
                    'scanned_code' => $ticket->ticket_code,
                    'method' => 'qr',
                    'result' => 'too_early',
                    'created_at' => $event->starts_at->copy()->subHours(3),
                ]);
            }
        }
    }

    private function existingEvent(string $title): ?Event
    {
        return Event::query()->where('title', $title)->first();
    }

    private function pastPublishedEvent(
        string $title,
        string $category,
        string $location,
        int $capacity,
        int $daysAgo,
        int $startHour,
        int $endHour,
        bool $paid = false,
    ): Event {
        $existing = $this->existingEvent($title);
        if ($existing !== null) {
            return $existing;
        }

        $factory = Event::factory()->published();
        if ($paid) {
            $factory = $factory->paid('0.01', 'USD');
        }

        return $factory->create([
            'title' => $title,
            'category' => $category,
            'location_label' => $location,
            'capacity' => $capacity,
            'starts_at' => now()->subDays($daysAgo)->setTime($startHour, 0),
            'ends_at' => now()->subDays($daysAgo)->setTime($endHour, 0),
        ]);
    }

    private function firstOrCreateCancelledClubNight(): void
    {
        if ($this->existingEvent('Cancelled club night') !== null) {
            return;
        }

        Event::factory()->cancelled()->create([
            'title' => 'Cancelled club night',
            'category' => 'Club',
            'capacity' => 40,
            'starts_at' => now()->addDays(4)->setTime(18, 0),
        ]);
    }
}
