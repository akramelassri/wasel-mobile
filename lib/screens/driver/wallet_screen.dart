import 'package:flutter/material.dart';
import 'package:wasel/api/driver_service.dart';
import 'package:wasel/main.dart';
import 'package:wasel/model/driver_wallet_model.dart';
import 'package:wasel/themes/colors.dart';
import 'package:wasel/themes/text_styles.dart';

// ─────────────────────────────────────────────────────────────────
// ÉCRAN WALLET DRIVER
// Accessible depuis Settings. Affiche :
// - Solde actuel du DriverWallet
// - Bouton Withdraw → bottom sheet
// - Liste paginée des transactions
// ─────────────────────────────────────────────────────────────────
class DriverWalletScreen extends StatefulWidget {
  const DriverWalletScreen({super.key});

  @override
  State<DriverWalletScreen> createState() => _DriverWalletScreenState();
}

class _DriverWalletScreenState extends State<DriverWalletScreen> {
  DriverWallet? _wallet;
  List<WalletTransaction> _transactions = [];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final authService = InheritedAuth.of(context).authService;
    final walletResult = await DriverService.fetchWallet(authService);
    final transactionsResult = await DriverService.fetchWalletTransactions(
      authService,
    );

    if (!mounted) return;

    if (!walletResult.isSuccess) {
      setState(() {
        _wallet = null;
        _transactions = [];
        _loading = false;
        _errorMessage = walletResult.message ?? 'Unable to load wallet.';
      });
      return;
    }

    setState(() {
      _wallet = walletResult.data;
      _transactions = transactionsResult.isSuccess
          ? transactionsResult.data ?? []
          : [];
      _loading = false;
      _errorMessage = transactionsResult.isSuccess
          ? null
          : transactionsResult.message ?? 'Unable to load transactions.';
    });
  }

  double get _monthlyEarnings => _wallet?.monthlyEarnings ?? 0.0;

  void _openWithdrawSheet() {
    if (_wallet == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WithdrawSheet(
        availableBalance: _wallet!.balance,
        currency: _wallet!.currency,
        onConfirmed: (amount) async {
          final authService = InheritedAuth.of(context).authService;
          final result = await DriverService.withdrawFunds(
            authService,
            amount,
            _wallet!.currency,
          );

          if (result.isSuccess) {
            await _loadData();
          }
          return result;
        },
      ),
    );
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
        title: Text('My Wallet', style: subHeadingText),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : _wallet == null
          ? _buildErrorState()
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // ── Carte solde ──
        // Fond secondaryColor (bleu foncé) pour contraster avec le fond blanc
        // Même logique que les cards bancaires dans les apps de paiement
        Container(
          margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: secondaryColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label + icône wallet
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Available Balance',
                    style: captionText.copyWith(
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: primaryColor,
                    size: 22,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Solde en grand — c'est l'élément principal de cette card
              Text(
                '${_wallet!.balance.toStringAsFixed(2)} ${_wallet!.currency}',
                style: displayText.copyWith(color: Colors.white),
              ),

              const SizedBox(height: 16),

              // Séparateur
              Container(height: 1, color: Colors.white.withValues(alpha: 0.1)),

              const SizedBox(height: 16),

              // Gains du mois + bouton Withdraw sur la même ligne
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This month',
                        style: captionText.copyWith(
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '+${_monthlyEarnings.toStringAsFixed(2)} ${_wallet!.currency}',
                        style: labelText.copyWith(color: primaryColor),
                      ),
                    ],
                  ),
                  // Bouton Withdraw — désactivé si solde = 0
                  ElevatedButton.icon(
                    onPressed: _wallet!.balance > 0 ? _openWithdrawSheet : null,
                    icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                    label: Text(
                      'Withdraw',
                      style: bolderLabelText.copyWith(color: secondaryColor),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: secondaryColor,
                      disabledBackgroundColor: surfaceVariant,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ── Header liste transactions ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Transactions', style: subHeadingText),
              Text(
                '${_transactions.length} total',
                style: captionText.copyWith(
                  color: secondaryColor.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Liste des transactions ──
        Expanded(
          child: _transactions.isEmpty
              ? Center(
                  child: Text(
                    'No transactions yet',
                    style: bodyText.copyWith(
                      color: secondaryColor.withValues(alpha: 0.4),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  itemCount: _transactions.length,
                  separatorBuilder: (context, index) =>
                      const Divider(color: surfaceVariant, height: 1),
                  itemBuilder: (context, index) {
                    return _TransactionRow(transaction: _transactions[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: surfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Could not load wallet',
            style: subHeadingText.copyWith(color: secondaryColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              setState(() => _loading = true);
              _loadData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: secondaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text('Retry', style: bolderLabelText),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// LIGNE DE TRANSACTION
// Une ligne par transaction dans la liste. Icône + label à gauche,
// montant coloré à droite (vert CREDIT, rouge DEBIT)
// ─────────────────────────────────────────────────────────────────
class _TransactionRow extends StatelessWidget {
  final WalletTransaction transaction;
  const _TransactionRow({required this.transaction});

  // Mapping reason → label lisible + icône
  ({String label, IconData icon}) get _meta => switch (transaction.reason) {
    'DELIVERY_EARNING' => (
      label: 'Delivery earning',
      icon: Icons.moped_rounded,
    ),
    'CASH_COLLECTION' => (
      label: 'Cash collected',
      icon: Icons.payments_rounded,
    ),
    'PLATFORM_COMMISSION' => (
      label: 'Platform commission',
      icon: Icons.percent_rounded,
    ),
    'DRIVER_WITHDRAWAL' => (
      label: 'Withdrawal',
      icon: Icons.arrow_upward_rounded,
    ),
    'REFUND' => (label: 'Refund', icon: Icons.replay_rounded),
    'MANUAL_ADJUSTMENT' => (label: 'Adjustment', icon: Icons.tune_rounded),
    _ => (label: transaction.reason, icon: Icons.swap_horiz_rounded),
  };

  @override
  Widget build(BuildContext context) {
    final meta = _meta;
    final isCredit = transaction.isCredit;
    final amountColor = isCredit ? primaryColor : secondaryColor;
    final amountPrefix = isCredit ? '+' : '-';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          // ── Icône de la transaction ──
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              // Vert pâle pour CREDIT, rouge pâle pour DEBIT
              color: amountColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(meta.icon, size: 20, color: amountColor),
          ),

          const SizedBox(width: 14),

          // ── Label + description + date ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meta.label, style: labelText.copyWith(fontSize: 14)),
                if (transaction.description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    transaction.description!,
                    style: captionText.copyWith(
                      color: secondaryColor.withValues(alpha: 0.5),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  _formatDate(transaction.createdAt),
                  style: captionText.copyWith(
                    color: secondaryColor.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // ── Montant ──
          Text(
            '$amountPrefix${transaction.amount.toStringAsFixed(2)} MAD',
            style: bolderLabelText.copyWith(color: amountColor, fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final hour = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    if (isToday) return 'Today $hour:$min';
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
    return '${date.day} ${months[date.month - 1]} $hour:$min';
  }
}

// ─────────────────────────────────────────────────────────────────
// BOTTOM SHEET DE RETRAIT
// Champ montant avec validation. Appelle onConfirmed si tout est OK.
// Dans le vrai projet : POST /api/wallet/driver/withdraw
// ─────────────────────────────────────────────────────────────────
class _WithdrawSheet extends StatefulWidget {
  final double availableBalance;
  final String currency;
  final Future<DriverApiResult<void>> Function(double amount) onConfirmed;

  const _WithdrawSheet({
    required this.availableBalance,
    required this.currency,
    required this.onConfirmed,
  });

  @override
  State<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<_WithdrawSheet> {
  final _amountCtrl = TextEditingController();
  bool _confirming = false;
  String? _error; // message d'erreur de validation affiché sous le champ

  // Montant minimum de retrait — à récupérer depuis la config API en prod
  static const double _minWithdraw = 50;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    // Validation du montant
    final raw = _amountCtrl.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(raw);

    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount');
      return;
    }
    if (amount < _minWithdraw) {
      setState(
        () => _error = 'Minimum withdrawal is $_minWithdraw ${widget.currency}',
      );
      return;
    }
    if (amount > widget.availableBalance) {
      setState(() => _error = 'Insufficient balance');
      return;
    }

    setState(() {
      _error = null;
      _confirming = true;
    });

    final result = await widget.onConfirmed(amount);
    if (!mounted) return;

    setState(() => _confirming = false);
    if (!result.isSuccess) {
      setState(() => _error = result.message ?? 'Withdrawal failed');
      return;
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Withdrawal of ${amount.toStringAsFixed(2)} ${widget.currency} requested',
        ),
        backgroundColor: secondaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + keyboardHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: surfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const SizedBox(height: 24),

          Text('Withdraw funds', style: subHeadingText),

          const SizedBox(height: 8),

          // Solde disponible affiché pour référence
          Text(
            'Available : ${widget.availableBalance.toStringAsFixed(2)} ${widget.currency}',
            style: captionText.copyWith(
              color: secondaryColor.withValues(alpha: 0.5),
            ),
          ),

          const SizedBox(height: 20),

          // Champ montant
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: headingText.copyWith(fontSize: 28),
            textAlign: TextAlign.center,
            // onChanged efface l'erreur dès que l'utilisateur retape
            onChanged: (_) => setState(() => _error = null),
            decoration: InputDecoration(
              hintText: '0.00',
              hintStyle: headingText.copyWith(
                fontSize: 28,
                color: secondaryColor.withValues(alpha: 0.2),
              ),
              // Suffixe devise
              suffix: Text(
                widget.currency,
                style: bodyText.copyWith(
                  color: secondaryColor.withValues(alpha: 0.5),
                ),
              ),
              filled: true,
              fillColor: surfaceColor,
              // Bordure rouge si erreur, jaune si focus, grise sinon
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _error != null ? Colors.red : surfaceVariant,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _error != null ? Colors.red : primaryColor,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 18),
            ),
          ),

          // Message d'erreur sous le champ — visible seulement si _error != null
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: captionText.copyWith(color: Colors.red)),
          ],

          const SizedBox(height: 8),

          // Info montant minimum
          Text(
            'Minimum withdrawal : $_minWithdraw ${widget.currency}',
            style: captionText.copyWith(
              color: secondaryColor.withValues(alpha: 0.4),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _confirming ? null : _confirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: secondaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _confirming
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: secondaryColor,
                    ),
                  )
                : Text(
                    'Confirm withdrawal',
                    style: bolderLabelText.copyWith(color: secondaryColor),
                  ),
          ),
        ],
      ),
    );
  }
}
