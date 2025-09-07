import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:godarna/providers/auth_provider.dart';
import 'package:godarna/providers/language_provider.dart';
import 'package:godarna/constants/app_strings.dart';
import 'package:godarna/widgets/app_logo.dart';
import 'package:godarna/widgets/bouncy_tap.dart';
import 'package:godarna/widgets/common/app_button.dart';
import 'package:godarna/theme/app_dimensions.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isOtpSent = false;
  bool _isLoading = false;
  bool _showUi = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _showUi = true);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.sendOtp(_emailController.text.trim());

      if (success && mounted) {
        setState(() => _isOtpSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.getString('otpSent', context)),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.verifyOtp(
        _emailController.text.trim(),
        _otpController.text.trim(),
      );

      if (success && mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _resetForm() {
    setState(() {
      _isOtpSent = false;
      _otpController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.primaryContainer.withAlpha((0.3 * 255).toInt()),
                colorScheme.surface,
              ],
              stops: const [0.0, 0.4],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: AppDimensions.paddingAll24,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOut,
                  opacity: _showUi ? 1 : 0,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    offset: _showUi ? Offset.zero : const Offset(0, 0.04),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Container(
                        padding: AppDimensions.paddingAll24,
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: AppDimensions.borderRadiusXLarge,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow
                                  .withAlpha((0.07 * 255).toInt()),
                              blurRadius: AppDimensions.elevationXLarge,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: languageProvider.isArabic
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              // Header
                              Center(
                                child: Column(
                                  children: [
                                    // Logo
                                    const AppLogo(
                                      heroTag: 'app_logo',
                                      size: 76,
                                      // Use theme-based default background from AppLogo
                                      borderRadius: 20,
                                      withShadow: false,
                                      animate: true,
                                      imagePath: 'assets/images/app_icon.png',
                                    ),

                                    const SizedBox(
                                        height: AppDimensions.space16),

                                    // Title
                                    Text(
                                      AppStrings.getString('login', context),
                                      style: theme.textTheme.displaySmall,
                                    ),

                                    const SizedBox(
                                        height: AppDimensions.space8),

                                    // Subtitle
                                    Text(
                                      AppStrings.getString(
                                          'appSlogan', context),
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 40),

                              // Email Field
                              Container(
                                padding: AppDimensions.inputFieldPadding,
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: colorScheme.outlineVariant),
                                ),
                                child: TextFormField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    labelText:
                                        AppStrings.getString('email', context),
                                    hintText: 'example@email.com',
                                    border: InputBorder.none,
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  enabled: !_isOtpSent,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return AppStrings.getString(
                                          'required', context);
                                    }
                                    if (!RegExp(
                                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                        .hasMatch(value)) {
                                      return AppStrings.getString(
                                          'invalidEmail', context);
                                    }
                                    return null;
                                  },
                                ),
                              ),

                              const SizedBox(height: 20),

                              // OTP Field (shown after OTP is sent)
                              if (_isOtpSent) ...[
                                Container(
                                  padding: AppDimensions.inputFieldPadding,
                                  decoration: BoxDecoration(
                                    color: colorScheme.surface,
                                    borderRadius:
                                        AppDimensions.inputFieldBorderRadius,
                                    border: Border.all(
                                        color: colorScheme.outlineVariant),
                                  ),
                                  child: TextFormField(
                                    controller: _otpController,
                                    decoration: InputDecoration(
                                      labelText: AppStrings.getString(
                                          'verifyOtp', context),
                                      hintText: '123456',
                                      counterText: '',
                                      border: InputBorder.none,
                                    ),
                                    keyboardType: TextInputType.number,
                                    maxLength: 6,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return AppStrings.getString(
                                            'required', context);
                                      }
                                      if (value.length != 6) {
                                        return AppStrings.getString(
                                            'otpInvalid', context);
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],

                              // Action Button
                              SizedBox(
                                width: double.infinity,
                                child: AppButton(
                                  text: _isOtpSent
                                      ? AppStrings.getString(
                                          'verifyOtp', context)
                                      : AppStrings.getString(
                                          'sendOtp', context),
                                  onPressed: _isLoading
                                      ? null
                                      : (_isOtpSent ? _verifyOtp : _sendOtp),
                                  isLoading: _isLoading,
                                  type: AppButtonType.primary,
                                  width: double.infinity,
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Reset Button (shown after OTP is sent)
                              if (_isOtpSent)
                                SizedBox(
                                  width: double.infinity,
                                  child: AppButton(
                                    text: AppStrings.getString('back', context),
                                    onPressed: _isLoading ? null : _resetForm,
                                    type: AppButtonType.text,
                                    width: double.infinity,
                                  ),
                                ),

                              const SizedBox(height: 40),

                              // Decorative Divider
                              const Divider(),

                              // Language Toggle
                              Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${AppStrings.getString('language', context)}: ',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    const SizedBox(width: AppDimensions.space4),
                                    BouncyTap(
                                      onTap: () =>
                                          languageProvider.toggleLanguage(),
                                      child: Container(
                                        padding: AppDimensions.chipPadding,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              colorScheme.primary,
                                              colorScheme.secondary
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius:
                                              AppDimensions.borderRadiusXLarge,
                                          boxShadow: [
                                            BoxShadow(
                                              color: colorScheme.primary
                                                  .withAlpha(
                                                      (0.3 * 255).toInt()),
                                              blurRadius: 10,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          languageProvider.currentLanguageName,
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                            color: colorScheme.onPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: AppDimensions.space16),
                              // Explore without login
                              Center(
                                child: AppButton(
                                  text: AppStrings.getString(
                                      'browseWithoutLogin', context),
                                  onPressed: () => context.go('/explore'),
                                  type: AppButtonType.text,
                                  size: AppButtonSize.medium,
                                ),
                              ),
                              const SizedBox(height: AppDimensions.space8),
                              // Sign up shortcut like Airbnb
                              Center(
                                child: AppButton(
                                  text: AppStrings.getString(
                                      'newToAppCreateAccount', context),
                                  onPressed: () => context.go('/signup'),
                                  type: AppButtonType.text,
                                  size: AppButtonSize.medium,
                                ),
                              ),

                              // Error Display
                              if (authProvider.error != null) ...[
                                const SizedBox(height: 20),
                                Container(
                                  width: double.infinity,
                                  padding: AppDimensions.paddingLarge,
                                  decoration: BoxDecoration(
                                    color: colorScheme.errorContainer,
                                    borderRadius:
                                        AppDimensions.borderRadiusMedium,
                                  ),
                                  child: Text(
                                    authProvider.error!,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onErrorContainer,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
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
