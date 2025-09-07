import 'package:flutter/services.dart';

export 'package:flutter/services.dart' show ClipboardData;

class Clipboard {
  static Future<void> setData(ClipboardData data) async {
    await SystemChannels.platform.invokeMethod(
      'Clipboard.setData',
      <String, dynamic>{
        'text': data.text,
      },
    );
  }

  static Future<ClipboardData?> getData() {
    return SystemChannels.platform.invokeMethod('Clipboard.getData').then((data) {
      return data != null ? ClipboardData(text: data['text'] ?? '') : null;
    });
  }
}
