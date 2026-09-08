import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/theme/app_theme.dart';
import 'package:itc_events/app/widgets/app_page_bar.dart';
import 'package:itc_events/modules/admin/check_in/check_in_page.dart';
import 'package:itc_events/modules/admin/check_in/scanner_page.dart';
import 'package:itc_events/modules/admin/events/events_page.dart';
import 'package:itc_events/modules/auth/auth_controller.dart';
import 'package:itc_events/modules/auth/sign_in/phone_sign_in_page.dart';
import 'package:itc_events/modules/auth/sign_in/sign_in_page.dart';
import 'package:itc_events/modules/auth/profile/settings_page.dart';
import 'package:itc_events/modules/auth/profile/widgets/campus_profile_fields.dart';
import 'package:itc_events/modules/events/saved/saved_events_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _showEditProfileDialog(
    BuildContext context,
    AuthController auth,
  ) async {
    auth.errorMessage.value = '';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _EditProfileDialog(auth: auth),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return Obx(() {
      final me = auth.me.value;
      final studentId = me?['student_id']?.toString();
      final department = me?['department']?.toString();
      final year = me?['year'];
      final campusParts = <String>[
        if (studentId != null && studentId.isNotEmpty) studentId,
        if (department != null && department.isNotEmpty) department,
        if (year != null) 'year_n'.trParams({'year': '$year'}),
      ];

      return Scaffold(
        backgroundColor: AppTheme.scaffoldOf(context),
        appBar: AppPageBar(
          title: 'nav_profile'.tr,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                tooltip: 'settings'.tr,
                onPressed: () => Get.to(() => const SettingsPage()),
                icon: const Icon(Icons.settings_outlined),
              ),
            ),
          ],
        ),
        body: me == null
            ? _SignedOutProfile()
            : ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
                children: [
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  me['name']?.toString() ?? 'no_name'.tr,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  me['email']?.toString() ?? '',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                if (campusParts.isNotEmpty) ...[
                                  SizedBox(height: 4),
                                  Text(
                                    campusParts.join(' · '),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                                if (auth.isAdmin) ...[
                                  SizedBox(height: 8),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'admin'.tr,
                                      style: TextStyle(
                                        color: AppTheme.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'edit_profile'.tr,
                            onPressed: () =>
                                _showEditProfileDialog(context, auth),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.bookmark_outline,
                        color: AppTheme.primary,
                      ),
                      title: Text('saved_events'.tr),
                      trailing: Icon(Icons.chevron_right),
                      onTap: () => Get.to(() => const SavedEventsPage()),
                    ),
                  ),
                  if (auth.isAdmin) ...[
                    SizedBox(height: 16),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(
                              Icons.event_rounded,
                              color: AppTheme.primary,
                            ),
                            title: Text('manage_events'.tr),
                            subtitle: Text('manage_events_subtitle'.tr),
                            trailing: Icon(Icons.chevron_right),
                            onTap: () => Get.to(() => const AdminEventsPage()),
                          ),
                          Divider(height: 1),
                          ListTile(
                            leading: Icon(
                              Icons.qr_code_scanner_rounded,
                              color: AppTheme.primary,
                            ),
                            title: Text('admin_scanner'.tr),
                            subtitle: Text('admin_scanner_subtitle'.tr),
                            trailing: Icon(Icons.chevron_right),
                            onTap: () => Get.to(() => const AdminScanerPage()),
                          ),
                          Divider(height: 1),
                          ListTile(
                            leading: Icon(
                              Icons.how_to_reg_rounded,
                              color: AppTheme.primary,
                            ),
                            title: Text('manual_check_in'.tr),
                            subtitle: Text('manual_check_in_subtitle'.tr),
                            trailing: Icon(Icons.chevron_right),
                            onTap: () => Get.to(() => const AdminCheckInPage()),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: 16),
                  _LinkedProvidersCard(auth: auth),
                  SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: () => auth.signOut(),
                    child: Text('sign_out'.tr),
                  ),
                ],
              ),
      );
    });
  }
}

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({required this.auth});

  final AuthController auth;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _studentIdController;
  String? _department;
  int? _year;

  @override
  void initState() {
    super.initState();
    final me = widget.auth.me.value;
    _nameController = TextEditingController(
      text: me?['name']?.toString() ?? '',
    );
    _emailController = TextEditingController(
      text: me?['email']?.toString() ?? '',
    );
    _studentIdController = TextEditingController(
      text: me?['student_id']?.toString() ?? '',
    );
    _department = me?['department']?.toString();
    _year = _yearFrom(me?['year']);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _studentIdController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty || email.isEmpty) {
      widget.auth.errorMessage.value = 'name_email_required'.tr;
      return;
    }

    if (!GetUtils.isEmail(email)) {
      widget.auth.errorMessage.value = 'enter_valid_email'.tr;
      return;
    }

    await widget.auth.updateProfile(
      name: name,
      email: email,
      studentId: _studentIdController.text,
      department: _department,
      year: _year,
    );

    if (widget.auth.errorMessage.value.isEmpty && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('edit_profile'.tr),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: 'name'.tr),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: 'email'.tr),
              ),
              const SizedBox(height: 16),
              CampusProfileFields(
                studentIdController: _studentIdController,
                department: _department,
                year: _year,
                onDepartmentChanged: (value) =>
                    setState(() => _department = value),
                onYearChanged: (value) => setState(() => _year = value),
              ),
              Obx(() {
                if (widget.auth.errorMessage.value.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    widget.auth.errorMessage.value,
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('cancel'.tr),
        ),
        Obx(
          () => FilledButton(
            onPressed: widget.auth.isLoading.value ? null : _save,
            child: widget.auth.isLoading.value
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('save'.tr),
          ),
        ),
      ],
    );
  }
}

int? _yearFrom(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '');
}

class _SignedOutProfile extends StatelessWidget {
  const _SignedOutProfile();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          Icon(
            Icons.person_outline,
            size: 56,
            color: AppTheme.textSecondaryOf(context),
          ),
          const SizedBox(height: 16),
          Text(
            'signed_out_message'.tr,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Get.to(() => const SignInPage()),
            child: Text('sign_in'.tr),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

// Linked sign-in methods card
class _LinkedProvidersCard extends StatelessWidget {
  const _LinkedProvidersCard({required this.auth});

  final AuthController auth;

  static const _providers = [
    _ProviderMeta(
      id: 'password',
      labelKey: 'provider_email_password',
      icon: Icons.email_outlined,
    ),
    _ProviderMeta(
      id: 'google.com',
      labelKey: 'provider_google',
      imageAsset: 'assets/google_logo.png',
    ),
    _ProviderMeta(
      id: 'phone',
      labelKey: 'provider_phone',
      icon: Icons.phone_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final linked = auth.linkedProviderIds;

      return Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                'linked_sign_in_methods'.tr,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            if (auth.errorMessage.value.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Text(
                  auth.errorMessage.value,
                  style: TextStyle(color: AppTheme.error, fontSize: 13),
                ),
              ),
            for (int i = 0; i < _providers.length; i++) ...[
              if (i > 0) const Divider(height: 1),
              _ProviderTile(
                meta: _providers[i],
                isLinked: linked.contains(_providers[i].id),
                isLoading: auth.isLoading.value,
                onLink: () => _handleLink(context, _providers[i].id),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      );
    });
  }

  Future<void> _handleLink(BuildContext context, String providerId) async {
    auth.errorMessage.value = '';
    switch (providerId) {
      case 'google.com':
        await auth.linkWithGoogle();
      case 'phone':
        await Get.to(() => const PhoneSignInPage(linkMode: true));
      default:
        // email/password already linked at registration, no action
        break;
    }
  }
}

class _ProviderMeta {
  const _ProviderMeta({
    required this.id,
    required this.labelKey,
    this.icon,
    this.imageAsset,
  });

  final String id;
  final String labelKey;
  final IconData? icon;
  final String? imageAsset;
}

class _ProviderTile extends StatelessWidget {
  const _ProviderTile({
    required this.meta,
    required this.isLinked,
    required this.isLoading,
    required this.onLink,
  });

  final _ProviderMeta meta;
  final bool isLinked;
  final bool isLoading;
  final VoidCallback onLink;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: meta.imageAsset != null
          ? Image.asset(meta.imageAsset!, width: 26, height: 26)
          : Icon(
              meta.icon ?? Icons.link,
              color: isLinked ? AppTheme.primary : null,
            ),
      title: Text(meta.labelKey.tr),
      trailing: isLinked
          ? Chip(
              avatar: Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: AppTheme.primary,
              ),
              label: Text(
                'linked'.tr,
                style: TextStyle(fontSize: 12, color: AppTheme.primary),
              ),
              backgroundColor: AppTheme.primary.withValues(alpha: 0.08),
              side: BorderSide.none,
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )
          : meta.id == 'password'
          ? null // linking email/password isn't available
          : TextButton(
              onPressed: isLoading ? null : onLink,
              child: Text('link'.tr),
            ),
    );
  }
}
