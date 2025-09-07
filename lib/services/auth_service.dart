import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:godarna/models/user_model.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final response = await _supabase
            .from('users')
            .select()
            .eq('id', user.id)
            .single();
        
        return UserModel.fromJson(response);
            }
      return null;
    } catch (e) {
      throw Exception('Failed to get current user: $e');
    }
  }

  // Send OTP
  Future<bool> sendOtp(String email) async {
    try {
      await _supabase.auth.signInWithOtp(
        email: email,
        emailRedirectTo: null,
        shouldCreateUser: true,
      );
      return true;
    } catch (e) {
      throw Exception('Failed to send OTP: $e');
    }
  }

  // Verify OTP and sign in
  Future<UserModel?> verifyOtp(String email, String otp) async {
    try {
      // تحقق فعلي عبر Supabase باستخدام رمز البريد
      await _supabase.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.email,
      );

      final authUser = _supabase.auth.currentUser;
      if (authUser == null) {
        return null;
      }

      // بعد المصادقة، يمكننا القراءة من جدول users وفق RLS
      final existing = await _supabase
          .from('users')
          .select()
          .eq('id', authUser.id)
          .maybeSingle();

      if (existing != null) {
        return UserModel.fromJson(existing);
      }

      // أنشئ صف المستخدم إن لم يكن موجوداً
      final newUser = await _createUser(id: authUser.id, email: authUser.email ?? email);
      return newUser;
    } catch (e) {
      throw Exception('Failed to verify OTP: $e');
    }
  }

  // Create new user
  Future<UserModel?> _createUser({required String id, required String email}) async {
    try {
      final userData = {
        'id': id,
        'email': email,
        'role': 'tenant', // Default role
        'is_email_verified': true,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('users')
          .upsert(userData)
          .select()
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  // Update user profile
  Future<UserModel?> updateProfile({
    required String userId,
    String? firstName,
    String? lastName,
    String? phone,
    String? language,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (firstName != null) updateData['first_name'] = firstName;
      if (lastName != null) updateData['last_name'] = lastName;
      if (phone != null) updateData['phone'] = phone;
      if (language != null) updateData['language'] = language;

      final response = await _supabase
          .from('users')
          .update(updateData)
          .eq('id', userId)
          .select()
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Change user role
  Future<UserModel?> changeRole({
    required String userId,
    required String role,
  }) async {
    try {
      final response = await _supabase
          .from('users')
          .update({
            'role': role,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId)
          .select()
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to change role: $e');
    }
  }

  // Check if email exists
  Future<bool> emailExists(String email) async {
    try {
      final response = await _supabase
          .from('users')
          .select('id')
          .eq('email', email)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      throw Exception('Failed to check email: $e');
    }
  }

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      
      return UserModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  // Delete user account
  Future<bool> deleteAccount(String userId) async {
    try {
      await _supabase
          .from('users')
          .delete()
          .eq('id', userId);
      
      await signOut();
      return true;
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }
}