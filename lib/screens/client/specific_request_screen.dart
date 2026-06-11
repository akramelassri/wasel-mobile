import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:wasel/api/delivery_service.dart';
import 'package:wasel/api/tracking_service.dart';
import 'package:wasel/main.dart';
import 'package:wasel/themes/colors.dart';
import 'package:wasel/themes/text_styles.dart';

// ── status helpers ─────────────────────────────────────────────────

const _terminalStatuses = {
  'DELIVERED',
  'CANCELLED_BY_CLIENT',
  'CANCELLED_BY_DRIVER',
  'CANCELLED_BY_ADMIN',
  'PROBLEM_REPORTED',
};

const _cancellableStatuses = {'CREATED', 'WAITING_DRIVER', 'ASSIGNED'};

const _activeStatuses = {
  'ACCEPTED',
  'ARRIVED_AT_PICKUP',
  'PICKED_UP',
  'IN_TRANSIT',
  'ARRIVED_AT_DROPOFF',
};

String _labelFor(String status) {
  return switch (status) {
    'CREATED' => 'Created',
    'WAITING_DRIVER' => 'Looking for a driver',
    'ASSIGNED' => 'Driver assigned',
    'ACCEPTED' => 'Driver accepted',
    'ARRIVED_AT_PICKUP' => 'Driver at pickup',
    'PICKED_UP' => 'Parcel picked up',
    'IN_TRANSIT' => 'On the way',
    'ARRIVED_AT_DROPOFF' => 'Driver at dropoff',
    'DELIVERED' => 'Delivered',
    'CANCELLED_BY_CLIENT' => 'Cancelled by you',
    'CANCELLED_BY_DRIVER' => 'Cancelled by driver',
    'CANCELLED_BY_ADMIN' => 'Cancelled by admin',
    'PROBLEM_REPORTED' => 'Problem reported',
    _ => status,
  };
}

Color _colorFor(String status) {
  if (_terminalStatuses.contains(status)) {
    return status == 'DELIVERED' ? Colors.green : Colors.red;
  }
  if (_activeStatuses.contains(status)) return primaryColor;
  return Colors.black38;
}

const _timelineStatuses = [
  'WAITING_DRIVER',
  'ASSIGNED',
  'ACCEPTED',
  'ARRIVED_AT_PICKUP',
  'PICKED_UP',
  'IN_TRANSIT',
  'ARRIVED_AT_DROPOFF',
  'DELIVERED',
];

// ── screen ─────────────────────────────────────────────────────────

class SpecificRequestScreen extends StatefulWidget {
  final String deliveryId;

  const SpecificRequestScreen({super.key, required this.deliveryId});

  @override
  State<SpecificRequestScreen> createState() => _SpecificRequestScreenState();
}

class _SpecificRequestScreenState extends State<SpecificRequestScreen> {
  final MapController _mapController = MapController();

  Map<String, dynamic>? _delivery;
  LatLng? _pickupLatLng;
  LatLng? _dropoffLatLng;
  LatLng? _driverLatLng;

  bool _loading = true;
  bool _cancelling = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _fetchDelivery();
      await _fetchDriverLocation();
      _startPolling();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final status = _delivery?['deliveryStatus'] as String?;
      if (status != null && _terminalStatuses.contains(status)) {
        _timer?.cancel();
        return;
      }
      await _fetchDelivery();

      if (_delivery?['assignedDriver'] != null) {
        await _fetchDriverLocation();
      }
    });
  }

  Future<void> _fetchDelivery() async {
    final authService = InheritedAuth.of(context).authService;
    final result = await DeliveryService.getDelivery(
      authService: authService,
      id: widget.deliveryId,
    );

    if (!mounted) return;

    if (result.isSuccess && result.data != null) {
      setState(() {
        _delivery = result.data;
        _loading = false;

        final pickup = _delivery!['pickupAddress'] as Map<String, dynamic>?;
        if (pickup != null && pickup['latitude'] != null) {
          _pickupLatLng = LatLng(
            (pickup['latitude'] as num).toDouble(),
            (pickup['longitude'] as num).toDouble(),
          );
        }

        final dropoff = _delivery!['deliveryAddress'] as Map<String, dynamic>?;
        if (dropoff != null && dropoff['latitude'] != null) {
          _dropoffLatLng = LatLng(
            (dropoff['latitude'] as num).toDouble(),
            (dropoff['longitude'] as num).toDouble(),
          );
        }
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchDriverLocation() async {
    final authService = InheritedAuth.of(context).authService;
    final result = await TrackingService.getDeliveryLastPosition(
      authService: authService,
      deliveryId: widget.deliveryId,
    );

    if (mounted && result.isSuccess && result.position != null) {
      setState(() => _driverLatLng = result.position);
    }
  }

  void _recenterMap() {
    final target =
        _driverLatLng ?? _pickupLatLng ?? const LatLng(33.5731, -7.5898);
    _mapController.move(target, 15);
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel delivery'),
        content: const Text('Are you sure you want to cancel this delivery?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'No',
              style: bolderLabelText.copyWith(color: Colors.black54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Yes, cancel',
              style: bolderLabelText.copyWith(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _cancelling = true);
    final authService = InheritedAuth.of(context).authService;
    final result = await DeliveryService.cancelDelivery(
      authService: authService,
      id: widget.deliveryId,
    );

    if (!mounted) return;
    setState(() => _cancelling = false);

    if (result.isSuccess) {
      await _fetchDelivery();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not cancel delivery. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: backgroundColor,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_delivery == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(backgroundColor: backgroundColor, elevation: 0),
        body: Center(child: Text('Could not load delivery', style: bodyText)),
      );
    }

    final status = _delivery!['deliveryStatus'] as String? ?? 'CREATED';
    final isTerminal = _terminalStatuses.contains(status);
    final canCancel = _cancellableStatuses.contains(status);
    final hasDriver = _delivery!['assignedDriver'] != null;
    final payment = _delivery!['payment'] as Map<String, dynamic>?;

    final mapCenter =
        _driverLatLng ?? _pickupLatLng ?? const LatLng(33.5731, -7.5898);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // ── map ────────────────────────────────────────────────
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.48,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(initialCenter: mapCenter, initialZoom: 14),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.wasel',
                ),
                MarkerLayer(
                  markers: [
                    if (_pickupLatLng != null)
                      Marker(
                        point: _pickupLatLng!,
                        child: const Icon(
                          Icons.circle,
                          color: primaryColor,
                          size: 16,
                        ),
                      ),
                    if (_dropoffLatLng != null)
                      Marker(
                        point: _dropoffLatLng!,
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: Colors.red,
                          size: 32,
                        ),
                      ),
                    if (_driverLatLng != null)
                      Marker(
                        point: _driverLatLng!,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.directions_car_rounded,
                            color: secondaryColor,
                            size: 24,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // ── back button ────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: secondaryColor),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // ── recenter button ────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(
                  Icons.my_location_rounded,
                  color: secondaryColor,
                ),
                onPressed: _recenterMap,
              ),
            ),
          ),

          // ── bottom sheet ───────────────────────────────────────
          DraggableScrollableSheet(
            initialChildSize: 0.58,
            minChildSize: 0.58,
            maxChildSize: 0.92,
            snap: true,
            snapSizes: const [0.58, 0.92],
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 15,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    // drag handle
                    Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 14),
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),

                    // ── status header ───────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _labelFor(status),
                            style: headingText.copyWith(
                              color: _colorFor(status),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (!isTerminal)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'In Progress',
                              style: captionText.copyWith(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── driver card ─────────────────────────────
                    if (hasDriver) ...[
                      _DriverCard(driver: _delivery!['assignedDriver']),
                      const SizedBox(height: 24),
                    ] else if (!isTerminal) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'Looking for a nearby driver...',
                                style: bodyText.copyWith(color: Colors.black54),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ── addresses ───────────────────────────────
                    _AddressRow(
                      icon: Icons.circle,
                      iconColor: primaryColor,
                      label: _delivery?['pickupAddress']?['street'] ?? '--',
                      sublabel: _delivery?['pickupAddress']?['city'] ?? '',
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: SizedBox(
                        height: 24,
                        child: VerticalDivider(width: 2, color: Colors.black12),
                      ),
                    ),
                    _AddressRow(
                      icon: Icons.location_on_rounded,
                      iconColor: Colors.red,
                      label: _delivery?['deliveryAddress']?['street'] ?? '--',
                      sublabel: _delivery?['deliveryAddress']?['city'] ?? '',
                    ),
                    const SizedBox(height: 24),

                    Divider(color: Colors.grey.shade200),
                    const SizedBox(height: 20),

                    // ── timeline ────────────────────────────────
                    Text('Tracking Status', style: subHeadingText),
                    const SizedBox(height: 20),
                    _StatusTimeline(
                      currentStatus: status,
                      statusHistory:
                          _delivery!['statusHistory'] as List<dynamic>? ?? [],
                    ),

                    const SizedBox(height: 20),
                    Divider(color: Colors.grey.shade200),
                    const SizedBox(height: 16),

                    // ── price ────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Price', style: labelText),
                        Text(
                          '${((payment?['amount'] as num?) ?? 0).toStringAsFixed(2)} DH',
                          style: headingText.copyWith(fontSize: 22),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // ── cancel button ────────────────────────────
                    if (canCancel)
                      OutlinedButton(
                        onPressed: _cancelling ? null : _cancel,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _cancelling
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.red,
                                ),
                              )
                            : Text(
                                'Cancel Delivery',
                                style: bolderLabelText.copyWith(
                                  color: Colors.red,
                                ),
                              ),
                      ),
                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── driver card ────────────────────────────────────────────────────

class _DriverCard extends StatelessWidget {
  final dynamic driver;
  const _DriverCard({required this.driver});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: surfaceVariant,
            child: const Icon(
              Icons.person_rounded,
              color: secondaryColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Driver Assigned', style: subHeadingText),
                const SizedBox(height: 4),
                Text(
                  'On the way to your location',
                  style: captionText.copyWith(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── address row ────────────────────────────────────────────────────

class _AddressRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String sublabel;

  const _AddressRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: bodyText.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (sublabel.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  sublabel,
                  style: captionText.copyWith(color: Colors.black45),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── status timeline ────────────────────────────────────────────────

class _StatusTimeline extends StatelessWidget {
  final String currentStatus;
  final List<dynamic> statusHistory;

  const _StatusTimeline({
    required this.currentStatus,
    required this.statusHistory,
  });

  @override
  Widget build(BuildContext context) {
    final currentIndex = _timelineStatuses.indexOf(currentStatus);

    return Column(
      children: List.generate(_timelineStatuses.length, (index) {
        final status = _timelineStatuses[index];
        final isDone = index <= currentIndex;
        final isCurrent = index == currentIndex;

        final historyEntry = statusHistory
            .cast<Map<String, dynamic>>()
            .where((h) => h['deliveryStatus'] == status)
            .firstOrNull;
        final timestamp = historyEntry?['changedAt'] as String?;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone ? primaryColor : Colors.grey.shade200,
                    border: isCurrent
                        ? Border.all(
                            color: primaryColor.withValues(alpha: 0.3),
                            width: 4,
                          )
                        : null,
                  ),
                  child: isDone && !isCurrent
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : (isCurrent
                            ? const Icon(
                                Icons.circle,
                                size: 8,
                                color: Colors.white,
                              )
                            : null),
                ),
                if (index < _timelineStatuses.length - 1)
                  Container(
                    width: 2,
                    height: 36,
                    color: isDone ? primaryColor : Colors.grey.shade200,
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _labelFor(status),
                      style: labelText.copyWith(
                        color: isDone ? onSurface : Colors.black38,
                        fontWeight: isCurrent
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    if (timestamp != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(timestamp),
                        style: captionText.copyWith(color: Colors.black45),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return '';
    }
  }
}
