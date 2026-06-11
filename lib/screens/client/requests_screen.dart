import 'package:flutter/material.dart';
import 'package:wasel/api/delivery_service.dart';
import 'package:wasel/main.dart';
import 'package:wasel/screens/client/history_screen.dart';
import 'package:wasel/screens/client/specific_request_screen.dart';
import 'package:wasel/themes/colors.dart';
import 'package:wasel/themes/text_styles.dart';

const _statusOrder = [
  'CREATED',
  'WAITING_DRIVER',
  'ASSIGNED',
  'ACCEPTED',
  'ARRIVED_AT_PICKUP',
  'PICKED_UP',
  'IN_TRANSIT',
  'ARRIVED_AT_DROPOFF',
  'DELIVERED',
];

const _pendingStatuses = {'CREATED', 'WAITING_DRIVER', 'ASSIGNED'};

double _progressFor(String status) {
  final index = _statusOrder.indexOf(status);
  if (index < 0) return 0;
  return (index + 1) / _statusOrder.length;
}

String _labelFor(String status) {
  return switch (status) {
    'CREATED' => 'Created',
    'WAITING_DRIVER' => 'Looking for driver',
    'ASSIGNED' => 'Assigning driver',
    'ACCEPTED' => 'Driver accepted',
    'ARRIVED_AT_PICKUP' => 'Driver at pickup',
    'PICKED_UP' => 'Parcel picked up',
    'IN_TRANSIT' => 'On the way',
    'ARRIVED_AT_DROPOFF' => 'Driver at dropoff',
    'DELIVERED' => 'Delivered',
    _ => status,
  };
}

class ClientRequestsScreen extends StatefulWidget {
  const ClientRequestsScreen({super.key});

  @override
  State<ClientRequestsScreen> createState() => _ClientRequestsScreenState();
}

class _ClientRequestsScreenState extends State<ClientRequestsScreen> {
  List<dynamic>? _active;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final authService = InheritedAuth.of(context).authService;
    final result = await DeliveryService.getActiveDeliveries(
      authService: authService,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      setState(() {
        _active = result.data!['items'] as List<dynamic>;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
      final message = switch (result.error) {
        DeliveryServiceError.unauthorized =>
          'Session expired, please sign in again',
        DeliveryServiceError.network => 'Could not reach the server',
        DeliveryServiceError.server => 'Something went wrong',
        null => 'Something went wrong',
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: primaryColor,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Active', style: headingText),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HistoryScreen(),
                          ),
                        ),
                        child: Text(
                          'View history',
                          style: labelText.copyWith(color: primaryColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              if (_loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_active == null || _active!.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No active deliveries',
                      style: bodyText.copyWith(color: Colors.black38),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = _active![index] as Map<String, dynamic>;
                      return _DeliveryCard(
                        item: item,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SpecificRequestScreen(
                              deliveryId:
                                  item['id']
                                      as String, // FIX: Backend sends 'id', not 'deliveryId'
                            ),
                          ),
                        ),
                      );
                    }, childCount: _active!.length),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── delivery card ──────────────────────────────────────────────────

class _DeliveryCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;

  const _DeliveryCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // FIX: Backend sends 'status', not 'finalStatus'
    final status = item['status'] as String? ?? 'CREATED';
    final isPending = _pendingStatuses.contains(status);
    final progress = _progressFor(status);
    final statusLabel = _labelFor(status);

    // FIX: Backend sends an address object, not a string
    final dropoffObj = item['dropoffAddress'] as Map<String, dynamic>?;
    final dropoff = dropoffObj != null
        ? '${dropoffObj['street']}, ${dropoffObj['city']}'
        : '--';

    // FIX: Safe parsing for JSON numbers using 'price', not 'pricePaid'
    final price = (item['price'] as num? ?? 0).toDouble();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    dropoff,
                    style: subHeadingText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text('${price.toStringAsFixed(2)} DH', style: subHeadingText),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  statusLabel,
                  style: labelText.copyWith(
                    color: isPending ? Colors.black38 : primaryColor,
                  ),
                ),
                Text(
                  'Waiting',
                  style: captionText.copyWith(color: Colors.black38),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: surfaceVariant,
                valueColor: AlwaysStoppedAnimation(
                  isPending ? Colors.black26 : primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
