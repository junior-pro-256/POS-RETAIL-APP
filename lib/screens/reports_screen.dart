import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../widgets/common.dart';

/// Screen 9 - Reports & Analytics (live: recalculated whenever a sale is made)
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _section = 0; // Sales / Inventory / Customers
  int _range = 0; // 7 days / 30 days / custom
  DateTimeRange? _custom;

  DateTimeRange get _dates {
    final today = DateTime.now();
    if (_range == 2 && _custom != null) return _custom!;
    final days = _range == 1 ? 29 : 6;
    return DateTimeRange(start: today.subtract(Duration(days: days)), end: today);
  }

  Future<void> _pickCustom() async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dates,
    );
    if (r != null) {
      setState(() {
      _custom = r;
      _range = 2;
    });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final primary = Theme.of(context).colorScheme.primary;
    final r = _dates;

    return Scaffold(
      appBar: simpleAppBar('Reports'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            PillChip(label: 'Sales', selected: _section == 0, onTap: () => setState(() => _section = 0)),
            const SizedBox(width: 8),
            PillChip(label: 'Inventory', selected: _section == 1, onTap: () => setState(() => _section = 1)),
            const SizedBox(width: 8),
            PillChip(label: 'Customers', selected: _section == 2, onTap: () => setState(() => _section = 2)),
          ]),
          const SizedBox(height: 12),
          if (_section == 0) ..._sales(state, primary, r),
          if (_section == 1) ..._inventory(state),
          if (_section == 2) ..._customers(state),
        ],
      ),
    );
  }

  List<Widget> _sales(AppState state, Color primary, DateTimeRange r) {
    final totals = state.dailyTotals(r.start, r.end);
    final labels = List.generate(totals.length, (i) {
      final d = DateTime(r.start.year, r.start.month, r.start.day).add(Duration(days: i));
      return '${d.day}/${d.month}';
    });
    final total = state.totalBetween(r.start, r.end);

    return [
      Row(children: [
        PillChip(label: '7 Days', selected: _range == 0, onTap: () => setState(() => _range = 0)),
        const SizedBox(width: 8),
        PillChip(label: '30 Days', selected: _range == 1, onTap: () => setState(() => _range = 1)),
        const SizedBox(width: 8),
        PillChip(label: 'Custom', selected: _range == 2, onTap: _pickCustom),
      ]),
      const SizedBox(height: 12),
      _card(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total Sales', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          const SizedBox(height: 2),
          Text(ugx(total), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          Text('${state.salesBetween(r.start, r.end).length} transactions',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ],
      )),
      const SizedBox(height: 12),
      const Text('Sales Trend', style: TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      _card(SizedBox(
        height: 170,
        child: CustomPaint(
          size: Size.infinite,
          painter: _TrendPainter(totals, labels, primary),
        ),
      )),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.star_outline),
            label: const Text('Top Products'),
            onPressed: () => _sheet('Top Products', state.topProducts(r.start, r.end).entries
                .map((e) => '${e.key}  -  ${e.value} sold')
                .toList()),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.payments_outlined),
            label: const Text('Payment Methods'),
            onPressed: () => _sheet('Payment Methods', state.paymentBreakdown(r.start, r.end).entries
                .map((e) => '${methodLabel(e.key)}  -  ${ugx(e.value)}')
                .toList()),
          ),
        ),
      ]),
    ];
  }

  List<Widget> _inventory(AppState state) => [
        _card(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Stock value', style: TextStyle(fontSize: 12)),
            Text(ugx(state.stockValue),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('${state.products.length} products, ${state.lowStock.length} low on stock'),
          ],
        )),
        const SizedBox(height: 12),
        ...state.lowStock.map((p) => ListTile(
              dense: true,
              leading: const Icon(Icons.warning_amber, color: Colors.red),
              title: Text(p.name),
              subtitle: Text('Stock ${p.stock} (reorder at ${p.reorder})'),
            )),
      ];

  List<Widget> _customers(AppState state) {
    final ranked = [...state.customers]
      ..sort((a, b) => state.spentBy(b).compareTo(state.spentBy(a)));
    return [
      _card(Text('${state.customers.length} customers',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
      const SizedBox(height: 12),
      const Text('Top spenders', style: TextStyle(fontWeight: FontWeight.w700)),
      ...ranked.take(5).map((c) => ListTile(
            dense: true,
            leading: const Icon(Icons.person_outline),
            title: Text(c.name),
            trailing: Text(ugx(state.spentBy(c))),
          )),
    ];
  }

  Widget _card(Widget child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: child,
      );

  void _sheet(String title, List<String> rows) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              if (rows.isEmpty) const Text('No data for this period'),
              ...rows.map((t) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(t),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final Color color;

  _TrendPainter(this.values, this.labels, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    const left = 4.0, bottom = 18.0, top = 8.0;
    final h = size.height - bottom - top;
    final w = size.width - left - 8;
    final maxV = values.fold<double>(1, (a, b) => b > a ? b : a);

    final grid = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = top + h * i / 3;
      canvas.drawLine(Offset(left, y), Offset(size.width, y), grid);
    }

    Offset pt(int i) {
      final x = values.length == 1 ? left + w / 2 : left + w * i / (values.length - 1);
      final y = top + h - (values[i] / maxV) * h;
      return Offset(x, y);
    }

    final path = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (var i = 1; i < values.length; i++) {
      path.lineTo(pt(i).dx, pt(i).dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );
    final dot = Paint()..color = color;
    final step = (values.length / 7).ceil();
    for (var i = 0; i < values.length; i++) {
      if (values.length <= 31) canvas.drawCircle(pt(i), 3, dot);
      if (i % step == 0) {
        final tp = TextPainter(
          text: TextSpan(text: labels[i], style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(pt(i).dx - tp.width / 2, size.height - 12));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) =>
      old.values != values || old.color != color;
}
