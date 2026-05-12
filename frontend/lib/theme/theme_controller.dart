import 'package:flutter/material.dart';

class ThemeControllerScope extends InheritedNotifier<ValueNotifier<ThemeMode>> {
  const ThemeControllerScope({
    super.key,
    required ValueNotifier<ThemeMode> notifier,
    required super.child,
  }) : super(notifier: notifier);

  static ValueNotifier<ThemeMode> of(BuildContext context) {
    final ThemeControllerScope? scope = context
        .dependOnInheritedWidgetOfExactType<ThemeControllerScope>();
    assert(scope != null, 'ThemeControllerScope not found in widget tree.');
    return scope!.notifier!;
  }
}
