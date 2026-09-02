import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/api_service.dart';

class CreatorDashboardView extends StatefulWidget {
  const CreatorDashboardView({super.key});

  @override
  State<CreatorDashboardView> createState() => _CreatorDashboardViewState();
}

class _CreatorDashboardViewState extends State<CreatorDashboardView> {
  bool _loading = true;
  Map<String, dynamic>? _dashboardData;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loading = true;
      _errorMsg = '';
    });

    try {
      final res = await ApiService.getAuth('/v1/creator/dashboard');
      if (mounted) {
        if (res != null) {
          setState(() {
            _dashboardData = res as Map<String, dynamic>;
            _loading = false;
          });
        } else {
          setState(() {
            _errorMsg = res['message'] ?? 'Failed to load creator dashboard';
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _requestPayout(double pendingAmount) async {
    final amountCtrl = TextEditingController(text: pendingAmount.toStringAsFixed(0));
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1e1e2e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Request Payout',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Available Pending: ₹${pendingAmount.toStringAsFixed(2)}',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Amount (₹)',
                  labelStyle: GoogleFonts.inter(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (v) {
                  final val = double.tryParse(v ?? '0') ?? 0;
                  if (val < 100) return 'Minimum payout is ₹100';
                  if (val > pendingAmount) return 'Cannot exceed pending amount';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366f1)),
            child: Text('Submit Request', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final amount = double.tryParse(amountCtrl.text) ?? 0;
      try {
        // A failed request throws, so reaching the snackbar means it succeeded.
        await ApiService.postAuth('/v1/creator/payout', {'amount': amount});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payout requested!'),
              backgroundColor: Colors.green,
            ),
          );
          _loadDashboard();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1A),
        title: Text(
          'Creator Studio',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadDashboard,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF818cf8)))
          : _errorMsg.isNotEmpty
              ? _buildErrorView()
              : _buildDashboardContent(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 48, color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              _errorMsg,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/become-creator'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366f1)),
              child: Text('Register as Creator', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    final creator = _dashboardData?['creator'] ?? {};
    final stats = _dashboardData?['stats'] ?? {};
    final materials = (_dashboardData?['materials'] as List?) ?? [];
    final recentSales = (_dashboardData?['recent_sales'] as List?) ?? [];

    final double pendingPayout = double.tryParse(creator['pending_payout']?.toString() ?? '0') ?? 0;
    final double totalEarned = double.tryParse(stats['total_earned']?.toString() ?? '0') ?? 0;

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      color: const Color(0xFF818cf8),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Creator Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1e1b4b), Color(0xFF312e81)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF818cf8).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFF6366f1),
                        child: Text(
                          (creator['display_name'] ?? 'C')[0].toUpperCase(),
                          style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              creator['display_name'] ?? '',
                              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                            Text(
                              'Status: ${creator['verification_status']?.toUpperCase() ?? 'PENDING'}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: creator['verification_status'] == 'approved' ? Colors.greenAccent : Colors.amberAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Available Balance', style: GoogleFonts.inter(fontSize: 11, color: Colors.white54)),
                          const SizedBox(height: 2),
                          Text('₹${pendingPayout.toStringAsFixed(0)}',
                              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.greenAccent)),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: pendingPayout >= 100 ? () => _requestPayout(pendingPayout) : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366f1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text('Withdraw', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 4 Stats Cards
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.6,
              children: [
                _buildStatBox('Total Sales', '${stats['total_sales'] ?? 0}', Icons.shopping_bag_outlined, Colors.blue),
                _buildStatBox('Total Earned', '₹${totalEarned.toStringAsFixed(0)}', Icons.payments_outlined, Colors.green),
                _buildStatBox('Study Materials', '${stats['total_materials'] ?? 0}', Icons.description_outlined, Colors.purple),
                _buildStatBox('UPI ID', creator['upi_id'] ?? 'Not set', Icons.qr_code, Colors.amber),
              ],
            ),

            const SizedBox(height: 28),

            // Materials Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Uploaded Materials',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (materials.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    'No study materials uploaded yet.',
                    style: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
                  ),
                ),
              )
            else
              ...materials.map((m) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366f1).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFF818cf8), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m['title'] ?? '',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${m['exam_title'] ?? 'General'} · ₹${m['price'] ?? '0'} · ${m['sales_count'] ?? 0} sales',
                                style: GoogleFonts.inter(fontSize: 11, color: Colors.white54),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: m['status'] == 'approved' ? Colors.green.withValues(alpha: 0.2) : Colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            m['status']?.toUpperCase() ?? 'PENDING',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: m['status'] == 'approved' ? Colors.greenAccent : Colors.amberAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),

            const SizedBox(height: 28),

            // Recent sales
            if (recentSales.isNotEmpty) ...[
              Text(
                'Recent Sales',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const SizedBox(height: 12),
              ...recentSales.map((s) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s['material_title'] ?? '',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                            Text(
                              'Buyer: ${s['buyer_name'] ?? 'Student'}',
                              style: GoogleFonts.inter(fontSize: 10, color: Colors.white38),
                            ),
                          ],
                        ),
                        Text(
                          '+₹${s['creator_earning'] ?? '0'}',
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.greenAccent),
                        ),
                      ],
                    ),
                  )),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String title, String val, IconData icon, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color.shade300),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.white54),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            val,
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
