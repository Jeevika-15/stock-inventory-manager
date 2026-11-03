import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';

const Color bg = Color(0xFF0B1020);
const Color panel = Color(0xFF151D30);
const Color panel2 = Color(0xFF1D2940);
const Color teal = Color(0xFF36D6C3);
const Color muted = Color(0xFF94A3B8);

const List<String> categories = [
  'Electronics',
  'Stationery',
  'Hardware',
  'Grocery',
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const StockifyApp());
}

class StockifyApp extends StatelessWidget {
  const StockifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stockify',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.dark(primary: teal, surface: panel),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: panel2,
          labelStyle: const TextStyle(color: muted),
          hintStyle: const TextStyle(color: muted),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF29364E)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: teal, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
        ),
      ),
      home: const InventoryPage(),
    );
  }
}

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final CollectionReference<Map<String, dynamic>> stock = FirebaseFirestore
      .instance
      .collection('stockItems');

  final formKey = GlobalKey<FormState>();
  final skuController = TextEditingController();
  final nameController = TextEditingController();
  final quantityController = TextEditingController();
  final priceController = TextEditingController();
  final reorderController = TextEditingController();
  final searchController = TextEditingController();

  String? selectedCategory;
  String categoryFilter = 'All';
  bool lowStockOnly = false;
  bool ascending = true;
  bool saving = false;

  @override
  void dispose() {
    skuController.dispose();
    nameController.dispose();
    quantityController.dispose();
    priceController.dispose();
    reorderController.dispose();
    searchController.dispose();
    super.dispose();
  }

  String? validateSku(String? value) {
    final v = (value ?? '').trim();
    if (!RegExp(r'^STK-\d{3}$', caseSensitive: false).hasMatch(v)) {
      return 'Use format STK-101';
    }
    return null;
  }

  String? validateName(String? value) {
    if ((value ?? '').trim().length < 3) {
      return 'Enter at least 3 characters';
    }
    return null;
  }

  String? validateInteger(String? value, String label) {
    final number = int.tryParse((value ?? '').trim());
    if (number == null || number < 0) {
      return '$label must be a whole number 0 or above';
    }
    return null;
  }

  String? validatePrice(String? value) {
    final number = double.tryParse((value ?? '').trim());
    if (number == null || number <= 0) {
      return 'Enter a price greater than RM 0';
    }
    return null;
  }

  Future<void> saveItem() async {
    if (!formKey.currentState!.validate()) return;

    if (selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    setState(() => saving = true);

    try {
      await stock.add({
        'sku': skuController.text.trim().toUpperCase(),
        'itemName': nameController.text.trim(),
        'category': selectedCategory,
        'quantity': int.parse(quantityController.text.trim()),
        'unitPrice': double.parse(priceController.text.trim()),
        'reorderLevel': int.parse(reorderController.text.trim()),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      skuController.clear();
      nameController.clear();
      quantityController.clear();
      priceController.clear();
      reorderController.clear();

      setState(() {
        selectedCategory = null;
        saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stock item saved successfully!'),
          backgroundColor: Color(0xFF168C79),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Save failed: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void clearFilters() {
    searchController.clear();
    setState(() {
      categoryFilter = 'All';
      lowStockOnly = false;
      ascending = true;
    });
  }

  Widget sectionTitle(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: teal.withOpacity(0.12),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: teal, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(color: muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget statCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: const Color(0xFF26334B)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 21),
            const SizedBox(height: 13),
            Text(
              value,
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: muted, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: teal, size: 20),
      ),
    );
  }

  Widget addStockForm() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF29364E)),
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionTitle(
              'Add New Stock',
              'Enter the product details below',
              Icons.add_box_outlined,
            ),
            const SizedBox(height: 22),
            textField(
              controller: skuController,
              label: 'SKU (e.g. STK-101)',
              icon: Icons.qr_code_2,
              validator: validateSku,
            ),
            const SizedBox(height: 14),
            textField(
              controller: nameController,
              label: 'Item Name',
              icon: Icons.inventory_2_outlined,
              validator: validateName,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Select Category',
                prefixIcon: Icon(Icons.category_outlined, color: teal),
              ),
              items: categories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => selectedCategory = value);
              },
              validator: (value) =>
                  value == null ? 'Please select a category' : null,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: textField(
                    controller: quantityController,
                    label: 'Quantity',
                    icon: Icons.numbers,
                    keyboard: TextInputType.number,
                    validator: (v) => validateInteger(v, 'Quantity'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: textField(
                    controller: priceController,
                    label: 'Price (RM)',
                    icon: Icons.currency_exchange,
                    keyboard: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: validatePrice,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            textField(
              controller: reorderController,
              label: 'Reorder Level',
              icon: Icons.notifications_active_outlined,
              keyboard: TextInputType.number,
              validator: (v) => validateInteger(v, 'Reorder level'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 53,
              child: ElevatedButton.icon(
                onPressed: saving ? null : saveItem,
                icon: saving
                    ? const SizedBox(
                        height: 19,
                        width: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: bg,
                        ),
                      )
                    : const Icon(Icons.add_circle_outline),
                label: Text(
                  saving ? 'Saving...' : 'SAVE STOCK ITEM',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: teal,
                  foregroundColor: bg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget inventoryControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF29364E)),
      ),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search by item name or SKU...',
              prefixIcon: const Icon(Icons.search, color: teal),
              suffixIcon: IconButton(
                icon: const Icon(Icons.close, color: muted),
                onPressed: () {
                  searchController.clear();
                  setState(() {});
                },
              ),
            ),
          ),
          const SizedBox(height: 13),
          DropdownButtonFormField<String>(
            value: categoryFilter,
            decoration: const InputDecoration(
              labelText: 'Category Filter',
              prefixIcon: Icon(Icons.filter_list, color: teal),
            ),
            items: [
              'All',
              ...categories,
            ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => categoryFilter = v ?? 'All'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilterChip(
                  selected: lowStockOnly,
                  onSelected: (v) => setState(() => lowStockOnly = v),
                  avatar: const Icon(Icons.warning_amber, size: 18),
                  label: const Text('Low stock only'),
                  selectedColor: teal.withOpacity(0.22),
                  checkmarkColor: teal,
                  side: BorderSide.none,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: ascending
                    ? 'Sort quantity descending'
                    : 'Sort quantity ascending',
                onPressed: () => setState(() => ascending = !ascending),
                style: IconButton.styleFrom(
                  backgroundColor: panel2,
                  foregroundColor: teal,
                ),
                icon: Icon(
                  ascending ? Icons.arrow_upward : Icons.arrow_downward,
                ),
              ),
              Text(
                ascending ? 'Qty ↑' : 'Qty ↓',
                style: const TextStyle(color: muted, fontSize: 12),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: clearFilters,
              icon: const Icon(Icons.restart_alt, size: 18),
              label: const Text('Clear Filters'),
              style: TextButton.styleFrom(foregroundColor: teal),
            ),
          ),
        ],
      ),
    );
  }

  Widget inventoryItem(Map<String, dynamic> item) {
    final name = item['itemName']?.toString() ?? 'Unnamed item';
    final sku = item['sku']?.toString() ?? '';
    final category = item['category']?.toString() ?? '';
    final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
    final price = (item['unitPrice'] as num?)?.toDouble() ?? 0;
    final reorder = (item['reorderLevel'] as num?)?.toInt() ?? 0;
    final isLow = quantity <= reorder;
    final createdAt = item['createdAt'];

    String addedTime = 'Timestamp pending';

    if (createdAt is Timestamp) {
      final dateTime = createdAt.toDate().toLocal();

      final date =
          '${dateTime.day.toString().padLeft(2, '0')}/'
          '${dateTime.month.toString().padLeft(2, '0')}/'
          '${dateTime.year}';

      final time =
          '${dateTime.hour.toString().padLeft(2, '0')}:'
          '${dateTime.minute.toString().padLeft(2, '0')}';

      addedTime = 'Added on $date at $time';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isLow
              ? Colors.orangeAccent.withOpacity(0.45)
              : const Color(0xFF29364E),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: teal.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.inventory_2, color: teal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$sku  •  $category',
                      style: const TextStyle(color: muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 15, color: teal),
                  const SizedBox(width: 7),
                  Text(
                    addedTime,
                    style: const TextStyle(color: muted, fontSize: 11),
                  ),
                ],
              ),
              if (isLow)
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orangeAccent,
                ),
            ],
          ),
          const Divider(height: 25, color: Color(0xFF29364E)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              itemMetric('QUANTITY', '$quantity'),
              itemMetric('PRICE', 'RM ${price.toStringAsFixed(2)}'),
              itemMetric('REORDER', '$reorder'),
            ],
          ),
          if (isLow) ...[
            const SizedBox(height: 12),
            const Text(
              'LOW STOCK • Replenishment recommended',
              style: TextStyle(
                color: Colors.orangeAccent,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget itemMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: muted, fontSize: 10, letterSpacing: 1),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  Widget inventoryList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stock.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: panel,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Firestore error: ${snapshot.error}',
              style: const TextStyle(color: Colors.redAccent),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(35),
            child: Center(child: CircularProgressIndicator(color: teal)),
          );
        }

        final items = snapshot.data!.docs
            .map((doc) {
              return doc.data();
            })
            .where((item) {
              final keyword = searchController.text.trim().toLowerCase();
              final name = (item['itemName'] ?? '').toString().toLowerCase();
              final sku = (item['sku'] ?? '').toString().toLowerCase();
              final category = (item['category'] ?? '').toString();
              final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
              final reorder = (item['reorderLevel'] as num?)?.toInt() ?? 0;

              final keywordMatch =
                  keyword.isEmpty ||
                  name.contains(keyword) ||
                  sku.contains(keyword);
              final categoryMatch =
                  categoryFilter == 'All' || category == categoryFilter;
              final lowMatch = !lowStockOnly || quantity <= reorder;

              return keywordMatch && categoryMatch && lowMatch;
            })
            .toList();

        items.sort((a, b) {
          final qa = (a['quantity'] as num?)?.toInt() ?? 0;
          final qb = (b['quantity'] as num?)?.toInt() ?? 0;
          return ascending ? qa.compareTo(qb) : qb.compareTo(qa);
        });

        if (items.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: panel,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
              children: [
                Icon(Icons.search_off, color: muted, size: 42),
                SizedBox(height: 12),
                Text(
                  'No inventory items found',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Try changing your search or filters.',
                  style: TextStyle(color: muted, fontSize: 12),
                ),
              ],
            ),
          );
        }

        return Column(children: items.map(inventoryItem).toList());
      },
    );
  }

  Widget dashboardStats() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stock.snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final totalProducts = docs.length;
        int totalQuantity = 0;
        int lowCount = 0;

        for (final doc in docs) {
          final data = doc.data();
          final qty = (data['quantity'] as num?)?.toInt() ?? 0;
          final reorder = (data['reorderLevel'] as num?)?.toInt() ?? 0;
          totalQuantity += qty;
          if (qty <= reorder) lowCount++;
        }

        return Row(
          children: [
            statCard(
              'Products',
              '$totalProducts',
              Icons.inventory_2_outlined,
              teal,
            ),
            const SizedBox(width: 10),
            statCard(
              'Total Units',
              '$totalQuantity',
              Icons.stacked_bar_chart,
              Colors.blueAccent,
            ),
            const SizedBox(width: 10),
            statCard(
              'Low Stock',
              '$lowCount',
              Icons.warning_amber_rounded,
              Colors.orangeAccent,
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 15, 18, 30),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: teal.withOpacity(0.13),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.widgets_rounded,
                          color: teal,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'STOCKIFY',
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                            Text(
                              'SMART INVENTORY MANAGEMENT',
                              style: TextStyle(
                                fontSize: 9,
                                color: muted,
                                letterSpacing: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.cloud_done, color: teal, size: 23),
                    ],
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    'Inventory Overview',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Monitor your stock in real time.',
                    style: TextStyle(color: muted),
                  ),
                  const SizedBox(height: 18),
                  dashboardStats(),
                  const SizedBox(height: 28),
                  addStockForm(),
                  const SizedBox(height: 28),
                  sectionTitle(
                    'Inventory Records',
                    'Your saved Firestore stock items',
                    Icons.view_list_rounded,
                  ),
                  const SizedBox(height: 16),
                  inventoryControls(),
                  const SizedBox(height: 18),
                  inventoryList(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
