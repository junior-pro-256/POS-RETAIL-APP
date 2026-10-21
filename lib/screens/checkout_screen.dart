import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../routes.dart';
import '../services/app_state.dart';
import '../widgets/common.dart';

/// Screen 5 - Create Sale / Checkout
class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  Future<void> _pickCustomer(BuildContext context, AppState state) async {
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Select customer',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Walk-in Customer'),
              onTap: () {
                state.setCustomer(null);
                Navigator.pop(ctx);
              },
            ),
            ...state.customers.map((c) => ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(c.name),
                  subtitle: Text(c.phone),
                  onTap: () {
                    state.setCustomer(c);
                    Navigator.pop(ctx);
                  },
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final lines = state.cartLines;
    final methods = ['Cash', 'Card', 'Mobile Money']
        .where((m) => state.enabledMethods[m] ?? true)
        .toList();

    return Scaffold(
      appBar: simpleAppBar('New Sale'),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(state.selectedCustomer?.name ?? 'Walk-in Customer')),
                      TextButton(
                          onPressed: () => _pickCustomer(context, state),
                          child: const Text('Change')),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (lines.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: Text('Cart is empty')),
                  ),
                ...lines.map((l) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l.product.name,
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text(ugx(l.product.price), style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => state.changeQty(l.product, -1),
                          ),
                          Text('${l.qty}', style: const TextStyle(fontWeight: FontWeight.w700)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () {
                              if (l.qty >= l.product.stock) {
                                toast(context, 'No more stock available');
                              } else {
                                state.changeQty(l.product, 1);
                              }
                            },
                          ),
                          SizedBox(
                            width: 84,
                            child: Text(ugx(l.product.price * l.qty),
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    )),
                const Divider(height: 28),
                _row('Subtotal', ugx(state.subtotal)),
                _row('Tax (${(state.taxRate * 100).toStringAsFixed(0)}%)', ugx(state.tax)),
                const SizedBox(height: 4),
                _row('Total', ugx(state.total), bold: true),
                const SizedBox(height: 18),
                const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: methods
                      .map((m) => PillChip(
                            label: m,
                            selected: state.paymentMethod == m,
                            onTap: () => state.setPaymentMethod(m),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: PrimaryButton(
                label: 'Complete Sale',
                onPressed: lines.isEmpty
                    ? null
                    : () => Navigator.pushNamed(context, Routes.payment),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String a, String b, {bool bold = false}) {
    final s = TextStyle(
        fontSize: bold ? 16 : 13, fontWeight: bold ? FontWeight.w800 : FontWeight.w500);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(a, style: s), Text(b, style: s)],
      ),
    );
  }
}
