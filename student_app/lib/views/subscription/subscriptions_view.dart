import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';
import '../../widgets/design_system_widgets.dart';
import '../../widgets/skeleton_loader.dart';

class SubscriptionsView extends StatefulWidget {
  const SubscriptionsView({super.key});

  @override
  State<SubscriptionsView> createState() => _SubscriptionsViewState();
}

class _SubscriptionsViewState extends State<SubscriptionsView> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _plans = [];
  List<dynamic> _features = [];
  Map<String, dynamic>? _mySubscription;

  int? _selectedPlanId;
  String _selectedPaymentMethod = 'upi';
  bool _isProcessingPayment = false;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await ApiService.get('/v1/subscriptions/plans');
      if (!mounted) return;

      if (res is Map) {
        setState(() {
          _plans = res['plans'] as List? ?? [];
          _features = res['features'] as List? ?? [];
          _mySubscription = res['my_subscription'] as Map<String, dynamic>?;

          // Default select the popular or first paid plan
          if (_plans.isNotEmpty) {
            final paidPlans = _plans.where((p) => (double.tryParse('${p['price']}') ?? 0) > 0).toList();
            if (paidPlans.isNotEmpty) {
              _selectedPlanId = int.tryParse('${paidPlans.first['id']}');
            } else {
              _selectedPlanId = int.tryParse('${_plans.first['id']}');
            }
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _showCheckoutSheet(Map<String, dynamic> plan) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.cardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final price = double.tryParse('${plan['price']}') ?? 0.0;
            final duration = plan['duration_days'] ?? 30;
            final planName = plan['name'] ?? 'Pro Pass';

            return Padding(
              padding: EdgeInsets.only(
                left: AppConstants.space20,
                right: AppConstants.space20,
                top: AppConstants.space24,
                bottom: MediaQuery.of(context).viewInsets.bottom + AppConstants.space24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Checkout & Activation',
                              style: const TextStyle(color: AppConstants.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text('$planName ($duration Days)',
                              style: const TextStyle(color: AppConstants.textSecondary, fontSize: 12.5)),
                        ],
                      ),
                      Text('₹${price.toStringAsFixed(0)}',
                          style: const TextStyle(color: AppConstants.accentCyan, fontSize: 22, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const SizedBox(height: AppConstants.space20),
                  const Divider(color: AppConstants.cardBorder),
                  const SizedBox(height: AppConstants.space12),

                  const Text('SELECT PAYMENT METHOD',
                      style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  const SizedBox(height: AppConstants.space12),

                  _buildPaymentOption('upi', 'UPI / GPay / PhonePe / Paytm', Icons.qr_code_2_outlined, setSheetState),
                  const SizedBox(height: 8),
                  _buildPaymentOption('card', 'Credit / Debit Card (Visa, RuPay, MC)', Icons.credit_card_outlined, setSheetState),
                  const SizedBox(height: 8),
                  _buildPaymentOption('netbanking', 'NetBanking (All Major Banks)', Icons.account_balance_outlined, setSheetState),

                  const SizedBox(height: AppConstants.space24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isProcessingPayment
                          ? null
                          : () async {
                              Navigator.pop(ctx);
                              await _processSubscription(plan);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.accentBlue,
                        foregroundColor: AppConstants.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMedium)),
                        elevation: 4,
                      ),
                      child: _isProcessingPayment
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              price == 0 ? 'Activate Free Pass →' : 'Pay ₹${price.toStringAsFixed(0)} & Activate Pro →',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Center(
                    child: Text('🔒 256-Bit SSL Encrypted • Instant Plan Activation',
                        style: TextStyle(color: AppConstants.textMuted, fontSize: 11)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPaymentOption(String id, String label, IconData icon, StateSetter setSheetState) {
    final isSelected = _selectedPaymentMethod == id;
    return InkWell(
      onTap: () {
        setSheetState(() => _selectedPaymentMethod = id);
        setState(() => _selectedPaymentMethod = id);
      },
      borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.surfaceElevated : AppConstants.primaryDark,
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          border: Border.all(
            color: isSelected ? AppConstants.accentCyan : AppConstants.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppConstants.accentCyan : AppConstants.textSecondary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: isSelected ? AppConstants.textPrimary : AppConstants.textSecondary,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppConstants.accentCyan, size: 18),
          ],
        ),
      ),
    );
  }

  Future<void> _processSubscription(Map<String, dynamic> plan) async {
    setState(() => _isProcessingPayment = true);
    final planId = plan['id'];
    final planName = plan['name'] ?? 'Pro Pass';

    try {
      final res = await ApiService.post('/v1/subscriptions/subscribe', {
        'plan_id': planId,
        'payment_method': _selectedPaymentMethod,
      });

      setState(() => _isProcessingPayment = false);

      if (!mounted) return;

      final expiry = res is Map ? res['expiry_date'] : null;
      final receipt = res is Map ? res['receipt_no'] : null;

      // Show Congratulations Dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppConstants.cardDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppConstants.accentEmerald.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified, color: AppConstants.accentEmerald, size: 36),
              ),
              const SizedBox(height: 16),
              Text('🌟 $planName Activated!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppConstants.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                'Your Pro Membership is now active until ${expiry != null ? expiry.toString().split(' ')[0] : 'the end of term'}. Enjoy unlimited tests, AI Exam-Twin and verified solutions!',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppConstants.textSecondary, fontSize: 13, height: 1.4),
              ),
              if (receipt != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppConstants.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Receipt: $receipt',
                      style: const TextStyle(color: AppConstants.textMuted, fontSize: 11, fontFamily: 'monospace')),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _loadPlans();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.accentBlue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Start Practicing Now ➔',
                      style: TextStyle(color: AppConstants.textPrimary, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      setState(() => _isProcessingPayment = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Subscription failed: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppConstants.accentRose,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryDark,
      appBar: AppBar(
        backgroundColor: AppConstants.cardDark,
        elevation: 0,
        title: const Text('ExamVerse Pro Passes',
            style: TextStyle(color: AppConstants.textPrimary, fontSize: 17, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Padding(
              padding: EdgeInsets.all(AppConstants.space20),
              child: SkeletonListLoader(count: 3, itemHeight: 140),
            )
          : _error != null
              ? Center(
                  child: EmptyStateWidget(
                    icon: Icons.cloud_off,
                    title: 'Could not load subscription plans',
                    description: _error!,
                    buttonLabel: 'Try Again',
                    onButtonPressed: _loadPlans,
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConstants.space20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Active Status Banner
                      _buildActiveStatusBanner(),
                      const SizedBox(height: AppConstants.space24),

                      // Feature Checklist
                      const Text('WHAT YOU UNLOCK WITH PRO',
                          style: TextStyle(
                              color: AppConstants.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5)),
                      const SizedBox(height: AppConstants.space12),
                      _buildFeaturesGrid(),
                      const SizedBox(height: 28),

                      // Subscription Plans Cards
                      const Text('CHOOSE YOUR MEMBERSHIP PLAN',
                          style: TextStyle(
                              color: AppConstants.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5)),
                      const SizedBox(height: AppConstants.space12),

                      ..._plans.map((plan) => _buildPlanCard(plan)),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
    );
  }

  Widget _buildActiveStatusBanner() {
    final sub = _mySubscription;
    final isActive = sub != null && sub['is_active'] == true;
    final planName = sub != null ? sub['plan_name'] : 'Free Starter Tier';
    final daysLeft = sub != null ? sub['days_left'] : 0;
    final expiry = sub != null && sub['expiry_date'] != null ? sub['expiry_date'].toString().split(' ')[0] : '—';

    return Container(
      padding: const EdgeInsets.all(AppConstants.space20),
      decoration: BoxDecoration(
        gradient: isActive ? AppConstants.primaryGradient : AppConstants.readinessGradient,
        borderRadius: BorderRadius.circular(AppConstants.radiusHero),
        boxShadow: AppConstants.glowShadow(isActive ? AppConstants.accentEmerald : AppConstants.accentIndigo),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppConstants.onAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isActive ? '🌟 PRO ACTIVE' : 'FREE TIER',
                  style: const TextStyle(color: AppConstants.onAccent, fontSize: 11, fontWeight: FontWeight.w900),
                ),
              ),
              if (isActive)
                Text('$daysLeft Days Left',
                    style: const TextStyle(color: AppConstants.onAccent, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: AppConstants.space12),
          Text(planName,
              style: const TextStyle(color: AppConstants.onAccent, fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(
            isActive
                ? 'Valid until $expiry • Full access to mock papers & AI tools'
                : 'Upgrade to ExamVerse Pro to practice full mock papers with All-India AIR benchmarking',
            style: TextStyle(color: AppConstants.onAccent.withValues(alpha: 0.85), fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.cardDark,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(color: AppConstants.cardBorder),
      ),
      child: Column(
        children: _features.map((feat) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AppConstants.accentEmerald, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    feat.toString(),
                    style: const TextStyle(color: AppConstants.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPlanCard(dynamic plan) {
    final id = int.tryParse('${plan['id']}');
    final name = plan['name'] ?? 'Pro Pass';
    final price = double.tryParse('${plan['price']}') ?? 0.0;
    final duration = int.tryParse('${plan['duration_days']}') ?? 30;
    final description = plan['description'] ?? '';

    final isSelected = _selectedPlanId == id;
    final isBestValue = duration >= 365;
    final isPopular = duration == 90 || (duration == 30 && price > 0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() => _selectedPlanId = id);
          _showCheckoutSheet(plan);
        },
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        child: Container(
          padding: const EdgeInsets.all(AppConstants.space16),
          decoration: BoxDecoration(
            color: isSelected ? AppConstants.surfaceElevated : AppConstants.cardDark,
            borderRadius: BorderRadius.circular(AppConstants.radiusCard),
            border: Border.all(
              color: isSelected ? AppConstants.accentCyan : AppConstants.cardBorder,
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected ? AppConstants.glowShadow(AppConstants.accentCyan) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(name,
                            style: const TextStyle(
                                color: AppConstants.textPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
                        if (isBestValue) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppConstants.accentEmerald.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('BEST VALUE',
                                style: TextStyle(
                                    color: AppConstants.accentEmerald, fontSize: 9.5, fontWeight: FontWeight.bold)),
                          ),
                        ] else if (isPopular) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppConstants.accentAmber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('POPULAR',
                                style: TextStyle(
                                    color: AppConstants.accentAmber, fontSize: 9.5, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    price == 0 ? 'FREE' : '₹${price.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: AppConstants.accentCyan, fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                description.isNotEmpty ? description : '$duration Days Full Platform Pro Pass',
                style: const TextStyle(color: AppConstants.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '⏳ $duration Days Validity',
                    style: const TextStyle(color: AppConstants.textMuted, fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    price == 0 ? 'Activate Free ➔' : 'Choose Plan ➔',
                    style: TextStyle(
                      color: isSelected ? AppConstants.accentCyan : AppConstants.accentBlue,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
