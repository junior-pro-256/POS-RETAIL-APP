import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/customer.dart';
import '../models/product.dart';
import '../models/sale.dart';

class CartLine {
  final Product product;
  final int qty;
  const CartLine(this.product, this.qty);
}

/// Single source of truth for the app. Everything is persisted locally in
/// SharedPreferences, so the app keeps working with no internet connection.
class AppState extends ChangeNotifier {
  static const _salt = 'pos_retail_pro_v1';

  SharedPreferences? _prefs;
  StreamSubscription? _connSub;

  // ---- data ----
  List<Product> products = [];
  List<Customer> customers = [];
  List<Sale> sales = [];

  // ---- current sale ----
  final Map<String, int> cart = {};
  Customer? selectedCustomer; // null = walk-in customer
  String paymentMethod = 'Cash';

  // ---- business / account ----
  String businessName = 'My Store';
  String businessType = 'Retail Store';
  String ownerName = 'Business Owner';
  String account = 'owner@business.com';
  String _passwordHash = _hash('password123');
  int themeColor = 0xFF1E6FE0;
  double taxRate = 0.18;
  int defaultReorder = 20;
  Map<String, bool> enabledMethods = {
    'Cash': true,
    'Card': true,
    'Mobile Money': true,
    'Bank Transfer': true,
  };

  // ---- session / connectivity ----
  bool loggedIn = false;
  bool forceOffline = false;
  bool networkOnline = true;

  bool get isOnline => networkOnline && !forceOffline;
  Color get primary => Color(themeColor);

  static String _hash(String pw) =>
      sha256.convert(utf8.encode('$_salt:$pw')).toString();

  
  // Load / save
  
  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;

    final pj = p.getString('products');
    if (pj == null) {
      _seed();
    } else {
      products = (jsonDecode(pj) as List)
          .map((e) => Product.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      customers = (jsonDecode(p.getString('customers') ?? '[]') as List)
          .map((e) => Customer.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      sales = (jsonDecode(p.getString('sales') ?? '[]') as List)
          .map((e) => Sale.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    businessName = p.getString('businessName') ?? businessName;
    businessType = p.getString('businessType') ?? businessType;
    ownerName = p.getString('ownerName') ?? ownerName;
    account = p.getString('account') ?? account;
    _passwordHash = p.getString('passwordHash') ?? _passwordHash;
    themeColor = p.getInt('themeColor') ?? themeColor;
    taxRate = p.getDouble('taxRate') ?? taxRate;
    defaultReorder = p.getInt('defaultReorder') ?? defaultReorder;
    loggedIn = p.getBool('loggedIn') ?? false;
    final em = p.getString('enabledMethods');
    if (em != null) {
      enabledMethods = Map<String, bool>.from(jsonDecode(em) as Map);
    }

    // Watch connectivity; when we come back online, mark offline sales synced.
    final first = await Connectivity().checkConnectivity();
    networkOnline = !first.contains(ConnectivityResult.none);
    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      networkOnline = !results.contains(ConnectivityResult.none);
      if (isOnline) _syncPending();
      notifyListeners();
    });
  }

  void _seed() {
    products = [
      Product(id: 'p1', name: 'Coca Cola 500ml', price: 2500, stock: 50, reorder: 20, category: 'Beverages'),
      Product(id: 'p2', name: 'Sprite 500ml', price: 2500, stock: 40, reorder: 20, category: 'Beverages'),
      Product(id: 'p3', name: 'Water 500ml', price: 1500, stock: 100, reorder: 30, category: 'Beverages'),
      Product(id: 'p4', name: 'Bread', price: 3000, stock: 30, reorder: 10, category: 'Groceries'),
      Product(id: 'p5', name: 'Chips', price: 2000, stock: 45, reorder: 15, category: 'Snacks'),
    ];
    customers = [
      Customer(id: 'c1', name: 'John Mwangi', phone: '+256 700 123 456'),
      Customer(id: 'c2', name: 'Sarah Nakato', phone: '+256 782 987 654'),
      Customer(id: 'c3', name: 'David Kato', phone: '+256 703 456 789'),
      Customer(id: 'c4', name: 'Aisha Namuindwa', phone: '+256 751 234 567'),
      Customer(id: 'c5', name: 'Peter Ssemanda', phone: '+256 787 654 321'),
    ];
    // A little history so the reports screen has something to show.
    final now = DateTime.now();
    const methods = ['Cash', 'Card', 'Mobile Money'];
    for (var d = 9; d >= 0; d--) {
      final p = products[d % products.length];
      final qty = 8 + (d * 7) % 15;
      final sub = p.price * qty;
      sales.add(Sale(
        id: 'seed$d',
        date: DateTime(now.year, now.month, now.day, 10, 15).subtract(Duration(days: d)),
        items: [SaleItem(productId: p.id, name: p.name, price: p.price, qty: qty)],
        customer: 'Walk-in Customer',
        method: methods[d % 3],
        subtotal: sub,
        tax: sub * taxRate,
        total: sub * (1 + taxRate),
      ));
    }
    _save();
  }

  Future<void> _save() async {
    final p = _prefs;
    if (p == null) return;
    await p.setString('products', jsonEncode(products.map((e) => e.toJson()).toList()));
    await p.setString('customers', jsonEncode(customers.map((e) => e.toJson()).toList()));
    await p.setString('sales', jsonEncode(sales.map((e) => e.toJson()).toList()));
    await p.setString('businessName', businessName);
    await p.setString('businessType', businessType);
    await p.setString('ownerName', ownerName);
    await p.setString('account', account);
    await p.setString('passwordHash', _passwordHash);
    await p.setInt('themeColor', themeColor);
    await p.setDouble('taxRate', taxRate);
    await p.setInt('defaultReorder', defaultReorder);
    await p.setBool('loggedIn', loggedIn);
    await p.setString('enabledMethods', jsonEncode(enabledMethods));
  }

  void _syncPending() {
    // Placeholder for uploading to a backend: here we just flag as synced.
    var changed = false;
    for (final s in sales) {
      if (!s.synced) {
        s.synced = true;
        changed = true;
      }
    }
    if (changed) _save();
  }

  int get pendingSyncCount => sales.where((s) => !s.synced).length;

  @override
  void dispose() {
    _connSub?.cancel();
    super.dispose();
  }


  // Auth (local only - see README for production hardening)
  
  bool login(String id, String pw, {required bool remember}) {
    if (id.trim().toLowerCase() == account.toLowerCase() &&
        _hash(pw) == _passwordHash) {
      loggedIn = remember;
      _save();
      notifyListeners();
      return true;
    }
    return false;
  }

  void signUp(String name, String id, String pw) {
    ownerName = name;
    account = id.trim();
    _passwordHash = _hash(pw);
    loggedIn = true;
    _save();
    notifyListeners();
  }

  void logout() {
    loggedIn = false;
    cart.clear();
    _save();
    notifyListeners();
  }

  // Cart / sale
  
  List<CartLine> get cartLines {
    final out = <CartLine>[];
    cart.forEach((id, q) {
      final i = products.indexWhere((p) => p.id == id);
      if (i >= 0) out.add(CartLine(products[i], q));
    });
    return out;
  }

  int get cartCount => cart.values.fold(0, (a, b) => a + b);
  double get subtotal => cartLines.fold(0.0, (a, l) => a + l.product.price * l.qty);
  double get tax => subtotal * taxRate;
  double get total => subtotal + tax;

  /// Returns false when there isn't enough stock.
  bool addToCart(Product p) {
    final cur = cart[p.id] ?? 0;
    if (cur + 1 > p.stock) return false;
    cart[p.id] = cur + 1;
    notifyListeners();
    return true;
  }

  void changeQty(Product p, int delta) {
    final next = (cart[p.id] ?? 0) + delta;
    if (next <= 0) {
      cart.remove(p.id);
    } else if (next <= p.stock) {
      cart[p.id] = next;
    }
    notifyListeners();
  }

  void setCustomer(Customer? c) {
    selectedCustomer = c;
    notifyListeners();
  }

  void setPaymentMethod(String m) {
    paymentMethod = m;
    notifyListeners();
  }

  Sale completeSale() {
    final lines = cartLines;
    final sale = Sale(
      id: 'S${DateTime.now().millisecondsSinceEpoch}',
      date: DateTime.now(),
      items: lines
          .map((l) => SaleItem(
                productId: l.product.id,
                name: l.product.name,
                price: l.product.price,
                qty: l.qty,
              ))
          .toList(),
      customer: selectedCustomer?.name ?? 'Walk-in Customer',
      method: paymentMethod,
      subtotal: subtotal,
      tax: tax,
      total: total,
      synced: isOnline,
    );
    for (final l in lines) {
      l.product.stock -= l.qty;
    }
    sales.add(sale);
    cart.clear();
    selectedCustomer = null;
    _save();
    notifyListeners();
    return sale;
  }


  // Inventory / customers
  
  void addProduct(String name, double price, int stock, int reorder, String category) {
    products.add(Product(
      id: 'p${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      price: price,
      stock: stock,
      reorder: reorder,
      category: category,
    ));
    _save();
    notifyListeners();
  }

  void updateStock(Product p, int stock, int reorder) {
    p.stock = stock;
    p.reorder = reorder;
    _save();
    notifyListeners();
  }

  void addCustomer(String name, String phone) {
    customers.add(Customer(
      id: 'c${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      phone: phone,
    ));
    _save();
    notifyListeners();
  }

  double spentBy(Customer c) =>
      sales.where((s) => s.customer == c.name).fold(0.0, (a, s) => a + s.total);
  int visitsBy(Customer c) => sales.where((s) => s.customer == c.name).length;

  // Settings
  
  void updateBusiness({String? name, String? type, int? color}) {
    if (name != null) businessName = name;
    if (type != null) businessType = type;
    if (color != null) themeColor = color;
    _save();
    notifyListeners();
  }

  void setTaxRate(double r) {
    taxRate = r;
    _save();
    notifyListeners();
  }

  void setDefaultReorder(int n) {
    defaultReorder = n;
    _save();
    notifyListeners();
  }

  void toggleMethod(String m, bool on) {
    enabledMethods[m] = on;
    if (!on && paymentMethod == m) {
      paymentMethod = enabledMethods.entries
          .firstWhere((e) => e.value, orElse: () => const MapEntry('Cash', true))
          .key;
    }
    _save();
    notifyListeners();
  }

  void setForceOffline(bool v) {
    forceOffline = v;
    if (isOnline) _syncPending();
    notifyListeners();
  }

  Future<void> resetData() async {
    await _prefs?.clear();
    cart.clear();
    sales = [];
    products = [];
    customers = [];
    businessName = 'My Store';
    loggedIn = false;
    _seed();
    notifyListeners();
  }

  // =====================================================================
  // Reports (computed live from the local sales list)
  // =====================================================================
  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  List<Sale> salesBetween(DateTime from, DateTime to) {
    final a = _day(from);
    final b = _day(to).add(const Duration(days: 1));
    return sales.where((s) => !s.date.isBefore(a) && s.date.isBefore(b)).toList();
  }

  double totalBetween(DateTime from, DateTime to) =>
      salesBetween(from, to).fold(0.0, (a, s) => a + s.total);

  List<double> dailyTotals(DateTime from, DateTime to) {
    final a = _day(from);
    final days = _day(to).difference(a).inDays + 1;
    final out = List<double>.filled(days < 1 ? 1 : days, 0);
    for (final s in salesBetween(from, to)) {
      final i = _day(s.date).difference(a).inDays;
      if (i >= 0 && i < out.length) out[i] += s.total;
    }
    return out;
  }

  Map<String, int> topProducts(DateTime from, DateTime to) {
    final m = <String, int>{};
    for (final s in salesBetween(from, to)) {
      for (final i in s.items) {
        m[i.name] = (m[i.name] ?? 0) + i.qty;
      }
    }
    final entries = m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return {for (final e in entries) e.key: e.value};
  }

  Map<String, double> paymentBreakdown(DateTime from, DateTime to) {
    final m = <String, double>{};
    for (final s in salesBetween(from, to)) {
      m[s.method] = (m[s.method] ?? 0) + s.total;
    }
    return m;
  }

  double get todaySales {
    final n = DateTime.now();
    return totalBetween(n, n);
  }

  double get todayChangePercent {
    final n = DateTime.now();
    final y = n.subtract(const Duration(days: 1));
    final yt = totalBetween(y, y);
    if (yt == 0) return 0;
    return (todaySales - yt) / yt * 100;
  }

  List<Sale> get recentSales {
    final l = [...sales]..sort((a, b) => b.date.compareTo(a.date));
    return l.take(3).toList();
  }

  double get stockValue => products.fold(0.0, (a, p) => a + p.price * p.stock);
  List<Product> get lowStock => products.where((p) => p.isLow).toList();
}
