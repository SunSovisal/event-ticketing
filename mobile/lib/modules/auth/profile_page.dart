import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/theme/app_theme.dart';
import 'package:itc_events/modules/auth/auth_controller.dart';
import 'package:itc_events/modules/auth/phone_sign_in_page.dart';
import 'package:itc_events/modules/auth/sign_in_page.dart';
import 'package:itc_events/modules/health/health_binding.dart';
import 'package:itc_events/modules/health/health_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _showEditNameDialog(
    BuildContext context,
    AuthController auth,
  ) async {
    var editedName = auth.me.value?['name']?.toString() ?? '';
    var editedEmail = auth.me.value?['email']?.toString() ?? '';

    auth.errorMessage.value = '';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit name'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: editedName,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Name'),
                onChanged: (value) => editedName = value,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: editedEmail,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Email'),
                onChanged: (value) => editedEmail = value,
              ),
              Obx(() {
                if (auth.errorMessage.value.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    auth.errorMessage.value,
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            Obx(
              () => FilledButton(
                onPressed: auth.isLoading.value
                    ? null
                    : () async {
                        if (editedName.trim().isEmpty &&
                            editedEmail.trim().isEmpty) {
                          auth.errorMessage.value = 'Name & Email is required';
                          return;
                        }

                        await auth.updateNameEmail(editedName, editedEmail);

                        if (auth.errorMessage.value.isEmpty &&
                            dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                      },
                child: auth.isLoading.value
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return Obx(() {
      final me = auth.me.value;

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
            ? Center(child: Text('No profile loaded'))
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
                            tooltip: 'Edit name',
                            onPressed: () => _showEditNameDialog(context, auth),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                        ],
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
                            subtitle: Text('Week 4'),
                          ),
                          Divider(height: 1),
                          ListTile(
                            leading: Icon(
                              Icons.qr_code_scanner_rounded,
                              color: AppTheme.primary,
                            ),
                            title: Text('Admin scanner'),
                            subtitle: Text('Week 8'),
                          ),
                          Divider(height: 1),
                          ListTile(
                            leading: Icon(
                              Icons.how_to_reg_rounded,
                              color: AppTheme.primary,
                            ),
                            title: Text('Manual check-in'),
                            subtitle: Text('Week 7'),
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
                      Get.offAll(() => SignInPage());
                    },
                    child: Text('Sign out'),
                  ),
                ],
              ),
      );
    });
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
      icon: Icons.g_mobiledata_rounded,
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
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
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
      leading: Icon(meta.icon, color: isLinked ? AppTheme.primary : null),
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
