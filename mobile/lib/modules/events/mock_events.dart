import 'package:itc_events/modules/events/event.dart';

/// Temporary sample data for layout work. Replace when the events API exists.
abstract final class MockEvents {
  static const categories = ['All', 'Workshops', 'Career', 'Tech'];

  static final List<Event> all = [
    Event(
      id: 'evt-flutter-workshop',
      title: 'Intro to Flutter Workshop',
      description:
          'Hands-on session covering Flutter widgets, navigation, and calling the ITC Events API. Bring a laptop and student ID. Limited to 50 seats.',
      startsAt: DateTime.utc(2026, 8, 14, 7, 0),
      endsAt: DateTime.utc(2026, 8, 14, 9, 0),
      locationLabel: 'Building A - Room 304',
      capacity: 50,
      spotsRemaining: 47,
      reservedCount: 3,
      checkedInCount: 0,
      status: 'published',
      category: 'Workshops',
      imageUrl:
          'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=800',
    ),
    Event(
      id: 'evt-career-fair',
      title: 'ITC Career Fair 2026',
      description:
          'Meet employers from engineering, software, and infrastructure. Bring a printed CV and student ID. Talks run in the main hall; booths stay open until 16:00.',
      startsAt: DateTime.utc(2026, 9, 12, 7, 0),
      endsAt: DateTime.utc(2026, 9, 12, 9, 0),
      locationLabel: 'Building A - Main Hall',
      capacity: 200,
      spotsRemaining: 42,
      reservedCount: 158,
      checkedInCount: 0,
      status: 'published',
      category: 'Career',
      imageUrl:
          'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800',
    ),
    Event(
      id: 'evt-open-source',
      title: 'Open Source Meetup',
      description:
          'Lightning talks from student contributors and a guided GitHub workflow demo. Snacks provided in the lobby afterward.',
      startsAt: DateTime.utc(2026, 8, 20, 10, 0),
      endsAt: DateTime.utc(2026, 8, 20, 12, 0),
      locationLabel: 'Building B - Room 204',
      capacity: 60,
      spotsRemaining: 18,
      reservedCount: 42,
      checkedInCount: 0,
      status: 'published',
      category: 'Tech',
    ),
    Event(
      id: 'evt-sold-out',
      title: 'Robotics club demo night',
      description:
          'Live robot demos from student teams. This session is at capacity; join the waitlist at the club desk if seats open.',
      startsAt: DateTime.utc(2026, 9, 3, 10, 30),
      locationLabel: 'Building C - Lab 1',
      capacity: 50,
      spotsRemaining: 0,
      reservedCount: 50,
      checkedInCount: 12,
      status: 'published',
      category: 'Tech',
      imageUrl:
          'https://images.unsplash.com/photo-1485827404703-89b55fcc595e?w=800',
    ),
    Event(
      id: 'evt-draft-orientation',
      title: 'New student orientation (draft)',
      description:
          'Campus walkthrough and faculty intros. Still being scheduled — not visible on Home until published.',
      startsAt: DateTime.utc(2026, 10, 1, 1, 30),
      locationLabel: 'Building A - Room 101',
      capacity: 120,
      spotsRemaining: 120,
      reservedCount: 0,
      checkedInCount: 0,
      status: 'draft',
      category: 'Career',
    ),
    Event(
      id: 'evt-cancelled-hackathon',
      title: 'Weekend hackathon',
      description:
          'Cancelled due to a room conflict. Attendees will be notified; a new date will be announced later.',
      startsAt: DateTime.utc(2026, 8, 22, 2, 0),
      locationLabel: 'Building D - Room 310',
      capacity: 80,
      spotsRemaining: 80,
      reservedCount: 0,
      checkedInCount: 0,
      status: 'cancelled',
      category: 'Tech',
    ),
  ];

  static List<Event> get published =>
      all.where((event) => event.isPublished).toList();

  static Event? get featured =>
      published.isEmpty ? null : published.first;

  static Event? byId(String id) {
    for (final event in all) {
      if (event.id == id) return event;
    }
    return null;
  }
}
