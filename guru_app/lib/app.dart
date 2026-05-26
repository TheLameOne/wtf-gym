import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'core/router/app_router.dart';

class GuruApp extends ConsumerWidget {
  const GuruApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(guruRouterProvider);
    return MaterialApp.router(
      title: 'Guru App',
      theme: AppTheme.guru(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
