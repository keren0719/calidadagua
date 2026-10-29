import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'state/app_services.dart';
import 'state/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final services = AppServices(prefs: prefs, settings: SettingsController(prefs));
  runApp(AgrovisionApp(services: services));
}
