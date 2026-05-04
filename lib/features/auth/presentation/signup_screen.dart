import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../routing/app_router.dart';
import '../application/auth_providers.dart';
import '../data/auth_repository.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/google_sign_in_button.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loadingEmail = false;
  bool _loadingGoogle = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (email.isEmpty || password.isEmpty) {
      _showAlert('Lengkapi data', 'Email dan password wajib diisi.');
      return;
    }
    if (password.length < 6) {
      _showAlert('Password lemah', 'Password minimal 6 karakter.');
      return;
    }
    if (password != confirm) {
      _showAlert('Tidak cocok', 'Konfirmasi password tidak sama.');
      return;
    }

    setState(() => _loadingEmail = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .signUpWithEmail(email: email, password: password);
      // Navigation otomatis lewat router redirect ke onboarding.
    } on AuthFailure catch (e) {
      _showAlert('Pendaftaran gagal', e.message);
    } finally {
      if (mounted) setState(() => _loadingEmail = false);
    }
  }

  Future<void> _signUpWithGoogle() async {
    setState(() => _loadingGoogle = true);
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
    } on AuthFailure catch (e) {
      _showAlert('Login Google gagal', e.message);
    } finally {
      if (mounted) setState(() => _loadingGoogle = false);
    }
  }

  void _showAlert(String title, String body) {
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loadingAny = _loadingEmail || _loadingGoogle;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.bgPrimary,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.bgPrimary,
        border: const Border(),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.go(AppRoute.login),
          child: const Icon(
            CupertinoIcons.chevron_back,
            color: AppColors.labelPrimary,
          ),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Text('Buat akun baru', style: AppTypography.title1),
              const SizedBox(height: 6),
              Text(
                'Datamu tersinkron aman di cloud.',
                style: AppTypography.subheadline.copyWith(
                  color: AppColors.labelSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              AuthTextField(
                controller: _emailController,
                label: 'Email',
                placeholder: 'kamu@email.com',
                icon: CupertinoIcons.mail,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.newUsername],
                textInputAction: TextInputAction.next,
                enabled: !loadingAny,
              ),
              const SizedBox(height: AppSpacing.lg),
              AuthTextField(
                controller: _passwordController,
                label: 'Password',
                placeholder: 'Minimal 6 karakter',
                icon: CupertinoIcons.lock,
                obscureText: true,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.next,
                enabled: !loadingAny,
              ),
              const SizedBox(height: AppSpacing.lg),
              AuthTextField(
                controller: _confirmController,
                label: 'Konfirmasi password',
                placeholder: 'Ulangi password',
                icon: CupertinoIcons.lock_shield,
                obscureText: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _signUp(),
                enabled: !loadingAny,
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'Daftar',
                onPressed: loadingAny ? null : _signUp,
                loading: _loadingEmail,
              ),
              const SizedBox(height: AppSpacing.xl),
              const _OrDivider(),
              const SizedBox(height: AppSpacing.xl),
              GoogleSignInButton(
                onPressed: loadingAny ? null : _signUpWithGoogle,
                loading: _loadingGoogle,
                label: 'Daftar dengan Google',
              ),
              const SizedBox(height: AppSpacing.xxl),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sudah punya akun?',
                    style: AppTypography.subheadline.copyWith(
                      color: AppColors.labelSecondary,
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    onPressed: loadingAny
                        ? null
                        : () => context.go(AppRoute.login),
                    child: Text(
                      'Masuk',
                      style: AppTypography.subheadline.copyWith(
                        color: AppColors.accentPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: AppColors.separator)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'atau',
            style: AppTypography.caption1.copyWith(
              color: AppColors.labelTertiary,
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: AppColors.separator)),
      ],
    );
  }
}
