import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../services/app_state.dart';
import '../widgets/common.dart';

/// Screen 7 - Inventory Management
class InventoryScreen extends StatefulWidget {
  final bool embedded;
  const InventoryScreen({super.key, this.embedded = false});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  int _tab = 0; // 0 Stock, 1 Low Stock, 2 Categories
  String _query = '';

  Future<void> _addProduct(AppState state) async {
    final name = TextEditingController();
    final price = TextEditingController();
    final stock = TextEditingController();
    final reorder = TextEditingController(text: '${state.defaultReorder}');
    final catCtrl = TextEditingController(text: 'Beverages');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
              TextField(
                  controller: price,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Price (UGX)')),
              TextField(
                  controller: stock,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Opening stock')),
              TextField(
                  controller: reorder,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Reorder level')),
              TextField(
                  controller: catCtrl,
                  decoration: const InputDecoration(labelText: 'Category')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final p = double.tryParse(price.text);
              final s = int.tryParse(stock.text);
              if (name.text.trim().isEmpty || p == null || s == null) {
                toast(ctx, 'Enter a name, price and stock');
                return;
              }
              state.addProduct(name.text.trim(), p, s,
                  int.tryParse(reorder.text) ?? state.defaultReorder,
                  catCtrl.text.trim().isEmpty ? 'General' : catCtrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _editStock(AppState state, Product p) async {
    final stock = TextEditingController(text: '${p.stock}');
    final reorder = TextEditingController(text: '${p.reorder}');
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(p.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: stock,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Stock level')),
            TextField(
                controller: reorder,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Reorder level')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              state.updateStock(p, int.tryParse(stock.text) ?? p.stock,
                  int.tryParse(reorder.text) ?? p.reorder);
              Navigator.pop(ctx);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final primary = Theme.of(context).colorScheme.primary;

    Widget body;
    if (_tab == 2) {
      final cats = <String, List<Product>>{};
      for (final p in state.products) {
        cats.putIfAbsent(p.category, () => []).add(p);
      }
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: cats.entries
            .map((e) => Card(
                  child: ListTile(
                    leading: Icon(Icons.category_outlined, color: primary),
                    title: Text(e.key),
                    subtitle: Text('${e.value.length} product(s)'),
                    trailing: Text(
                        '${e.value.fold<int>(0, (a, p) => a + p.stock)} units'),
                  ),
                ))
            .toList(),
      );
    } else {
      final items = state.products
          .where((p) => _tab == 0 || p.isLow)
          .where((p) => p.name.toLowerCase().contains(_query.toLowerCase()))
          .toList();
      body = items.isEmpty
          ? Center(child: Text(_tab == 1 ? 'Nothing is low on stock' : 'No items'))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final p = items[i];
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.inventory_2_outlined, color: primary, size: 20),
                  ),
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Stock: ${p.stock}   Reorder: ${p.reorder}',
                      style: TextStyle(color: p.isLow ? Colors.red : null, fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _editStock(state, p),
                );
              },
            );
    }

    return Scaffold(
      appBar: simpleAppBar('Inventory', back: !widget.embedded),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        onPressed: () => _addProduct(state),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                PillChip(label: 'Stock', selected: _tab == 0, onTap: () => setState(() => _tab = 0)),
                const SizedBox(width: 8),
                PillChip(
                    label: 'Low Stock (${state.lowStock.length})',
                    selected: _tab == 1,
                    onTap: () => setState(() => _tab = 1)),
                const SizedBox(width: 8),
                PillChip(label: 'Categories', selected: _tab == 2, onTap: () => setState(() => _tab = 2)),
              ],
            ),
          ),
          if (_tab != 2)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SearchField(
                  hint: 'Search inventory...', onChanged: (v) => setState(() => _query = v)),
            ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
