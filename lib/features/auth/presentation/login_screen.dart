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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loadingEmail = false;
  bool _loadingGoogle = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      _showAlert('Lengkapi data', 'Email dan password wajib diisi.');
      return;
    }
    setState(() => _loadingEmail = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .signInWithEmail(email: email, password: password);
      // Navigation otomatis lewat router redirect.
    } on AuthFailure catch (e) {
      _showAlert('Login gagal', e.message);
    } finally {
      if (mounted) setState(() => _loadingEmail = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _loadingGoogle = true);
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
    } on AuthFailure catch (e) {
      _showAlert('Login Google gagal', e.message);
    } finally {
      if (mounted) setState(() => _loadingGoogle = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showAlert(
        'Reset password',
        'Isi email kamu dulu di kolom email, lalu tekan tombol ini lagi.',
      );
      return;
    }
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(email);
      if (!mounted) return;
      _showAlert(
        'Email terkirim',
        'Cek inbox $email untuk instruksi reset password.',
      );
    } on AuthFailure catch (e) {
      _showAlert('Gagal kirim', e.message);
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
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              _Header(),
              const SizedBox(height: 40),
              AuthTextField(
                controller: _emailController,
                label: 'Email',
                placeholder: 'kamu@email.com',
                icon: CupertinoIcons.mail,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                enabled: !loadingAny,
              ),
              const SizedBox(height: AppSpacing.lg),
              AuthTextField(
                controller: _passwordController,
                label: 'Password',
                placeholder: 'Masukkan password',
                icon: CupertinoIcons.lock,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _signInWithEmail(),
                enabled: !loadingAny,
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: loadingAny ? null : _forgotPassword,
                  child: Text(
                    'Lupa password?',
                    style: AppTypography.footnoteEmphasized.copyWith(
                      color: AppColors.accentPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Masuk',
                onPressed: loadingAny ? null : _signInWithEmail,
                loading: _loadingEmail,
              ),
              const SizedBox(height: AppSpacing.xl),
              const _OrDivider(),
              const SizedBox(height: AppSpacing.xl),
              GoogleSignInButton(
                onPressed: loadingAny ? null : _signInWithGoogle,
                loading: _loadingGoogle,
              ),
              const SizedBox(height: AppSpacing.xxl),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Belum punya akun?',
                    style: AppTypography.subheadline.copyWith(
                      color: AppColors.labelSecondary,
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    onPressed: loadingAny
                        ? null
                        : () => context.go(AppRoute.signup),
                    child: Text(
                      'Daftar',
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

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.accentSoft,
                AppColors.accentPrimary.withValues(alpha: 0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Center(
            child: Icon(
              CupertinoIcons.heart_fill,
              color: CupertinoColors.white,
              size: 32,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Selamat datang kembali',
          style: AppTypography.title1,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Masuk untuk lanjut melacak kesehatanmu.',
          style: AppTypography.subheadline.copyWith(
            color: AppColors.labelSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
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
