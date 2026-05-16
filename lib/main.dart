import 'package:flutter/material.dart';

import 'bootstrap/bootstrap_host.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BootstrapHost());
}
