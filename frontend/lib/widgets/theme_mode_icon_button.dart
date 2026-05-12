import 'package:flutter/material.dart';

import '../theme/theme_controller.dart';

class ThemeModeIconButton extends StatelessWidget {
  const ThemeModeIconButton({
    super.key,
    this.lightTooltip = 'Switch to light mode',
    this.darkTooltip = 'Switch to dark mode',
    this.iconColor,
  });

  final String lightTooltip;
  final String darkTooltip;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final ValueNotifier<ThemeMode> themeModeNotifier = ThemeControllerScope.of(
      context,
    );

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (BuildContext context, ThemeMode themeMode, Widget? _) {
        final bool isDark = themeMode == ThemeMode.dark;

        return IconButton(
          tooltip: isDark ? lightTooltip : darkTooltip,
          onPressed: () {
            themeModeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
          },
          icon: Icon(
            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            color: iconColor,
          ),
        );
      },
    );
  }
}
