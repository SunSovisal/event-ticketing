import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/locale/locale_controller.dart';
import 'package:itc_events/app/theme/app_theme.dart';
import 'package:itc_events/app/theme/them_controller_page.dart';
import 'package:itc_events/app/widgets/app_page_bar.dart';
import 'package:itc_events/modules/auth/profile/legal_document_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const _privacySectionKeys = [
    ('privacy_overview_title', 'privacy_overview_body'),
    ('privacy_collect_title', 'privacy_collect_body'),
    ('privacy_use_title', 'privacy_use_body'),
    ('privacy_sharing_title', 'privacy_sharing_body'),
    ('privacy_contact_title', 'privacy_contact_body'),
  ];

  static const _termsSectionKeys = [
    ('terms_acceptance_title', 'terms_acceptance_body'),
    ('terms_eligibility_title', 'terms_eligibility_body'),
    ('terms_accounts_title', 'terms_accounts_body'),
    ('terms_tickets_title', 'terms_tickets_body'),
    ('terms_use_title', 'terms_use_body'),
    ('terms_changes_title', 'terms_changes_body'),
  ];

  @override
  Widget build(BuildContext context) {
    final themeCtrl = Get.find<ThemeController>();
    final localeCtrl = Get.find<LocaleController>();

    return Scaffold(
      backgroundColor: AppTheme.scaffoldOf(context),
      appBar: AppPageBar(title: 'settings'.tr),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        children: [
          Card(
            child: Obx(
              () => ListTile(
                leading: const Icon(
                  Icons.language_outlined,
                  color: AppTheme.primary,
                ),
                title: Text('language'.tr),
                subtitle: Text(localeCtrl.currentLanguageLabel),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showLanguageSelectionDialog(context, localeCtrl),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Obx(
              () => ListTile(
                leading: Icon(
                  themeCtrl.currentThemeIcon,
                  color: AppTheme.primary,
                ),
                title: Text('appearance'.tr),
                subtitle: Text(themeCtrl.currentThemeLabel),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showThemeSelectionDialog(context, themeCtrl),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.privacy_tip_outlined,
                    color: AppTheme.primary,
                  ),
                  title: Text('privacy_policy'.tr),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Get.to(
                    () => LegalDocumentPage(
                      title: 'privacy_policy'.tr,
                      sections: [
                        for (final key in _privacySectionKeys)
                          (key.$1.tr, key.$2.tr),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.description_outlined,
                    color: AppTheme.primary,
                  ),
                  title: Text('terms_of_use'.tr),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Get.to(
                    () => LegalDocumentPage(
                      title: 'terms_of_use'.tr,
                      sections: [
                        for (final key in _termsSectionKeys)
                          (key.$1.tr, key.$2.tr),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showLanguageSelectionDialog(
  BuildContext context,
  LocaleController localeCtrl,
) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('language'.tr),
      content: Obx(
        () => RadioGroup<String>(
          groupValue: localeCtrl.languageCode,
          onChanged: (code) {
            Navigator.pop(dialogContext);
            if (code != null) localeCtrl.setLanguage(code);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: Text('language_english'.tr),
                value: 'en',
              ),
              RadioListTile<String>(
                title: Text('language_khmer'.tr),
                value: 'kh',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text('cancel'.tr),
        ),
      ],
    ),
  );
}

Future<void> _showThemeSelectionDialog(
  BuildContext context,
  ThemeController themeCtrl,
) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('appearance'.tr),
      content: Obx(
        () => RadioGroup<ThemeMode>(
          groupValue: themeCtrl.themeMode.value,
          onChanged: (mode) {
            Navigator.pop(dialogContext);
            if (mode != null) themeCtrl.setThemeMode(mode);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: Text('theme_system'.tr),
                value: ThemeMode.system,
              ),
              RadioListTile<ThemeMode>(
                title: Text('theme_light'.tr),
                value: ThemeMode.light,
              ),
              RadioListTile<ThemeMode>(
                title: Text('theme_dark'.tr),
                value: ThemeMode.dark,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text('cancel'.tr),
        ),
      ],
    ),
  );
}
