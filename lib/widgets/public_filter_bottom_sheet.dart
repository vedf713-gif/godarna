import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:godarna/providers/public_browse_provider.dart';
import 'package:godarna/constants/app_icons.dart';
import 'package:godarna/widgets/common/app_button.dart';

class PublicFilterBottomSheet extends StatefulWidget {
  const PublicFilterBottomSheet({super.key});

  @override
  State<PublicFilterBottomSheet> createState() =>
      _PublicFilterBottomSheetState();
}

class _PublicFilterBottomSheetState extends State<PublicFilterBottomSheet> {
  final _cityController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _radiusController = TextEditingController();
  String _orderBy = 'recent';
  String? _propertyType; // apartment, villa, riad, studio
  int _maxGuests = 1;

  Future<void> _useMyLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // يمكن إظهار رسالة للمستخدم لتفعيل GPS
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        // يجب على المستخدم تفعيل الصلاحية من الإعدادات
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium);
      if (!mounted) return;
      setState(() {
        _latController.text = pos.latitude.toStringAsFixed(6);
        _lngController.text = pos.longitude.toStringAsFixed(6);
        if (_radiusController.text.trim().isEmpty) {
          _radiusController.text = '10';
        }
      });
    } catch (_) {
      // تجاهل الخطأ بصمت أو أظهر SnackBar من الأعلى في الشاشة المستضيفة
    }
  }

  @override
  void initState() {
    super.initState();
    final prov = context.read<PublicBrowseProvider>();
    _cityController.text = prov.city ?? '';
    _minPriceController.text = prov.minPrice?.toString() ?? '';
    _maxPriceController.text = prov.maxPrice?.toString() ?? '';
    _orderBy = prov.orderBy;
    _propertyType = prov.propertyType;
    _maxGuests = prov.maxGuests ?? 1;
    _latController.text = prov.centerLat?.toString() ?? '';
    _lngController.text = prov.centerLng?.toString() ?? '';
    _radiusController.text = prov.radiusKm?.toString() ?? '';
  }

  @override
  void dispose() {
    _cityController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  num? _parseNum(String s) {
    if (s.trim().isEmpty) return null;
    return num.tryParse(s.trim());
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Container(
      decoration: const BoxDecoration(color: Colors.transparent),
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.9,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      const Icon(AppIcons.filter, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'عوامل التصفية',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(<String, dynamic>{
                            'city': null,
                            'propertyType': null,
                            'maxGuests': 1,
                            'minPrice': null,
                            'maxPrice': null,
                            'orderBy': 'recent',
                          });
                        },
                        child: const Text('مسح الكل'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('المدينة',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _cityController,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            hintText: 'مثال: الدار البيضاء، مراكش ...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('البحث القريب (اختياري)',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            AppButton(
                              onPressed: _useMyLocation,
                              text: 'استخدم موقعي',
                              icon: AppIcons.myLocation,
                              type: AppButtonType.secondary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _latController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true, signed: true),
                                decoration: InputDecoration(
                                  hintText: 'Latitude',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _lngController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true, signed: true),
                                decoration: InputDecoration(
                                  hintText: 'Longitude',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _radiusController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            hintText: 'نطاق المسافة بالكيلومتر (مثال: 10)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),
                        const SizedBox(height: 8),
                        StatefulBuilder(
                          builder: (context, setSB) {
                            double currentRadius = double.tryParse(
                                    _radiusController.text.trim()) ??
                                10.0;
                            if (currentRadius < 1) currentRadius = 1;
                            if (currentRadius > 100) currentRadius = 100;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text('النطاق'),
                                    const SizedBox(width: 8),
                                    Chip(
                                        label: Text(
                                            '${currentRadius.toStringAsFixed(0)} كم')),
                                  ],
                                ),
                                Slider(
                                  value: currentRadius,
                                  min: 1,
                                  max: 100,
                                  divisions: 99,
                                  label:
                                      '${currentRadius.toStringAsFixed(0)} كم',
                                  onChanged: (v) {
                                    setSB(() {
                                      _radiusController.text =
                                          v.toStringAsFixed(0);
                                    });
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text('نوع العقار',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildTypeChip(null, 'الكل'),
                            _buildTypeChip('apartment', 'شقة'),
                            _buildTypeChip('villa', 'فيلا'),
                            _buildTypeChip('riad', 'رياض'),
                            _buildTypeChip('studio', 'ستوديو'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text('أقصى عدد نزلاء',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Theme.of(context).colorScheme.outline),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                onPressed: _maxGuests > 1
                                    ? () => setState(() => _maxGuests--)
                                    : null,
                                icon: const Icon(AppIcons.removeCircle),
                              ),
                              Text('$_maxGuests',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                              IconButton(
                                onPressed: () => setState(() => _maxGuests++),
                                icon: const Icon(AppIcons.addCircle),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('نطاق السعر (لليلة)',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _minPriceController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'الأدنى',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _maxPriceController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'الأعلى',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text('الترتيب',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _orderBy,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'recent', child: Text('الأحدث')),
                            DropdownMenuItem(
                                value: 'price_asc',
                                child: Text('السعر: تصاعدي')),
                            DropdownMenuItem(
                                value: 'price_desc',
                                child: Text('السعر: تنازلي')),
                            DropdownMenuItem(
                                value: 'rating_desc',
                                child: Text('الأعلى تقييماً')),
                          ],
                          onChanged: (v) =>
                              setState(() => _orderBy = v ?? 'recent'),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withAlpha(15),
                          blurRadius: 8,
                          offset: const Offset(0, -2)),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          onPressed: () => Navigator.of(context).pop(),
                          text: 'إلغاء',
                          type: AppButtonType.secondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppButton(
                          onPressed: () {
                            double? parseDouble(String s) {
                              if (s.trim().isEmpty) return null;
                              return double.tryParse(s.trim());
                            }

                            final result = <String, dynamic>{
                              'city': _cityController.text.trim().isEmpty
                                  ? null
                                  : _cityController.text.trim(),
                              'propertyType': _propertyType,
                              'maxGuests': _maxGuests,
                              'minPrice': _parseNum(_minPriceController.text),
                              'maxPrice': _parseNum(_maxPriceController.text),
                              'orderBy': _orderBy,
                              'centerLat': parseDouble(_latController.text),
                              'centerLng': parseDouble(_lngController.text),
                              'radiusKm': parseDouble(_radiusController.text),
                            };
                            Navigator.of(context).pop(result);
                          },
                          text: 'تطبيق',
                          type: AppButtonType.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String? value, String label) {
    final bool selected = _propertyType == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _propertyType = value),
      selectedColor: Theme.of(context).colorScheme.primary.withAlpha(31),
      labelStyle: TextStyle(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface),
      shape: StadiumBorder(
          side: BorderSide(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline)),
    );
  }
}
