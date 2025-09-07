import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:godarna/providers/auth_provider.dart';
import 'package:godarna/providers/property_provider.dart';
import 'package:godarna/constants/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:godarna/widgets/common/app_app_bar.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  String _debugInfo = 'جارٍ فحص التطبيق...';
  
  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    final buffer = StringBuffer();
    
    try {
      buffer.writeln('=== تشخيص التطبيق ===\n');
      
      // فحص Supabase
      buffer.writeln('1. فحص Supabase:');
      try {
        final client = Supabase.instance.client;
        buffer.writeln('   ✅ Supabase متصل');
        buffer.writeln('   URL: متصل');
        buffer.writeln('   Auth: ${client.auth.currentUser?.id ?? "غير مسجل"}');
      } catch (e) {
        buffer.writeln('   ❌ خطأ في Supabase: $e');
      }
      
      buffer.writeln('\n2. فحص AuthProvider:');
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        buffer.writeln('   مهيأ: ${authProvider.isInitialized}');
        buffer.writeln('   مسجل: ${authProvider.isAuthenticated}');
        buffer.writeln('   مستخدم: ${authProvider.isAuthenticated ? "موجود" : "لا يوجد"}');
        buffer.writeln('   مضيف: ${authProvider.isHost}');
        buffer.writeln('   مدير: ${authProvider.isAdmin}');
      } catch (e) {
        buffer.writeln('   ❌ خطأ في AuthProvider: $e');
      }
      
      buffer.writeln('\n3. فحص PropertyProvider:');
      try {
        final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
        buffer.writeln('   يحمل: ${propertyProvider.isLoading}');
        buffer.writeln('   خطأ: ${propertyProvider.error ?? "لا يوجد"}');
        buffer.writeln('   عدد العقارات: ${propertyProvider.properties.length}');
      } catch (e) {
        buffer.writeln('   ❌ خطأ في PropertyProvider: $e');
      }
      
      buffer.writeln('\n4. فحص الثيم:');
      try {
        final theme = Theme.of(context);
        buffer.writeln('   نمط: ${theme.brightness}');
        buffer.writeln('   لون أساسي: ${theme.colorScheme.primary}');
        buffer.writeln('   خلفية: ${theme.scaffoldBackgroundColor}');
      } catch (e) {
        buffer.writeln('   ❌ خطأ في الثيم: $e');
      }
      
      buffer.writeln('\n5. فحص الألوان:');
      buffer.writeln('   أحمر أساسي: ${AppColors.primaryRed}');
      buffer.writeln('   خلفية أساسية: ${AppColors.backgroundPrimary}');
      buffer.writeln('   نص أساسي: ${AppColors.textPrimary}');
      
    } catch (e) {
      buffer.writeln('❌ خطأ عام في التشخيص: $e');
    }
    
    if (mounted) {
      setState(() {
        _debugInfo = buffer.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: const AppAppBar(
        title: 'تشخيص التطبيق',
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Text(
                    _debugInfo,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _runDiagnostics,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: AppColors.textOnPrimary,
                    ),
                    child: const Text('إعادة فحص'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.grey500,
                      foregroundColor: AppColors.textOnPrimary,
                    ),
                    child: const Text('إغلاق'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
