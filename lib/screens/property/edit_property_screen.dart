import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:godarna/mixins/realtime_mixin.dart';
import 'package:godarna/providers/property_provider.dart';
import 'package:godarna/constants/app_strings.dart';
import 'package:godarna/models/property_model.dart';
import 'package:godarna/widgets/common/app_app_bar.dart';

class EditPropertyScreen extends StatefulWidget {
  final PropertyModel property;

  const EditPropertyScreen({
    super.key,
    required this.property,
  });

  @override
  State<EditPropertyScreen> createState() => _EditPropertyScreenState();
}

class _EditPropertyScreenState extends State<EditPropertyScreen> with RealtimeMixin {
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
  List<String> _selectedAmenities = [];
  bool _isLoading = false;

  final List<String> _availableAmenities = [
    'مكيف هواء',
    'تدفئة',
    'مطبخ',
    'غسالة',
    'واي فاي',
    'تلفاز',
    'موقف سيارات',
    'حديقة',
    'بركة سباحة',
    'مصعد',
  ];

  late final Color primaryColor = const Color(0xFFFF3A44); // Airbnb Red

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupRealtimeSubscriptions();
    });
  }

  void _setupRealtimeSubscriptions() {
    // اشتراك في تحديثات العقار المحدد
    subscribeToTable(
      table: 'properties',
      filter: 'id',
      filterValue: widget.property.id,
      onInsert: (payload) {
        if (mounted) {
          // تحديث بيانات العقار
          final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
          propertyProvider.fetchProperties(forceRefresh: true);
        }
      },
      onUpdate: (payload) {
        if (mounted) {
          final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
          propertyProvider.fetchProperties(forceRefresh: true);
        }
      },
      onDelete: (payload) {
        if (mounted) {
          // العقار تم حذفه - العودة للقائمة
          Navigator.of(context).pop();
        }
      },
    );
  }

  void _initializeControllers() {
    _titleController.text = widget.property.title;
    _descriptionController.text = widget.property.description;
    _addressController.text = widget.property.address;
    _cityController.text = widget.property.city;
    _areaController.text = widget.property.area;
    _pricePerNightController.text = widget.property.pricePerNight.toString();
    _pricePerMonthController.text = widget.property.pricePerMonth.toString();
    _bedroomsController.text = widget.property.bedrooms.toString();
    _bathroomsController.text = widget.property.bathrooms.toString();
    _maxGuestsController.text = widget.property.maxGuests.toString();
    _selectedPropertyType = widget.property.propertyType;
    _selectedAmenities = List.from(widget.property.amenities);
  }

  @override
  void dispose() {
    unsubscribeAll();
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


  Future<void> _updateProperty() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final propertyProvider =
          Provider.of<PropertyProvider>(context, listen: false);

      final updatedProperty = widget.property.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        propertyType: _selectedPropertyType,
        pricePerNight: double.parse(_pricePerNightController.text),
        pricePerMonth: double.parse(_pricePerMonthController.text),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        area: _areaController.text.trim(),
        bedrooms: int.parse(_bedroomsController.text),
        bathrooms: int.parse(_bathroomsController.text),
        maxGuests: int.parse(_maxGuestsController.text),
        amenities: _selectedAmenities,
        updatedAt: DateTime.now(),
      );

      final success = await propertyProvider.updateProperty(updatedProperty);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث العقار بنجاح'),
            backgroundColor: Color(0xFF00D1B2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("حدث خطأ: $e"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppAppBar(title: AppStrings.getString('editProperty', context)),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
          child: Column(
            children: [
              // === 1. Basic Information ===
              _buildSection(
                title: 'المعلومات الأساسية',
                children: [
                  _buildTextField(
                    controller: _titleController,
                    label: 'اسم العقار',
                    hint: 'مثلاً: شقة أنيقة في الدار البيضاء',
                    validator: (v) =>
                        v?.isEmpty == true ? 'هذا الحقل مطلوب' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'الوصف',
                    hint: 'اكتب وصفًا جذابًا للعقار...',
                    maxLines: 4,
                    validator: (v) => v?.isEmpty == true ? 'الوصف مطلوب' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    value: _selectedPropertyType,
                    label: 'نوع العقار',
                    items: const [
                      ('apartment', 'شقة'),
                      ('villa', 'فيلا'),
                      ('riad', 'riad'),
                      ('studio', 'ستوديو'),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedPropertyType = value;
                        });
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // === 2. Location ===
              _buildSection(
                title: 'الموقع',
                children: [
                  _buildTextField(
                    controller: _addressController,
                    label: 'العنوان التفصيلي',
                    hint: 'شارع، رقم المبنى، مدخل...',
                    validator: (v) => v?.isEmpty == true ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _cityController,
                          label: 'المدينة',
                          hint: 'الدار البيضاء',
                          validator: (v) => v?.isEmpty == true ? 'مطلوب' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _areaController,
                          label: 'المنطقة',
                          hint: 'حي الحسن الثاني',
                          validator: (v) => v?.isEmpty == true ? 'مطلوب' : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // === 3. Property Details ===
              _buildSection(
                title: 'تفاصيل العقار',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildNumberField(
                          controller: _bedroomsController,
                          label: 'غرف النوم',
                          hint: '0',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildNumberField(
                          controller: _bathroomsController,
                          label: 'الحمامات',
                          hint: '0',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildNumberField(
                    controller: _maxGuestsController,
                    label: 'الحد الأقصى للضيوف',
                    hint: '1',
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // === 4. Pricing ===
              _buildSection(
                title: 'التسعير',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildNumberField(
                          controller: _pricePerNightController,
                          label: 'السعر لليلة (درهم)',
                          hint: '0',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildNumberField(
                          controller: _pricePerMonthController,
                          label: 'السعر للشهر (درهم)',
                          hint: '0',
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // === 5. Amenities ===
              _buildSection(
                title: 'المرافق',
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableAmenities.map((amenity) {
                      final isSelected = _selectedAmenities.contains(amenity);
                      return FilterChip(
                        label:
                            Text(amenity, style: const TextStyle(fontSize: 14)),
                        selected: isSelected,
                        selectedColor: primaryColor.withAlpha((0.15 * 255).round()),
                        backgroundColor: Colors.white,
                        checkmarkColor: primaryColor,
                        labelStyle: TextStyle(
                          color: isSelected ? primaryColor : Colors.grey[700],
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color:
                                isSelected ? primaryColor : Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedAmenities.add(amenity);
                            } else {
                              _selectedAmenities.remove(amenity);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),

      // === 6. Floating Save Button ===
      bottomNavigationBar: Container(
        height: 80,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.1 * 255).round()),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _updateProperty,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  'تحديث العقار',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }

  Widget _buildSection(
      {required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int? maxLines,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines ?? 1,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return _buildTextField(
      controller: controller,
      label: label,
      hint: hint,
      validator: (v) {
        if (v?.isEmpty == true) return 'مطلوب';
        if (double.tryParse(v ?? '') == null) return 'أدخل رقمًا صحيحًا';
        return null;
      },
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String label,
    required List<(String value, String label)> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            isDense: true,
          ),
          items: items.map<DropdownMenuItem<String>>((item) {
            return DropdownMenuItem<String>(
              value: item.$1,
              child: Text(item.$2),
            );
          }).toList(),
          onChanged: onChanged,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
        ),
      ],
    );
  }
}
