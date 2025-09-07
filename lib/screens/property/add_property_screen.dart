import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:godarna/mixins/realtime_mixin.dart';
import 'package:godarna/providers/auth_provider.dart';
import 'package:godarna/providers/property_provider.dart';
import 'package:godarna/constants/app_strings.dart';
import 'package:godarna/widgets/common/app_app_bar.dart';
import 'package:godarna/widgets/custom_text_field.dart';
import 'package:godarna/models/property_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:godarna/services/property_service.dart';
import 'package:godarna/screens/map/pick_location_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import 'package:godarna/utils/permissions.dart';
import 'package:godarna/widgets/permission_rationale.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';
import 'package:godarna/data/morocco_regions_cities.dart';
import 'package:godarna/providers/language_provider.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen>
    with RealtimeMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _areaController = TextEditingController();
  final _pricePerNightController = TextEditingController();
  final _pricePerMonthController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _maxGuestsController = TextEditingController();

  String _selectedPropertyType = 'apartment';
  String? _selectedRegion;
  String? _selectedCity;

  final List<Uint8List> _selectedImages = [];
  final List<String> _selectedAmenities = [];
  final List<String> _selectedExperiences = [];

  bool _isLoading = false;
  double? _pickedLat;
  double? _pickedLng;
  int _uploadCompleted = 0;
  int _uploadTotal = 0;
  int _currentStep = 0;

  bool _hasUnsavedChanges = false;
  Timer? _saveDebounce;
  final NumberFormat _numberFormatter = NumberFormat.decimalPattern();

  static const String _draftKey = 'add_property_draft_v1';

  static const Map<String, List<String>> _typeGroups = {
    '🏘️ الإقامات العصرية': ['apartment', 'studio', 'villa'],
    '🏡 الإقامات التقليدية': ['riad', 'kasbah', 'village_house'],
    '🏕️ الإقامات البديلة': ['desert_camp', 'eco_lodge', 'guesthouse'],
    '🏨 الإقامات السياحية': ['hotel', 'resort'],
  };

  String _typeLabel(BuildContext context, String type) {
    switch (type) {
      case 'apartment':
        return AppStrings.getString('typeApartment', context);
      case 'studio':
        return AppStrings.getString('typeStudio', context);
      case 'villa':
        return AppStrings.getString('typeVilla', context);
      case 'riad':
        return AppStrings.getString('typeRiad', context);
      case 'kasbah':
        return AppStrings.getString('typeKasbah', context);
      case 'village_house':
        return AppStrings.getString('typeVillageHouse', context);
      case 'desert_camp':
        return AppStrings.getString('typeDesertCamp', context);
      case 'eco_lodge':
        return AppStrings.getString('typeEcoLodge', context);
      case 'guesthouse':
        return AppStrings.getString('typeGuesthouse', context);
      case 'hotel':
        return AppStrings.getString('typeHotel', context);
      case 'resort':
        return AppStrings.getString('typeResort', context);
      default:
        return type;
    }
  }

  @override
  void initState() {
    super.initState();
    for (final c in [
      _titleController,
      _descriptionController,
      _addressController,
      _cityController,
      _areaController,
      _bedroomsController,
      _bathroomsController,
      _maxGuestsController,
    ]) {
      c.addListener(_onAnyChange);
    }
    _pricePerNightController
        .addListener(() => _onPriceChanged(_pricePerNightController));
    _pricePerMonthController
        .addListener(() => _onPriceChanged(_pricePerMonthController));
    _restoreDraft();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupRealtimeSubscriptions();
    });
  }

  void _setupRealtimeSubscriptions() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;

    if (userId == null) return;

    // اشتراك في تحديثات العقارات الخاصة بالمستخدم
    subscribeToTable(
      table: 'properties',
      filter: 'host_id',
      filterValue: userId,
      onInsert: (payload) {
        if (mounted) {
          // عقار جديد تم إضافته - تحديث المزود
          final propertyProvider =
              Provider.of<PropertyProvider>(context, listen: false);
          propertyProvider.fetchProperties(forceRefresh: true);
        }
      },
      onUpdate: (payload) {
        if (mounted) {
          final propertyProvider =
              Provider.of<PropertyProvider>(context, listen: false);
          propertyProvider.fetchProperties(forceRefresh: true);
        }
      },
      onDelete: (payload) {
        if (mounted) {
          final propertyProvider =
              Provider.of<PropertyProvider>(context, listen: false);
          propertyProvider.fetchProperties(forceRefresh: true);
        }
      },
    );
  }


  final List<String> _availableAmenities = [
    'amenityAirConditioning',
    'amenityHeating',
    'amenityKitchen',
    'amenityWasher',
    'amenityWifi',
    'amenityTV',
    'amenityParking',
    'amenityGarden',
    'amenityPool',
    'amenityGym',
    'amenityBalcony',
    'amenityGarden',
    'amenityFireplace',
    'amenityBBQ',
    'amenityTerrace',
    'amenityElevator',
    'amenityPetFriendly',
    'amenitySmokingAllowed',
    'amenityChildFriendly',
  ];

  final List<Map<String, String>> _experiencesOptions = const [
    {'code': 'cuisine', 'labelKey': 'expCuisine'},
    {'code': 'cultural_tours', 'labelKey': 'expCulturalTours'},
    {'code': 'music_arts', 'labelKey': 'expMusicArts'},
    {'code': 'adventure_nature', 'labelKey': 'expAdventureNature'},
    {'code': 'traditions_lifestyle', 'labelKey': 'expTraditionsLifestyle'},
    {'code': 'nomadic_tribal', 'labelKey': 'expNomadicTribal'},
    {'code': 'everyday_life', 'labelKey': 'expEverydayLife'},
  ];

  @override
  void dispose() {
    unsubscribeAll();
    _saveDebounce?.cancel();
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _pricePerNightController.dispose();
    _pricePerMonthController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _maxGuestsController.dispose();
    super.dispose();
  }

  void _onAnyChange() {
    _hasUnsavedChanges = true;
    _saveDebounced();
  }

  void _onPriceChanged(TextEditingController controller) {
    _hasUnsavedChanges = true;
    final raw = controller.text;
    final sanitized = _sanitizeNumber(raw);
    if (sanitized.isEmpty) {
      _saveDebounced();
      return;
    }
    final num? value = num.tryParse(sanitized);
    if (value == null) {
      _saveDebounced();
      return;
    }
    final formatted = _numberFormatter.format(value);
    if (formatted != raw) {
      final selectionIndexFromRight =
          raw.length - controller.selection.baseOffset;
      controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(
          offset: (formatted.length - selectionIndexFromRight)
              .clamp(0, formatted.length),
        ),
      );
    }
    _saveDebounced();
  }

  String _sanitizeNumber(String input) {
    return input.replaceAll(RegExp(r'[^0-9.]'), '');
  }

  double _parsePrice(String input) {
    final s = _sanitizeNumber(input);
    if (s.isEmpty) return 0;
    return double.tryParse(s) ?? 0;
  }

  void _saveDebounced() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 500), _saveDraft);
  }

  Future<void> _saveDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'address': _addressController.text,
        'city': _cityController.text,
        'region': _selectedRegion,
        'area': _areaController.text,
        'pricePerNight': _pricePerNightController.text,
        'pricePerMonth': _pricePerMonthController.text,
        'bedrooms': _bedroomsController.text,
        'bathrooms': _bathroomsController.text,
        'maxGuests': _maxGuestsController.text,
        'propertyType': _selectedPropertyType,
        'lat': _pickedLat,
        'lng': _pickedLng,
        'amenities': _selectedAmenities,
        'experiences': _selectedExperiences,
      };
      await prefs.setString(_draftKey, jsonEncode(data));
    } catch (_) {}
  }

  Future<void> _restoreDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_draftKey);
      if (raw == null) return;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      setState(() {
        _titleController.text = (map['title'] ?? '') as String;
        _descriptionController.text = (map['description'] ?? '') as String;
        _addressController.text = (map['address'] ?? '') as String;
        _cityController.text = (map['city'] ?? '') as String;
        final r = (map['region'] ?? '') as String;
        _selectedRegion = r.isEmpty ? null : r;
        final restoredCity = (map['city'] ?? '') as String;
        if (restoredCity.isNotEmpty && _selectedRegion != null) {
          final list = MoroccoRegionsCities.citiesFor(_selectedRegion);
          _selectedCity = list.contains(restoredCity) ? restoredCity : null;
        } else {
          _selectedCity = null;
        }
        _areaController.text = (map['area'] ?? '') as String;
        _pricePerNightController.text = (map['pricePerNight'] ?? '') as String;
        _pricePerMonthController.text = (map['pricePerMonth'] ?? '') as String;
        _bedroomsController.text = (map['bedrooms'] ?? '') as String;
        _bathroomsController.text = (map['bathrooms'] ?? '') as String;
        _maxGuestsController.text = (map['maxGuests'] ?? '') as String;
        final pt = (map['propertyType'] ?? 'apartment') as String;
        _selectedPropertyType = pt.isEmpty ? 'apartment' : pt;
        final latVal = map['lat'];
        final lngVal = map['lng'];
        _pickedLat = latVal is num
            ? latVal.toDouble()
            : double.tryParse((latVal ?? '').toString());
        _pickedLng = lngVal is num
            ? lngVal.toDouble()
            : double.tryParse((lngVal ?? '').toString());
        final amenities = map['amenities'];
        _selectedAmenities
          ..clear()
          ..addAll(amenities is List
              ? amenities.map((e) => e.toString())
              : <String>[]);
        final experiences = map['experiences'];
        _selectedExperiences
          ..clear()
          ..addAll(experiences is List
              ? experiences.map((e) => e.toString())
              : <String>[]);
        _hasUnsavedChanges = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppStrings.getString('draftRestored', context))),
        );
      }
    } catch (_) {}
  }

  Future<void> _clearDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_draftKey);
      _hasUnsavedChanges = false;
    } catch (_) {}
  }

  Future<void> _pickImages() async {
    try {
      // Skip permission dialog for web
      if (!kIsWeb) {
        final proceed = await showPermissionRationale(
          context,
          title: 'الوصول إلى الصور',
          message: 'نحتاج إذنك للوصول إلى صورك لرفع صور العقار.',
        );
        if (!proceed) return;

        final granted =
            await PermissionsHelper.requestMediaPermissionWithFallback();
        if (!mounted) return;

        if (!granted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'تم رفض الصلاحيات. يرجى السماح بالوصول للصور من الإعدادات.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'تشخيص',
                textColor: Colors.white,
                onPressed: () => _showPermissionDiagnostic(),
              ),
            ),
          );
          return;
        }
      }

      final ImagePicker picker = ImagePicker();

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('جاري فتح معرض الصور...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      final List<XFile> images = await picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (!mounted) return;

      // Clear loading message
      ScaffoldMessenger.of(context).clearSnackBars();

      if (images.isNotEmpty) {
        // Show processing message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('جاري معالجة ${images.length} صورة...'),
            backgroundColor: const Color(0xFF00D1B2),
          ),
        );

        for (final image in images) {
          try {
            final bytes = await image.readAsBytes();
            final compressed = _compressImage(bytes);
            if (mounted) {
              setState(() {
                _selectedImages.add(compressed);
                _hasUnsavedChanges = true;
              });
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('خطأ في معالجة الصورة: ${image.name}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم إضافة ${images.length} صورة بنجاح'),
              backgroundColor: const Color(0xFF00D1B2),
            ),
          );
          _saveDebounced();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('لم يتم اختيار أي صورة'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في فتح معرض الصور: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _pickSingleImage({bool fromCamera = false}) async {
    try {
      // Skip permissions for web, camera not supported in web
      if (kIsWeb && fromCamera) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'الكاميرا غير مدعومة في المتصفح. يرجى اختيار صورة من الجهاز.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (!kIsWeb) {
        final granted = fromCamera
            ? await PermissionsHelper.requestCameraPermission()
            : await PermissionsHelper.requestMediaPermissionWithFallback();

        if (!mounted) return;

        if (!granted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(fromCamera
                  ? 'تم رفض صلاحية الكاميرا'
                  : 'تم رفض صلاحية الوصول للصور'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      final ImagePicker picker = ImagePicker();
      final XFile? image = fromCamera
          ? await picker.pickImage(
              source: ImageSource.camera,
              maxWidth: 1920,
              maxHeight: 1920,
              imageQuality: 85,
            )
          : await picker.pickImage(
              source: ImageSource.gallery,
              maxWidth: 1920,
              maxHeight: 1920,
              imageQuality: 85,
            );

      if (image != null && mounted) {
        final bytes = await image.readAsBytes();
        final compressed = _compressImage(bytes);
        setState(() {
          _selectedImages.add(compressed);
          _hasUnsavedChanges = true;
        });
        _saveDebounced();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إضافة الصورة بنجاح'),
              backgroundColor: Color(0xFF00D1B2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('خطأ في ${fromCamera ? "التقاط" : "اختيار"} الصورة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'اختر مصدر الصورة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            if (kIsWeb)
              // Web only shows gallery option
              _imageSourceButton(
                icon: Icons.photo_library,
                label: 'اختر من الجهاز',
                onTap: () {
                  Navigator.pop(context);
                  _pickImages();
                },
              )
            else
              // Mobile shows both options
              Row(
                children: [
                  Expanded(
                    child: _imageSourceButton(
                      icon: Icons.photo_library,
                      label: 'المعرض',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImages();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _imageSourceButton(
                      icon: Icons.camera_alt,
                      label: 'الكاميرا',
                      onTap: () {
                        Navigator.pop(context);
                        _pickSingleImage(fromCamera: true);
                      },
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _imageSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: const Color(0xFFFF3A44)),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      _hasUnsavedChanges = true;
    });
    _saveDebounced();
  }

  Future<void> _showPermissionDiagnostic() async {
    try {
      final diagnostic =
          await PermissionsHelper.diagnoseMediaPermissionIssues();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFFFF3A44)),
              SizedBox(width: 8),
              Text('تشخيص الصلاحيات'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  diagnostic,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final navigator = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);
                          navigator.pop();
                          final fixed =
                              await PermissionsHelper.attemptPermissionFix();
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(fixed
                                    ? 'تم إصلاح الصلاحيات بنجاح!'
                                    : 'لم يتم إصلاح الصلاحيات. يرجى المحاولة يدوياً.'),
                                backgroundColor: fixed
                                    ? const Color(0xFF00D1B2)
                                    : Colors.orange,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.build),
                        label: const Text('محاولة الإصلاح'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00D1B2),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await openAppSettings();
              },
              child: const Text('الإعدادات'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في التشخيص: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleAmenity(String amenity) {
    setState(() {
      if (_selectedAmenities.contains(amenity)) {
        _selectedAmenities.remove(amenity);
      } else {
        _selectedAmenities.add(amenity);
      }
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedLat == null || _pickedLng == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء تحديد موقع العقار')),
      );
      return;
    }
    if (_selectedImages.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إضافة صورة واحدة على الأقل')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final propertyProvider =
          Provider.of<PropertyProvider>(context, listen: false);
      final propertyService = PropertyService();

      final property = PropertyModel(
        id: '',
        hostId: authProvider.currentUser!.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        propertyType: _selectedPropertyType,
        pricePerNight: _parsePrice(_pricePerNightController.text),
        pricePerMonth: _parsePrice(_pricePerMonthController.text),
        address: _addressController.text.trim(),
        region: _selectedRegion ?? '',
        city: _cityController.text.trim(),
        area: _areaController.text.trim(),
        latitude: _pickedLat!,
        longitude: _pickedLng!,
        bedrooms: int.parse(_bedroomsController.text),
        bathrooms: int.parse(_bathroomsController.text),
        maxGuests: int.parse(_maxGuestsController.text),
        amenities: _selectedAmenities,
        photos: [],
        isAvailable: true,
        isVerified: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        additionalInfo: {
          'experiences': _selectedExperiences,
          'region': _selectedRegion,
        },
      );

      final created = await propertyProvider.addPropertyAndGet(property);
      if (created == null) {
        throw Exception(
            'فشل إنشاء العقار - لم يتم إرجاع العقار من قاعدة البيانات');
      }

      _uploadCompleted = 0;
      _uploadTotal = _selectedImages.length;
      setState(() {});

      final urls =
          await PropertyService().uploadMultiplePropertyPhotosBytesConcurrent(
        propertyId: created.id,
        files: _selectedImages,
        concurrency: 3,
        maxRetries: 2,
        signedUrl: false,
        onProgress: (completed, total) {
          if (mounted) {
            setState(() {
              _uploadCompleted = completed;
              _uploadTotal = total;
            });
          }
        },
      );

      if (urls.isNotEmpty) {
        await propertyService.addPhotosToProperty(created.id, urls);
      }

      await _clearDraft();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('تم إضافة العقار بنجاح'),
            backgroundColor: Color(0xFF00D1B2)),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Uint8List _compressImage(Uint8List inputBytes) {
    try {
      final decoded = img.decodeImage(inputBytes);
      if (decoded == null) return inputBytes;
      final resized =
          decoded.width > 1600 ? img.copyResize(decoded, width: 1600) : decoded;
      final encoded = img.encodeJpg(resized, quality: 80);
      return Uint8List.fromList(encoded);
    } catch (_) {
      return inputBytes;
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFF3A44); // Airbnb Red

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (!_hasUnsavedChanges) {
          Navigator.of(context).maybePop();
          return;
        }
        final shouldLeave = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('هل تريد مغادرة الصفحة؟'),
            content: const Text('سيتم فقدان التغييرات غير المحفوظة.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('إلغاء')),
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('مغادرة')),
            ],
          ),
        );
        if (shouldLeave == true && mounted) {
          final navigator = Navigator.of(context);
          setState(() => _hasUnsavedChanges = false);
          navigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppAppBar(title: AppStrings.getString('addProperty', context)),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (_isLoading && _uploadTotal > 0) ...[
                  LinearProgressIndicator(
                    value: _uploadTotal == 0
                        ? null
                        : (_uploadCompleted / _uploadTotal).clamp(0, 1),
                  ),
                  const SizedBox(height: 8),
                  Text('رفع الصور: $_uploadCompleted/$_uploadTotal'),
                  const SizedBox(height: 16),
                ],
                _stepProgress(),
                const SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: KeyedSubtree(
                    key: ValueKey(_currentStep),
                    child: Column(
                      children: [
                        if (_currentStep == 0) _buildBasicInfo(),
                        if (_currentStep == 1) _buildLocationInfo(),
                        if (_currentStep == 2) _buildMediaAndFeatures(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey[200]!)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.1 * 255).round()),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          if (_currentStep == 0) {
                            _saveDraft();
                          } else {
                            setState(() =>
                                _currentStep = (_currentStep - 1).clamp(0, 2));
                          }
                        },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _currentStep == 0 ? 'حفظ كمسودة' : 'السابق',
                    style: const TextStyle(color: primaryColor),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          if (_currentStep < 2) {
                            setState(() =>
                                _currentStep = (_currentStep + 1).clamp(0, 2));
                          } else {
                            _submitForm();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _currentStep < 2 ? 'التالي' : 'إضافة العقار',
                          style: const TextStyle(color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepProgress() {
    const steps = ['الأساسيات', 'الموقع', 'الصور والمزايا'];
    const icons = [
      Icons.info_rounded,
      Icons.place_outlined,
      Icons.photo_library_outlined
    ];
    return Row(
      children: List.generate(3, (i) {
        final reached = _currentStep >= i;
        final done = _currentStep > i;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color:
                          reached ? const Color(0xFFFF3A44) : Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      done ? Icons.check : icons[i],
                      size: 18,
                      color: reached ? Colors.white : Colors.grey[600],
                    ),
                  ),
                  if (i < 2) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: _currentStep > i
                              ? const Color(0xFFFF3A44)
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Text(
                steps[i],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: reached ? FontWeight.bold : FontWeight.normal,
                  color: reached ? const Color(0xFFFF3A44) : Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildBasicInfo() {
    return _buildSection(
      title: 'المعلومات الأساسية',
      children: [
        CustomTextField(
          controller: _titleController,
          labelText: 'عنوان العقار',
          hintText: 'أدخل عنوان العقار',
          validator: (v) => v?.isEmpty == true ? 'مطلوب' : null,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _descriptionController,
          labelText: 'وصف العقار',
          hintText: 'أدخل وصفًا دقيقًا',
          maxLines: 4,
          validator: (v) => v?.isEmpty == true ? 'مطلوب' : null,
        ),
        const SizedBox(height: 16),
        const Text('نوع العقار', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _typeGroups.values.expand((e) => e).map((t) {
            final selected = _selectedPropertyType == t;
            return _pillChip(
              label: _typeLabel(context, t),
              selected: selected,
              onTap: () {
                setState(() => _selectedPropertyType = t);
                _hasUnsavedChanges = true;
                _saveDebounced();
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: _numberCounter(
                    label: 'غرف النوم',
                    controller: _bedroomsController,
                    min: 0,
                    max: 20)),
            const SizedBox(width: 8),
            Expanded(
                child: _numberCounter(
                    label: 'الحمّامات',
                    controller: _bathroomsController,
                    min: 0,
                    max: 20)),
            const SizedBox(width: 8),
            Expanded(
                child: _numberCounter(
                    label: 'الضيوف',
                    controller: _maxGuestsController,
                    min: 1,
                    max: 30)),
          ],
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _pricePerNightController,
          labelText: 'السعر لليلة (MAD)',
          hintText: 'أدخل السعر',
          keyboardType: TextInputType.number,
          validator: (v) => v?.isEmpty == true ? 'مطلوب' : null,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _pricePerMonthController,
          labelText: 'السعر للشهر (MAD)',
          hintText: 'اختياري',
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildLocationInfo() {
    return _buildSection(
      title: 'الموقع',
      children: [
        CustomTextField(
          controller: _addressController,
          labelText: 'العنوان التفصيلي',
          hintText: 'شارع، رقم، مبنى...',
          validator: (v) => v?.isEmpty == true ? 'مطلوب' : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedRegion,
          decoration: InputDecoration(
            labelText: 'الجهة',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: MoroccoRegionsCities.regions.map((r) {
            final isFr =
                Provider.of<LanguageProvider>(context, listen: false).isFrench;
            return DropdownMenuItem(
                value: r,
                child:
                    Text(MoroccoRegionsCities.displayRegion(r, french: isFr)));
          }).toList(),
          onChanged: (v) {
            setState(() {
              _selectedRegion = v;
              _selectedCity = null;
              _cityController.text = '';
              _hasUnsavedChanges = true;
            });
            _saveDebounced();
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedCity,
          decoration: InputDecoration(
            labelText: 'المدينة',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: MoroccoRegionsCities.citiesFor(_selectedRegion).map((c) {
            final isFr =
                Provider.of<LanguageProvider>(context, listen: false).isFrench;
            return DropdownMenuItem(
                value: c,
                child: Text(MoroccoRegionsCities.displayCity(c, french: isFr)));
          }).toList(),
          onChanged: (v) {
            setState(() {
              _selectedCity = v;
              _cityController.text = v ?? '';
              _hasUnsavedChanges = true;
            });
            _saveDebounced();
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _areaController,
          labelText: 'المنطقة',
          hintText: 'اسم الحي أو المنطقة',
          validator: (v) => v?.isEmpty == true ? 'مطلوب' : null,
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () async {
            final LatLng? result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PickLocationScreen()),
            );
            if (result != null) {
              setState(() {
                _pickedLat = result.latitude;
                _pickedLng = result.longitude;
                _hasUnsavedChanges = true;
              });
              _saveDebounced();
            }
          },
          icon: const Icon(Icons.place),
          label: Text(_pickedLat == null
              ? 'حدد الموقع على الخريطة'
              : 'تم تحديد الموقع'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[100],
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaAndFeatures() {
    return Column(
      children: [
        _buildSection(
          title: 'المزايا',
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _availableAmenities.map((amenity) {
                final selected = _selectedAmenities.contains(amenity);
                return _pillChip(
                  label: AppStrings.getString(amenity, context),
                  selected: selected,
                  onTap: () {
                    _toggleAmenity(amenity);
                    _hasUnsavedChanges = true;
                    _saveDebounced();
                  },
                );
              }).toList(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSection(
          title: 'تجارب مغربية',
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _experiencesOptions.map((opt) {
                final code = opt['code']!;
                final labelKey = opt['labelKey']!;
                final selected = _selectedExperiences.contains(code);
                return _pillChip(
                  label: AppStrings.getString(labelKey, context),
                  selected: selected,
                  onTap: () {
                    setState(() {
                      if (selected) {
                        _selectedExperiences.remove(code);
                      } else {
                        _selectedExperiences.add(code);
                      }
                      _hasUnsavedChanges = true;
                    });
                    _saveDebounced();
                  },
                );
              }).toList(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSection(
          title: 'الصور',
          children: [
            if (_selectedImages.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          _selectedImages[index],
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showImagePickerOptions,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('أضف صورة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[100],
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSection(
      {required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3A44),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _numberCounter(
      {required String label,
      required TextEditingController controller,
      required int min,
      required int max}) {
    int current() =>
        int.tryParse(controller.text.trim())?.clamp(min, max) ?? min;
    void setVal(int v) {
      final nv = v.clamp(min, max);
      controller.text = nv.toString();
      _hasUnsavedChanges = true;
      _saveDebounced();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border:
                Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                onPressed: current() > min ? () => setVal(current() - 1) : null,
                icon: const Icon(Icons.remove, size: 18),
                padding: const EdgeInsets.all(6),
              ),
              Expanded(
                child: Center(
                  child: Text(current().toString(),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              IconButton(
                onPressed: current() < max ? () => setVal(current() + 1) : null,
                icon: const Icon(Icons.add, size: 18),
                padding: const EdgeInsets.all(6),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pillChip(
      {required String label,
      required bool selected,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFF3A44) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? const Color(0xFFFF3A44) : Colors.grey[300]!),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black,
            fontSize: 14,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
