import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/theme/app_theme.dart';
import 'package:itc_events/app/widgets/app_card.dart';
import 'package:itc_events/app/widgets/app_snackbar.dart';
import 'package:itc_events/app/widgets/status_chip.dart';
import 'package:itc_events/modules/admin/events/event_controller.dart';
import 'package:itc_events/modules/events/event.dart';
import 'package:itc_events/modules/events/event_category.dart';

class AdminEventFormPage extends StatefulWidget {
  const AdminEventFormPage({super.key, this.event});

  final Event? event;

  @override
  State<AdminEventFormPage> createState() => _AdminEventFormPageState();
}

class _AdminEventFormPageState extends State<AdminEventFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final AdminEventController _controller;

  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _location;
  late final TextEditingController _capacity;
  late String _category;

  Event? _event;
  DateTime? _startsAtLocal;
  DateTime? _endsAtLocal;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<AdminEventController>();
    _controller.errorMessage.value = null;
    _event = widget.event;

    _title = TextEditingController(text: _event?.title ?? '');
    _description = TextEditingController(text: _event?.description ?? '');
    _location = TextEditingController(text: _event?.locationLabel ?? '');
    _capacity = TextEditingController(
      text: _event?.capacity.toString() ?? '50',
    );
    _category = _event?.category ?? EventCategory.general;
    _startsAtLocal = _event?.startsAt.toLocal();
    _endsAtLocal = _event?.endsAt?.toLocal();
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    _capacity.dispose();
    super.dispose();
  }

  bool get _readOnly => _event?.isCancelled ?? false;

  Map<String, dynamic>? _bodyOrNull() {
    if (!(_formKey.currentState?.validate() ?? false)) return null;

    if (_startsAtLocal == null) {
      _controller.errorMessage.value = 'Start date and time are required.';
      return null;
    }

    if (_endsAtLocal != null && !_endsAtLocal!.isAfter(_startsAtLocal!)) {
      _controller.errorMessage.value = 'End time must be after the start time.';
      return null;
    }

    return {
      'title': _title.text.trim(),
      'description': _description.text.trim(),
      'starts_at': _startsAtLocal!.toUtc().toIso8601String(),
      'ends_at': _endsAtLocal?.toUtc().toIso8601String(),
      'location_label': _location.text.trim(),
      'category': _category,
      'capacity': int.parse(_capacity.text.trim()),
    };
  }

  Future<bool> _save() async {
    final body = _bodyOrNull();
    if (body == null) return false;

    final saved = _event == null
        ? await _controller.createEvent(body)
        : await _controller.updateEvent(_event!.id, body);

    if (saved == null) return false;

    setState(() => _event = saved);
    return true;
  }

  Future<void> _onSave() async {
    final ok = await _save();
    if (!ok || !mounted) return;

    final message = _event?.isDraft == true ? 'Draft saved.' : 'Event updated.';
    Navigator.pop(context);
    AppSnackbar.success(message, title: 'Saved');
  }

  Future<void> _onPublish() async {
    if (!await _save()) return;

    final confirmed = await _confirm(
      title: 'Publish event?',
      message: 'It will appear on Home for attendees.',
      action: 'Publish',
    );
    if (!confirmed) return;

    final published = await _controller.publishEvent(_event!.id);
    if (published == null || !mounted) return;
    setState(() => _event = published);
    AppSnackbar.success('It now appears on Home.', title: 'Published');
  }

  Future<void> _onCancelEvent() async {
    final confirmed = await _confirm(
      title: 'Cancel event?',
      message:
          'Tickets for this event will be cancelled. This cannot be undone.',
      action: 'Cancel event',
      destructive: true,
    );
    if (!confirmed) return;

    final cancelled = await _controller.cancelEvent(_event!.id);
    if (cancelled == null || !mounted) return;
    setState(() => _event = cancelled);
    AppSnackbar.warning(
      'Tickets for this event were cancelled.',
      title: 'Cancelled',
    );
  }

  Future<void> _onDelete() async {
    final confirmed = await _confirm(
      title: 'Delete draft?',
      message: 'This draft will be removed. This cannot be undone.',
      action: 'Delete',
      destructive: true,
    );
    if (!confirmed) return;

    final ok = await _controller.deleteDraft(_event!.id);
    if (!ok || !mounted) return;
    Navigator.pop(context);
    AppSnackbar.success('The draft was removed.', title: 'Deleted');
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String action,
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: destructive
                ? FilledButton.styleFrom(backgroundColor: AppTheme.error)
                : null,
            child: Text(action),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _pickStart() async {
    final picked = await _pickDateTime(_startsAtLocal ?? DateTime.now());
    if (picked != null) setState(() => _startsAtLocal = picked);
  }

  Future<void> _pickEnd() async {
    final picked = await _pickDateTime(
      _endsAtLocal ??
          (_startsAtLocal ?? DateTime.now()).add(const Duration(hours: 2)),
    );
    if (picked != null) setState(() => _endsAtLocal = picked);
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );
    if (date == null || !mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String _formatLocal(DateTime? value) {
    if (value == null) return 'Not set';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${value.day}/${value.month}/${value.year}  ${two(value.hour)}:${two(value.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final event = _event;
    final title = event == null ? 'New event' : 'Edit event';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Obx(() {
        final saving = _controller.isSaving.value;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            if (event != null) ...[
              Row(
                children: [
                  StatusChip.eventStatus(event.status),
                  const Spacer(),
                  Text(
                    '${event.reservedCount} reserved · ${event.checkedInCount} checked in',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            Form(
              key: _formKey,
              child: AppCard(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _title,
                      enabled: !_readOnly,
                      maxLength: 120,
                      decoration: const InputDecoration(labelText: 'Title'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Title is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _description,
                      enabled: !_readOnly,
                      minLines: 3,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Description is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _location,
                      enabled: !_readOnly,
                      maxLength: 120,
                      decoration: const InputDecoration(labelText: 'Location'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Location is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: [
                        for (final category in EventCategory.values)
                          DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ),
                      ],
                      onChanged: _readOnly
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() => _category = value);
                              }
                            },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _capacity,
                      enabled: !_readOnly,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Capacity (1–500)',
                      ),
                      validator: (value) {
                        final n = int.tryParse(value ?? '');
                        if (n == null || n < 1 || n > 500) {
                          return 'Enter a number from 1 to 500';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Starts at'),
                      subtitle: Text(_formatLocal(_startsAtLocal)),
                      trailing: const Icon(Icons.calendar_today_outlined),
                      onTap: _readOnly ? null : _pickStart,
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Ends at (optional)'),
                      subtitle: Text(_formatLocal(_endsAtLocal)),
                      trailing: _endsAtLocal == null || _readOnly
                          ? const Icon(Icons.schedule_outlined)
                          : IconButton(
                              tooltip: 'Clear end time',
                              onPressed: () =>
                                  setState(() => _endsAtLocal = null),
                              icon: const Icon(Icons.clear),
                            ),
                      onTap: _readOnly ? null : _pickEnd,
                    ),
                  ],
                ),
              ),
            ),
            if (_controller.errorMessage.value != null) ...[
              const SizedBox(height: 12),
              Text(
                _controller.errorMessage.value!,
                style: const TextStyle(color: AppTheme.error),
              ),
            ],
            const SizedBox(height: 20),
            if (!_readOnly)
              FilledButton(
                onPressed: saving ? null : _onSave,
                child: saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(event == null ? 'Save draft' : 'Save changes'),
              ),
            if (event?.canPublish == true) ...[
              const SizedBox(height: 12),
              FilledButton(
                onPressed: saving ? null : _onPublish,
                child: const Text('Publish'),
              ),
            ],
            if (event?.canCancelEvent == true) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: saving ? null : _onCancelEvent,
                child: const Text('Cancel event'),
              ),
            ],
            if (event?.canDelete == true) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: saving ? null : _onDelete,
                child: const Text(
                  'Delete draft',
                  style: TextStyle(color: AppTheme.error),
                ),
              ),
            ],
          ],
        );
      }),
    );
  }
}
