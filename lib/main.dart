import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:proballdev/app/app.dart';

/// Wicked Rolling Ball Pro — AI-powered IoT pet toy app.
/// Runs fully without hardware. BLE-ready for production.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(WickedRollingBallApp(prefs: prefs));
}
