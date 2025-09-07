import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:godarna/utils/permissions.dart';
import 'package:godarna/widgets/permission_rationale.dart';
import 'package:godarna/constants/app_strings.dart';
import 'package:godarna/theme/app_dimensions.dart';
import 'package:godarna/widgets/common/app_app_bar.dart';
import 'package:godarna/widgets/common/app_button.dart';

class PickLocationScreen extends StatefulWidget {
  const PickLocationScreen({super.key});

  @override
  State<PickLocationScreen> createState() => _PickLocationScreenState();
}

class _PickLocationScreenState extends State<PickLocationScreen> {
  GoogleMapController? _mapController;
  LatLng? _selected;
  bool _locationGranted = false;

  // مركز المغرب وحدوده
  static const LatLng _centerMA = LatLng(31.7917, -7.0926);
  static const LatLng _maSouthWest = LatLng(20.0, -17.5);
  static const LatLng _maNorthEast = LatLng(36.5, -0.5);
  static final LatLngBounds _moroccoBounds = LatLngBounds(
    southwest: _maSouthWest,
    northeast: _maNorthEast,
  );

  // أنماط الخريطة
  static const String _mapStyleLight =
      '[{"elementType":"geometry","stylers":[{"color":"#f5f5f5"}]}, {"elementType":"labels.icon","stylers":[{"visibility":"off"}]}, {"elementType":"labels.text.fill","stylers":[{"color":"#616161"}]}, {"elementType":"labels.text.stroke","stylers":[{"color":"#f5f5f5"}]}, {"featureType":"administrative.land_parcel","elementType":"labels.text.fill","stylers":[{"color":"#bdbdbd"}]}, {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#eeeeee"}]}, {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]}, {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#e5e5e5"}]}, {"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#9e9e9e"}]}, {"featureType":"road","elementType":"geometry","stylers":[{"color":"#ffffff"}]}, {"featureType":"road.arterial","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]}, {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#dadada"}]}, {"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#616161"}]}, {"featureType":"road.local","elementType":"labels.text.fill","stylers":[{"color":"#9e9e9e"}]}, {"featureType":"transit.line","elementType":"geometry","stylers":[{"color":"#e5e5e5"}]}, {"featureType":"water","elementType":"geometry","stylers":[{"color":"#c9d7f0"}]}, {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#9e9e9e"}]}]';
  static const String _mapStyleDark =
      '[{"elementType":"geometry","stylers":[{"color":"#1f1f1f"}]}, {"elementType":"labels.icon","stylers":[{"visibility":"off"}]}, {"elementType":"labels.text.fill","stylers":[{"color":"#9aa0a6"}]}, {"elementType":"labels.text.stroke","stylers":[{"color":"#1f1f1f"}]}, {"featureType":"administrative","elementType":"geometry.stroke","stylers":[{"color":"#2f2f2f"}]}, {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#2a2a2a"}]}, {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#263238"}]}, {"featureType":"road","elementType":"geometry","stylers":[{"color":"#2c2c2c"}]}, {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#303134"}]}, {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#3c4043"}]}, {"featureType":"transit","elementType":"geometry","stylers":[{"color":"#2f2f2f"}]}, {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0e2433"}]}]';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestLocationPermission();
    });
  }

  Future<void> _requestLocationPermission() async {
    if (_locationGranted) return;

    final proceed = await showPermissionRationale(
      context,
      title: PermissionRationaleTexts.locationTitle(context),
      message: PermissionRationaleTexts.locationBody(context),
    );
    final granted =
        proceed ? await PermissionsHelper.requestLocationPermission() : false;
    if (mounted) {
      setState(() {
        _locationGranted = granted;
      });
    }
  }

  String? get _currentMapStyle {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? _mapStyleDark : _mapStyleLight;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: AppStrings.getString('pickLocationOnMap', context),
        actions: [
          AppButton(
            text: AppStrings.getString('confirm', context),
            onPressed: _selected == null
                ? null
                : () {
                    Navigator.pop(context, _selected);
                  },
            type: AppButtonType.text,
            size: AppButtonSize.medium,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _centerMA,
              zoom: 5.8,
            ),
            style: _currentMapStyle,
            myLocationEnabled: _locationGranted,
            myLocationButtonEnabled: _locationGranted,
            zoomControlsEnabled: true,
            liteModeEnabled: false,
            cameraTargetBounds: CameraTargetBounds(_moroccoBounds),
            minMaxZoomPreference: const MinMaxZoomPreference(5.5, 20),
            markers: {
              if (_selected != null)
                Marker(
                  markerId: const MarkerId('picked'),
                  position: _selected!,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueRed),
                )
            },
            onMapCreated: (controller) {
              _mapController = controller;
            },
            onTap: (latLng) {
              setState(() {
                _selected = latLng;
              });
            },
          ),

          // ✅ مؤشر في وسط الخريطة (لإظهار أين سيتم تحديد الموقع)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on,
                  color: Theme.of(context).colorScheme.primary,
                  size: 40,
                ),
                const SizedBox(height: 2),
                Container(
                  width: 40,
                  height: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),

          // ✅ تلميح للمستخدم
          if (_selected == null)
            const SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'انقر على الخريطة لتحديد الموقع',
                  style: TextStyle(
                    backgroundColor: Colors.black54,
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _selected == null
          ? null
          : SafeArea(
              bottom: true,
              child: Padding(
                padding: AppDimensions.paddingAll12,
                child: AppButton(
                  text:
                      '${AppStrings.getString('confirmCoordinates', context)} (${_selected!.latitude.toStringAsFixed(5)}, ${_selected!.longitude.toStringAsFixed(5)})',
                  onPressed: () => Navigator.pop(context, _selected),
                  type: AppButtonType.primary,
                  size: AppButtonSize.large,
                  icon: Icons.check,
                  width: double.infinity,
                ),
              ),
            ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // تم نقل تطبيق نمط الخريطة إلى خاصية style في GoogleMap
    setState(() {}); // إعادة بناء الواجهة لتطبيق النمط الجديد
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
