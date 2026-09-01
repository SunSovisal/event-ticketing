import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/theme/app_theme.dart';
import 'package:itc_events/modules/admin/admin_events_page.dart';
import 'package:itc_events/modules/auth/auth_controller.dart';
import 'package:itc_events/modules/auth/phone_sign_in_page.dart';
import 'package:itc_events/modules/auth/sign_in_page.dart';
import 'package:itc_events/app/theme/them_controller_page.dart';
import 'package:itc_events/modules/auth/widgets/campus_profile_fields.dart';
import 'package:itc_events/modules/events/saved_events_page.dart';
import 'package:itc_events/modules/health/health_binding.dart';
import 'package:itc_events/modules/health/health_page.dart';
import 'package:itc_events/modules/shell/main_shell.dart';

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
    final themeCtrl = Get.find<ThemeController>();

    return Obx(() {
      final me = auth.me.value;
      final studentId = me?['student_id']?.toString();
      final department = me?['department']?.toString();
      final year = me?['year'];
      final campusParts = <String>[
        if (studentId != null && studentId.isNotEmpty) studentId,
        if (department != null && department.isNotEmpty) department,
        if (year != null) 'Year $year',
      ];

      return Scaffold(
        appBar: AppBar(title: Text('Profile')),
        floatingActionButton: auth.isAdmin
            ? FloatingActionButton(
                onPressed: () {
                  Get.to(() => HealthPage(), binding: HealthBinding());
                },
                child: Icon(Icons.network_check),
              )
            : null,
        body: me == null
            ? const _SignedOutProfile()
            : ListView(
                padding: EdgeInsets.all(24),
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
                                  me['name']?.toString() ?? 'No name',
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
                                      'Admin',
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
                            tooltip: 'Edit profile',
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
                      title: Text('Saved events'),
                      trailing: Icon(Icons.chevron_right),
                      onTap: () => Get.to(() => const SavedEventsPage()),
                    ),
                  ),
                  SizedBox(height: 16),
                  Card(
                    child: Obx(
                      () => ListTile(
                        leading: Icon(
                          themeCtrl.currentThemeIcon,
                          color: AppTheme.primary,
                        ),
                        title: const Text('Appearance'),
                        subtitle: Text(themeCtrl.currentThemeLabel),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () =>
                            _showThemeSelectionDialog(context, themeCtrl),
                      ),
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
                            title: Text('Manage events'),
                            subtitle: Text(
                              'Create, publish, and cancel events',
                            ),
                            trailing: Icon(Icons.chevron_right),
                            onTap: () => Get.to(() => const AdminEventsPage()),
                          ),
                          Divider(height: 1),
                          ListTile(
                            leading: Icon(
                              Icons.qr_code_scanner_rounded,
                              color: AppTheme.primary,
                            ),
                            title: Text('Admin scanner'),
                            subtitle: Text('Coming later'),
                            trailing: Icon(Icons.chevron_right),
                          ),
                          Divider(height: 1),
                          ListTile(
                            leading: Icon(
                              Icons.how_to_reg_rounded,
                              color: AppTheme.primary,
                            ),
                            title: Text('Manual check-in'),
                            subtitle: Text('Coming later'),
                            trailing: Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: 16),
                  _LinkedProvidersCard(auth: auth),
                  SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: () async {
                      await auth.signOut();
                      openMainShell();
                    },
                    child: Text('Sign out'),
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
      widget.auth.errorMessage.value = 'Name and email are required';
      return;
    }

    if (!GetUtils.isEmail(email)) {
      widget.auth.errorMessage.value = 'Enter a valid email';
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
      title: const Text('Edit profile'),
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
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Email'),
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
          child: const Text('Cancel'),
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
                : const Text('Save'),
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
            'Sign in to reserve tickets and manage your profile.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Get.to(() => const SignInPage()),
            child: const Text('Sign in'),
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
      label: 'Email / Password',
      icon: Icons.email_outlined,
    ),
    _ProviderMeta(
      id: 'google.com',
      label: 'Google',
      imageAsset: 'assets/google_logo.png',
    ),
    _ProviderMeta(
      id: 'phone',
      label: 'Phone (SMS)',
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
                'Linked sign-in methods',
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
    required this.label,
    this.icon,
    this.imageAsset,
  });

  final String id;
  final String label;
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
      title: Text(meta.label),
      trailing: isLinked
          ? Chip(
              avatar: Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: AppTheme.primary,
              ),
              label: Text(
                'Linked',
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
              child: const Text('Link'),
            ),
    );
  }
}

Future<void> _showThemeSelectionDialog(
  BuildContext context,
  ThemeController themeCtrl,
) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Appearance'),
      content: Obx(
        () => RadioGroup<ThemeMode>(
          groupValue: themeCtrl.themeMode.value,
          onChanged: (mode) {
            Navigator.pop(dialogContext);
            if (mode != null) themeCtrl.setThemeMode(mode);
          },
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: Text('System auto'),
                value: ThemeMode.system,
              ),
              RadioListTile<ThemeMode>(
                title: Text('Light'),
                value: ThemeMode.light,
              ),
              RadioListTile<ThemeMode>(
                title: Text('Dark'),
                value: ThemeMode.dark,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
}
