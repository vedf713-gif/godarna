# دليل التصميم المغربي - تطبيق GoDarna

## نظرة عامة
تم تطوير نظام تصميم مغربي عصري شامل لتطبيق GoDarna يجمع بين الأصالة المغربية والحداثة التقنية.

## 🎨 نظام الألوان

### الألوان الأساسية
```dart
- الأحمر المغربي: #AE392C (primaryRed)
- البرتقالي الثانوي: #E67E22 (secondaryOrange) 
- الذهبي المميز: #F39C12 (accentGold)
- الأبيض الكريمي: #FDF6E3 (backgroundLight)
```

### الألوان الوظيفية
```dart
- النجاح: #27AE60
- الخطأ: #E74C3C
- التحذير: #F39C12
- المعلومات: #3498DB
```

## 📝 نظام الطباعة

### الخط الأساسي
- **الخط**: Cairo (يدعم العربية بشكل ممتاز)
- **الأوزان**: Light (300), Regular (400), Bold (700)

### أحجام النصوص
```dart
- العنوان الكبير: 32px, Bold
- العنوان المتوسط: 24px, Bold  
- العنوان الصغير: 20px, SemiBold
- النص الأساسي: 16px, Regular
- النص الثانوي: 14px, Regular
- النص الصغير: 12px, Light
```

## 🏗️ المكونات المغربية

### MoroccanCard
بطاقة مغربية مع تدرجات لونية وظلال ناعمة:
```dart
MoroccanCard(
  child: YourContent(),
  elevation: 4,
  borderRadius: 16,
)
```

### MoroccanButton
زر مغربي تفاعلي مع تأثيرات بصرية:
```dart
MoroccanButton(
  text: 'النص',
  icon: Icons.icon_name,
  onPressed: () {},
  style: MoroccanButtonStyle.primary,
)
```

### MoroccanTextField
حقل إدخال مغربي مع دعم RTL:
```dart
MoroccanTextField(
  label: 'التسمية',
  hint: 'النص التوضيحي',
  controller: controller,
  textDirection: TextDirection.rtl,
)
```

### MoroccanHeader
رأس مغربي مع تدرج لوني:
```dart
MoroccanHeader(
  title: 'العنوان',
  subtitle: 'العنوان الفرعي',
  showPattern: true,
)
```

## 🎭 الحركات والانتقالات

### انتقالات الصفحات
```dart
// انتقال من اليمين
MoroccanPageTransition(
  child: NewPage(),
  type: TransitionType.slideFromRight,
)

// انتقال بنمط مغربي
MoroccanPageTransition(
  child: NewPage(),
  type: TransitionType.moroccanPattern,
)
```

### التفاعلات
```dart
MoroccanInteractiveTransition(
  child: YourWidget(),
  onTap: () {},
  duration: Duration(milliseconds: 200),
)
```

## 💀 مؤثرات التحميل

### Skeleton Loaders
```dart
// تحميل بطاقة العقار
MoroccanPropertyCardSkeleton()

// تحميل قائمة العقارات  
MoroccanPropertyListSkeleton(itemCount: 6)

// تحميل الملف الشخصي
MoroccanProfileSkeleton()
```

### حالات فارغة
```dart
MoroccanEmptyState(
  title: 'لا توجد نتائج',
  description: 'لم نجد أي عقارات تطابق بحثك',
  icon: Icons.search_off,
  actionText: 'ابحث مرة أخرى',
  onAction: () {},
)
```

## 🌍 دعم اللغة العربية

### تنسيق النصوص
```dart
// نص عربي مع تنسيق تلقائي
ArabicText(
  'النص العربي',
  style: TextStyle(fontSize: 16),
  convertNumbers: true,
)

// نص مختلط (عربي/إنجليزي)
MixedText(
  'النص المختلط Mixed Text',
  arabicStyle: arabicStyle,
  englishStyle: englishStyle,
)
```

### التنسيقات المحلية
```dart
// تنسيق العملة المغربية
ArabicSupport.formatMoroccanCurrency(1500.0) // "١٥٠٠.٠٠ د.م."

// تنسيق التاريخ
ArabicSupport.formatArabicDate(DateTime.now()) // "الاثنين، ١٥ يناير ٢٠٢٤"

// تنسيق المسافة
ArabicSupport.formatDistance(2.5) // "٢.٥ كم"
```

## 🏛️ الهيكل المعماري

### تنظيم الملفات
```
lib/
├── theme/
│   ├── app_theme.dart
│   ├── app_colors.dart
│   ├── app_typography.dart
│   ├── moroccan_decorations.dart
│   └── moroccan_animations.dart
├── widgets/
│   ├── moroccan_widgets.dart
│   ├── moroccan_skeleton_loaders.dart
│   ├── moroccan_transitions.dart
│   └── moroccan_auth_background.dart
├── utils/
│   └── arabic_support.dart
└── screens/
    ├── main/
    ├── auth/
    └── property/
```

## 🎯 أفضل الممارسات

### 1. الألوان
- استخدم الألوان المغربية الأساسية للعناصر المهمة
- طبق التدرجات اللونية للخلفيات والعناصر الكبيرة
- احترم نسب التباين للوضوح

### 2. الطباعة
- استخدم خط Cairo لجميع النصوص
- طبق الأحجام المحددة للتناسق
- اعتمد على الأوزان المختلفة للتسلسل الهرمي

### 3. التخطيط
- استخدم الزوايا المستديرة (16px+) للعناصر
- طبق المسافات المتناسقة (8, 16, 24, 32px)
- اعتمد على الشبكة المرنة للتخطيط

### 4. التفاعل
- أضف انتقالات ناعمة للتفاعلات
- استخدم ردود الفعل البصرية واللمسية
- طبق مؤثرات التحميل المناسبة

### 5. إمكانية الوصول
- ادعم قارئات الشاشة
- وفر نسب تباين كافية
- اجعل العناصر قابلة للوصول بالكيبورد

## 🔧 التنفيذ

### إعداد التيم
```dart
MaterialApp(
  theme: AppTheme.light,
  darkTheme: AppTheme.dark,
  themeMode: ThemeMode.system,
  // ...
)
```

### استخدام المكونات
```dart
// في أي شاشة
import 'package:godarna/widgets/moroccan_widgets.dart';

// استخدام المكونات المغربية
MoroccanCard(
  child: Column(
    children: [
      MoroccanHeader(title: 'العنوان'),
      MoroccanTextField(label: 'البحث'),
      MoroccanButton(
        text: 'بحث',
        onPressed: () {},
      ),
    ],
  ),
)
```

## 📱 الشاشات المحدثة

### ✅ مكتملة
- الشاشة الرئيسية (HomeScreen)
- شاشة الاستكشاف (ExploreScreen)  
- شاشة الحجوزات (BookingsScreen)
- شاشة الملف الشخصي (ProfileScreen)
- شاشة تفاصيل العقار (PropertyDetailsScreen)
- شاشة تسجيل الدخول (LoginScreen)

### 🔄 قيد التطوير
- شاشات الإدارة
- شاشة الخريطة
- شاشة الإشعارات

## 🚀 الخطوات القادمة

1. **تحسين الأداء**: تحسين الحركات والانتقالات
2. **اختبار المستخدم**: جمع ملاحظات المستخدمين
3. **التوسع**: إضافة مكونات جديدة حسب الحاجة
4. **التحديث**: تحديث المكونات بناءً على التغذية الراجعة

## 📞 الدعم

للأسئلة أو المساعدة في التنفيذ، راجع:
- ملفات المكونات في `/lib/widgets/`
- أمثلة الاستخدام في `/lib/screens/`
- ملفات الثيم في `/lib/theme/`

---

**تم إنشاء هذا الدليل كجزء من مشروع تطوير التصميم المغربي لتطبيق GoDarna**
