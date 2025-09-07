// ignore_for_file: avoid_web_libraries_in_flutter
import 'package:web/web.dart' as web;

void removeWebSplash() {
  web.document.getElementById('splash')?.remove();
  web.document.getElementById('splash-branding')?.remove();
  web.document.body?.style.background = 'transparent';
}
