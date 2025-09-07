ضع هنا ملف الحدود الرسمية للمغرب باسم:

morocco_full.geojson

الشروط:
- التنسيق: GeoJSON (Polygon أو MultiPolygon)
- نظام الإحداثيات: WGS84 (EPSG:4326)
- ترتيب الإحداثيات داخل كل نقطة: [longitude, latitude]
- الحلقات الداخلية (إن وجدت) تُعالج تلقائياً، نأخذ الحلقة الخارجية لكل مضلع لرسم الحدود.

مصادر موثوقة للحصول على الملف:
- GADM: https://gadm.org/
- Natural Earth: https://www.naturalearthdata.com/
- OpenStreetMap (تصدير GeoJSON من أدوات مثل Overpass Turbo)

بعد إضافة الملف:
1) تأكد من أن المسار في pubspec.yaml يحتوي على `assets/geo/` (مضاف بالفعل)
2) نفّذ: flutter pub get
3) أعد تشغيل التطبيق.

إذا أردت أن أجلب الملف وأضيفه لك، أرسل لي رابط المصدر أو الملف مباشرة هنا.
