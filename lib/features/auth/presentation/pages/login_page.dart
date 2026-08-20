import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:cedsif_overtime_mobile/core/constants/constants.dart';
import 'package:cedsif_overtime_mobile/features/auth/presentation/providers/login_provider.dart';
import 'package:cedsif_overtime_mobile/theme/app_colors.dart';
import 'package:cedsif_overtime_mobile/theme/app_spacing.dart';
import 'package:cedsif_overtime_mobile/theme/app_typography.dart';
import 'package:cedsif_overtime_mobile/widgets/app_button.dart';
import 'package:cedsif_overtime_mobile/widgets/app_scaffold.dart';
import 'package:cedsif_overtime_mobile/widgets/app_text_field.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({this.onAuthenticated, super.key});

  final VoidCallback? onAuthenticated;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _nuitController = TextEditingController();
  final _passwordController = TextEditingController();
  @override
  void dispose() {
    _nuitController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateNuit(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'auth.required'.tr();
    }
    if (text.length != AppConstants.nuitLength ||
        !RegExp(r'^\d+$').hasMatch(text)) {
      return 'auth.invalidNuit'.tr();
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'auth.required'.tr();
    }
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final authenticated = await ref
        .read(loginNotifierProvider.notifier)
        .login(
          nuit: _nuitController.text.trim(),
          password: _passwordController.text,
        );
    if (!mounted || !authenticated) {
      return;
    }
    final callback = widget.onAuthenticated;
    if (callback != null) {
      callback();
      return;
    }
    context.go(RouteConstants.facialValidation);
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginNotifierProvider);
    return AppScaffold(
      backgroundColor: AppColors.canvas,
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space24,
            vertical: AppSpacing.space32,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - AppSpacing.space64,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSpacing.pageMaxWidth,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        image: true,
                        label: 'app.emblem'.tr(),
                        child: SvgPicture.asset(
                          'assets/images/moz.svg',
                          width: AppSpacing.emblemLarge,
                          height: AppSpacing.emblemLarge,
                          excludeFromSemantics: true,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space24),
                      Text(
                        'app.title'.tr(),
                        style: AppTypography.screenTitleLarge.copyWith(
                          color: AppColors.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.space12),
                      Text(
                        'auth.subtitle'.tr(),
                        style: AppTypography.body.copyWith(
                          color: AppColors.textMuted,
                          fontFamily: AppTypography.uiFontFamily,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.space40),
                      AppTextField(
                        controller: _nuitController,
                        label: 'auth.nuit'.tr(),
                        isRequired: true,
                        validator: _validateNuit,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(
                            AppConstants.nuitLength,
                          ),
                        ],
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.space24),
                      AppTextField(
                        controller: _passwordController,
                        label: 'auth.password'.tr(),
                        isRequired: true,
                        validator: _validatePassword,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: AppSpacing.space24),
                      AppButton(
                        label: 'auth.enter'.tr(),
                        isLoading: loginState.isLoading,
                        onPressed: _submit,
                      ),
                      if (loginState.errorKey case final errorKey?) ...[
                        const SizedBox(height: AppSpacing.space12),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            errorKey.tr(),
                            style: AppTypography.body.copyWith(
                              color: AppColors.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.space8),
                      SizedBox(
                        height: AppSpacing.touchTarget,
                        child: TextButton(
                          onPressed: loginState.isLoading ? null : () {},
                          child: Text(
                            'auth.forgotPassword'.tr(),
                            style: AppTypography.labelStrong.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
