import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/theme/app_theme.dart';
import 'package:itc_events/modules/auth/auth_controller.dart';
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
                        if (editedName.trim().isEmpty) {
                          auth.errorMessage.value = 'Name is required';
                          return;
                        }

                        await auth.updateName(editedName);

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
