import 'package:flutter/material.dart';

void main() {
  runApp(const MadinaTentServiceApp());
}

class MadinaTentServiceApp extends StatelessWidget {
  const MadinaTentServiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'مدینہ ٹینٹ سروس',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'sans',
        colorSchemeSeed: const Color(0xFF0B6B45),
      ),
      home: const HomePage(),
    );
  }
}

class RentalItem {
  final String name;
  final int price;
  int available;
  int selected;

  RentalItem(this.name, this.price, this.available, {this.selected = 0});
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<RentalItem> items = [
    RentalItem('ٹینٹ', 100, 100),
    RentalItem('کرسی', 100, 500),
    RentalItem('میز', 100, 500),
    RentalItem('پلیٹ', 5, 1000),
    RentalItem('جگ', 10, 500),
    RentalItem('دیگ', 200, 15),
    RentalItem('دری', 25, 200),
    RentalItem('دستر خوان', 20, 100),
    RentalItem('پنکھا', 50, 50),
    RentalItem('لائٹ', 50, 100),
  ];

  int get total {
    return items.fold(0, (sum, item) => sum + item.selected * item.price);
  }

  int get selectedCount {
    return items.fold(0, (sum, item) => sum + item.selected);
  }

  void changeQty(RentalItem item, int delta) {
    setState(() {
      final next = item.selected + delta;
      if (next >= 0 && next <= item.available) {
        item.selected = next;
      }
    });
  }

  void openRental() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RentalPage(
          items: items,
          onChanged: () => setState(() {}),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مدینہ ٹینٹ سروس',
              style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    const Icon(Icons.storefront, size: 48),
                    const SizedBox(height: 8),
                    const Text('کرایہ کا سامان',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('$selectedCount اشیاء منتخب • کل رقم: Rs. $total'),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: openRental,
                      icon: const Icon(Icons.receipt_long),
                      label: const Text('کرایہ بنائیں'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text('سامان کی فہرست',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...items.map(
              (item) => Card(
                child: ListTile(
                  title: Text(item.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      'کرایہ: Rs. ${item.price}  •  دستیاب: ${item.available}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: item.selected > 0
                            ? () => changeQty(item, -1)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      SizedBox(
                        width: 28,
                        child: Text('${item.selected}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 17)),
                      ),
                      IconButton(
                        onPressed: item.selected < item.available
                            ? () => changeQty(item, 1)
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text('سادہ، تیز اور رسید کے بغیر کرایہ مینجمنٹ',
                  style: TextStyle(fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}

class RentalPage extends StatelessWidget {
  final List<RentalItem> items;
  final VoidCallback onChanged;

  const RentalPage({
    super.key,
    required this.items,
    required this.onChanged,
  });

  int get total =>
      items.fold(0, (sum, item) => sum + item.selected * item.price);

  @override
  Widget build(BuildContext context) {
    final selected = items.where((e) => e.selected > 0).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('کرایہ کی تفصیل')),
        body: selected.isEmpty
            ? const Center(child: Text('ابھی کوئی سامان منتخب نہیں کیا گیا۔'))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ...selected.map(
                    (item) => Card(
                      child: ListTile(
                        title: Text(item.name),
                        subtitle: Text(
                            '${item.selected} × Rs. ${item.price} = Rs. ${item.selected * item.price}'),
                        trailing: Text('Rs. ${item.selected * item.price}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('کل کرایہ',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          Text('Rs. $total',
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () {
                      for (final item in items) {
                        item.selected = 0;
                      }
                      onChanged();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.clear_all),
                    label: const Text('سب صاف کریں'),
                  ),
                ],
              ),
      ),
    );
  }
}
