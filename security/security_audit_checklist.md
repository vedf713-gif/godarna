# 🔒 قائمة التحقق الأمني الشاملة - GoDarna

## 🎯 مراجعة ما قبل النشر

### ✅ **1. تفعيل Row-Level Security**

- [ ] تفعيل RLS على جدول `profiles`
- [ ] تفعيل RLS على جدول `listings`
- [ ] تفعيل RLS على جدول `bookings`
- [ ] تفعيل RLS على جدول `payments`
- [ ] تفعيل RLS على جدول `reviews`
- [ ] تفعيل RLS على جدول `favorites`
- [ ] تفعيل RLS على جدول `notifications`
- [ ] تفعيل RLS على جدول `chats`
- [ ] تفعيل RLS على جدول `chat_participants`
- [ ] تفعيل RLS على جدول `messages`

### 🔍 **2. اختبار السياسات**

#### اختبار المستخدم العادي (tenant):
- [ ] يمكن رؤية ملفه الشخصي فقط
- [ ] يمكن رؤية العقارات المنشورة فقط
- [ ] يمكن إنشاء حجوزات جديدة
- [ ] يمكن رؤية حجوزاته فقط
- [ ] يمكن إدارة مفضلته فقط
- [ ] يمكن كتابة تقييمات للحجوزات المكتملة فقط
- [ ] لا يمكن رؤية إشعارات المستخدمين الآخرين

#### اختبار المالك (host):
- [ ] يمكن إدارة عقاراته فقط
- [ ] يمكن رؤية حجوزات عقاراته
- [ ] يمكن تحديث حالة الحجوزات
- [ ] يمكن رؤية مدفوعات عقاراته
- [ ] لا يمكن رؤية عقارات المالكين الآخرين

#### اختبار المدير (admin):
- [ ] وصول كامل لجميع الجداول
- [ ] يمكن تحديث أدوار المستخدمين
- [ ] يمكن إدارة جميع العقارات
- [ ] يمكن رؤية جميع المدفوعات

### 🛡️ **3. أمان الدوال والـ RPCs**

- [ ] دالة `is_admin()` تعمل بشكل صحيح
- [ ] دالة `is_host()` تعمل بشكل صحيح
- [ ] دالة `owns_listing()` تعمل بشكل صحيح
- [ ] دالة `is_chat_participant()` تعمل بشكل صحيح
- [ ] دالة `browse_public_listings()` لا تكشف بيانات حساسة
- [ ] دالة `admin_update_user_role()` محمية للمديرين فقط

### 🔐 **4. أمان التخزين (Storage)**

- [ ] صور العقارات المنشورة متاحة للعموم
- [ ] رفع الصور مقيد للمستخدمين المصادق عليهم
- [ ] تعديل/حذف الصور مقيد لأصحابها
- [ ] لا يوجد تسريب لصور العقارات غير المنشورة

### 📱 **5. أمان التطبيق**

- [ ] التحقق من الجلسة في كل استعلام
- [ ] معالجة أخطاء الأمان بشكل مناسب
- [ ] عدم تخزين بيانات حساسة محلياً
- [ ] تشفير البيانات الحساسة
- [ ] تسجيل العمليات الحساسة

## 🚨 اختبارات الثغرات الأمنية

### **1. اختبار تسريب البيانات**

```sql
-- اختبار 1: محاولة الوصول لبيانات مستخدم آخر
SET LOCAL request.jwt.claim.sub = 'user-1-id';
SELECT * FROM public.profiles WHERE id = 'user-2-id'; -- يجب أن يعيد 0 صفوف

-- اختبار 2: محاولة رؤية حجوزات مستخدم آخر
SELECT * FROM public.bookings WHERE tenant_id = 'other-user-id'; -- يجب أن يعيد 0 صفوف

-- اختبار 3: محاولة تعديل عقار مستخدم آخر
UPDATE public.listings SET title = 'hacked' WHERE host_id != auth.uid(); -- يجب أن يفشل
```

### **2. اختبار تصعيد الصلاحيات**

```sql
-- اختبار 1: محاولة تحديث دور المستخدم بدون صلاحية مدير
SELECT public.admin_update_user_role('target-user-id', 'admin'); -- يجب أن يفشل

-- اختبار 2: محاولة الوصول لدوال إدارية
SELECT public.admin_update_listing_status('listing-id', false); -- يجب أن يفشل للمستخدم العادي
```

### **3. اختبار حقن SQL**

```dart
// اختبار في التطبيق
final maliciousInput = "'; DROP TABLE profiles; --";
await PropertyService.searchProperties(maliciousInput); // يجب أن يكون آمن
```

## 📊 مراقبة الأمان

### **1. مراقبة محاولات الوصول المشبوهة**

```sql
-- إنشاء جدول لتسجيل محاولات الوصول المشبوهة
CREATE TABLE IF NOT EXISTS public.security_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID,
  action TEXT NOT NULL,
  table_name TEXT,
  attempted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  ip_address INET,
  user_agent TEXT,
  success BOOLEAN DEFAULT false
);

-- دالة لتسجيل محاولات الوصول
CREATE OR REPLACE FUNCTION public.log_security_event(
  p_action TEXT,
  p_table_name TEXT DEFAULT NULL,
  p_success BOOLEAN DEFAULT false
)
RETURNS VOID AS $$
BEGIN
  INSERT INTO public.security_logs (user_id, action, table_name, success)
  VALUES (auth.uid(), p_action, p_table_name, p_success);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### **2. تنبيهات الأمان**

```sql
-- دالة للتحقق من محاولات الوصول المشبوهة
CREATE OR REPLACE FUNCTION public.check_suspicious_activity()
RETURNS TABLE (
  user_id UUID,
  failed_attempts BIGINT,
  last_attempt TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    sl.user_id,
    COUNT(*) as failed_attempts,
    MAX(sl.attempted_at) as last_attempt
  FROM public.security_logs sl
  WHERE sl.success = false 
    AND sl.attempted_at > NOW() - INTERVAL '1 hour'
  GROUP BY sl.user_id
  HAVING COUNT(*) > 10; -- أكثر من 10 محاولات فاشلة في الساعة
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

## 🔄 صيانة دورية

### **أسبوعياً:**
- [ ] مراجعة سجلات الأمان
- [ ] التحقق من الاستعلامات البطيئة
- [ ] مراجعة محاولات الوصول الفاشلة

### **شهرياً:**
- [ ] مراجعة وتحديث السياسات
- [ ] اختبار السياسات مع بيانات جديدة
- [ ] مراجعة صلاحيات المستخدمين
- [ ] تنظيف سجلات الأمان القديمة

### **ربع سنوياً:**
- [ ] مراجعة شاملة للأمان
- [ ] اختبار اختراق محدود
- [ ] تحديث كلمات المرور الإدارية
- [ ] مراجعة النسخ الاحتياطية

## 🚨 خطة الاستجابة للحوادث

### **في حالة اكتشاف ثغرة أمنية:**

1. **الاستجابة الفورية (0-15 دقيقة):**
   - تعطيل الوصول للجدول المتأثر
   - تسجيل تفاصيل الحادث
   - إشعار الفريق التقني

2. **التقييم (15-60 دقيقة):**
   - تحديد نطاق التأثير
   - فحص سجلات الوصول
   - تقييم البيانات المتسربة

3. **الإصلاح (1-4 ساعات):**
   - إصلاح الثغرة
   - تحديث السياسات
   - اختبار الإصلاح

4. **المتابعة (24-48 ساعة):**
   - مراقبة مكثفة
   - إشعار المستخدمين المتأثرين
   - توثيق الحادث والدروس المستفادة

## 📞 جهات الاتصال

- **فريق التطوير**: [البريد الإلكتروني]
- **مدير الأمان**: [البريد الإلكتروني]
- **الدعم التقني**: [رقم الهاتف]

---

**آخر تحديث**: [التاريخ]  
**المراجع**: فريق تطوير GoDarna
