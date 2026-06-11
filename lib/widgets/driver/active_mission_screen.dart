import 'package:flutter/material.dart';
import 'package:wasel/api/driver_service.dart';
import 'package:wasel/main.dart';
import 'package:wasel/model/available_delivery_model.dart';
import 'package:wasel/themes/colors.dart';
import 'package:wasel/themes/text_styles.dart';
import 'package:wasel/widgets/driver/address_row.dart';
import 'package:wasel/widgets/driver/mission_step_model.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:wasel/widgets/driver/driver_map.dart';

// ─────────────────────────────────────────────────────────────────
// ÉCRAN MISSION EN COURS
// Ouvert après acceptation d'une course. Montre les étapes de la
// mission avec des boutons séquentiels (un seul visible à la fois)
// correspondant aux statuts : ACCEPTED → ARRIVED_AT_PICKUP →
// PICKED_UP → IN_TRANSIT → ARRIVED_AT_DROPOFF → DELIVERED
// ─────────────────────────────────────────────────────────────────
class ActiveMissionScreen extends StatefulWidget {
  final AvailableDelivery delivery;
  const ActiveMissionScreen({super.key, required this.delivery});

  @override
  State<ActiveMissionScreen> createState() => _ActiveMissionScreenState();
}

class _ActiveMissionScreenState extends State<ActiveMissionScreen> {
  static const _statusSequence = [
    'ACCEPTED',
    'ARRIVED_AT_PICKUP',
    'PICKED_UP',
    'IN_TRANSIT',
    'ARRIVED_AT_DROPOFF',
  ];

  late int _stepIndex;
  late String _currentStatus;
  bool _updating = false; // spinner sur le bouton pendant l'appel API

  @override
  void initState() {
    super.initState();
    print('Pickup: ${widget.delivery.pickupLatitude}, ${widget.delivery.pickupLongitude}');
  print('Dropoff: ${widget.delivery.dropoffLatitude}, ${widget.delivery.dropoffLongitude}');
    _currentStatus = widget.delivery.status;
    _stepIndex = _indexForStatus(_currentStatus);
  }

  int _indexForStatus(String status) {
    final index = _statusSequence.indexOf(status);
    return index >= 0 ? index : 0;
  }

  Future<bool> _onWillPop() async {
    Navigator.pop(context, _currentStatus);
    return false;
  }

  /// Appelle l'API backend pour mettre à jour le statut de la mission
  /// Gère les transitions d'état correctes et la synchronisation
  Future<void> _nextStep() async {
    if (_updating) return;

    // Déterminer le prochain statut
    String nextStatus;
    if (_stepIndex >= _statusSequence.length - 1) {
      nextStatus = 'DELIVERED';
    } else {
      nextStatus = _statusSequence[_stepIndex + 1];
    }

    setState(() => _updating = true);

    try {
      final authService = InheritedAuth.of(context).authService;
      final result = await DriverService.updateMissionStatus(
        authService,
        widget.delivery.id,
        nextStatus,
        note: 'Status updated from mobile app',
      );

      if (!mounted) return;

      if (!result.isSuccess) {
        setState(() => _updating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Failed to update status'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Mise à jour réussie
      setState(() {
        _currentStatus = nextStatus;
        if (_stepIndex < _statusSequence.length - 1) {
          _stepIndex++;
        }
        _updating = false;
      });

      if (nextStatus == 'DELIVERED') {
        Navigator.pop(context, nextStatus);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Delivery completed!'),
            backgroundColor: secondaryColor,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _updating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = missionSteps[_stepIndex];
    final isLast = _stepIndex == missionSteps.length - 1;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: secondaryColor),
            onPressed: () => Navigator.pop(context, _currentStatus),
          ),
          title: Text('Active Mission', style: subHeadingText),
          centerTitle: true,
        ),
        body: Stack(
  children: [
    Positioned.fill(
      child: DriverMap(
        center: LatLng(
          widget.delivery.pickupLatitude,
          widget.delivery.pickupLongitude,
        ),

        markers: [
          Marker(
            point: LatLng(
              widget.delivery.pickupLatitude,
              widget.delivery.pickupLongitude,
            ),
            width: 40,
            height: 40,
            child: const Icon(
              Icons.storefront,
              color: Colors.orange,
              size: 30,
            ),
          ),

          Marker(
            point: LatLng(
              widget.delivery.dropoffLatitude,
              widget.delivery.dropoffLongitude,
            ),
            width: 40,
            height: 40,
            child: const Icon(
              Icons.location_on,
              color: Colors.red,
              size: 34,
            ),
          ),
        ],

        polylinePoints: [
          LatLng(
            widget.delivery.pickupLatitude,
            widget.delivery.pickupLongitude,
          ),
          LatLng(
            widget.delivery.dropoffLatitude,
            widget.delivery.dropoffLongitude,
          ),
        ],
      ),
    ),

    SafeArea(
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context, _currentStatus),
            ),
          ),
        ),
      ),
    ),

    _buildBottomSheet(),
  ],
),
      ),
    );

  }
  Widget _buildBottomSheet() {
  final currentStep = missionSteps[_stepIndex];
  final isLast = _stepIndex == missionSteps.length - 1;

  return DraggableScrollableSheet(
    initialChildSize: 0.38,
    minChildSize: 0.28,
    maxChildSize: 0.85,
    builder: (context, controller) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              '${widget.delivery.price.toStringAsFixed(0)} DH',
              style: headingText.copyWith(
                color: secondaryColor,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            AddressRow(
              icon: Icons.storefront,
              iconColor: primaryColor,
              label: widget.delivery.pickupLabel,
            ),

            const SizedBox(height: 12),

            AddressRow(
              icon: Icons.location_on_rounded,
              iconColor: Colors.red,
              label: widget.delivery.dropoffLabel,
            ),

            const SizedBox(height: 20),

            Text(
              'Mission Progress',
              style: subHeadingText,
            ),

            const SizedBox(height: 16),

            ...List.generate(
              missionSteps.length,
              (index) {
                final step = missionSteps[index];
                final isDone = index < _stepIndex;
                final isCurrent = index == _stepIndex;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isDone
                        ? primaryColor
                        : isCurrent
                        ? primaryColor.withValues(alpha: 0.15)
                        : surfaceColor,
                    child: Icon(
                      isDone ? Icons.check : step.icon,
                      color: isDone
                          ? secondaryColor
                          : isCurrent
                          ? primaryColor
                          : surfaceVariant,
                    ),
                  ),
                  title: Text(step.statusLabel),
                );
              },
            ),

            const SizedBox(height: 20),

            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _updating ? null : _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isLast ? secondaryColor : primaryColor,
                  foregroundColor:
                      isLast ? Colors.white : secondaryColor,
                ),
                child: _updating
                    ? CircularProgressIndicator(
                        color: isLast
                            ? Colors.white
                            : secondaryColor,
                      )
                    : Text(currentStep.buttonLabel),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      );
    },
  );
}
}


