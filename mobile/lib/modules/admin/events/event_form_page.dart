import 'dart:ffi';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:itc_events/app/theme/app_theme.dart';
import 'package:itc_events/app/widgets/app_card.dart';
import 'package:itc_events/app/widgets/app_page_bar.dart';
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
  File? _coverImage;

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
      _controller.errorMessage.value = 'start_required'.tr;
      return null;
    }

    if (_endsAtLocal != null && !_endsAtLocal!.isAfter(_startsAtLocal!)) {
      _controller.errorMessage.value = 'end_after_start'.tr;
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

    var updatedEvent = saved;

    if (_coverImage != null) {
      final uploaded = await _controller.uploadCover(saved.id, _coverImage!);

      if (uploaded == null) {
        return false;
      }

      updatedEvent = uploaded;
    }

    if (!mounted) return false;

    setState(() {
      _event = updatedEvent;
      _coverImage = null;
    });
    return true;
  }

  Future<void> _onSave() async {
    final ok = await _save();
    if (!ok || !mounted) return;

    final message = _event?.isDraft == true
        ? 'draft_saved'.tr
        : 'event_updated'.tr;
    Navigator.pop(context);
    AppSnackbar.success(message, title: 'saved_title'.tr);
  }

  Future<void> _onPublish() async {
    if (!await _save()) return;

    final confirmed = await _confirm(
      title: 'publish_event_q'.tr,
      message: 'publish_event_body'.tr,
      action: 'publish'.tr,
    );
    if (!confirmed) return;

    final published = await _controller.publishEvent(_event!.id);
    if (published == null || !mounted) return;
    setState(() => _event = published);
    AppSnackbar.success('now_on_home'.tr, title: 'published_title'.tr);
  }

  Future<void> _onCancelEvent() async {
    final confirmed = await _confirm(
      title: 'cancel_event_q'.tr,
      message: 'cancel_event_body'.tr,
      action: 'cancel_event'.tr,
      destructive: true,
    );
    if (!confirmed) return;

    final cancelled = await _controller.cancelEvent(_event!.id);
    if (cancelled == null || !mounted) return;
    setState(() => _event = cancelled);
    AppSnackbar.warning(
      'tickets_cancelled_msg'.tr,
      title: 'cancelled_title'.tr,
    );
  }

  Future<void> _onDelete() async {
    final confirmed = await _confirm(
      title: 'delete_draft_q'.tr,
      message: 'delete_draft_body'.tr,
      action: 'delete'.tr,
      destructive: true,
    );
    if (!confirmed) return;

    final ok = await _controller.deleteDraft(_event!.id);
    if (!ok || !mounted) return;
    Navigator.pop(context);
    AppSnackbar.success('draft_removed'.tr, title: 'deleted_title'.tr);
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
            child: Text('back'.tr),
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

  Future<void> _pickCoverImage() async {
    if (_readOnly) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() {
      _coverImage = File(picked.path);
    });
  }

  Future<void> _deleteCover() async {
    if (_event == null || _event!.imageUrl == null) return;

    final confirmed = await _confirm(
      title: 'Delete cover image?',
      message: 'Are you sure you want to delete this cover image?',
      action: 'Delete',
      destructive: true,
    );

    if (!confirmed) return;

    final deleted = await _controller.deleteCover(_event!.id);

    if (deleted == null || !mounted) return;

    setState(() {
      _event = deleted;
      _coverImage = null;
    });

    AppSnackbar.success('Cover image deleted', title: 'Deleted');
  }

  String _formatLocal(DateTime? value) {
    if (value == null) return 'not_set'.tr;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${value.day}/${value.month}/${value.year}  ${two(value.hour)}:${two(value.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final event = _event;
    final title = event == null ? 'new_event'.tr : 'edit_event'.tr;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldOf(context),
      appBar: AppPageBar(title: title),
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
                    // Event Cover Image
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: _readOnly ? null : _pickCoverImage,
                          child: Container(
                            width: double.infinity,
                            height: 180,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _coverImage != null
                                ? Image.file(
                                    _coverImage!,
                                    width: double.infinity,
                                    height: 180,
                                    fit: BoxFit.cover,
                                  )
                                : _event?.imageUrl != null
                                ? Image.network(
                                    _event!.imageUrl!,
                                    width: double.infinity,
                                    height: 180,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildCoverPlaceholder();
                                    },
                                  )
                                : _buildCoverPlaceholder(),
                          ),
                        ),

                        // Delete cover button
                        if (!_readOnly &&
                            _event?.imageUrl != null &&
                            _coverImage == null)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Material(
                              color: Colors.black54,
                              shape: const CircleBorder(),
                              child: IconButton(
                                tooltip: 'Delete cover image',
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.white,
                                ),
                                onPressed: _controller.isSaving.value
                                    ? null
                                    : _deleteCover,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _title,
                      enabled: !_readOnly,
                      maxLength: 120,
                      decoration: InputDecoration(labelText: 'title_label'.tr),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'title_required'.tr;
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
                      decoration: InputDecoration(labelText: 'description'.tr),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'description_required'.tr;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _location,
                      enabled: !_readOnly,
                      maxLength: 120,
                      decoration: InputDecoration(labelText: 'location'.tr),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'location_required'.tr;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: InputDecoration(labelText: 'category'.tr),
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
                      decoration: InputDecoration(
                        labelText: 'capacity_label'.tr,
                      ),
                      validator: (value) {
                        final n = int.tryParse(value ?? '');
                        if (n == null || n < 1 || n > 500) {
                          return 'capacity_range'.tr;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('starts_at'.tr),
                      subtitle: Text(_formatLocal(_startsAtLocal)),
                      trailing: const Icon(Icons.calendar_today_outlined),
                      onTap: _readOnly ? null : _pickStart,
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('ends_at_optional'.tr),
                      subtitle: Text(_formatLocal(_endsAtLocal)),
                      trailing: _endsAtLocal == null || _readOnly
                          ? const Icon(Icons.schedule_outlined)
                          : IconButton(
                              tooltip: 'clear_end_time'.tr,
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
                    : Text(event == null ? 'save_draft'.tr : 'save_changes'.tr),
              ),
            if (event?.canPublish == true) ...[
              const SizedBox(height: 12),
              FilledButton(
                onPressed: saving ? null : _onPublish,
                child: Text('publish'.tr),
              ),
            ],
            if (event?.canCancelEvent == true) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: saving ? null : _onCancelEvent,
                child: Text('cancel_event'.tr),
              ),
            ],
            if (event?.canDelete == true) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: saving ? null : _onDelete,
                child: Text(
                  'delete_draft'.tr,
                  style: const TextStyle(color: AppTheme.error),
                ),
              ),
            ],
          ],
        );
      }),
    );
  }

  Widget _buildCoverPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.add_photo_alternate_outlined, size: 48),
        const SizedBox(height: 8),
        Text(
          'Upload cover image',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
