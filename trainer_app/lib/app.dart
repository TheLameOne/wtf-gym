import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'core/router/app_router.dart';

class TrainerApp extends ConsumerWidget {
  const TrainerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(trainerRouterProvider);
    return MaterialApp.router(
      title: 'Trainer App',
      theme: AppTheme.trainer(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
