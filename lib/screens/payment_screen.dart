import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../routes.dart';
import '../services/app_state.dart';
import '../widgets/common.dart';

/// Screen 6 - Payment Methods
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _cash = TextEditingController();
  final _phone = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _cash.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pay(AppState state) async {
    final method = state.paymentMethod;
    final total = state.total;

    if (method == 'Cash') {
      final received = double.tryParse(_cash.text.replaceAll(',', '')) ?? 0;
      if (received < total) {
        toast(context, 'Amount received is less than the total');
        return;
      }
    }
    if (method == 'Mobile Money' && _phone.text.trim().length < 9) {
      toast(context, 'Enter the customer phone number (MTN / Airtel)');
      return;
    }

    setState(() => _busy = true);
    // Simulated processing. Replace with your card / mobile-money gateway call.
    await Future.delayed(const Duration(milliseconds: 900));
    final sale = state.completeSale();
    if (!mounted) return;
    setState(() => _busy = false);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('Payment successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(ugx(sale.total),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('${methodLabel(sale.method)} - ${sale.customer}'),
            if (!sale.synced)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Saved offline - will sync when online',
                    style: TextStyle(fontSize: 12, color: Colors.orange.shade800)),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done')),
        ],
      ),
    );
    if (!mounted) return;
    Navigator.popUntil(context, (r) => r.settings.name == Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final primary = Theme.of(context).colorScheme.primary;
    final methods = state.enabledMethods.entries.where((e) => e.value).map((e) => e.key).toList();
    final received = double.tryParse(_cash.text.replaceAll(',', '')) ?? 0;

    return Scaffold(
      appBar: simpleAppBar('Payment'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Text('Total Amount', style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Text(ugx(state.total),
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...methods.map((m) {
            final sel = state.paymentMethod == m;
            return GestureDetector(
              onTap: () => state.setPaymentMethod(m),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: sel ? primary : Colors.grey.shade200, width: sel ? 1.5 : 1),
                ),
                child: Row(
                  children: [
                    Icon(methodIcon(m), color: primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        m == 'Mobile Money' ? 'Mobile Money (MTN/Airtel)' : methodLabel(m),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Icon(sel ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        color: sel ? primary : Colors.grey),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 6),
          if (state.paymentMethod == 'Cash') ...[
            TextField(
              controller: _cash,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Amount received (UGX)',
                border: OutlineInputBorder(),
              ),
            ),
            if (received >= state.total)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Change: ${ugx(received - state.total)}',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
          ],
          if (state.paymentMethod == 'Mobile Money')
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Customer phone number',
                hintText: '+256 7XX XXX XXX',
                border: OutlineInputBorder(),
              ),
            ),
          if (state.paymentMethod == 'Card')
            Text('Tap / insert the card on your card reader, then press Pay Now.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          if (state.paymentMethod == 'Bank Transfer')
            Text('Confirm the transfer has arrived, then press Pay Now.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 20),
          PrimaryButton(
            label: _busy ? 'Processing...' : 'Pay Now',
            onPressed: _busy ? null : () => _pay(state),
          ),
        ],
      ),
    );
  }
}
