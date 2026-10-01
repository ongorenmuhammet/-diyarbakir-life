import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/constants/districts.dart';
import '../../../core/widgets/app_image.dart';
import '../domain/business_model.dart';
import 'business_provider.dart';

class AddEditBusinessScreen extends ConsumerStatefulWidget {
  final BusinessModel? business;

  const AddEditBusinessScreen({super.key, this.business});

  @override
  ConsumerState<AddEditBusinessScreen> createState() => _AddEditBusinessScreenState();
}

class _AddEditBusinessScreenState extends ConsumerState<AddEditBusinessScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _descController;

  // Inline Menu Item Editor Controllers
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _itemDescController = TextEditingController();
  final TextEditingController _itemPriceController = TextEditingController();
  String _itemCategory = 'Yemekler';
  String? _itemImagePath;
  bool _showMenuItemEditor = false;
  int? _editingMenuItemIndex;

  String? _coverImagePath;
  String? _logoImagePath;
  bool _isPickingImage = false;

  String _selectedCategory = 'Restoran & Kafe';
  String _selectedDistrict = 'Kayapınar';
  bool _isFeatured = false;

  List<BusinessMenuItem> _menuItems = [];

  static const _categories = [
    'Restoran & Kafe',
    'Fırın & Ciğerci',
    'Tatlı & Pastane',
    'Market & Şarküteri',
    'Giyim & Moda',
    'Elektronik & İletişim',
    'Otomotiv & Sanayi',
    'Eczane & Sağlık',
    'Güzellik & Kuaför',
    'İnşaat & Yapı Market',
    'Kırtasiye & Kitabevi',
    'Emlak & Gayrimenkul',
    'Spor & Eğlence',
    'Hizmet & Nakliyat',
    'Diğer İşletmeler',
  ];

  @override
  void initState() {
    super.initState();
    final b = widget.business;
    _nameController = TextEditingController(text: b?.name ?? '');
    _addressController = TextEditingController(text: b?.address ?? '');
    _phoneController = TextEditingController(text: b?.phone ?? '');
    _descController = TextEditingController(text: b?.description ?? '');

    _coverImagePath = b?.coverImageUrl;
    _logoImagePath = b?.logoUrl;

    if (b != null) {
      if (_categories.contains(b.category)) {
        _selectedCategory = b.category;
      }
      if (kDistricts.contains(b.district)) {
        _selectedDistrict = b.district;
      }
      _isFeatured = b.isFeatured;
      _menuItems = List.from(b.menu);
    } else {
      // Ana sayfadaki seçili ilçe neyse otomatik o olsun
      final currentDistrict = ref.read(selectedDistrictProvider);
      if (currentDistrict != 'Diyarbakır' && kDistricts.contains(currentDistrict)) {
        _selectedDistrict = currentDistrict;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _descController.dispose();
    _itemNameController.dispose();
    _itemDescController.dispose();
    _itemPriceController.dispose();
    super.dispose();
  }

  Future<String?> _pickDeviceImage() async {
    if (_isPickingImage) return null;
    _isPickingImage = true;
    try {
      FocusScope.of(context).unfocus();
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 50,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        final base64Str = base64Encode(bytes);
        final mimeType = file.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
        return 'data:$mimeType;base64,$base64Str';
      }
    } catch (e) {
      debugPrint('Görsel seçme hatası: $e');
    } finally {
      _isPickingImage = false;
    }
    return null;
  }

  void _openInlineMenuItemEditor([BusinessMenuItem? existingItem, int? index]) {
    setState(() {
      _editingMenuItemIndex = index;
      _itemNameController.text = existingItem?.name ?? '';
      _itemDescController.text = existingItem?.description ?? '';
      _itemPriceController.text = existingItem?.price != null ? existingItem!.price.toString() : '';
      _itemCategory = existingItem?.category ?? 'Yemekler';
      _itemImagePath = existingItem?.imageUrl;
      _showMenuItemEditor = true;
    });
  }

  void _saveInlineMenuItem() {
    final name = _itemNameController.text.trim();
    final priceStr = _itemPriceController.text.trim();
    if (name.isEmpty || priceStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen ürün adı ve fiyatını doldurun.')),
      );
      return;
    }

    final price = double.tryParse(priceStr) ?? 0.0;
    final newItem = BusinessMenuItem(
      id: _editingMenuItemIndex != null
          ? _menuItems[_editingMenuItemIndex!].id
          : DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: _itemDescController.text.trim(),
      price: price,
      category: _itemCategory,
      imageUrl: _itemImagePath,
    );

    setState(() {
      if (_editingMenuItemIndex != null) {
        _menuItems[_editingMenuItemIndex!] = newItem;
      } else {
        _menuItems.add(newItem);
      }
      _showMenuItemEditor = false;
      _editingMenuItemIndex = null;
      _itemNameController.clear();
      _itemDescController.clear();
      _itemPriceController.clear();
      _itemImagePath = null;
    });
  }

  void _cancelInlineMenuItemEditor() {
    setState(() {
      _showMenuItemEditor = false;
      _editingMenuItemIndex = null;
      _itemNameController.clear();
      _itemDescController.clear();
      _itemPriceController.clear();
      _itemImagePath = null;
    });
  }

  void _saveBusiness() {
    if (!_formKey.currentState!.validate()) return;

    final authState = ref.read(authProvider);
    final isEdit = widget.business != null;
    final model = BusinessModel(
      id: isEdit ? widget.business!.id : 'biz-${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      category: _selectedCategory,
      district: _selectedDistrict,
      rating: 0.0,
      reviewCount: 0,
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      coverImageUrl: _coverImagePath ?? '',
      logoUrl: _logoImagePath ?? '',
      description: _descController.text.trim(),
      isFeatured: _isFeatured,
      menu: _menuItems,
      ownerEmail: isEdit ? widget.business?.ownerEmail : authState.email,
      status: authState.isAdmin ? 'approved' : (isEdit ? (widget.business?.status ?? 'pending') : 'pending'),
    );

    FirebaseFirestore.instance.collection('businesses').doc(model.id).set(model.toJson());

    final isPending = !authState.isAdmin && (!isEdit || model.status == 'pending');
    Navigator.of(context).pop();

    if (isPending) {
      _showApprovalWaitingDialog(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? 'İşletme güncellendi.' : 'İşletme eklendi.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showApprovalWaitingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.hourglass_top_rounded, color: Colors.amber.shade900, size: 28),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Onay Bekliyor',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: const Text(
            'İşletme kaydınız yöneticimizin onayına sunulmuştur. Yönetici onayladıktan hemen sonra yayında olacaktır.',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Tamam', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEdit = widget.business != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'İşletmeyi Düzenle' : 'Yeni İşletme Ekle'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'İşletme Adı *'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Zorunlu alan' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(labelText: 'Kategori'),
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCategory = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedDistrict,
                      decoration: const InputDecoration(labelText: 'İlçe'),
                      items: kDistricts
                          .where((d) => d != 'Diyarbakır')
                          .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedDistrict = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s()-]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Telefon Numarası *',
                  hintText: '05xx xxx xx xx',
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Zorunlu alan' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Adres *'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Zorunlu alan' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'İşletme Açıklaması *'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Zorunlu alan' : null,
              ),
              const SizedBox(height: 20),

              // Cover Image Picker Box
              const Text('Kapak Görseli (İsteğe Bağlı):', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (_coverImagePath != null && _coverImagePath!.isNotEmpty) ...[
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AppImage(
                        path: _coverImagePath!,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        backgroundColor: Colors.black.withValues(alpha: 0.7),
                        radius: 18,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.close, color: Colors.white, size: 20),
                          onPressed: () => setState(() => _coverImagePath = null),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              OutlinedButton.icon(
                onPressed: () async {
                  final path = await _pickDeviceImage();
                  if (path != null) {
                    setState(() => _coverImagePath = path);
                  }
                },
                icon: const Icon(Icons.add_photo_alternate),
                label: Text((_coverImagePath != null && _coverImagePath!.isNotEmpty)
                    ? 'Kapak Görselini Değiştir'
                    : 'Cihazdan Kapak Görseli Seç'),
              ),
              const SizedBox(height: 20),

              // Logo Image Picker Box
              const Text('Logo Görseli (İsteğe Bağlı):', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (_logoImagePath != null && _logoImagePath!.isNotEmpty) ...[
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: AppImage(
                        path: _logoImagePath!,
                        height: 60,
                        width: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    TextButton.icon(
                      onPressed: () => setState(() => _logoImagePath = null),
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text('Logoyu Kaldır', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              OutlinedButton.icon(
                onPressed: () async {
                  final path = await _pickDeviceImage();
                  if (path != null) {
                    setState(() => _logoImagePath = path);
                  }
                },
                icon: const Icon(Icons.image),
                label: Text((_logoImagePath != null && _logoImagePath!.isNotEmpty)
                    ? 'Logo Görselini Değiştir'
                    : 'Cihazdan Logo Görseli Seç'),
              ),
              const SizedBox(height: 16),
              if (authState.isAdmin) ...[
                SwitchListTile(
                  title: const Text('Öne Çıkan İşletme Yap'),
                  subtitle: const Text('Ana sayfadaki Öne Çıkan İşletmeler alanında gösterilsin'),
                  value: _isFeatured,
                  onChanged: (val) => setState(() => _isFeatured = val),
                ),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),

              // Menu Items Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Menü ve Ürünler (${_menuItems.length})',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (!_showMenuItemEditor)
                    ElevatedButton.icon(
                      onPressed: () => _openInlineMenuItemEditor(),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Ürün Ekle'),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Inline Menu Item Editor Box
              if (_showMenuItemEditor) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade900 : Colors.blue.shade50.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.primary.withOpacity(0.4), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _editingMenuItemIndex == null ? 'Yeni Ürün Ekle' : 'Ürünü Düzenle',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: _cancelInlineMenuItemEditor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _itemNameController,
                        decoration: const InputDecoration(labelText: 'Ürün Adı *'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _itemCategory,
                              decoration: const InputDecoration(labelText: 'Kategori'),
                              items: ['Yemekler', 'Tatlılar', 'İçecekler', 'Kahvaltı', 'Atıştırmalıklar']
                                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _itemCategory = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _itemPriceController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                              ],
                              decoration: const InputDecoration(labelText: 'Fiyat (TL) *'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _itemDescController,
                        decoration: const InputDecoration(labelText: 'Açıklama / İçerik'),
                      ),
                      const SizedBox(height: 16),

                      // Product Image Picker
                      const Text('Ürün Görseli (İsteğe Bağlı):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      if (_itemImagePath != null && _itemImagePath!.isNotEmpty) ...[
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: AppImage(
                                path: _itemImagePath!,
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: CircleAvatar(
                                backgroundColor: Colors.black.withValues(alpha: 0.7),
                                radius: 16,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.close, color: Colors.white, size: 18),
                                  onPressed: () => setState(() => _itemImagePath = null),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      OutlinedButton.icon(
                        onPressed: () async {
                          final path = await _pickDeviceImage();
                          if (path != null) {
                            setState(() => _itemImagePath = path);
                          }
                        },
                        icon: const Icon(Icons.photo_library),
                        label: Text((_itemImagePath != null && _itemImagePath!.isNotEmpty)
                            ? 'Ürün Görselini Değiştir'
                            : 'Cihazdan Ürün Görseli Seç'),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _cancelInlineMenuItemEditor,
                            child: const Text('İptal'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _saveInlineMenuItem,
                            icon: const Icon(Icons.check),
                            label: Text(_editingMenuItemIndex == null ? 'Ürünü Menüye Ekle' : 'Ürünü Güncelle'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Menu Items List
              if (_menuItems.isEmpty && !_showMenuItemEditor)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Henüz menü ürünü eklenmedi. Ürün eklemek için butona tıklayın.'),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _menuItems.length,
                  itemBuilder: (context, idx) {
                    final item = _menuItems[idx];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                          child: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: AppImage(path: item.imageUrl!, height: 40, width: 40, fit: BoxFit.cover),
                                )
                              : Icon(Icons.restaurant, color: theme.colorScheme.primary),
                        ),
                        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${item.category} • ${item.price} ₺'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _openInlineMenuItemEditor(item, idx),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => setState(() => _menuItems.removeAt(idx)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saveBusiness,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(isEdit ? 'İşletmeyi Kaydet' : 'İşletmeyi Oluştur'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
