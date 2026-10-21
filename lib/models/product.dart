class Product {
  final String id;
  String name;
  double price;
  int stock;
  int reorder;
  String category;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.reorder,
    required this.category,
  });

  bool get isLow => stock <= reorder;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'stock': stock,
        'reorder': reorder,
        'category': category,
      };

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: j['id'] as String,
        name: j['name'] as String,
        price: (j['price'] as num).toDouble(),
        stock: j['stock'] as int,
        reorder: j['reorder'] as int,
        category: j['category'] as String,
      );
}
