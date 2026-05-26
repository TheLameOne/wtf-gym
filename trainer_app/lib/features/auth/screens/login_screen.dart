import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _loginAsAarav() async {
    setState(() => _isLoading = true);
    try {
      final user = UserModel(
        id: AppConstants.trainerAaravId,
        name: 'Aarav',
        email: 'aarav@wtfgym.com',
        role: 'trainer',
      );
      await UserService.instance.saveUser(user);
      await AuthService.instance.saveSession(user);
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.trainerPrimary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.fitness_center,
                    size: 48, color: AppColors.trainerPrimary),
              ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
              const SizedBox(height: AppSpacing.xl),
              Text('WTF Trainer', style: AppTextStyles.h1),
              const SizedBox(height: AppSpacing.xs),
              Text('Your dashboard to manage members',
                  style: AppTextStyles.body.copyWith(color: AppColors.grey600),
                  textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xxl),
              CtaButton(
                label: 'Login as Aarav',
                onPressed: _loginAsAarav,
                isLoading: _isLoading,
                icon: Icons.person,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
