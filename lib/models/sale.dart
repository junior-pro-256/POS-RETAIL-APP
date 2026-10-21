class SaleItem {
  final String productId;
  final String name;
  final double price;
  final int qty;

  const SaleItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.qty,
  });

  double get total => price * qty;

  Map<String, dynamic> toJson() =>
      {'productId': productId, 'name': name, 'price': price, 'qty': qty};

  factory SaleItem.fromJson(Map<String, dynamic> j) => SaleItem(
        productId: j['productId'] as String,
        name: j['name'] as String,
        price: (j['price'] as num).toDouble(),
        qty: j['qty'] as int,
      );
}

class Sale {
  final String id;
  final DateTime date;
  final List<SaleItem> items;
  final String customer;
  final String method;
  final double subtotal;
  final double tax;
  final double total;

  /// false while the sale only exists on the device (made offline).
  bool synced;

  Sale({
    required this.id,
    required this.date,
    required this.items,
    required this.customer,
    required this.method,
    required this.subtotal,
    required this.tax,
    required this.total,
    this.synced = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'items': items.map((e) => e.toJson()).toList(),
        'customer': customer,
        'method': method,
        'subtotal': subtotal,
        'tax': tax,
        'total': total,
        'synced': synced,
      };

  factory Sale.fromJson(Map<String, dynamic> j) => Sale(
        id: j['id'] as String,
        date: DateTime.parse(j['date'] as String),
        items: (j['items'] as List)
            .map((e) => SaleItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        customer: j['customer'] as String,
        method: j['method'] as String,
        subtotal: (j['subtotal'] as num).toDouble(),
        tax: (j['tax'] as num).toDouble(),
        total: (j['total'] as num).toDouble(),
        synced: j['synced'] as bool? ?? true,
      );
}
