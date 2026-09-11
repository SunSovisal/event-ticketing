import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:itc_events/app/theme/app_theme.dart';

/// Flat page header that matches the scaffold. Pass [title] on tab roots;
/// omit it for a back-only bar.
class AppPageBar extends StatelessWidget implements PreferredSizeWidget {
  const AppPageBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
  });

  final String? title;
  final List<Widget>? actions;
  final Widget? leading;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final foreground = AppTheme.textPrimaryOf(context);
    final isDark = AppTheme.isDark(context);

    return AppBar(
      backgroundColor: AppTheme.scaffoldOf(context),
      foregroundColor: foreground,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      leading: leading,
      iconTheme: IconThemeData(color: foreground),
      actionsIconTheme: IconThemeData(color: foreground),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      title: title == null || title!.isEmpty
          ? null
          : Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                title!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: foreground,
                  fontWeight:
                      Theme.of(context).textTheme.headlineMedium?.fontFamily ==
                          AppTheme.khmerFontFamily
                      ? FontWeight.w400
                      : FontWeight.w700,
                ),
              ),
            ),
      actions: actions,
    );
  }
}
