import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:wasel/api/driver_service.dart';
import 'package:wasel/main.dart';
import 'package:wasel/model/available_delivery_model.dart';
import 'package:wasel/model/driver_mission_model.dart';
import 'package:wasel/widgets/driver/active_mission_screen.dart';
import 'package:wasel/widgets/driver/mission_list.dart';
import 'package:wasel/widgets/driver/driver_map.dart';
import 'package:wasel/screens/driver/wallet_screen.dart';
import 'package:wasel/themes/colors.dart';
import 'package:wasel/themes/text_styles.dart';

// ─────────────────────────────────────────────────────────────────
// ÉCRAN REQUESTS DU DRIVER
// Deux onglets : Active (missions en cours) et History (terminées)
// ─────────────────────────────────────────────────────────────────
class DriverRequestsScreen extends StatefulWidget {
  const DriverRequestsScreen({super.key});

  @override
  State<DriverRequestsScreen> createState() => _DriverRequestsScreenState();
}

class _DriverRequestsScreenState extends State<DriverRequestsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final List<DriverMission> _missions = [];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMissions());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMissions() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final authService = InheritedAuth.of(context).authService;
    final result = await DriverService.fetchMyMissions(authService);
    if (!mounted) return;

    setState(() {
      _loading = false;
      if (result.isSuccess) {
        _missions
          ..clear()
          ..addAll(result.data ?? []);
      } else {
        _missions.clear();
        _errorMessage = result.message ?? 'Unable to load missions.';
      }
    });
  }

  /// Refresh individual mission details from backend including status history
  Future<void> _refreshMissionDetails(String missionId) async {
    final authService = InheritedAuth.of(context).authService;
    final result = await DriverService.fetchMissionDetails(
      authService,
      missionId,
    );

    if (!mounted) return;

    if (result.isSuccess && result.data != null) {
      setState(() {
        final index = _missions.indexWhere((m) => m.id == missionId);
        if (index >= 0) {
          _missions[index] = result.data!;
        }
      });
    }
  }

  Future<void> _openMission(DriverMission mission) async {
  if (!mission.isActive) return;

  // Fetch les détails complets (avec coords) avant d'ouvrir l'écran
  final authService = InheritedAuth.of(context).authService;
  final result = await DriverService.fetchMissionDetails(authService, mission.id);

  if (!mounted) return;

  if (result.isSuccess && result.data != null) {
    final detailed = result.data!;

    final updatedStatus = await Navigator.push<String?>(
      context,
      MaterialPageRoute(
        builder: (_) => ActiveMissionScreen(
          delivery: AvailableDelivery.fromDriverMission(detailed), // coords réelles
        ),
      ),
    );

    if (updatedStatus == null || updatedStatus == mission.status) return;
    await _refreshMissionDetails(mission.id);

  } else {
    // Fallback silencieux ou snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to load mission details.')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    final activeMissions = _missions.where((m) => m.isActive).toList();
    final historyMissions = _missions.where((m) => !m.isActive).toList();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Missions'),
        backgroundColor: surfaceColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DriverWalletScreen()),
              );
            },
          ),
          IconButton(
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
            onPressed: _loading ? null : _loadMissions,
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
                color: Colors.red.withOpacity(0.08),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Text(
                  _errorMessage!,
                  style: captionText.copyWith(color: Colors.red),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: secondaryColor,
                  unselectedLabelColor: secondaryColor.withOpacity(0.5),
                  labelStyle: bolderLabelText.copyWith(fontSize: 14),
                  unselectedLabelStyle: bodyText.copyWith(fontSize: 14),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Active'),
                          if (activeMissions.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: secondaryColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${activeMissions.length}',
                                style: captionText.copyWith(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Tab(text: 'History'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading && _missions.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        MissionList(
                          missions: activeMissions,
                          emptyMessage: 'No active missions',
                          emptySubMessage:
                              'Accept a delivery from the Home tab',
                          emptyIcon: Icons.moped_rounded,
                          onMissionTap: _openMission,
                        ),
                        MissionList(
                          missions: historyMissions,
                          emptyMessage: 'No missions yet',
                          emptySubMessage:
                              'Your completed deliveries will appear here',
                          emptyIcon: Icons.history_rounded,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
