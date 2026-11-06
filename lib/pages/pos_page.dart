import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../money_format.dart';
import '../pos_data.dart';
import '../theme/app_theme.dart';

class PosPage extends StatefulWidget {
  const PosPage({super.key});

  @override
  State<PosPage> createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> {
  final _search = TextEditingController();
  final _cart = <String, double>{};
  String _query = '';
  String _category = 'Semua';

  static const _categories = <String, IconData>{
    'Semua': Icons.apps_rounded,
    'Domba': Icons.pets_rounded,
    'Iga': Icons.set_meal_rounded,
    'Paket': Icons.inventory_2_rounded,
  };

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  double _cartTotal(List<Map<String, dynamic>> products) {
    var total = 0.0;
    for (final entry in _cart.entries) {
      final matches = products.where((product) => product['id'] == entry.key);
      if (matches.isEmpty) continue;
      total += ((matches.first['hargaPerKg'] as num).toDouble() * entry.value)
          .roundToDouble();
    }
    return total;
  }

  String _money(num value) {
    final grouped = value.round().toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return 'Rp $grouped';
  }

  void _addToCart(Map<String, dynamic> product) {
    final id = '${product['id']}';
    final current = _cart[id] ?? 0;
    final stock = (product['stokKg'] as num).toDouble();
    if (current >= stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stok ${product['nama']} tidak mencukupi.')),
      );
      return;
    }
    setState(() => _cart[id] = (current + 0.25).clamp(0, stock).toDouble());
  }

  Future<void> _manageProduct({Map<String, dynamic>? product}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _ProductFormDialog(product: product),
    );
    if (saved == true && mounted) setState(() {});
  }

  Future<void> _restock(Map<String, dynamic> product) async {
    final quantity = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Tambah stok ${product['nama']}'),
        content: TextField(
          controller: quantity,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Jumlah tambahan (kg)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              double.tryParse(quantity.text.trim().replaceAll(',', '.')),
            ),
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
    quantity.dispose();
    if (amount == null || !mounted) return;
    try {
      await PosData.addStock('${product['id']}', amount);
      setState(() {});
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Stok gagal ditambah: $error')));
      }
    }
  }

  Future<void> _productMenu(String action, Map<String, dynamic> product) async {
    if (action == 'edit') {
      await _manageProduct(product: product);
    } else if (action == 'restock') {
      await _restock(product);
    } else if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Nonaktifkan produk?'),
          content: Text('${product['nama']} tidak akan bisa dijual lagi.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Nonaktifkan'),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await PosData.deleteProduct('${product['id']}');
        if (mounted) setState(() => _cart.remove('${product['id']}'));
      }
    }
  }

  Future<void> _openCart(List<Map<String, dynamic>> products) async {
    if (_cart.isEmpty) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, updateSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keranjang',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final entry in _cart.entries.toList())
                        Builder(
                          builder: (context) {
                            final product = products.firstWhere(
                              (item) => item['id'] == entry.key,
                            );
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text('${product['nama']}'),
                              subtitle: Text(
                                '${_money(product['hargaPerKg'] as num)}/kg · '
                                '${_money(((product['hargaPerKg'] as num) * entry.value).round())}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      final next = entry.value - 0.25;
                                      setState(() {
                                        if (next <= 0) {
                                          _cart.remove(entry.key);
                                        } else {
                                          _cart[entry.key] = next;
                                        }
                                      });
                                      updateSheet(() {});
                                    },
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                    ),
                                  ),
                                  Text('${entry.value.toStringAsFixed(2)} kg'),
                                  IconButton(
                                    onPressed: () {
                                      final stock = (product['stokKg'] as num)
                                          .toDouble();
                                      if (entry.value >= stock) return;
                                      setState(
                                        () => _cart[entry.key] =
                                            (entry.value + 0.25)
                                                .clamp(0, stock)
                                                .toDouble(),
                                      );
                                      updateSheet(() {});
                                    },
                                    icon: const Icon(Icons.add_circle_outline),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _money(_cartTotal(products)),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final checkoutItems = products
                          .where((product) => _cart.containsKey(product['id']))
                          .map(
                            (product) => {
                              ...product,
                              'beratKg': _cart['${product['id']}'],
                            },
                          )
                          .toList();
                      Navigator.pop(sheetContext);
                      final completed = await Navigator.push<bool>(
                        this.context,
                        MaterialPageRoute(
                          builder: (_) => PosCheckoutPage(
                            items: checkoutItems,
                            quantitiesKg: Map<String, double>.from(_cart),
                          ),
                        ),
                      );
                      if (completed == true && mounted) {
                        setState(_cart.clear);
                      }
                    },
                    icon: const Icon(Icons.payment),
                    label: const Text('Lanjut pembayaran'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.warmCream,
    appBar: AppBar(
      title: const Text('Ngapak Ngapiki Farm · POS'),
      actions: [
        if (PosData.isOwner)
          Tooltip(
            message: 'Tambah produk',
            child: TextButton.icon(
              onPressed: () => _manageProduct(),
              icon: const Icon(Icons.add),
              label: const Text('Tambah produk'),
            ),
          ),
        const SizedBox(width: 12),
      ],
    ),
    body: ValueListenableBuilder(
      valueListenable: PosData.products.listenable(),
      builder: (context, _, _) {
        final all = PosData.productList();
        final shown = all.where((product) {
          final value = '${product['nama']} ${product['deskripsi']}'
              .toLowerCase();
          return value.contains(_query) &&
              (_category == 'Semua' || value.contains(_category.toLowerCase()));
        }).toList();
        final desktop = MediaQuery.sizeOf(context).width >= 1000;
        final catalog = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _panel(
              'Kategori',
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.entries.map((entry) {
                  final count = entry.key == 'Semua'
                      ? all.length
                      : all
                            .where(
                              (p) => '${p['nama']} ${p['deskripsi']}'
                                  .toLowerCase()
                                  .contains(entry.key.toLowerCase()),
                            )
                            .length;
                  return ChoiceChip(
                    avatar: Icon(entry.value, size: 18),
                    label: Text('${entry.key} · $count'),
                    selected: _category == entry.key,
                    onSelected: (_) => setState(() => _category = entry.key),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),
            _panel(
              'Daftar Produk',
              Column(
                children: [
                  TextField(
                    controller: _search,
                    onChanged: (value) =>
                        setState(() => _query = value.trim().toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Cari produk...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: AppTheme.warmCream,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (shown.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        all.isEmpty
                            ? 'Belum ada produk daging.'
                            : 'Produk tidak ditemukan.',
                      ),
                    )
                  else
                    LayoutBuilder(
                      builder: (context, size) {
                        final columns = size.maxWidth >= 850
                            ? 4
                            : size.maxWidth >= 540
                            ? 3
                            : size.maxWidth >= 350
                            ? 2
                            : 1;
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: shown.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: columns == 1 ? 2.8 : .82,
                              ),
                          itemBuilder: (context, index) {
                            final product = shown[index];
                            final id = '${product['id']}';
                            final stock = (product['stokKg'] as num).toDouble();
                            final amount = _cart[id] ?? 0;
                            return InkWell(
                              onTap: stock > amount
                                  ? () => _addToCart(product)
                                  : null,
                              borderRadius: BorderRadius.circular(15),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: const Color(0xFFE8ECE5),
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Container(
                                        width: double.infinity,
                                        color: AppTheme.sageGreen,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            const Icon(
                                              Icons.set_meal_rounded,
                                              size: 54,
                                              color: AppTheme.oliveGreen,
                                            ),
                                            if (PosData.isOwner)
                                              Positioned(
                                                right: 0,
                                                top: 0,
                                                child: PopupMenuButton<String>(
                                                  onSelected: (action) =>
                                                      _productMenu(
                                                        action,
                                                        product,
                                                      ),
                                                  itemBuilder: (_) => const [
                                                    PopupMenuItem(
                                                      value: 'edit',
                                                      child: Text(
                                                        'Edit produk',
                                                      ),
                                                    ),
                                                    PopupMenuItem(
                                                      value: 'restock',
                                                      child: Text(
                                                        'Tambah stok',
                                                      ),
                                                    ),
                                                    PopupMenuItem(
                                                      value: 'delete',
                                                      child: Text(
                                                        'Nonaktifkan',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${product['nama']}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '${_money(product['hargaPerKg'] as num)}/kg',
                                            style: const TextStyle(
                                              color: AppTheme.forestGreen,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'Stok ${stock.toStringAsFixed(2)} kg',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                visualDensity:
                                                    VisualDensity.compact,
                                                onPressed: stock > amount
                                                    ? () => _addToCart(product)
                                                    : null,
                                                icon: const Icon(
                                                  Icons.add_circle,
                                                  color: AppTheme.forestGreen,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        );
        final cartItems = all
            .where((p) => _cart.containsKey('${p['id']}'))
            .toList();
        final cart = _panel(
          'Pesanan',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (cartItems.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Keranjang masih kosong',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                )
              else
                ...cartItems.map((product) {
                  final id = '${product['id']}';
                  final qty = _cart[id]!;
                  final stock = (product['stokKg'] as num).toDouble();
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${product['nama']}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            _money((product['hargaPerKg'] as num) * qty),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Text(
                        '${_money(product['hargaPerKg'] as num)}/kg',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => setState(() {
                              if (qty <= .25) {
                                _cart.remove(id);
                              } else {
                                _cart[id] = qty - .25;
                              }
                            }),
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text('${qty.toStringAsFixed(2)} kg'),
                          IconButton(
                            onPressed: qty < stock
                                ? () => setState(
                                    () => _cart[id] = (qty + .25)
                                        .clamp(0, stock)
                                        .toDouble(),
                                  )
                                : null,
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => setState(() => _cart.remove(id)),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: const Color(0xFFB5473B),
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                    ],
                  );
                }),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Berat total'),
                  Text(
                    '${_cart.values.fold<double>(0, (a, b) => a + b).toStringAsFixed(2)} kg',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    _money(_cartTotal(all)),
                    style: const TextStyle(
                      color: AppTheme.forestGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _cart.isEmpty ? null : () => _openCart(all),
                icon: const Icon(Icons.payment),
                label: const Text('Lanjut pembayaran'),
              ),
            ],
          ),
        );
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: desktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: catalog),
                    const SizedBox(width: 16),
                    SizedBox(width: 310, child: cart),
                  ],
                )
              : Column(children: [catalog, const SizedBox(height: 14), cart]),
        );
      },
    ),
  );

  Widget _panel(String title, Widget child) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );
}

class _ProductFormDialog extends StatefulWidget {
  const _ProductFormDialog({this.product});

  final Map<String, dynamic>? product;

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _stock;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _name = TextEditingController(text: '${product?['nama'] ?? ''}');
    _description = TextEditingController(
      text: '${product?['deskripsi'] ?? ''}',
    );
    _price = TextEditingController(
      text: product == null
          ? ''
          : formatThousands('${(product['hargaPerKg'] as num).round()}'),
    );
    _stock = TextEditingController(
      text: product == null ? '' : '${product['stokKg']}',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _stock.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await PosData.saveProduct(
        id: widget.product?['id'] as String?,
        name: _name.text,
        description: _description.text,
        pricePerKg: parseMoneyInput(_price.text)!,
        openingStockKg: double.parse(_stock.text.trim().replaceAll(',', '.')),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Produk gagal disimpan: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.product == null ? 'Tambah produk' : 'Edit produk'),
    content: Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nama produk'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Nama produk wajib diisi.'
                  : null,
            ),
            TextField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Keterangan'),
              maxLines: 2,
            ),
            TextFormField(
              controller: _price,
              keyboardType: TextInputType.number,
              inputFormatters: const [ThousandsSeparatorInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'Harga jual per kg (Rp)',
              ),
              validator: (value) => (parseMoneyInput(value ?? '') ?? 0) <= 0
                  ? 'Harga harus lebih dari 0.'
                  : null,
            ),
            TextFormField(
              controller: _stock,
              readOnly: widget.product != null,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: widget.product == null
                    ? 'Stok awal (kg)'
                    : 'Stok tersedia (kg)',
                helperText: widget.product == null
                    ? null
                    : 'Gunakan menu produk untuk menambah stok.',
              ),
              validator: (value) {
                final stock = double.tryParse(
                  (value ?? '').trim().replaceAll(',', '.'),
                );
                if (stock == null || !stock.isFinite || stock < 0) {
                  return 'Masukkan stok yang valid.';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: const Text('Batal'),
      ),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: Text(_saving ? 'Menyimpan...' : 'Simpan'),
      ),
    ],
  );
}

class PosCheckoutPage extends StatefulWidget {
  const PosCheckoutPage({
    super.key,
    required this.items,
    required this.quantitiesKg,
  });

  final List<Map<String, dynamic>> items;
  final Map<String, double> quantitiesKg;

  @override
  State<PosCheckoutPage> createState() => _PosCheckoutPageState();
}

class _PosCheckoutPageState extends State<PosCheckoutPage> {
  final _cashReceived = TextEditingController();
  final _picker = ImagePicker();
  String _paymentMethod = 'Cash';
  String? _proofPath;
  bool _saving = false;

  double get _total => widget.items.fold<double>(
    0,
    (sum, item) =>
        sum +
        ((item['hargaPerKg'] as num) * (item['beratKg'] as double))
            .roundToDouble(),
  );

  String _money(num value) {
    final grouped = value.round().toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return 'Rp $grouped';
  }

  @override
  void initState() {
    super.initState();
    _cashReceived.text = formatThousands(_total.round().toString());
  }

  @override
  void dispose() {
    _cashReceived.dispose();
    super.dispose();
  }

  Future<void> _pickProof(ImageSource source) async {
    try {
      final photo = await _picker.pickImage(source: source, imageQuality: 80);
      if (photo != null) {
        final directory = await getApplicationDocumentsDirectory();
        final savedPhoto = await File(photo.path).copy(
          '${directory.path}${Platform.pathSeparator}'
          'qris-${DateTime.now().microsecondsSinceEpoch}.jpg',
        );
        if (mounted) setState(() => _proofPath = savedPhoto.path);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Foto bukti gagal diambil: $error')),
        );
      }
    }
  }

  Future<void> _chooseProofSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Ambil foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari galeri'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) await _pickProof(source);
  }

  Future<void> _pay() async {
    final paid = _paymentMethod == 'Cash'
        ? parseMoneyInput(_cashReceived.text) ?? 0
        : _total;
    if (_paymentMethod == 'Cash' && paid < _total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uang diterima kurang dari total.')),
      );
      return;
    }
    if (_paymentMethod == 'QRIS' && _proofPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto bukti pembayaran QRIS wajib ada.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final id = await PosData.checkout(
        quantitiesKg: widget.quantitiesKg,
        paymentMethod: _paymentMethod,
        paidAmount: paid,
        paymentProofPath: _proofPath ?? '',
      );
      if (!mounted) return;
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => PosReceiptPage(
            sale: Map<String, dynamic>.from(PosData.sales.get(id)),
          ),
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Pembayaran gagal: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pembayaran')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Ringkasan pesanan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        for (final item in widget.items)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('${item['nama']}'),
            subtitle: Text(
              '${(item['beratKg'] as double).toStringAsFixed(2)} kg Ã— '
              '${_money(item['hargaPerKg'] as num)}/kg',
            ),
            trailing: Text(
              _money(
                ((item['beratKg'] as double) * (item['hargaPerKg'] as num))
                    .round(),
              ),
            ),
          ),
        const Divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Total pembayaran',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          trailing: Text(
            _money(_total),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'Cash',
              label: Text('Cash'),
              icon: Icon(Icons.payments_outlined),
            ),
            ButtonSegment(
              value: 'QRIS',
              label: Text('QRIS'),
              icon: Icon(Icons.qr_code_2),
            ),
          ],
          selected: {_paymentMethod},
          onSelectionChanged: (value) =>
              setState(() => _paymentMethod = value.first),
        ),
        const SizedBox(height: 16),
        if (_paymentMethod == 'Cash') ...[
          TextField(
            controller: _cashReceived,
            keyboardType: TextInputType.number,
            inputFormatters: const [ThousandsSeparatorInputFormatter()],
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Uang diterima (Rp)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
              final paid = parseMoneyInput(_cashReceived.text) ?? 0;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Kembalian'),
                trailing: Text(_money(paid > _total ? paid - _total : 0)),
              );
            },
          ),
        ] else ...[
          OutlinedButton.icon(
            onPressed: _saving ? null : _chooseProofSource,
            icon: const Icon(Icons.add_a_photo_outlined),
            label: Text(
              _proofPath == null
                  ? 'Masukkan foto bukti QRIS'
                  : 'Ganti foto bukti',
            ),
          ),
          if (_proofPath != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(_proofPath!),
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox(
                  height: 100,
                  child: Center(child: Text('Foto bukti tidak dapat dibuka.')),
                ),
              ),
            ),
          ],
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _saving ? null : _pay,
            icon: const Icon(Icons.check_circle_outline),
            label: Text(_saving ? 'Memproses...' : 'Bayar & tampilkan struk'),
          ),
        ),
      ],
    ),
  );
}

class PosReceiptPage extends StatelessWidget {
  const PosReceiptPage({super.key, required this.sale});

  final Map<String, dynamic> sale;

  String _money(num value) {
    final grouped = value.round().toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return 'Rp $grouped';
  }

  @override
  Widget build(BuildContext context) {
    final items = (sale['items'] as List).cast<Map>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Struk POS'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Kembali ke POS',
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Column(
                      children: [
                        Text(
                          'NGAPAK NGAPIKI FARM',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text('STRUK PENJUALAN PRODUK DAGING'),
                      ],
                    ),
                  ),
                  const Divider(height: 28),
                  Text('No. transaksi: ${sale['id']}'),
                  Text('Tanggal: ${sale['tanggal']}'),
                  Text('Kasir: ${sale['namaKasir']}'),
                  Text('Pembayaran: ${sale['metodePembayaran']}'),
                  const Divider(height: 28),
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item['nama']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${(item['beratKg'] as num).toStringAsFixed(2)} kg Ã— '
                                  '${_money(item['hargaPerKg'] as num)}/kg',
                                ),
                              ],
                            ),
                          ),
                          Text(_money(item['subtotal'] as num)),
                        ],
                      ),
                    ),
                  const Divider(height: 28),
                  _row('Total berat', '${sale['totalBeratKg']} kg'),
                  _row('Total', _money(sale['total'] as num), bold: true),
                  if (sale['metodePembayaran'] == 'Cash') ...[
                    _row('Uang diterima', _money(sale['uangDiterima'] as num)),
                    _row('Kembalian', _money(sale['kembalian'] as num)),
                  ],
                  if (sale['metodePembayaran'] == 'QRIS' &&
                      '${sale['buktiPembayaran']}'.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Bukti pembayaran QRIS',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File('${sale['buktiPembayaran']}'),
                        height: 240,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const Text('Foto bukti tidak dapat dibuka.'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.point_of_sale),
            label: const Text('Transaksi baru'),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            fontSize: bold ? 17 : 14,
          ),
        ),
      ],
    ),
  );
}
