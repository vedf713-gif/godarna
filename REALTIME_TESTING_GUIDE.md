# 🔄 دليل اختبار نظام Realtime في تطبيق GoDarna

## 📋 قائمة التحقق الشاملة

### 1. 🔧 التحقق من إعدادات Supabase

#### أ) فحص تفعيل Realtime في قاعدة البيانات:
```sql
-- تحقق من تفعيل Realtime للجداول المطلوبة
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename IN ('profiles', 'listings', 'bookings', 'notifications', 'messages', 'favorites', 'reviews', 'payments');

-- تحقق من publications للـ realtime
SELECT * FROM pg_publication_tables WHERE pubname = 'supabase_realtime';
```

#### ب) تحقق من أن الجداول مُضافة للـ Realtime:
```sql
-- إضافة الجداول للـ realtime إذا لم تكن مُضافة
ALTER PUBLICATION supabase_realtime ADD TABLE profiles;
ALTER PUBLICATION supabase_realtime ADD TABLE listings;
ALTER PUBLICATION supabase_realtime ADD TABLE bookings;
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE favorites;
ALTER PUBLICATION supabase_realtime ADD TABLE reviews;
ALTER PUBLICATION supabase_realtime ADD TABLE payments;
```

### 2. 📱 التحقق من تطبيق RealtimeMixin في الشاشات

#### الشاشات التي يجب أن تحتوي على RealtimeMixin:

✅ **الشاشات الأساسية:**
- `home_screen.dart` - للإشعارات والتحديثات العامة
- `explore_screen.dart` - لتحديثات العقارات
- `search_screen.dart` - لنتائج البحث المحدثة
- `favorites_screen.dart` - لتحديثات المفضلة
- `bookings_screen.dart` - لحالات الحجوزات
- `notifications_screen.dart` - للإشعارات الجديدة
- `profile_screen.dart` - لتحديثات الملف الشخصي

✅ **شاشات التفاصيل:**
- `property_details_screen.dart` - لتحديثات العقار والمراجعات
- `booking_details_screen.dart` - لحالة الحجز والرسائل
- `my_bookings_screen.dart` - لحجوزات المستأجر
- `host_bookings_screen.dart` - لحجوزات المضيف
- `payment_screen.dart` - لحالة الدفع
- `payment_history_screen.dart` - لتاريخ المدفوعات

### 3. 🧪 اختبارات الوظائف الفورية

#### أ) اختبار الإشعارات الفورية:
1. **افتح التطبيق على جهازين مختلفين**
2. **سجل دخول بحسابين مختلفين**
3. **من الجهاز الأول:** أرسل رسالة في محادثة حجز
4. **في الجهاز الثاني:** يجب أن تظهر الإشعار فوراً في:
   - شاشة الإشعارات
   - badge الإشعارات في الشاشة الرئيسية
   - شاشة تفاصيل الحجز (إذا كانت مفتوحة)

#### ب) اختبار تحديثات الحجوزات:
1. **من لوحة Supabase:** غيّر حالة حجز من "pending" إلى "confirmed"
2. **في التطبيق:** يجب أن تتحدث الحالة فوراً في:
   - شاشة قائمة الحجوزات
   - شاشة تفاصيل الحجز
   - الإشعارات

#### ج) اختبار المفضلة الفورية:
1. **من جهاز:** أضف عقار للمفضلة
2. **من جهاز آخر (نفس الحساب):** يجب أن يظهر العقار في المفضلة فوراً
3. **احذف من المفضلة:** يجب أن يختفي من الجهاز الآخر فوراً

#### د) اختبار الرسائل الفورية:
1. **افتح محادثة حجز على جهازين**
2. **أرسل رسالة من جهاز**
3. **يجب أن تظهر فوراً في الجهاز الآخر**
4. **تحقق من تحديث "آخر ظهور" و "قُرئت"**

### 4. 🔍 أدوات التشخيص

#### أ) فحص Console Logs:
```dart
// في RealtimeMixin، تأكد من وجود logs:
print('🔄 Realtime: Subscribed to $tableName');
print('📨 Realtime: Received event: ${payload.eventType}');
print('❌ Realtime: Error in subscription: $error');
```

#### ب) فحص Network في Developer Tools:
- ابحث عن WebSocket connections إلى Supabase
- تأكد من وجود اتصالات realtime نشطة
- راقب الرسائل المرسلة والمستقبلة

#### ج) فحص Supabase Dashboard:
1. اذهب إلى **Database > Realtime**
2. تحقق من أن الجداول مُفعلة
3. راقب Real-time connections في **Settings > API**

### 5. 🚨 علامات المشاكل الشائعة

#### مشاكل الاتصال:
- ❌ لا توجد WebSocket connections في Network tab
- ❌ خطأ "Failed to connect to realtime"
- ❌ انقطاع متكرر في الاتصال

#### مشاكل الصلاحيات:
- ❌ خطأ "insufficient_privilege"
- ❌ لا تصل التحديثات لبعض المستخدمين
- ❌ تصل التحديثات لمستخدمين غير مخولين

#### مشاكل الأداء:
- ❌ تأخير في وصول التحديثات (أكثر من 2-3 ثواني)
- ❌ استهلاك عالي للذاكرة
- ❌ بطء في التطبيق

### 6. 📊 اختبار الأداء

#### أ) اختبار الحمولة:
1. **افتح التطبيق على 5+ أجهزة**
2. **قم بأنشطة متزامنة** (إضافة مفضلة، إرسال رسائل)
3. **راقب سرعة التحديثات**

#### ب) اختبار الاستقرار:
1. **اترك التطبيق مفتوح لمدة ساعة**
2. **قم بأنشطة دورية كل 10 دقائق**
3. **تأكد من استمرار عمل Realtime**

### 7. ✅ معايير النجاح

#### الإشعارات:
- ✅ تصل الإشعارات خلال 1-2 ثانية
- ✅ تظهر في جميع الشاشات المناسبة
- ✅ تحديث badge الإشعارات فورياً

#### الحجوزات:
- ✅ تحديث حالة الحجز فورياً
- ✅ تحديث قوائم الحجوزات
- ✅ إشعارات تغيير الحالة

#### المفضلة:
- ✅ إضافة/حذف فوري عبر الأجهزة
- ✅ تحديث العدادات
- ✅ تحديث أيقونة القلب

#### الرسائل:
- ✅ وصول الرسائل خلال 1 ثانية
- ✅ تحديث حالة "قُرئت"
- ✅ تحديث "آخر ظهور"

### 8. 🔧 حلول المشاكل الشائعة

#### إذا لم تعمل الإشعارات:
```sql
-- تحقق من سياسات RLS
SELECT * FROM pg_policies WHERE tablename = 'notifications';

-- تأكد من وجود السياسة الصحيحة
DROP POLICY IF EXISTS "notifications_insert_admin" ON notifications;
CREATE POLICY "notifications_insert_authenticated" ON notifications
FOR INSERT TO authenticated
WITH CHECK (true);
```

#### إذا لم تعمل الرسائل:
```sql
-- تحقق من دالة is_chat_participant
SELECT routine_name, routine_definition 
FROM information_schema.routines 
WHERE routine_name = 'is_chat_participant';
```

#### إذا كان هناك بطء:
```dart
// قلل عدد الاشتراكات
// استخدم فلاتر دقيقة
subscribeToTable(
  'bookings',
  filter: 'tenant_id=eq.$userId',
  callback: _onBookingUpdate,
);
```

### 9. 📈 مراقبة مستمرة

#### KPIs للمراقبة:
- **زمن وصول الإشعارات:** < 2 ثانية
- **معدل نجاح التحديثات:** > 99%
- **استهلاك الذاكرة:** مستقر
- **عدد الاتصالات النشطة:** متوقع

#### أدوات المراقبة:
- Supabase Dashboard
- Firebase Performance (إذا مُفعل)
- Device logs
- User feedback

---

## 🎯 خلاصة الاختبار

بعد تطبيق جميع الاختبارات أعلاه، يجب أن يكون لديك:

✅ **نظام realtime يعمل بكفاءة 100%**
✅ **تحديثات فورية عبر جميع الشاشات**
✅ **تجربة مستخدم سلسة ومتجاوبة**
✅ **أداء مستقر تحت الحمولة**

إذا واجهت أي مشاكل، راجع الحلول المقترحة أو اطلب المساعدة مع تفاصيل الخطأ المحدد.
