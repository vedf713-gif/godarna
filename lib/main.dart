import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:godarna/providers/auth_provider.dart';
import 'package:godarna/providers/property_provider.dart';
import 'package:godarna/providers/booking_provider.dart';
import 'package:godarna/providers/language_provider.dart';
import 'package:godarna/providers/public_browse_provider.dart';
import 'package:godarna/providers/favorites_provider.dart';
import 'package:godarna/providers/notification_provider.dart';
import 'package:godarna/utils/app_localizations.dart';
import 'package:godarna/utils/realtime_sync_manager.dart';
import 'package:godarna/utils/app_router.dart';
import 'package:godarna/theme/app_theme.dart';
import 'package:godarna/services/notifications_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// Conditional import to remove web splash overlay
import 'web/splash_remove_stub.dart'
    if (dart.library.html) 'web/splash_remove_web.dart' as web_splash;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Prefer dart-define values for production; optionally load .env for local dev
  const defineUrl = String.fromEnvironment('SUPABASE_URL');
  const defineAnon = String.fromEnvironment('SUPABASE_ANON_KEY');
  String? supabaseUrl = defineUrl.isNotEmpty ? defineUrl : null;
  String? supabaseAnonKey = defineAnon.isNotEmpty ? defineAnon : null;

  if (supabaseUrl == null || supabaseAnonKey == null) {
    // Attempt to load from .env if present (development only)
    try {
      await dotenv.load(fileName: ".env", mergeWith: const {});
      supabaseUrl = supabaseUrl ?? dotenv.env['SUPABASE_URL'];
      supabaseAnonKey = supabaseAnonKey ?? dotenv.env['SUPABASE_ANON_KEY'];
    } catch (_) {
      // ignore if .env not found
    }
  }

  if (supabaseUrl == null || supabaseUrl.isEmpty || supabaseAnonKey == null || supabaseAnonKey.isEmpty) {
    throw Exception('Missing Supabase credentials. Provide via --dart-define or .env');
  }

  // Initialize Supabase using env values
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  
  // Initialize realtime sync system
  await RealtimeSyncManager.instance.initialize();
  
  // تهيئة خدمة الإشعارات
  try {
    await NotificationsService().initialize();
    debugPrint('✅ [Main] Notifications service initialized successfully');
  } catch (e) {
    debugPrint('❌ [Main] Failed to initialize notifications service: $e');
  }
  
  runApp(const GoDarnaApp());

  // After first frame, remove the splash overlay on web so content is visible
  WidgetsBinding.instance.addPostFrameCallback((_) {
    try {
      web_splash.removeWebSplash();
    } catch (_) {
      // no-op on non-web or if element missing
    }
  });
}

class GoDarnaApp extends StatelessWidget {
  const GoDarnaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          final p = AuthProvider();
          Future.microtask(() => p.initialize());
          return p;
        }),
        ChangeNotifierProvider(create: (_) {
          final provider = PropertyProvider();
          Future.microtask(() => provider.initializeRealtime());
          return provider;
        }),
        ChangeNotifierProvider(create: (_) {
          final provider = BookingProvider();
          Future.microtask(() => provider.initializeRealtime());
          return provider;
        }),
        ChangeNotifierProvider(create: (_) {
          final p = LanguageProvider();
          Future.microtask(() => p.initialize());
          return p;
        }),
        ChangeNotifierProvider(create: (_) => PublicBrowseProvider()),
        ChangeNotifierProvider(create: (_) {
          final provider = FavoritesProvider();
          Future.microtask(() async {
            provider.initializeRealtime();
            // جلب المفضلة تلقائياً مع فرض التحديث لتنظيف المحذوف
            await provider.fetchFavorites(forceRefresh: true);
          });
          return provider;
        }),
        ChangeNotifierProvider(create: (_) {
          final provider = NotificationProvider();
          Future.microtask(() => provider.loadNotifications());
          return provider;
        }),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp.router(
            title: 'GoDarna',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: ThemeMode.system,
            locale: languageProvider.currentLocale,
            supportedLocales: const [
              Locale('ar', 'MA'), // Arabic (Morocco)
              Locale('fr', 'MA'), // French (Morocco)
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}