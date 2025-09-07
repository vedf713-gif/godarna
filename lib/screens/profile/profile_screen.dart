import 'package:flutter/material.dart';
import 'package:godarna/mixins/realtime_mixin.dart';
import 'package:provider/provider.dart';
import 'package:godarna/providers/auth_provider.dart';
import 'package:godarna/providers/language_provider.dart';
import 'package:godarna/constants/app_strings.dart';
import 'package:go_router/go_router.dart';
import 'package:godarna/screens/profile/edit_profile_screen.dart';
import 'package:godarna/screens/profile/my_properties_screen.dart';
import 'package:godarna/screens/profile/my_bookings_screen.dart';
import 'package:godarna/screens/host/host_bookings_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:godarna/widgets/common/app_app_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with RealtimeMixin {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentUser != null) {
        // Profile will be refreshed via realtime updates
        _setupRealtimeSubscriptions();
      }
    });
  }

  @override
  void dispose() {
    unsubscribeAll();
    super.dispose();
  }

  void _setupRealtimeSubscriptions() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;
    
    if (userId == null) return;
    
    // اشتراك في تحديثات بيانات المستخدم
    subscribeToTable(
      table: 'profiles',
      filter: 'id',
      filterValue: userId,
      onInsert: (payload) {
        if (mounted) {
          // تحديث بيانات المستخدم
          authProvider.refreshUser();
        }
      },
      onUpdate: (payload) {
        if (mounted) {
          authProvider.refreshUser();
        }
      },
      onDelete: (payload) {
        if (mounted) {
          // تم حذف الحساب - تسجيل الخروج
          authProvider.signOut();
        }
      },
    );

    // اشتراك في تحديثات الإشعارات
    subscribeToTable(
      table: 'notifications',
      filter: 'user_id',
      filterValue: userId,
      onInsert: (payload) {
        if (mounted) {
          // إشعار جديد - تحديث العداد
          setState(() {});
        }
      },
      onUpdate: (payload) {
        if (mounted) {
          setState(() {});
        }
      },
      onDelete: (payload) {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    const primaryColor = Color(0xFFFF3A44); // Airbnb Red

    if (!authProvider.isAuthenticated) {
      return _buildNotAuthenticated(context);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppAppBar(
        title: AppStrings.getString('profile', context),
        actions: [
          IconButton(
            onPressed: () => languageProvider.toggleLanguage(),
            icon: const Icon(Icons.language, color: Colors.black54),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Column(
          children: [
            // Profile Header
            _buildProfileHeader(context, authProvider, primaryColor),

            const SizedBox(height: 20),

            // Quick Actions
            _buildProfileActions(context, authProvider, primaryColor),

            const SizedBox(height: 20),

            // Settings
            _buildSettings(context, languageProvider, primaryColor),

            const SizedBox(height: 20),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showLogoutDialog(context, authProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('تسجيل الخروج',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotAuthenticated(BuildContext context) {
    const primaryColor = Color(0xFFFF3A44);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppAppBar(title: AppStrings.getString('profile', context)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              AppStrings.getString('loginRequired', context),
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: () => context.go('/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('تسجيل الدخول',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
      BuildContext context, AuthProvider authProvider, Color primaryColor) {
    final user = authProvider.currentUser!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[200],
            backgroundImage: user.avatar != null
                ? CachedNetworkImageProvider(user.avatar!)
                : null,
            child: user.avatar == null
                ? Icon(Icons.person, size: 50, color: Colors.grey[600])
                : null,
          ),

          const SizedBox(height: 16),

          // User Info
          Text(
            user.fullName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            user.email,
            style: const TextStyle(fontSize: 15, color: Colors.grey),
          ),

          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getRoleColor(user.role).withAlpha((0.1 * 255).toInt()),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _getRoleColor(user.role), width: 1),
            ),
            child: Text(
              _getRoleDisplayName(user.role),
              style: TextStyle(
                color: _getRoleColor(user.role),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          if (user.phone != null) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.phone, color: Colors.grey[600], size: 18),
                const SizedBox(width: 8),
                Text(
                  user.phone!,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileActions(
      BuildContext context, AuthProvider authProvider, Color primaryColor) {
    final user = authProvider.currentUser!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'إجراءات سريعة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          _actionTile(Icons.edit, 'تعديل الملف الشخصي', () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()));
          }),
          if (user.isHost)
            _actionTile(Icons.home, 'عقاراتي', () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MyPropertiesScreen()));
            }),
          if (user.isHost)
            _actionTile(Icons.calendar_today, 'حجوزاتي (كمالك)', () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const HostBookingsScreen()));
            }),
          _actionTile(Icons.bookmarks, 'حجوزاتي', () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MyBookingsScreen()));
          }),
          if (user.role == 'tenant')
            _actionTile(Icons.swap_horiz, 'أصبح مالك عقار',
                () => _showChangeRoleDialog(context, authProvider)),
        ],
      ),
    );
  }

  Widget _buildSettings(BuildContext context, LanguageProvider languageProvider,
      Color primaryColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الإعدادات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          _actionTile(
              Icons.language, 'اللغة', () => languageProvider.toggleLanguage(),
              subtitle: languageProvider.currentLanguageName),
          _actionTile(Icons.notifications, 'الإشعارات', () {}),
          _actionTile(Icons.privacy_tip, 'الخصوصية', () {}),
          _actionTile(Icons.help, 'المساعدة والدعم', () {}),
        ],
      ),
    );
  }

  Widget _actionTile(IconData icon, String title, VoidCallback onTap,
      {String? subtitle}) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFFFF3A44), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            )
          : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد أنك تريد تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              context.pop();
              await authProvider.signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child:
                const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showChangeRoleDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('أصبح مالك عقار'),
        content: const Text('هل أنت متأكد أنك تريد التحول إلى دور مالك عقار؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await authProvider.changeRole('host');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم تغيير دورك إلى مالك عقار'),
                      backgroundColor: Color(0xFF00D1B2),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('حدث خطأ: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'host':
        return const Color(0xFFFF3A44);
      case 'tenant':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'admin':
        return 'مدير';
      case 'host':
        return 'مالك عقار';
      case 'tenant':
        return 'مستأجر';
      default:
        return 'مستخدم';
    }
  }
}
