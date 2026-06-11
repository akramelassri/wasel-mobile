import 'package:flutter/material.dart';
import 'package:wasel/api/driver_service.dart';
import 'package:wasel/main.dart';
import 'package:wasel/themes/colors.dart';
import 'package:wasel/themes/text_styles.dart';
import 'package:wasel/model/available_delivery_model.dart';
import 'package:wasel/widgets/driver/delivery_card.dart';
import 'package:wasel/widgets/driver/active_mission_screen.dart';
import 'package:wasel/screens/driver/notifications_screen.dart';

// ─────────────────────────────────────────────────────────────────
// ÉCRAN PRINCIPAL DRIVER — liste des courses disponibles
// ─────────────────────────────────────────────────────────────────
class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  static const _defaultLatitude = 35.7595;
  static const _defaultLongitude = -5.83395;

  List<AvailableDelivery> _deliveries = [];
  bool _loading = false;
  String? _acceptingId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    await _loadAvailableDeliveries();
  }

  Future<void> _loadAvailableDeliveries() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final authService = InheritedAuth.of(context).authService;
    final result = await DriverService.fetchAvailableDeliveries(
      authService,
      latitude: _defaultLatitude,
      longitude: _defaultLongitude,
    );

    if (!mounted) return;

    setState(() {
      _loading = false;

      if (result.isSuccess) {
        _deliveries = result.data ?? [];
      } else {
        _deliveries = [];
        _errorMessage =
            result.message ?? 'Unable to load available deliveries.';
      }
    });
  }

  Future<void> _acceptDelivery(AvailableDelivery delivery) async {
    setState(() => _acceptingId = delivery.id);
    final authService = InheritedAuth.of(context).authService;
    final result = await DriverService.respondToDelivery(
      authService,
      delivery.id,
      true,
    );

    if (!mounted) return;
    setState(() => _acceptingId = null);

    if (result.isSuccess) {
      setState(() => _deliveries.removeWhere((d) => d.id == delivery.id));
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ActiveMissionScreen(delivery: delivery),
        ),
      );
      return;
    }

    if (result.error == DriverApiError.conflict) {
      setState(() => _deliveries.removeWhere((d) => d.id == delivery.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message ?? 'This delivery has already been taken.',
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message ?? 'Unable to accept delivery.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        title: const Text('Deliveries'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DriverNotificationsScreen(),
                ),
              );
            },
          ),
          IconButton(
            onPressed: _loading ? null : _refresh,
            icon: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: secondaryColor,
                    ),
                  )
                : const Icon(Icons.refresh_rounded, color: secondaryColor),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                color: Colors.red.withValues(alpha: 0.08),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Text(
                  _errorMessage!,
                  style: captionText.copyWith(color: Colors.red),
                ),
              ),
            Expanded(
              child: _loading && _deliveries.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    )
                  : _deliveries.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _refresh,
                      color: primaryColor,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: _deliveries.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final delivery = _deliveries[index];
                          return DeliveryCard(
                            delivery: delivery,
                            isAccepting: _acceptingId == delivery.id,
                            onAccept: () => _acceptDelivery(delivery),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.moped_rounded, size: 64, color: surfaceVariant),
          const SizedBox(height: 16),
          Text(
            'No deliveries nearby',
            style: subHeadingText.copyWith(color: secondaryColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Pull down to refresh',
            style: captionText.copyWith(
              color: secondaryColor.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
