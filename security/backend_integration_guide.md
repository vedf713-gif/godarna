# 🔗 دليل تكامل Backend مع Row-Level Security

## 📋 نظرة عامة

هذا الدليل يوضح كيفية تكامل تطبيق GoDarna مع سياسات Row-Level Security المطبقة على قاعدة البيانات.

## 🎯 التكامل مع Supabase Flutter SDK

### 1. **التكامل التلقائي**

```dart
// في Supabase Flutter SDK، معرف المستخدم يُمرر تلقائياً
final response = await supabase
  .from('bookings')
  .select()
  .execute(); // auth.uid() متاح تلقائياً في السياسات
```

### 2. **التحقق من الجلسة**

```dart
// في AuthService
class AuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  
  // التحقق من حالة المصادقة
  static bool get isAuthenticated => _supabase.auth.currentUser != null;
  
  // الحصول على معرف المستخدم الحالي
  static String? get currentUserId => _supabase.auth.currentUser?.id;
  
  // الحصول على دور المستخدم
  static Future<String?> getCurrentUserRole() async {
    if (!isAuthenticated) return null;
    
    final response = await _supabase
      .from('profiles')
      .select('role')
      .eq('id', currentUserId!)
      .single();
      
    return response['role'];
  }
}
```

## 🛡️ أفضل الممارسات الأمنية

### 1. **التحقق من الصلاحيات في التطبيق**

```dart
// في PropertyService
class PropertyService {
  static Future<bool> canManageProperty(String propertyId) async {
    final userRole = await AuthService.getCurrentUserRole();
    
    if (userRole == 'admin') return true;
    
    final property = await supabase
      .from('listings')
      .select('host_id')
      .eq('id', propertyId)
      .single();
      
    return property['host_id'] == AuthService.currentUserId;
  }
  
  static Future<void> updateProperty(String id, Map<String, dynamic> data) async {
    // التحقق من الصلاحية قبل التحديث
    if (!await canManageProperty(id)) {
      throw Exception('ليس لديك صلاحية لتعديل هذا العقار');
    }
    
    await supabase
      .from('listings')
      .update(data)
      .eq('id', id);
  }
}
```

### 2. **معالجة الأخطاء الأمنية**

```dart
// في BaseService
class BaseService {
  static Future<T> executeSecurely<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw SecurityException('ليس لديك صلاحية للوصول لهذه البيانات');
      }
      rethrow;
    }
  }
}

class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);
}
```

### 3. **تسجيل العمليات الحساسة**

```dart
// في AdminService
class AdminService {
  static Future<void> updateUserRole(String userId, String newRole) async {
    final currentUserRole = await AuthService.getCurrentUserRole();
    
    if (currentUserRole != 'admin') {
      throw SecurityException('هذه العملية مخصصة للمديرين فقط');
    }
    
    // تسجيل العملية
    await _logAdminAction('update_user_role', {
      'target_user_id': userId,
      'new_role': newRole,
      'admin_id': AuthService.currentUserId,
    });
    
    // تنفيذ العملية
    await supabase.rpc('admin_update_user_role', {
      'p_user_id': userId,
      'p_new_role': newRole,
    });
  }
  
  static Future<void> _logAdminAction(String action, Map<String, dynamic> details) async {
    await supabase.from('admin_logs').insert({
      'action': action,
      'details': details,
      'admin_id': AuthService.currentUserId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}
```

## 🔄 إدارة الجلسات والتوكين

### 1. **تحديث التوكين التلقائي**

```dart
// في main.dart
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }
  
  void _setupAuthListener() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;
      
      if (event == AuthChangeEvent.tokenRefreshed) {
        print('Token refreshed successfully');
      } else if (event == AuthChangeEvent.signedOut) {
        // تنظيف البيانات المحلية
        _clearLocalData();
      }
    });
  }
  
  void _clearLocalData() {
    // مسح البيانات المخزنة محلياً عند تسجيل الخروج
    // لضمان عدم تسرب البيانات
  }
}
```

### 2. **التعامل مع انتهاء الجلسة**

```dart
// في HttpInterceptor
class SupabaseInterceptor {
  static Future<void> handleAuthError(PostgrestException error) async {
    if (error.code == 'PGRST301') { // Unauthorized
      // إعادة توجيه لشاشة تسجيل الدخول
      await AuthService.signOut();
      // التنقل لشاشة تسجيل الدخول
    }
  }
}
```

## 🧪 اختبار السياسات

### 1. **اختبارات وحدة للأمان**

```dart
// في test/security_test.dart
void main() {
  group('RLS Security Tests', () {
    test('User can only access own bookings', () async {
      // إنشاء مستخدم تجريبي
      final testUser = await createTestUser();
      await signInAs(testUser);
      
      // محاولة الوصول لحجوزات مستخدم آخر
      expect(
        () => BookingService.getBookingById('other-user-booking-id'),
        throwsA(isA<SecurityException>())
      );
    });
    
    test('Host can manage own properties only', () async {
      final hostUser = await createTestHost();
      await signInAs(hostUser);
      
      // يمكن إدارة العقار الخاص
      expect(
        await PropertyService.canManageProperty('own-property-id'),
        isTrue
      );
      
      // لا يمكن إدارة عقار آخر
      expect(
        await PropertyService.canManageProperty('other-property-id'),
        isFalse
      );
    });
  });
}
```

### 2. **اختبار السياسات في قاعدة البيانات**

```sql
-- اختبار سياسات المستخدم العادي
SET LOCAL role = 'authenticated';
SET LOCAL request.jwt.claim.sub = 'test-user-id';

-- يجب أن يعيد صف واحد فقط (المستخدم نفسه)
SELECT COUNT(*) FROM public.profiles; -- Expected: 1

-- يجب أن يعيد العقارات المنشورة فقط
SELECT COUNT(*) FROM public.listings WHERE is_published = false; -- Expected: 0

-- اختبار سياسات المدير
SET LOCAL request.jwt.claim.sub = 'admin-user-id';
SELECT COUNT(*) FROM public.profiles; -- Expected: جميع المستخدمين
```

## 📊 مراقبة الأداء

### 1. **مراقبة الاستعلامات البطيئة**

```sql
-- تفعيل تسجيل الاستعلامات البطيئة
ALTER SYSTEM SET log_min_duration_statement = 1000; -- 1 ثانية
ALTER SYSTEM SET log_statement = 'all';
SELECT pg_reload_conf();

-- عرض الاستعلامات البطيئة
SELECT 
  query,
  mean_exec_time,
  calls,
  total_exec_time
FROM pg_stat_statements 
WHERE mean_exec_time > 1000 -- أكثر من ثانية
ORDER BY mean_exec_time DESC;
```

### 2. **مراقبة استخدام الفهارس**

```sql
-- التحقق من استخدام الفهارس في سياسات RLS
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM public.bookings 
WHERE tenant_id = auth.uid();
```

## 🚀 النشر الآمن

### 1. **قائمة التحقق قبل النشر**

- [ ] تفعيل RLS على جميع الجداول الحساسة
- [ ] اختبار جميع السياسات مع أدوار مختلفة
- [ ] التحقق من عدم وجود تسريب بيانات
- [ ] مراجعة صلاحيات الدوال SECURITY DEFINER
- [ ] تفعيل مراقبة الأداء
- [ ] إعداد تنبيهات الأمان
- [ ] نسخ احتياطية قبل النشر

### 2. **إعدادات الإنتاج**

```sql
-- إعدادات أمان الإنتاج
ALTER DATABASE godarna SET log_statement = 'mod'; -- تسجيل التعديلات فقط
ALTER DATABASE godarna SET log_min_duration_statement = 5000; -- 5 ثوان
ALTER DATABASE godarna SET shared_preload_libraries = 'pg_stat_statements';

-- تفعيل SSL
ALTER SYSTEM SET ssl = on;
ALTER SYSTEM SET ssl_cert_file = 'server.crt';
ALTER SYSTEM SET ssl_key_file = 'server.key';
```

## 🔧 استكشاف الأخطاء

### 1. **أخطاء RLS شائعة**

```dart
// خطأ: new row violates row-level security policy
// الحل: التحقق من WITH CHECK في السياسة

// خطأ: permission denied for table
// الحل: التحقق من منح الصلاحيات الأساسية

// خطأ: function auth.uid() does not exist
// الحل: التأكد من تفعيل امتداد auth
```

### 2. **تشخيص مشاكل الأداء**

```sql
-- عرض الاستعلامات التي تستغرق وقتاً طويلاً
SELECT 
  substring(query, 1, 100) as query_start,
  mean_exec_time,
  calls
FROM pg_stat_statements 
WHERE query LIKE '%RLS%' OR query LIKE '%auth.uid%'
ORDER BY mean_exec_time DESC;
```

## 📚 مراجع إضافية

- [Supabase RLS Documentation](https://supabase.com/docs/guides/auth/row-level-security)
- [PostgreSQL RLS Documentation](https://www.postgresql.org/docs/current/ddl-rowsecurity.html)
- [Flutter Security Best Practices](https://flutter.dev/docs/development/data-and-backend/security)

---

**تم إعداد هذا الدليل بناءً على مراجعة شاملة لمشروع GoDarna**
