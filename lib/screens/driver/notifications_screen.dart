import 'package:flutter/material.dart';
import 'package:wasel/main.dart';
import 'package:wasel/api/driver_service.dart';
import 'package:wasel/model/driver_notification_model.dart';
import 'package:wasel/themes/colors.dart';
import 'package:wasel/themes/text_styles.dart';

// ─────────────────────────────────────────────────────────────────
// ÉCRAN NOTIFICATIONS
// Accessible depuis la cloche dans le header du Home Screen.
// - Liste de toutes les notifications triées par date
// - Tap sur une notification → marque comme lue
// - Bouton "Mark all as read"
// ─────────────────────────────────────────────────────────────────
class DriverNotificationsScreen extends StatefulWidget {
  const DriverNotificationsScreen({super.key});

  @override
  State<DriverNotificationsScreen> createState() =>
      _DriverNotificationsScreenState();
}

class _DriverNotificationsScreenState extends State<DriverNotificationsScreen> {
  List<DriverNotification> _notifications = [];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadNotifications());
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final authService = InheritedAuth.of(context).authService;
    final result = await DriverService.fetchNotifications(authService);

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.isSuccess) {
        _notifications = result.data ?? [];
      } else {
        _notifications = [];
        _errorMessage = result.message ?? 'Unable to load notifications.';
      }
    });
  }

  int get _unreadCount => _notifications.where((n) => n.isUnread).length;

  Future<void> _markAsRead(DriverNotification notif) async {
    if (!notif.isUnread) return;
    final authService = InheritedAuth.of(context).authService;
    final result = await DriverService.markNotificationRead(
      authService,
      notif.id,
    );

    if (!mounted) return;
    if (result.isSuccess) {
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notif.id);
        if (index != -1) {
          _notifications[index] = DriverNotification(
            id: notif.id,
            type: notif.type,
            title: notif.title,
            body: notif.body,
            status: 'READ',
            sentAt: notif.sentAt,
          );
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message ?? 'Unable to mark notification as read.',
          ),
        ),
      );
    }
  }

  Future<void> _markAllAsRead() async {
    final authService = InheritedAuth.of(context).authService;
    final result = await DriverService.markAllNotificationsRead(authService);

    if (!mounted) return;
    if (result.isSuccess) {
      setState(() {
        _notifications = _notifications
            .map(
              (n) => DriverNotification(
                id: n.id,
                type: n.type,
                title: n.title,
                body: n.body,
                status: 'READ',
                sentAt: n.sentAt,
              ),
            )
            .toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message ?? 'Unable to mark all notifications read.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: secondaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Notifications', style: subHeadingText),
        centerTitle: true,
        actions: [
          // Bouton "Mark all" visible seulement s'il y a des non lues
          if (!_loading && _unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Mark all',
                style: captionText.copyWith(
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : Column(
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
                  child: _notifications.isEmpty
                      ? _buildEmptyState()
                      : _buildList(),
                ),
              ],
            ),
    );
  }

  Widget _buildList() {
    // Groupe les notifications par date : Today, Yesterday, Earlier
    // pour une meilleure lisibilité — pattern standard dans toutes les apps
    final groups = _groupByDate(_notifications);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Label du groupe (Today / Yesterday / Earlier) ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Text(
                group.label,
                style: captionText.copyWith(
                  color: secondaryColor.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            // ── Notifications du groupe ──
            ...group.items.map(
              (notif) => _NotificationTile(
                notification: notif,
                onTap: () => _markAsRead(notif),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_rounded,
            size: 56,
            color: surfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: subHeadingText.copyWith(color: secondaryColor),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll be notified about new deliveries\nand payments here',
            style: captionText.copyWith(
              color: secondaryColor.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Groupement par date ──
  // Sépare les notifications en trois groupes : Today, Yesterday, Earlier
  // Évite d'afficher des timestamps bruts, plus lisible pour l'utilisateur
  List<_NotifGroup> _groupByDate(List<DriverNotification> notifications) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final todayItems = notifications.where((n) {
      final d = DateTime(n.sentAt.year, n.sentAt.month, n.sentAt.day);
      return d == today;
    }).toList();

    final yesterdayItems = notifications.where((n) {
      final d = DateTime(n.sentAt.year, n.sentAt.month, n.sentAt.day);
      return d == yesterday;
    }).toList();

    final earlierItems = notifications.where((n) {
      final d = DateTime(n.sentAt.year, n.sentAt.month, n.sentAt.day);
      return d.isBefore(yesterday);
    }).toList();

    return [
      if (todayItems.isNotEmpty) _NotifGroup(label: 'TODAY', items: todayItems),
      if (yesterdayItems.isNotEmpty)
        _NotifGroup(label: 'YESTERDAY', items: yesterdayItems),
      if (earlierItems.isNotEmpty)
        _NotifGroup(label: 'EARLIER', items: earlierItems),
    ];
  }
}

// Modèle interne pour représenter un groupe de notifications
class _NotifGroup {
  final String label;
  final List<DriverNotification> items;
  const _NotifGroup({required this.label, required this.items});
}

// ─────────────────────────────────────────────────────────────────
// TUILE DE NOTIFICATION
// Fond légèrement coloré si UNREAD, blanc si READ
// Point bleu à gauche pour indiquer le statut non lu
// Tap → marque comme lue via le callback
// ─────────────────────────────────────────────────────────────────
class _NotificationTile extends StatelessWidget {
  final DriverNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  // Mapping type → icône
  ({IconData icon, Color color}) get _icon => switch (notification.type) {
    'DELIVERY_ASSIGNED' => (icon: Icons.moped_rounded, color: secondaryColor),
    'DRIVER_ARRIVING' => (
      icon: Icons.location_on_rounded,
      color: secondaryColor,
    ),
    'PAYMENT_CONFIRMED' => (
      icon: Icons.account_balance_wallet_rounded,
      color: secondaryColor,
    ),
    'COMPLAINT_CREATED' => (
      icon: Icons.report_problem_rounded,
      color: secondaryColor,
    ),
    'COMPLAINT_RESOLVED' => (
      icon: Icons.check_circle_outline_rounded,
      color: secondaryColor,
    ),
    'NEW_MESSAGE' => (
      icon: Icons.chat_bubble_outline_rounded,
      color: secondaryColor,
    ),
    _ => (icon: Icons.notifications_rounded, color: secondaryColor),
  };

  @override
  Widget build(BuildContext context) {
    final iconMeta = _icon;

    return InkWell(
      onTap: onTap,
      child: Container(
        // Fond jaune très pâle si non lue — subtil mais visible
        color: notification.isUnread
            ? primaryColor.withValues(alpha: 0.05)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Icône du type de notification ──
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconMeta.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(iconMeta.icon, size: 22, color: iconMeta.color),
            ),

            const SizedBox(width: 14),

            // ── Contenu : titre + body + heure ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: labelText.copyWith(
                            fontSize: 14,
                            // Titre en gras si non lue, normal si lue
                            fontWeight: notification.isUnread
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Heure d'envoi
                      Text(
                        _formatTime(notification.sentAt),
                        style: captionText.copyWith(
                          color: secondaryColor.withValues(alpha: 0.4),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: bodyText.copyWith(
                      fontSize: 13,
                      color: notification.isUnread
                          ? onBackground
                          : secondaryColor.withValues(alpha: 0.6),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // ── Point bleu UNREAD ──
            // Visible seulement si non lue. Petit mais suffisant pour signaler
            if (notification.isUnread)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    // Moins d'une heure → affiche "X min ago"
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    // Moins d'un jour → affiche "Xh ago"
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    // Plus → affiche la date
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }
}
