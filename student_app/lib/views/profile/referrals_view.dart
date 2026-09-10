import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';

class ReferralsView extends StatefulWidget {
  const ReferralsView({super.key});

  @override
  State<ReferralsView> createState() => _ReferralsViewState();
}

class _ReferralsViewState extends State<ReferralsView> {
  bool _isLoading = true;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _fetchReferrals();
  }

  Future<void> _fetchReferrals() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.getAuth('/v1/referrals/me');
      if (!mounted) return;
      if (res != null && res['status'] == 'success') {
        setState(() => _data = res['data']);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading referral info: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Referral code copied to clipboard!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final code = _data?['referral_code'] ?? '...';
    final stats = _data?['stats'] as Map<String, dynamic>? ?? {};
    final history = _data?['history'] as List<dynamic>? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Refer & Earn Premium'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Hero Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppConstants.accentYellowSoft, Colors.amber.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.amber.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text('🎁 Invite Friends, Earn Premium!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 8),
                        const Text(
                          'Your friend gets 30 Days Free Premium Pass on their first test, and you get 7 Days Extension!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(code, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2)),
                              const SizedBox(width: 12),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 20, color: Colors.black87),
                                onPressed: () => _copyCode(code),
                                tooltip: 'Copy Code',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Stats Row
                  Row(
                    children: [
                      _buildStatCard('Friends Invited', '${stats['total_referred'] ?? 0}', Colors.blue),
                      const SizedBox(width: 12),
                      _buildStatCard('Qualified', '${stats['qualified_count'] ?? 0}', Colors.green),
                      const SizedBox(width: 12),
                      _buildStatCard('Days Earned', '+${stats['total_reward_days'] ?? 0}d', Colors.purple),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Referral History
                  Align(
                    alignment: Alignment.centerLeft,
                    child: const Text('Recent Referral Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),

                  if (history.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: const Center(
                        child: Text('No referrals yet. Share your code with fellow aspirants!', style: TextStyle(color: Colors.black54, fontSize: 13)),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: history.length,
                      itemBuilder: (context, idx) {
                        final item = history[idx];
                        final isQualified = item['status'] == 'qualified' || item['status'] == 'rewarded';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isQualified ? Colors.green.shade100 : Colors.amber.shade100,
                              child: Icon(isQualified ? Icons.check : Icons.hourglass_top, color: isQualified ? Colors.green : Colors.amber.shade800, size: 20),
                            ),
                            title: Text(item['referred_name'] ?? 'Aspirant', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: Text(item['status'].toString().toUpperCase(), style: TextStyle(fontSize: 11, color: isQualified ? Colors.green : Colors.orange)),
                            trailing: isQualified
                                ? const Text('+7 Days', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))
                                : const Text('Pending Test', style: TextStyle(fontSize: 11, color: Colors.black45)),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
