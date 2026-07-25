import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soom_mobile/app/localization/l10n_extensions.dart';
import 'package:soom_mobile/app/theme/app_colors.dart';
import 'package:soom_mobile/app/theme/app_spacing.dart';
import 'package:soom_mobile/features/auth/domain/qatar_phone.dart';
import 'package:soom_mobile/features/auth/presentation/phone_login_cubit.dart';

/// S02 — Phone Login (M1.2).
///
/// Captures a Qatar mobile number. **No country picker**: Qatar is fixed, so
/// `+974` is shown as a static prefix and the user types 8 digits.
///
/// Called with the destination the user was heading for, so the flow can
/// resume after verification — UX Spec: "Store intended destination before
/// requesting OTP."
class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({this.onCodeSent, super.key});

  /// Invoked once the OTP is on its way, with the number it went to.
  final void Function(QatarPhone phone)? onCodeSent;

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme text = theme.textTheme;

    return BlocConsumer<PhoneLoginCubit, PhoneLoginState>(
      listenWhen: (PhoneLoginState p, PhoneLoginState c) => p.status != c.status,
      listener: (BuildContext context, PhoneLoginState state) {
        if (state.status == PhoneLoginStatus.codeSent && state.phone != null) {
          widget.onCodeSent?.call(state.phone!);
        }
      },
      builder: (BuildContext context, PhoneLoginState state) {
        return Scaffold(
          appBar: AppBar(),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsetsDirectional.all(AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(context.l10n.loginTitle, style: text.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
                  Text(context.l10n.loginSubtitle, style: text.bodyMedium),
                  const SizedBox(height: AppSpacing.xl),

                  _PhoneField(
                    controller: _controller,
                    focusNode: _focusNode,
                    state: state,
                    onChanged: context.read<PhoneLoginCubit>().onInputChanged,
                    onSubmitted: (_) => context.read<PhoneLoginCubit>().submit(),
                  ),

                  if (_messageFor(context, state) case final String message)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        top: AppSpacing.sm,
                      ),
                      child: Text(
                        message,
                        style: text.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),

                  const SizedBox(height: AppSpacing.xl),

                  Text(
                    context.l10n.loginTermsNote,
                    style: text.labelSmall,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  FilledButton(
                    onPressed: state.canSubmit
                        ? context.read<PhoneLoginCubit>().submit
                        : null,
                    child: state.isSubmitting
                        ? const SizedBox.square(
                            dimension: AppSizes.iconSm,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(context.l10n.loginContinue),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Guest browsing stays open — say so, so the screen does not
                  // read as a wall.
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.warningBg,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Text(
                      context.l10n.loginGuestNote,
                      style: text.bodySmall?.copyWith(
                        color: AppColors.textPrimary,
                      ),
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

  /// The error to display, or null when there is nothing to say.
  String? _messageFor(BuildContext context, PhoneLoginState state) {
    if (state.status == PhoneLoginStatus.rateLimited) {
      final Duration? wait = state.retryAfter;
      return wait == null
          ? context.l10n.loginErrorRateLimited
          : context.l10n.loginErrorRateLimitedIn(wait.inSeconds);
    }
    if (state.status == PhoneLoginStatus.networkError) {
      return context.l10n.errorNoConnection;
    }
    if (state.status == PhoneLoginStatus.failure) {
      return context.l10n.errorGeneric;
    }
    if (!state.showsError) return null;

    return switch (state.error!) {
      QatarPhoneError.empty => context.l10n.loginErrorEmpty,
      QatarPhoneError.tooShort => context.l10n.loginErrorTooShort,
      QatarPhoneError.tooLong => context.l10n.loginErrorTooLong,
      QatarPhoneError.notMobile => context.l10n.loginErrorNotMobile,
    };
  }
}

/// The `+974` prefix and 8-digit input.
class _PhoneField extends StatelessWidget {
  const _PhoneField({
    required this.controller,
    required this.focusNode,
    required this.state,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final PhoneLoginState state;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(context.l10n.loginPhoneLabel, style: theme.textTheme.labelMedium),
        const SizedBox(height: AppSpacing.xs),

        // `textDirection: ltr` keeps the DIGITS in logical order, so a number
        // never renders scrambled. The field itself is left to follow the
        // ambient direction, which puts +974 on the leading edge — left in
        // English, right in Arabic — matching the approved S02 reference.
        //
        // Forcing the whole field LTR would pin +974 to the left even in
        // Arabic, fighting the layout. Only the digit run needs pinning.
        TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          enabled: !state.isSubmitting,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          autofillHints: const <String>[AutofillHints.telephoneNumber],
          textDirection: TextDirection.ltr,
          style: theme.textTheme.bodyLarge,
          inputFormatters: <TextInputFormatter>[
            // Accept Arabic-Indic digits too — an Arabic keyboard produces
            // them, and QatarPhone.normalise converts them. Blocking them
            // here would make a valid number impossible to type.
            FilteringTextInputFormatter.allow(
              RegExp(r'[0-9٠-٩۰-۹ +\-()]'),
            ),
            // Generous cap: room for a pasted "+974 5512 3456" without
            // truncating it before normalisation can strip the prefix.
            LengthLimitingTextInputFormatter(20),
          ],
          decoration: InputDecoration(
            hintText: context.l10n.loginPhoneHint,
            hintTextDirection: TextDirection.ltr,
            errorText: state.showsError ? '' : null,
            errorStyle: const TextStyle(height: 0, fontSize: 0),
            prefixIcon: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Text(
                QatarPhone.dialCode,
                textDirection: TextDirection.ltr,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0),
          ),
        ),

        const SizedBox(height: AppSpacing.xs),
        // Explains the absence of a country picker, per the S02 reference.
        Text(context.l10n.loginPhoneHelper, style: theme.textTheme.labelSmall),
      ],
    );
  }
}
