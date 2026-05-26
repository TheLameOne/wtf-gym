import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared/shared.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Hive.initFlutter();
  UserService.instance.seedDefaultUsers(); // non-blocking: runs in background
  final savedTheme = await loadPersistedTheme();
  runApp(
    ProviderScope(
      overrides: [
        themeNotifierProvider.overrideWith(() => ThemeNotifier(savedTheme)),
      ],
      child: const TrainerApp(),
    ),
  );
}
