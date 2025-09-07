import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:godarna/mixins/realtime_mixin.dart';
import 'package:godarna/models/property_model.dart';
import 'package:godarna/providers/auth_provider.dart';
import 'package:godarna/providers/booking_provider.dart';
import 'package:godarna/theme/app_dimensions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:godarna/services/notifications_service.dart';

class CreateBookingScreen extends StatefulWidget {
  final PropertyModel property;
  const CreateBookingScreen({
    super.key,
    required this.property,
  });

  @override
  State<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen>
    with TickerProviderStateMixin, RealtimeMixin {
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  int _guests = 1;
  final int _adults = 1;
  String _paymentMethod = 'cash_on_delivery';
  String _notes = '';
  bool _isLoading = false;
  final _scrollController = ScrollController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _guests = _adults;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupRealtimeSubscriptions();
    });
  }

  void _setupRealtimeSubscriptions() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;

    if (userId == null) return;

    // اشتراك في تحديثات الحجوزات الخاصة بالمستخدم
    subscribeToTable(
      table: 'bookings',
      filter: 'tenant_id',
      filterValue: userId,
      onInsert: (payload) {
        if (mounted) {
          // حجز جديد تم إضافته - تحديث المزود
          final bookingProvider =
              Provider.of<BookingProvider>(context, listen: false);
          bookingProvider.fetchBookings(forceRefresh: true);
        }
      },
      onUpdate: (payload) {
        if (mounted) {
          final bookingProvider =
              Provider.of<BookingProvider>(context, listen: false);
          bookingProvider.fetchBookings(forceRefresh: true);
        }
      },
      onDelete: (payload) {
        if (mounted) {
          final bookingProvider =
              Provider.of<BookingProvider>(context, listen: false);
          bookingProvider.fetchBookings(forceRefresh: true);
        }
      },
    );
  }

  @override
  void dispose() {
    unsubscribeAll();
    _notesController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  int get _nights {
    if (_checkInDate == null || _checkOutDate == null) return 0;
    return _checkOutDate!.difference(_checkInDate!).inDays;
  }

  double get _basePrice => _nights * widget.property.pricePerNight;
  double get _totalPrice => _basePrice;

  bool _canBook() {
    return _checkInDate != null &&
        _checkOutDate != null &&
        _nights > 0 &&
        _guests > 0 &&
        _guests <= widget.property.maxGuests;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildSliverAppBar(context, cs),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildPropertyHeroCard(context, cs),
                const SizedBox(height: 32),
                _buildBookingSteps(context, cs),
                const SizedBox(height: 120), // Space for bottom navigation bar
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildFloatingPriceCard(context, cs),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, ColorScheme cs) {
    return SliverAppBar(
      expandedHeight: 100,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0.5,
      leading: IconButton(
        onPressed: () {
          if (!kIsWeb) HapticFeedback.lightImpact();
          context.pop();
        },
        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          shape: const CircleBorder(),
          elevation: 1,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            if (!kIsWeb) HapticFeedback.lightImpact();
          },
          icon: const Icon(Icons.share_outlined, size: 20),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            shape: const CircleBorder(),
            elevation: 1,
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'طلب الحجز',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        background: Container(
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildPropertyHeroCard(BuildContext context, ColorScheme cs) {
    return Hero(
      tag: 'property-${widget.property.id}',
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  widget.property.hasPhotos
                      ? Image.network(
                          widget.property.mainPhoto!,
                          width: double.infinity,
                          height: 220,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildImagePlaceholder(cs),
                        )
                      : _buildImagePlaceholder(cs),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        widget.property.propertyTypeDisplay,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  if (widget.property.rating > 0)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star,
                                color: Color(0xFFFF385C), size: 14),
                            const SizedBox(width: 2),
                            Text(
                              widget.property.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.property.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.property.locationDisplay,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildFeatureChip(
                          cs, '${widget.property.bedrooms} غرف', Icons.bed),
                      const SizedBox(width: 8),
                      _buildFeatureChip(cs, '${widget.property.bathrooms} حمام',
                          Icons.bathtub_outlined),
                      const SizedBox(width: 8),
                      _buildFeatureChip(cs, '${widget.property.maxGuests} ضيوف',
                          Icons.people_outline),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(
                      height: 1, thickness: 1, color: Color(0xFFEBEBEB)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'السعر لليلة',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '${widget.property.pricePerNight.toStringAsFixed(0)} درهم',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureChip(ColorScheme cs, String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEBEBEB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF717171)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF222222),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder(ColorScheme cs) {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        gradient:
            LinearGradient(colors: [cs.primary.withAlpha(51), cs.surface]),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.home_outlined, color: cs.onSurface, size: 64),
          const SizedBox(height: 12),
          Text(
            'لا توجد صور متاحة',
            style: TextStyle(
                color: cs.onSurface, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingSteps(BuildContext context, ColorScheme cs) {
    return Padding(
      padding: AppDimensions.paddingHorizontal20,
      child: Column(
        children: [
          _buildDateSelectionCard(context, cs),
          const SizedBox(height: 20),
          _buildPaymentMethodCard(context, cs),
          const SizedBox(height: 20),
          _buildNotesCard(context, cs),
        ],
      ),
    );
  }

  // Helper method to get Arabic month name
  String _getMonthName(int month) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ];
    return months[month - 1];
  }

  Widget _buildDateSelectionCard(BuildContext context, ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBEBEB), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تواريخ الإقامة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFEBEBEB),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectCheckInDate(context),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: Color(0xFFEBEBEB),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'الوصول',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _checkInDate != null
                                    ? Colors.black87
                                    : Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _checkInDate != null
                                  ? '${_checkInDate!.day} ${_getMonthName(_checkInDate!.month)} ${_checkInDate!.year}'
                                  : 'أضف تاريخ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: _checkInDate != null
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: _checkInDate != null
                                    ? Colors.black87
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectCheckOutDate(context),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'المغادرة',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _checkOutDate != null
                                    ? Colors.black87
                                    : Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _checkOutDate != null
                                  ? '${_checkOutDate!.day} ${_getMonthName(_checkOutDate!.month)} ${_checkOutDate!.year}'
                                  : 'أضف تاريخ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: _checkOutDate != null
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: _checkOutDate != null
                                    ? Colors.black87
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_nights > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: AppDimensions.paddingSymmetric16x12,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [cs.primary, cs.secondary]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.nights_stay,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '$_nights ${_nights == 1 ? 'ليلة' : 'ليلة'}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${(_nights * widget.property.pricePerNight).toStringAsFixed(0)} درهم',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(BuildContext context, ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBEBEB), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'طريقة الدفع',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildPaymentOption(
              'الدفع عند الاستلام',
              'ادفع نقداً عند وصولك',
              Icons.money_off_csred_outlined,
              'cash_on_delivery',
              cs,
            ),
            const SizedBox(height: 12),
            _buildPaymentOption(
              'بطاقة ائتمان / خصم',
              'أضف بطاقة للدفع الآن',
              Icons.credit_card_outlined,
              'credit_card',
              cs,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String title, String subtitle, IconData icon,
      String value, ColorScheme cs) {
    final isSelected = _paymentMethod == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _paymentMethod = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF7F7F7) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF222222) : const Color(0xFFEBEBEB),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFF385C)
                    : const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF717171),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: const Color(0xFF222222),
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF717171),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected
                  ? const Color(0xFFFF385C)
                  : const Color(0xFFDDDDDD),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard(BuildContext context, ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBEBEB), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ملاحظات إضافية',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _notesController,
                maxLines: 4,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF222222),
                ),
                decoration: const InputDecoration(
                  hintText:
                      'أخبر المضيف إذا كان لديك أي طلبات خاصة أو أسئلة...',
                  hintStyle: TextStyle(
                    color: Color(0xFFB0B0B0),
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
                onChanged: (value) {
                  setState(() {
                    _notes = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'سيتم إرسال هذه الملاحظة إلى المضيف بعد تأكيد الحجز',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF717171),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // تحديث الويدجت لتعمل كشريط سفولي
  Widget _buildFloatingPriceCard(BuildContext context, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPriceRow(
                  '${widget.property.pricePerNight.toStringAsFixed(0)} × $_nights ليالي',
                  '${_basePrice.toStringAsFixed(0)} درهم',
                  cs,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 1, color: Color(0xFFEBEBEB)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'المجموع',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '${_totalPrice.toStringAsFixed(0)} درهم',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF222222),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canBook() ? _createBooking : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF385C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'تأكيد الحجز',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String amount, ColorScheme cs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color.fromRGBO(255, 255, 255, 0.9),
          ),
        ),
        Text(
          amount,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color.fromRGBO(255, 255, 255, 0.9),
          ),
        ),
      ],
    );
  }

  Future<void> _selectCheckInDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _checkInDate = date;
        if (_checkOutDate != null &&
            _checkOutDate!.isBefore(date.add(const Duration(days: 1)))) {
          _checkOutDate = null;
        }
      });
    }
  }

  Future<void> _selectCheckOutDate(BuildContext context) async {
    if (_checkInDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار تاريخ الوصول أولاً')),
      );
      return;
    }
    final date = await showDatePicker(
      context: context,
      initialDate: _checkInDate!.add(const Duration(days: 1)),
      firstDate: _checkInDate!.add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _checkOutDate = date);
    }
  }

  Future<void> _createBooking() async {
    if (!_canBook()) return;
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }
      final bookingData = {
        'listing_id': widget.property.id,
        'tenant_id': user.id,
        'host_id': widget.property.hostId,
        'start_date': _checkInDate!.toIso8601String(),
        'end_date': _checkOutDate!.toIso8601String(),
        'nights': _nights,
        'total_price': _totalPrice,
        'status': 'pending',
        'payment_method': _paymentMethod,
        'payment_status': 'pending',
        'notes': _notes.isNotEmpty ? _notes : null,
      };
      final result = await Supabase.instance.client
          .from('bookings')
          .insert(bookingData)
          .select()
          .single();

      // إرسال إشعار للمستخدم والمضيف
      final bookingId = result['id'].toString();
      await _sendBookingNotifications(bookingId, user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إنشاء الحجز بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );
        // الانتقال إلى تفاصيل الحجز المُنشأ حديثاً
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إنشاء الحجز: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendBookingNotifications(
      String bookingId, String tenantId) async {
    try {
      final notificationService = NotificationsService();

      // إشعار للمستخدم (المستأجر)
      await notificationService.sendNotification(
        userId: tenantId,
        title: '🎉 تم إنشاء الحجز بنجاح',
        message:
            'تم إرسال طلب حجزك لعقار ${widget.property.title} بنجاح. سيتم إشعارك عند استجابة المضيف.',
        type: 'booking_created',
        data: {
          'booking_id': bookingId,
          'property_id': widget.property.id,
          'property_title': widget.property.title,
        },
      );

      // إشعار للمضيف
      await notificationService.sendNotification(
        userId: widget.property.hostId,
        title: '📋 طلب حجز جديد',
        message:
            'تلقيت طلب حجز جديد لعقار ${widget.property.title}. يرجى مراجعة التفاصيل والرد على الطلب.',
        type: 'new_booking_request',
        data: {
          'booking_id': bookingId,
          'property_id': widget.property.id,
          'property_title': widget.property.title,
          'tenant_id': tenantId,
        },
      );
    } catch (e) {
      // لا نعرض خطأ للمستخدم لأن الحجز تم بنجاح
      // فقط نسجل الخطأ في الـ debug console
      if (kDebugMode) {
        debugPrint('Error sending booking notifications: $e');
      }
    }
  }
}
