import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

class CreateProfileScreen extends ConsumerStatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  ConsumerState<CreateProfileScreen> createState() =>
      _CreateProfileScreenState();
}

class _CreateProfileScreenState extends ConsumerState<CreateProfileScreen> {
  final _nameController = TextEditingController(text: 'DK');
  final _formKey = GlobalKey<FormState>();
  List<UserModel> _trainers = [];
  UserModel? _selectedTrainer;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadTrainers();
  }

  Future<void> _loadTrainers() async {
    final trainers = await UserService.instance.getTrainers();
    if (mounted) {
      setState(() {
        _trainers = trainers;
        _selectedTrainer = trainers.isNotEmpty ? trainers.first : null;
        _isLoading = false;
      });
    }
  }

  Future<void> _createProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTrainer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a trainer')),
      );
      return;
    }
    setState(() => _isSaving = true);

    try {
      final user = UserModel(
        id: AppConstants.memberDkId,
        name: _nameController.text.trim(),
        email: 'dk@wtfgym.com',
        role: 'member',
        assignedTrainerId: _selectedTrainer!.id,
      );
      await UserService.instance.saveUser(user);
      await AuthService.instance.saveSession(user);

      // Ensure chat meta exists
      await ChatService.instance.ensureChatMeta(
        memberId: user.id,
        trainerId: _selectedTrainer!.id,
        memberName: user.name,
        trainerName: _selectedTrainer!.name,
      );

      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Your Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    Text('Your Name', style: AppTextStyles.label),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _nameController,
                      decoration:
                          const InputDecoration(hintText: 'Enter your name'),
                      validator: (v) => Validators.isValidName(v ?? '')
                          ? null
                          : 'Name cannot be empty',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Choose Your Trainer', style: AppTextStyles.label),
                    const SizedBox(height: AppSpacing.sm),
                    if (_trainers.isEmpty)
                      const Text('No trainers available')
                    else
                      ...(_trainers.map(
                        (trainer) => _TrainerCard(
                          trainer: trainer,
                          isSelected: _selectedTrainer?.id == trainer.id,
                          onTap: () =>
                              setState(() => _selectedTrainer = trainer),
                        ),
                      )),
                    const SizedBox(height: AppSpacing.xl),
                    CtaButton(
                      label: 'Create Profile',
                      onPressed: _createProfile,
                      isLoading: _isSaving,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _TrainerCard extends StatelessWidget {
  final UserModel trainer;
  final bool isSelected;
  final VoidCallback onTap;

  const _TrainerCard({
    required this.trainer,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? primary : AppColors.grey200,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? primary.withOpacity(0.05) : AppColors.white,
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: primary.withOpacity(0.15),
              child: Text(
                trainer.name[0].toUpperCase(),
                style: TextStyle(color: primary, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(trainer.name, style: AppTextStyles.label),
                  Text('Lead Trainer',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.grey600)),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: primary),
          ],
        ),
      ),
    );
  }
}
