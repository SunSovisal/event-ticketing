import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/modules/auth/auth_controller.dart';
import 'package:itc_events/modules/auth/widgets/sign_in_sheet.dart';
import 'package:itc_events/modules/events/event.dart';
import 'package:itc_events/modules/events/event_controller.dart';
import 'package:itc_events/modules/events/saved_event_controller.dart';

Future<void> toggleEventBookmark(BuildContext context, Event event) async {
  if (!Get.isRegistered<EventController>()) {
    return;
  }

  final events = Get.find<EventController>();
  final auth = Get.isRegistered<AuthController>()
      ? Get.find<AuthController>()
      : null;

  if (auth == null || !auth.isSignedIn) {
    final signedIn = await showSignInSheet(context);
    if (!signedIn) {
      return;
    }
    await events.fetchEvents();
    final latest = _latest(events, event);
    if (latest.isSaved) {
      return;
    }
    await events.toggleSave(latest);
    return;
  }

  await events.toggleSave(_latest(events, event));
}

Event _latest(EventController events, Event event) {
  return events.byId(event.id) ??
      (Get.isRegistered<SavedEventController>()
          ? Get.find<SavedEventController>().byId(event.id)
          : null) ??
      event;
}
