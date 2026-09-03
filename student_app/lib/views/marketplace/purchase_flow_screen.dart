import 'package:flutter/material.dart';
import '../../core/constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/api_service.dart';

class PurchaseFlowScreen extends StatefulWidget {
  final Map<String, dynamic> material;
  const PurchaseFlowScreen({super.key, required this.material});

  @override
  State<PurchaseFlowScreen> createState() => _PurchaseFlowScreenState();
}

class _PurchaseFlowScreenState extends State<PurchaseFlowScreen>
    with SingleTickerProviderStateMixin {
  int _step = 0; // 0=details, 1=processing, 2=success, 3=error
  String _selectedMethod = 'upi';
  String _errorMsg = '';
  late AnimationController _successCtrl;
  late Animation<double> _successAnim;

  @override
  void initState() {
    super.initState();
    _successCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _successAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _successCtrl.dispose();
    super.dispose();
  }

  Future<void> _purchase() async {
    setState(() => _step = 1);
    try {
      // Simulate payment delay (2s)
      await Future.delayed(const Duration(seconds: 2));

      final m = widget.material;
      // A non-2xx response throws, so reaching the next line means the server
      // recorded the purchase.
      await ApiService.postAuth('/v1/marketplace/${m['id']}/purchase', {
        'payment_method': _selectedMethod,
      });

      if (!mounted) return;
      setState(() => _step = 2);
      _successCtrl.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _step = 3;
        _errorMsg = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  bool _downloading = false;

  /// Requests a signed, short-lived download grant and opens it.
  Future<void> _download() async {
    setState(() => _downloading = true);
    try {
      final id = widget.material['id'];
      final res = await ApiService.getAuth('/v1/marketplace/$id/download');
      final url = (res is Map ? res['download_url'] : null)?.toString();
      if (url == null || url.isEmpty) throw Exception('No download link was returned');

      final uri = Uri.parse('${AppConstants.apiBaseUrl.replaceFirst(RegExp(r'/api/?$'), '')}$url');
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not open the download');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceAll('Exception: ', '')),
        backgroundColor: Colors.redAccent,
      ));
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: _step == 0 ? AppBar(
        backgroundColor: const Color(0xFF0F0F1A),
        title: Text('Complete Purchase', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18), onPressed: () => Navigator.pop(context)),
      ) : null,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _step == 0 ? _buildDetails()
            : _step == 1 ? _buildProcessing()
            : _step == 2 ? _buildSuccess()
            : _buildError(),
      ),
    );
  }

  Widget _buildDetails() {
    final m = widget.material;
    final bool isFree = m['is_free'] == 1 || (m['price']?.toString() ?? '0') == '0';
    final double price = double.tryParse(m['price']?.toString() ?? '0') ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Order summary
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1a1a2e), Color(0xFF16213e)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: Column(children: [
            Row(children: [
              Container(width: 50, height: 60, decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(colors: [Color(0xFF1d4ed8), Color(0xFF4338ca)])),
                  child: const Icon(Icons.menu_book_outlined, color: Colors.white54, size: 24)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(m['title'] ?? '', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white), maxLines: 2),
                const SizedBox(height: 4),
                Text('by ${m['creator_name'] ?? ''}', style: GoogleFonts.inter(fontSize: 12, color: Colors.white38)),
              ])),
            ]),
            const SizedBox(height: 16),
            const Divider(color: Colors.white12),
            const SizedBox(height: 12),
            _OrderRow(label: 'Price', value: isFree ? 'Free' : '₹${price.toStringAsFixed(2)}'),
            const SizedBox(height: 6),
            _OrderRow(label: 'Platform Fee', value: isFree ? '₹0' : '₹${(price * 0.00).toStringAsFixed(2)}', subtitle: 'Included'),
            const Divider(color: Colors.white12, height: 24),
            _OrderRow(label: 'Total', value: isFree ? 'FREE' : '₹${price.toStringAsFixed(2)}', isTotal: true),
          ]),
        ),

        const SizedBox(height: 28),

        if (!isFree) ...[
          Text('Select Payment Method', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 14),
          for (final method in [
            {'id': 'upi', 'label': 'UPI (GPay, PhonePe, Paytm)', 'icon': Icons.qr_code},
            {'id': 'card', 'label': 'Credit / Debit Card', 'icon': Icons.credit_card},
            {'id': 'netbanking', 'label': 'Net Banking', 'icon': Icons.account_balance},
            {'id': 'wallet', 'label': 'Wallet (Paytm, Mobikwik)', 'icon': Icons.account_balance_wallet},
          ])
            _PaymentOption(
              method: method,
              selected: _selectedMethod == method['id'],
              onTap: () => setState(() => _selectedMethod = method['id'] as String),
            ),
          const SizedBox(height: 24),
        ],

        // Secure badge
        Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.lock_outlined, size: 14, color: Colors.white38),
          const SizedBox(width: 6),
          Text('256-bit SSL secured · Mock sandbox payment', style: GoogleFonts.inter(fontSize: 11, color: Colors.white38)),
        ])),

        const SizedBox(height: 32),

        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: _purchase,
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366f1),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          child: Text(isFree ? 'Get Material for Free' : 'Pay ₹${price.toStringAsFixed(0)} Now',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800)),
        )),
      ]),
    );
  }

  Widget _buildProcessing() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const SizedBox(
        width: 60, height: 60,
        child: CircularProgressIndicator(
            strokeWidth: 3, color: Color(0xFF818cf8), strokeCap: StrokeCap.round),
      ),
      const SizedBox(height: 28),
      Text('Processing Payment...', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
      const SizedBox(height: 8),
      Text('Please wait. Do not close this screen.', style: GoogleFonts.inter(fontSize: 13, color: Colors.white38)),
    ]));
  }

  Widget _buildSuccess() {
    final m = widget.material;
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        ScaleTransition(
          scale: _successAnim,
          child: Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
                color: Colors.green.shade700.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.green.shade400, width: 2)),
            child: Icon(Icons.check_rounded, size: 54, color: Colors.green.shade400),
          ),
        ),
        const SizedBox(height: 28),
        Text('Payment Successful!', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
        const SizedBox(height: 8),
        Text('"${m['title']}" is now unlocked', style: GoogleFonts.inter(fontSize: 14, color: Colors.white54), textAlign: TextAlign.center),
        const SizedBox(height: 32),
        _InfoTile(icon: Icons.description_outlined, title: 'What next?', subtitle: 'Go to My Purchases in your profile to access and download the material.'),
        const SizedBox(height: 32),
        Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
            style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                side: const BorderSide(color: Colors.white24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text('Go to Home', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.w600)),
          )),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(
            onPressed: _downloading ? null : _download,
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366f1),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text(_downloading ? 'Preparing…' : 'Download',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          )),
        ]),
      ]),
    ));
  }

  Widget _buildError() {
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 100, height: 100, decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1), shape: BoxShape.circle,
            border: Border.all(color: Colors.red.shade400, width: 2)),
            child: Icon(Icons.close_rounded, size: 54, color: Colors.red.shade400)),
        const SizedBox(height: 24),
        Text('Payment Failed', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 8),
        Text(_errorMsg, style: GoogleFonts.inter(fontSize: 13, color: Colors.white38), textAlign: TextAlign.center),
        const SizedBox(height: 32),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: () => setState(() { _step = 0; _errorMsg = ''; }),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366f1), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: Text('Try Again', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        )),
      ]),
    ));
  }
}

class _OrderRow extends StatelessWidget {
  final String label, value;
  final String? subtitle;
  final bool isTotal;
  const _OrderRow({required this.label, required this.value, this.subtitle, this.isTotal = false});

  @override
  Widget build(BuildContext context) => Row(children: [
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.inter(fontSize: isTotal ? 14 : 13, fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500, color: isTotal ? Colors.white : Colors.white60)),
      if (subtitle != null) Text(subtitle!, style: GoogleFonts.inter(fontSize: 10, color: Colors.white38)),
    ]),
    const Spacer(),
    Text(value, style: GoogleFonts.inter(fontSize: isTotal ? 18 : 13, fontWeight: isTotal ? FontWeight.w900 : FontWeight.w600, color: isTotal ? Colors.white : Colors.white70)),
  ]);
}

class _PaymentOption extends StatelessWidget {
  final Map<String, dynamic> method;
  final bool selected;
  final VoidCallback onTap;
  const _PaymentOption({required this.method, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: selected ? const Color(0xFF818cf8) : Colors.white12, width: selected ? 1.5 : 1),
        color: selected ? const Color(0xFF6366f1).withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.03),
      ),
      child: Row(children: [
        Icon(method['icon'] as IconData, size: 20, color: selected ? const Color(0xFF818cf8) : Colors.white38),
        const SizedBox(width: 14),
        Text(method['label'] as String, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? Colors.white : Colors.white60)),
        const Spacer(),
        if (selected) const Icon(Icons.radio_button_checked, size: 18, color: Color(0xFF818cf8))
        else const Icon(Icons.radio_button_unchecked, size: 18, color: Colors.white24),
      ]),
    ),
  );
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  const _InfoTile({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(14)),
    child: Row(children: [
      Icon(icon, color: const Color(0xFF818cf8), size: 22),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 3),
        Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: Colors.white38)),
      ])),
    ]),
  );
}
