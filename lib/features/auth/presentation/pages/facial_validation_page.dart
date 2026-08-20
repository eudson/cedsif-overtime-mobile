import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cedsif_overtime_mobile/core/config/environment_config.dart';
import 'package:cedsif_overtime_mobile/core/constants/constants.dart';
import 'package:cedsif_overtime_mobile/features/auth/presentation/services/facial_camera.dart';
import 'package:cedsif_overtime_mobile/features/auth/presentation/services/facial_verifier.dart';
import 'package:cedsif_overtime_mobile/features/auth/presentation/providers/login_provider.dart';
import 'package:cedsif_overtime_mobile/theme/app_colors.dart';
import 'package:cedsif_overtime_mobile/theme/app_spacing.dart';
import 'package:cedsif_overtime_mobile/theme/app_typography.dart';
import 'package:cedsif_overtime_mobile/widgets/app_button.dart';
import 'package:cedsif_overtime_mobile/widgets/app_scaffold.dart';

class FacialValidationPage extends ConsumerStatefulWidget {
  const FacialValidationPage({
    this.camera,
    this.verifier,
    this.simulationEnabled,
    this.onValidated,
    super.key,
  });

  final FacialCamera? camera;
  final FacialVerifier? verifier;
  final bool? simulationEnabled;
  final ValueChanged<String>? onValidated;

  @override
  ConsumerState<FacialValidationPage> createState() =>
      _FacialValidationPageState();
}

class _FacialValidationPageState extends ConsumerState<FacialValidationPage>
    with WidgetsBindingObserver {
  late final FacialCamera _camera;
  late final FacialVerifier _verifier;
  late final bool _simulationEnabled;
  bool _isInitializing = false;
  bool _isReady = false;
  bool _isVerifying = false;
  String? _errorKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _simulationEnabled =
        widget.simulationEnabled ??
        FacialSimulationPolicy.isEnabled(EnvironmentConfig.environment);
    _camera = widget.camera ?? PluginFacialCamera();
    _verifier =
        widget.verifier ?? SimulatedFacialVerifier(enabled: _simulationEnabled);
    if (_simulationEnabled) {
      unawaited(_initializeCamera());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_simulationEnabled) {
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      unawaited(_suspendCamera());
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_initializeCamera());
    }
  }

  Future<void> _initializeCamera() async {
    if (_isInitializing || _isVerifying) {
      return;
    }
    setState(() {
      _isInitializing = true;
      _isReady = false;
      _errorKey = null;
    });
    try {
      await _camera.initialize();
      if (mounted) {
        setState(() => _isReady = true);
      }
    } on Object {
      if (mounted) {
        setState(() => _errorKey = 'auth.cameraUnavailable');
      }
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  Future<void> _suspendCamera() async {
    await _camera.dispose();
    if (mounted) {
      setState(() => _isReady = false);
    }
  }

  Future<void> _captureAndVerify() async {
    if (!_simulationEnabled || !_isReady || _isVerifying) {
      return;
    }
    setState(() {
      _isVerifying = true;
      _errorKey = null;
    });
    CapturedFace? face;
    try {
      face = await _camera.capture();
      final reference = await _verifier.verify(face);
      if (!mounted) {
        return;
      }
      final onValidated = widget.onValidated;
      if (onValidated != null) {
        onValidated(reference);
      } else {
        ref.read(facialReferenceProvider.notifier).store(reference);
        context.go(RouteConstants.home);
      }
    } on Object {
      if (mounted) {
        setState(() => _errorKey = 'auth.verificationFailed');
      }
    } finally {
      await face?.delete();
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_camera.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    backgroundColor: AppColors.canvas,
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.space24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.pageMaxWidth,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'auth.facialValidation'.tr(),
                  style: AppTypography.screenTitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.space8),
                Text(
                  (_simulationEnabled
                          ? 'auth.facialInstructions'
                          : 'auth.verificationUnavailable')
                      .tr(),
                  style: AppTypography.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.space24),
                if (_simulationEnabled) _buildCameraContent(),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _buildCameraContent() {
    if (_isInitializing) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorKey != null && !_isReady) {
      return Column(
        children: [
          const Icon(
            Icons.no_photography_outlined,
            color: AppColors.danger,
            size: AppSpacing.iconHero,
          ),
          const SizedBox(height: AppSpacing.space16),
          Text(
            _errorKey!.tr(),
            style: AppTypography.body,
            textAlign: TextAlign.center,
          ),
          TextButton(
            onPressed: _initializeCamera,
            child: Text('common.retry'.tr()),
          ),
        ],
      );
    }
    if (!_isReady) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          child: AspectRatio(aspectRatio: 3 / 4, child: _camera.buildPreview()),
        ),
        if (_errorKey != null) ...[
          const SizedBox(height: AppSpacing.space12),
          Text(
            _errorKey!.tr(),
            style: AppTypography.body.copyWith(color: AppColors.danger),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: AppSpacing.space24),
        AppButton(
          label: 'auth.simulateAndContinue'.tr(),
          leadingIcon: Icons.camera_alt_outlined,
          isLoading: _isVerifying,
          onPressed: _isVerifying ? null : _captureAndVerify,
        ),
      ],
    );
  }
}
