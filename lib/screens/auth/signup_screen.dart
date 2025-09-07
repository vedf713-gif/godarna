import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:godarna/providers/language_provider.dart';
import 'package:godarna/providers/auth_provider.dart';
import 'package:godarna/services/auth_service.dart';
import 'package:godarna/widgets/app_logo.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isOtpSent = false;
  bool _isLoading = false;
  bool _agreeTerms = false;
  bool _otpVerified = false;
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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // مؤشر خطوة
  Widget _buildStepDot({required bool active}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: active ? 10 : 8,
      height: active ? 10 : 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active
            ? const Color(0xFFFF3A44) // Airbnb Red
            : Colors.grey[400],
      ),
    );
  }

  Future<void> _verifyOtpAndNext() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final verified = await authProvider.verifyOtp(
        _emailController.text.trim(),
        _otpController.text.trim(),
      );

      if (!verified) {
        if (!mounted) return;
        final msg = authProvider.error ?? 'رمز التحقق غير صحيح';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
        return;
      }

      if (!mounted) return;
      setState(() => _otpVerified = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم التحقق بنجاح! أكمل ملفك الشخصي')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeTerms) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب الموافقة على الشروط')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final ok = await authProvider.sendOtp(_emailController.text.trim());
      if (ok && mounted) {
        setState(() {
          _isOtpSent = true;
          _otpVerified = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال الرمز إلى بريدك الإلكتروني')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _completeSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_otpVerified) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء التحقق من الرمز أولاً')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authService = AuthService();
      final user = await authService.getCurrentUser();
      if (user != null) {
        await authService.updateProfile(
          userId: user.id,
          firstName: _firstNameController.text.trim().isEmpty
              ? null
              : _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim().isEmpty
              ? null
              : _lastNameController.text.trim(),
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
        );
      }

      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final textDirection = lang.isArabic ? TextDirection.rtl : TextDirection.ltr;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 80),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 450),
              opacity: _showUi ? 1 : 0,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // === 1. Logo & Title ===
                    Column(
                      children: [
                        const AppLogo(
                          heroTag: 'app_logo_signup',
                          size: 70,
                          borderRadius: 20,
                          withShadow: true,
                          imagePath: 'assets/images/app_icon.png',
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'أنشئ حسابك',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'انضم إلى عالم الإقامة المغربية الأصيلة',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // === 2. Step Indicator ===
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStepDot(active: !_isOtpSent),
                        const SizedBox(width: 6),
                        _buildStepDot(active: _isOtpSent && !_otpVerified),
                        const SizedBox(width: 6),
                        _buildStepDot(active: _otpVerified),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // === 3. Form Fields ===
                    TextFormField(
                      controller: _firstNameController,
                      textDirection: textDirection,
                      decoration: InputDecoration(
                        labelText: 'الاسم الأول',
                        hintText: 'أدخل اسمك الأول',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFFFF3A44), width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'مطلوب';
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _lastNameController,
                      textDirection: textDirection,
                      decoration: InputDecoration(
                        labelText: 'الاسم الأخير',
                        hintText: 'أدخل اسمك الأخير',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFFFF3A44), width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'مطلوب';
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _phoneController,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(
                        labelText: 'رقم الهاتف',
                        hintText: '+212 6 XX XX XX XX',
                        prefixIcon: const Icon(Icons.phone, color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFFFF3A44), width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'مطلوب';
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _emailController,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        hintText: 'example@email.com',
                        prefixIcon: const Icon(Icons.email, color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFFFF3A44), width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      enabled: !_isOtpSent,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'مطلوب';
                        if (!RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          return 'بريد إلكتروني غير صالح';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // === 4. Terms Agreement ===
                    Row(
                      children: [
                        Checkbox(
                          value: _agreeTerms,
                          onChanged: (v) =>
                              setState(() => _agreeTerms = v ?? false),
                          activeColor: const Color(0xFFFF3A44),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _agreeTerms = !_agreeTerms),
                            child: Text(
                              'أوافق على الشروط والأحكام وسياسة الخصوصية',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[700]),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (_isOtpSent && !_otpVerified) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _otpController,
                        textDirection: TextDirection.ltr,
                        decoration: InputDecoration(
                          labelText: 'رمز التحقق (OTP)',
                          hintText: '123456',
                          prefixIcon:
                              const Icon(Icons.lock, color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFFFF3A44), width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'مطلوب';
                          if (value.length != 6) {
                            return 'يجب أن يكون الرمز 6 أرقام';
                          }
                          return null;
                        },
                      ),
                    ],

                    const SizedBox(height: 24),

                    // === 5. Action Button ===
                    ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : (!_isOtpSent
                              ? _sendOtp
                              : (!_otpVerified
                                  ? _verifyOtpAndNext
                                  : _completeSignUp)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF3A44),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              !_isOtpSent
                                  ? 'إرسال الرمز'
                                  : (!_otpVerified
                                      ? 'التحقق من الرمز'
                                      : 'إكمال التسجيل'),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16),
                            ),
                    ),

                    const SizedBox(height: 16),

                    // === 6. Already have account? ===
                    TextButton(
                      onPressed: _isLoading ? null : () => context.go('/login'),
                      child: const Text('هل لديك حساب بالفعل؟ تسجيل الدخول'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
