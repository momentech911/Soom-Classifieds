import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soom_mobile/app/localization/l10n_extensions.dart';
import 'package:soom_mobile/app/localization/locale_cubit.dart';
import 'package:soom_mobile/app/theme/app_colors.dart';
import 'package:soom_mobile/app/theme/app_spacing.dart';
import 'package:soom_mobile/core/utils/arabic_digits.dart';
import 'package:soom_mobile/features/auth/presentation/otp_cubit.dart';

/// S03 — OTP Verification (M1.3).
///
/// Six digits, an expiry countdown, resend-with-cooldown and change-phone.
///
/// A single hidden [TextField] backs six visual boxes rather than six real
/// fields. Six fields mean six focus nodes, manual advance-and-backspace
/// handling, and SMS autofill that only ever populates the first — a well
/// known source of bugs. One field keeps autofill and paste working for free.
class OtpScreen extends StatefulWidget {
  const OtpScreen({this.onVerified, this.onChangePhone, super.key});

  /// Called once the code is accepted — resume the interrupted action.
  final VoidCallback? onVerified;

  /// Called when the user wants to correct their number.
  final VoidCallback? onChangePhone;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Countdowns begin when the screen appears, not when the cubit is built.
    _cubit = context.read<OtpCubit>()..start();

    // The code is the only thing to do on this screen — open the keyboard.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    // Stop the countdowns with the screen. Without this a popped screen keeps
    // ticking, and the cubit outlives the UI when its provider does.
    _cubit.stop();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Captured in [initState]: `context.read` is unavailable during dispose.
  late final OtpCubit _cubit;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme text = theme.textTheme;
    final String languageCode = context.watch<LocaleCubit>().state.languageCode;

    return BlocConsumer<OtpCubit, OtpState>(
      listenWhen: (OtpState p, OtpState c) => p.status != c.status,
      listener: (BuildContext context, OtpState state) {
        if (state.status == OtpStatus.verified) widget.onVerified?.call();
        // A resend clears the field; keep the visible boxes in step.
        if (state.code.isEmpty) _controller.clear();
      },
      builder: (BuildContext context, OtpState state) {
        final OtpCubit cubit = context.read<OtpCubit>();

        return Scaffold(
          appBar: AppBar(title: Text(context.l10n.otpAppBarTitle)),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsetsDirectional.all(AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(context.l10n.otpTitle, style: text.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    context.l10n.otpSentTo(state.phone.masked),
                    style: text.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  _CodeBoxes(
                    controller: _controller,
                    focusNode: _focusNode,
                    state: state,
                    onChanged: cubit.onCodeChanged,
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Expiry countdown, or the reason verification failed.
                  Center(
                    child: Text(
                      _statusLine(context, state, languageCode),
                      style: text.bodySmall?.copyWith(
                        color: _isError(state) ? theme.colorScheme.error : null,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  FilledButton(
                    onPressed: state.canVerify ? cubit.verify : null,
                    child: state.isVerifying
                        ? const SizedBox.square(
                            dimension: AppSizes.iconSm,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(context.l10n.otpVerify),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  Center(
                    child: state.canResend
                        ? TextButton(
                            onPressed: cubit.resend,
                            child: Text(context.l10n.otpResend),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                            child: Text(
                              context.l10n.otpResendIn(
                                ArabicDigits.countdown(
                                  state.resendIn,
                                  languageCode,
                                ),
                              ),
                              style: text.labelMedium?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                  ),

                  Center(
                    child: TextButton(
                      onPressed: widget.onChangePhone,
                      child: Text(context.l10n.otpChangePhone),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  bool _isError(OtpState state) =>
      state.status == OtpStatus.invalid ||
      state.status == OtpStatus.expired ||
      state.status == OtpStatus.rateLimited ||
      state.status == OtpStatus.failure;

  /// The line under the boxes: an error if there is one, otherwise the
  /// expiry countdown.
  String _statusLine(BuildContext context, OtpState state, String language) {
    return switch (state.status) {
      OtpStatus.invalid => context.l10n.otpErrorInvalid,
      OtpStatus.expired => context.l10n.otpErrorExpired,
      OtpStatus.rateLimited => context.l10n.otpErrorRateLimited,
      OtpStatus.failure => context.l10n.errorGeneric,
      _ => context.l10n.otpExpiresIn(
          ArabicDigits.countdown(state.expiresIn, language),
        ),
    };
  }
}

/// Six boxes showing the code, backed by one hidden field.
class _CodeBoxes extends StatelessWidget {
  const _CodeBoxes({
    required this.controller,
    required this.focusNode,
    required this.state,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final OtpState state;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        // The boxes are laid out left-to-right in both languages. The code is
        // a number read in the order the SMS presents it; mirroring the row
        // in Arabic would show it reversed against the message the user is
        // copying from.
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              for (int i = 0; i < OtpCubit.codeLength; i++)
                _Box(
                  digit: i < state.code.length ? state.code[i] : '',
                  isActive: i == state.code.length,
                  hasError: state.status == OtpStatus.invalid ||
                      state.status == OtpStatus.expired,
                ),
            ],
          ),
        ),

        // Invisible but real: it owns focus, the keyboard, paste and SMS
        // autofill. Opacity rather than Offstage — an offstage field cannot
        // take focus.
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              enabled: !state.isVerifying,
              keyboardType: TextInputType.number,
              textDirection: TextDirection.ltr,
              autofillHints: const <String>[AutofillHints.oneTimeCode],
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹]')),
                LengthLimitingTextInputFormatter(OtpCubit.codeLength),
              ],
              showCursor: false,
              decoration: const InputDecoration(
                border: InputBorder.none,
                counterText: '',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({
    required this.digit,
    required this.isActive,
    required this.hasError,
  });

  final String digit;
  final bool isActive;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final Color border = hasError
        ? theme.colorScheme.error
        : isActive
            ? theme.colorScheme.primary
            : theme.colorScheme.outline;

    return Container(
      width: 48,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: border,
          width: isActive || hasError ? 1.5 : 1,
        ),
      ),
      child: Text(
        digit,
        style: theme.textTheme.titleMedium?.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
