import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../routes.dart';
import '../services/app_state.dart';
import '../widgets/common.dart';

/// Screen 4 - Product / Item Selection
class ProductsScreen extends StatefulWidget {
  /// true when shown as a tab inside HomeScreen (no back arrow).
  final bool embedded;
  const ProductsScreen({super.key, this.embedded = false});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String _query = '';
  String _category = 'All';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final primary = Theme.of(context).colorScheme.primary;
    final cats = ['All', ...{...state.products.map((p) => p.category)}];
    final items = state.products
        .where((p) => _category == 'All' || p.category == _category)
        .where((p) => p.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: simpleAppBar('Products', back: !widget.embedded),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SearchField(
                hint: 'Search products...', onChanged: (v) => setState(() => _query = v)),
          ),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: cats.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) => PillChip(
                label: cats[i],
                selected: _category == cats[i],
                onTap: () => setState(() => _category = cats[i]),
              ),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('No products found'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final p = items[i];
                      final inCart = state.cart[p.id] ?? 0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.local_mall_outlined, color: primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.name,
                                      style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text(ugx(p.price), style: const TextStyle(fontSize: 12)),
                                  Text('Stock: ${p.stock}',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: p.isLow ? Colors.red : Colors.grey.shade600)),
                                ],
                              ),
                            ),
                            if (inCart > 0)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text('x$inCart',
                                    style: TextStyle(
                                        color: primary, fontWeight: FontWeight.w700)),
                              ),
                            IconButton.filled(
                              style: IconButton.styleFrom(backgroundColor: primary),
                              icon: const Icon(Icons.add, size: 18),
                              onPressed: () {
                                if (!state.addToCart(p)) {
                                  toast(context, 'Not enough stock for ${p.name}');
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          if (state.cartCount > 0)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: PrimaryButton(
                  icon: Icons.shopping_cart_checkout,
                  label: 'View Cart (${state.cartCount})  -  ${ugx(state.total)}',
                  onPressed: () => Navigator.pushNamed(context, Routes.checkout),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
