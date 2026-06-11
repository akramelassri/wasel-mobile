import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:wasel/api/delivery_service.dart';
import 'package:wasel/api/location_service.dart';
import 'package:wasel/main.dart';
import 'package:wasel/screens/client/specific_request_screen.dart';
import 'package:wasel/themes/colors.dart';
import 'package:wasel/themes/text_styles.dart';

enum _PickMode { none, pickup, dropoff }

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  final _locationService = LocationService();
  final _mapController = MapController();

  final LatLng _initialMapCenter = const LatLng(33.5731, -7.5898);
  _PickMode _pickMode = _PickMode.none;
  bool _isReverseGeocoding = false;

  AddressResult? _pickupAddress;
  AddressResult? _dropoffAddress;

  final _weightController = TextEditingController();
  bool _isFragile = false;
  bool _isSubmitting = false;

  double? _estimatedPrice;
  double? _estimatedDistance;
  bool _estimating = false;
  Timer? _debounce;

  final _sheetController = DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _centerOnCurrentLocation(),
    );
    _weightController.addListener(_onFormChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _weightController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  void _onFormChanged() {
    final weight = double.tryParse(_weightController.text.trim());
    if (_pickupAddress != null &&
        _dropoffAddress != null &&
        weight != null &&
        weight > 0) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), _fetchEstimate);
    }
  }

  Future<void> _fetchEstimate() async {
    final weight = double.tryParse(_weightController.text.trim());
    if (weight == null || _pickupAddress == null || _dropoffAddress == null)
      return;

    setState(() => _estimating = true);

    final authService = InheritedAuth.of(context).authService;
    final result = await DeliveryService.estimateDelivery(
      authService: authService,
      pickupLat: _pickupAddress!.latitude,
      pickupLng: _pickupAddress!.longitude,
      dropoffLat: _dropoffAddress!.latitude,
      dropoffLng: _dropoffAddress!.longitude,
      weight: weight,
      isFragile: _isFragile,
    );

    if (!mounted) return;
    setState(() => _estimating = false);

    if (result.isSuccess) {
      setState(() {
        _estimatedPrice = (result.data!['estimatedPrice'] as num).toDouble();
        _estimatedDistance = (result.data!['distanceKm'] as num).toDouble();
      });
    }
  }

  Future<void> _centerOnCurrentLocation() async {
    final position = await _locationService.getCurrentPosition();
    if (position == null) return;
    _mapController.move(LatLng(position.latitude, position.longitude), 15);
  }

  Future<AddressResult?> _getCurrentLocationAddress() async {
    final position = await _locationService.getCurrentPosition();
    if (position == null) return null;
    return await _locationService.reverseGeocode(
      position.latitude,
      position.longitude,
    );
  }

  void _showAddressPicker(_PickMode mode) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              mode == _PickMode.pickup ? 'Pickup address' : 'Dropoff address',
              style: headingText,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                final addr = await _getCurrentLocationAddress();
                if (addr != null) {
                  setState(
                    () => mode == _PickMode.pickup
                        ? _pickupAddress = addr
                        : _dropoffAddress = addr,
                  );
                  _onFormChanged();
                }
              },
              icon: const Icon(Icons.my_location_rounded),
              label: const Text('Your current location'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _pickMode = mode);
                // Minimize sheet so user can see map
                _sheetController.animateTo(
                  0.15,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              },
              icon: const Icon(Icons.map_rounded),
              label: const Text('Select on map'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmMapPin() async {
    setState(() => _isReverseGeocoding = true);
    final address = await _locationService.reverseGeocode(
      _mapController.camera.center.latitude,
      _mapController.camera.center.longitude,
    );
    setState(() => _isReverseGeocoding = false);

    if (address != null) {
      setState(() {
        if (_pickMode == _PickMode.pickup) {
          _pickupAddress = address;
        } else {
          _dropoffAddress = address;
        }
        _pickMode = _PickMode.none;
      });
      _onFormChanged();
      // Snap sheet back up after selection
      _sheetController.animateTo(
        0.5,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not resolve this address on the map'),
          ),
        );
      }
    }
  }

  Future<void> _submitDelivery() async {
    // FIX 2: Added visual feedback for missing fields
    if (_pickupAddress == null || _dropoffAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set pickup and dropoff addresses'),
        ),
      );
      return;
    }

    final weightText = _weightController.text.trim();
    final weight = double.tryParse(weightText);

    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid weight in kg')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final result = await DeliveryService.createDelivery(
      authService: InheritedAuth.of(context).authService,
      pickupAddress: _pickupAddress!,
      dropoffAddress: _dropoffAddress!,
      weight: weight,
      isFragile: _isFragile,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.isSuccess) {
      setState(() {
        _pickupAddress = null;
        _dropoffAddress = null;
        _weightController.clear();
        _isFragile = false;
        _estimatedPrice = null;
        _estimatedDistance = null;
        _pickMode = _PickMode.none;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              SpecificRequestScreen(deliveryId: result.data!['deliveryId']),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not submit delivery. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialMapCenter,
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.wasel',
              ),
              MarkerLayer(
                markers: [
                  if (_pickupAddress != null)
                    Marker(
                      point: LatLng(
                        _pickupAddress!.latitude,
                        _pickupAddress!.longitude,
                      ),
                      child: const Icon(Icons.circle, color: primaryColor),
                    ),
                  if (_dropoffAddress != null)
                    Marker(
                      point: LatLng(
                        _dropoffAddress!.latitude,
                        _dropoffAddress!.longitude,
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Colors.red,
                        size: 32,
                      ),
                    ),
                ],
              ),
            ],
          ),

          // FIX 1: The visual Center Pin when user is moving the map
          if (_pickMode != _PickMode.none)
            const Align(
              alignment: Alignment.center,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: 32.0,
                ), // Shift up slightly to point at exact center
                child: Icon(
                  Icons.location_on_rounded,
                  color: secondaryColor,
                  size: 40,
                ),
              ),
            ),

          // My Location Button
          Positioned(
            right: 16,
            bottom: MediaQuery.of(context).size.height * 0.5,
            child: FloatingActionButton.small(
              onPressed: _centerOnCurrentLocation,
              backgroundColor: Colors.white,
              foregroundColor: secondaryColor,
              child: const Icon(Icons.my_location_rounded),
            ),
          ),

          if (_pickMode != _PickMode.none)
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.18,
              left: 24,
              right: 24,
              child: ElevatedButton(
                onPressed: _isReverseGeocoding ? null : _confirmMapPin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isReverseGeocoding
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _pickMode == _PickMode.pickup
                            ? 'Set pickup here'
                            : 'Set dropoff here',
                        style: bolderLabelText,
                      ),
              ),
            ),

          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.5,
            minChildSize: 0.15,
            maxChildSize: 0.92,
            snap: true,
            snapSizes: const [0.15, 0.5, 0.92],
            builder: (context, controller) => Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  // FIX 4: Drag Handle Pill
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text('New delivery', style: headingText),
                  const SizedBox(height: 20),

                  _AddressField(
                    label: 'Pickup',
                    address: _pickupAddress,
                    icon: Icons.circle,
                    iconColor: primaryColor,
                    onTap: () => _showAddressPicker(_PickMode.pickup),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: SizedBox(
                      height: 16,
                      child: VerticalDivider(width: 1, color: Colors.black26),
                    ),
                  ),
                  _AddressField(
                    label: 'Where to?',
                    address: _dropoffAddress,
                    icon: Icons.location_on_rounded,
                    iconColor: Colors.red,
                    onTap: () => _showAddressPicker(_PickMode.dropoff),
                  ),
                  const SizedBox(height: 24),
                  Divider(color: Colors.grey.shade200),
                  const SizedBox(height: 16),

                  Text('Parcel', style: subHeadingText),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Weight (kg)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      suffixText: 'kg',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: Text('Fragile', style: labelText),
                    contentPadding: EdgeInsets.zero,
                    activeColor: primaryColor,
                    value: _isFragile,
                    onChanged: (v) {
                      setState(() => _isFragile = v);
                      _onFormChanged(); // Trigger re-estimate if fragile costs more
                    },
                  ),
                  const SizedBox(height: 16),
                  Divider(color: Colors.grey.shade200),
                  const SizedBox(height: 16),

                  // FIX 3: Restored Price & Distance Display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Est. Price', style: labelText),
                          if (_estimatedDistance != null)
                            Text(
                              '${_estimatedDistance!.toStringAsFixed(1)} km',
                              style: captionText.copyWith(
                                color: Colors.black38,
                              ),
                            ),
                        ],
                      ),
                      _estimating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: secondaryColor,
                              ),
                            )
                          : Text(
                              _estimatedPrice != null
                                  ? '${_estimatedPrice!.toStringAsFixed(2)} MAD'
                                  : '-- MAD',
                              style: headingText,
                            ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitDelivery,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text('Confirm Delivery', style: bolderLabelText),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Customized visually for premium feel
class _AddressField extends StatelessWidget {
  final String label;
  final AddressResult? address;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  const _AddressField({
    required this.label,
    required this.address,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                address?.label ?? label,
                style: bodyText.copyWith(
                  color: address == null ? Colors.black38 : onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
