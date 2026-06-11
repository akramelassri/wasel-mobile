import 'package:flutter/material.dart';
import 'package:wasel/api/delivery_service.dart';
import 'package:wasel/main.dart';
import 'package:wasel/screens/client/specific_request_screen.dart';
import 'package:wasel/themes/colors.dart';
import 'package:wasel/themes/text_styles.dart';

const _terminalColors = {
  'DELIVERED': Colors.green,
  'CANCELLED_BY_CLIENT': Colors.red,
  'CANCELLED_BY_DRIVER': Colors.red,
  'CANCELLED_BY_ADMIN': Colors.red,
  'PROBLEM_REPORTED': Colors.orange,
};

String _labelFor(String status) {
  return switch (status) {
    'DELIVERED' => 'Delivered',
    'CANCELLED_BY_CLIENT' => 'Cancelled by you',
    'CANCELLED_BY_DRIVER' => 'Cancelled by driver',
    'CANCELLED_BY_ADMIN' => 'Cancelled by admin',
    'PROBLEM_REPORTED' => 'Problem reported',
    _ => status,
  };
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final List<dynamic> _items = [];
  int _page = 1;
  int _totalPages = 1;
  bool _loading = true;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _items.clear();
      _page = 1;
    });

    final authService = InheritedAuth.of(context).authService;
    final result = await DeliveryService.getMyDeliveries(
      authService: authService,
      page: 1,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      setState(() {
        _items.addAll(result.data!['items'] as List<dynamic>);
        _totalPages = (result.data!['totalPages'] as num).toInt();
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

  Future<void> _loadMore() async {
    if (_loadingMore || _page >= _totalPages) return;
    setState(() => _loadingMore = true);

    final authService = InheritedAuth.of(context).authService;
    final result = await DeliveryService.getMyDeliveries(
      authService: authService,
      page: _page + 1,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      setState(() {
        _items.addAll(result.data!['items'] as List<dynamic>);
        _page++;
        _loadingMore = false;
      });
    } else {
      setState(() => _loadingMore = false);
      // ADDED: Error handling so it doesn't fail silently
      final message = switch (result.error) {
        DeliveryServiceError.unauthorized =>
          'Session expired, please sign in again',
        DeliveryServiceError.network => 'Could not reach the server',
        _ => 'Could not load more deliveries',
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
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text('History', style: headingText),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: secondaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? Center(
              child: Text(
                'No deliveries yet',
                style: bodyText.copyWith(color: Colors.black38),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: primaryColor,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                itemCount: _items.length + 1,
                itemBuilder: (context, index) {
                  if (index == _items.length) {
                    if (_page >= _totalPages) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: OutlinedButton(
                        onPressed: _loadingMore ? null : _loadMore,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: surfaceVariant),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _loadingMore
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: secondaryColor,
                                ),
                              )
                            : Text('Load more', style: labelText),
                      ),
                    );
                  }

                  final item = _items[index] as Map<String, dynamic>;
                  return _HistoryCard(
                    item: item,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SpecificRequestScreen(
                          deliveryId: item['deliveryId'] as String,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

// ── history card ───────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;

  const _HistoryCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = item['finalStatus'] as String? ?? '';
    final statusColor = _terminalColors[status] ?? Colors.black38;
    final pickup = item['pickupAddress'] as String? ?? '--';
    final dropoff = item['dropoffAddress'] as String? ?? '--';

    // APPLIED FIX: Using num parsing to prevent TypeError on whole numbers
    final price = (item['pricePaid'] as num? ?? 0).toDouble();

    final date = _formatDate(item['date'] as String? ?? '');

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
                Text(date, style: captionText.copyWith(color: Colors.black38)),
                Text('${price.toStringAsFixed(2)} DH', style: subHeadingText),
              ],
            ),
            const SizedBox(height: 10),
            _AddressLine(
              icon: Icons.circle,
              iconColor: primaryColor,
              text: pickup,
            ),
            const SizedBox(height: 6),
            _AddressLine(
              icon: Icons.location_on_rounded,
              iconColor: Colors.red,
              text: dropoff,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _labelFor(status),
                style: captionText.copyWith(color: statusColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      // Padded digits for a cleaner look (e.g., 05/02/2024)
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      return '$day/$month/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}

// ── address line ───────────────────────────────────────────────────

class _AddressLine extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;

  const _AddressLine({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 14),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: bodyText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
