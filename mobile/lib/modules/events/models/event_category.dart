/// Allowed event categories. Keep in sync with `App\Enums\EventCategory`.
abstract final class EventCategory {
  static const workshop = 'Workshop';
  static const meetup = 'Meetup';
  static const academic = 'Academic';
  static const sports = 'Sports';
  static const club = 'Club';
  static const career = 'Career';
  static const social = 'Social';
  static const general = 'General';

  static const values = [
    workshop,
    meetup,
    academic,
    sports,
    club,
    career,
    social,
    general,
  ];
}
