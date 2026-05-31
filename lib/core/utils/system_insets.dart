import 'package:flutter/widgets.dart';

/// Returns the persistent bottom system inset (e.g. Android navigation bar).
double bottomSystemInset(BuildContext context) {
  return MediaQuery.viewPaddingOf(context).bottom;
}

/// Returns the bottom inset caused by the on-screen keyboard.
double bottomKeyboardInset(BuildContext context) {
  return MediaQuery.viewInsetsOf(context).bottom;
}
