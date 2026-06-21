import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../providers/language_provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import 'reviews_section.dart';
import 'package:url_launcher/url_launcher.dart';

class FoodScreen extends StatefulWidget {
  const FoodScreen({Key? key}) : super(key: key);

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  // Cart maps "dishId:::restaurantName" -> quantity
  final Map<String, int> _cart = {};
  List<Map<String, dynamic>> _dishes = [];
  bool _isLoading = true;

  Future<void> _pickAndUploadImage(TextEditingController controller, BuildContext context, Function setModalState) async {
    final picker = ImagePicker();
    
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    try {
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile == null) return;

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: const Color(0xFF00B4DB),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.ratio3x2,
            lockAspectRatio: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioPresets: [
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
        ],
      );

      if (croppedFile == null) return;

      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final bytes = await croppedFile.readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      final uploadedUrl = await ApiService.uploadImage(base64Image);

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (uploadedUrl != null) {
        setModalState(() {
          controller.text = uploadedUrl;
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image uploaded successfully')),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image upload failed'), backgroundColor: Colors.redAccent),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking/uploading image: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _callRestaurant(String phone, BuildContext context) async {
    final Uri url = Uri.parse('tel:$phone');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        throw 'Could not dial $phone';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot place call automatically. Dial manually: $phone'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadDishes();
  }

  Future<void> _loadDishes() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final data = await ApiService.fetchContent('food');
      setState(() {
        _dishes = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading food: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  int get _cartTotalItems {
    return _cart.values.fold(0, (sum, q) => sum + q);
  }

  int get _cartTotalPrice {
    int total = 0;
    _cart.forEach((key, qty) {
      final parts = key.split(':::');
      final dishId = parts[0];
      final restName = parts[1];

      final dish = _dishes.firstWhere((element) => element['id'] == dishId || element['_id'] == dishId);
      final offer = (dish['offers'] as List).firstWhere((o) => o['restaurant'] == restName);
      
      total += (offer['price'] as int) * qty;
    });
    return total;
  }

  void _addToCart(String dishId, String restaurantName) {
    final key = '${dishId}:::$restaurantName';
    setState(() {
      _cart[key] = (_cart[key] ?? 0) + 1;
    });
  }

  void _removeFromCart(String dishId, String restaurantName) {
    final key = '${dishId}:::$restaurantName';
    if (!_cart.containsKey(key)) return;
    setState(() {
      if (_cart[key] == 1) {
        _cart.remove(key);
      } else {
        _cart[key] = _cart[key]! - 1;
      }
    });
  }

  int _getCartQty(String dishId, String restaurantName) {
    return _cart['${dishId}:::$restaurantName'] ?? 0;
  }

  Future<void> _deleteRestaurant(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this restaurant?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ApiService.deleteContent('food', id);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Restaurant deleted successfully')),
          );
        }
        _loadDishes();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete restaurant'), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  void _addOrEditRestaurant({Map<String, dynamic>? restaurant}) {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isEdit = restaurant != null;
    final nameEnController = TextEditingController(text: isEdit ? restaurant['name_en'] : '');
    final nameBnController = TextEditingController(text: isEdit ? restaurant['name_bn'] : '');
    final addressController = TextEditingController(text: isEdit ? restaurant['address'] : '');
    final phoneController = TextEditingController(text: isEdit ? restaurant['phone'] : '');
    final imageController = TextEditingController(text: isEdit ? restaurant['image'] : '');
    String menuType = isEdit ? (restaurant['menu_type'] ?? 'list') : 'list';
    final menuImageController = TextEditingController(text: isEdit ? (restaurant['menu_image'] ?? '') : '');

    List<Map<String, dynamic>> restaurantMenu = isEdit 
        ? List<Map<String, dynamic>>.from((restaurant['menu'] as List?)?.map((m) => Map<String, dynamic>.from(m)) ?? [])
        : [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 20,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEdit ? 'Edit Restaurant Details' : 'Add New Restaurant',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 10),
                      TextField(
                        controller: nameEnController,
                        decoration: const InputDecoration(labelText: 'Restaurant Name (English)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nameBnController,
                        decoration: const InputDecoration(labelText: 'Restaurant Name (Bangla)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: addressController,
                        decoration: const InputDecoration(labelText: 'Address (ঠিকানা)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Phone Number (মোবাইল নম্বর)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: imageController,
                              decoration: const InputDecoration(
                                labelText: 'Restaurant Image URL',
                                border: OutlineInputBorder(),
                                hintText: 'Enter URL or upload',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _pickAndUploadImage(imageController, context, setModalState),
                            icon: const Icon(Icons.upload_file, size: 18),
                            label: const Text('Upload'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00B4DB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // MENU TYPE SELECTOR
                      Text(
                        langProvider.isBangla ? 'মেনু টাইপ নির্বাচন করুন:' : 'Select Menu Type:',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: menuType == 'image' ? const Color(0x1A00B4DB) : Colors.transparent,
                                side: BorderSide(
                                  color: menuType == 'image' ? const Color(0xFF00B4DB) : Colors.grey.withAlpha(76),
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () {
                                setModalState(() {
                                  menuType = 'image';
                                });
                              },
                              icon: Icon(Icons.image_outlined, color: menuType == 'image' ? const Color(0xFF00B4DB) : Colors.grey),
                              label: Text(
                                langProvider.isBangla ? 'মেনু ছবি' : 'Menu Image',
                                style: TextStyle(
                                  color: menuType == 'image' ? const Color(0xFF00B4DB) : Colors.grey,
                                  fontWeight: menuType == 'image' ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: menuType == 'list' ? const Color(0x1A00B4DB) : Colors.transparent,
                                side: BorderSide(
                                  color: menuType == 'list' ? const Color(0xFF00B4DB) : Colors.grey.withAlpha(76),
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () {
                                setModalState(() {
                                  menuType = 'list';
                                });
                              },
                              icon: Icon(Icons.format_list_bulleted, color: menuType == 'list' ? const Color(0xFF00B4DB) : Colors.grey),
                              label: Text(
                                langProvider.isBangla ? 'আলাদা খাবারের তালিকা' : 'Food List',
                                style: TextStyle(
                                  color: menuType == 'list' ? const Color(0xFF00B4DB) : Colors.grey,
                                  fontWeight: menuType == 'list' ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (menuType == 'image') ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: menuImageController,
                                decoration: InputDecoration(
                                  labelText: langProvider.isBangla ? 'মেনু ছবির লিঙ্ক' : 'Menu Image URL',
                                  border: const OutlineInputBorder(),
                                  hintText: langProvider.isBangla ? 'লিঙ্ক লিখুন বা আপলোড করুন' : 'Enter URL or upload',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () => _pickAndUploadImage(menuImageController, context, setModalState),
                              icon: const Icon(Icons.upload_file, size: 18),
                              label: Text(langProvider.isBangla ? 'আপলোড' : 'Upload'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00B4DB),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              langProvider.isBangla ? 'খাবারের তালিকা' : 'Food Menu Items',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final menuItem = await _showMenuDialog();
                                if (menuItem != null) {
                                  setModalState(() {
                                    restaurantMenu.add(menuItem);
                                  });
                                }
                              },
                              icon: const Icon(Icons.add, size: 14),
                              label: Text(langProvider.isBangla ? 'যোগ করুন' : 'Add Item', style: const TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00B4DB),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        restaurantMenu.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Theme.of(context).dividerColor),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(langProvider.isBangla ? 'কোনো খাবার তালিকা যোগ করা হয়নি' : 'No menu items added. Menu is optional.'),
                                ),
                              )
                            : Column(
                                children: restaurantMenu.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final m = entry.value;
                                  return Card(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    child: ListTile(
                                      leading: ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.network(
                                          m['image'] ?? '',
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                          errorBuilder: (c, e, s) => Container(color: Colors.white10, width: 40, height: 40),
                                        ),
                                      ),
                                      title: Text(langProvider.isBangla ? (m['name_bn'] ?? m['name_en'] ?? '') : (m['name_en'] ?? '')),
                                      subtitle: Text('৳${m['price']}'),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Color(0xFF00B4DB), size: 20),
                                            onPressed: () async {
                                              final updatedMenuItem = await _showMenuDialog(menuItem: m);
                                              if (updatedMenuItem != null) {
                                                setModalState(() {
                                                  restaurantMenu[idx] = updatedMenuItem;
                                                });
                                              }
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                            onPressed: () {
                                              setModalState(() {
                                                restaurantMenu.removeAt(idx);
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                      ],
                      
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () async {
                          if (nameEnController.text.isEmpty || nameBnController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please fill in Name fields')),
                            );
                            return;
                          }

                          final item = {
                            'name_en': nameEnController.text.trim(),
                            'name_bn': nameBnController.text.trim(),
                            'address': addressController.text.trim(),
                            'phone': phoneController.text.trim(),
                            'image': imageController.text.trim().isNotEmpty
                                ? imageController.text.trim()
                                : 'https://images.unsplash.com/photo-1553618551-fba689030290?auto=format&fit=crop&w=400&q=80',
                            'menu_type': menuType,
                            'menu_image': menuImageController.text.trim(),
                            'menu': restaurantMenu,
                          };

                          bool success = false;
                          if (isEdit) {
                            final res = await ApiService.updateContent(restaurant['_id'], item);
                            success = res != null;
                          } else {
                            final res = await ApiService.createContent('food', item);
                            success = res != null;
                          }

                          if (success) {
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(isEdit ? 'Restaurant updated successfully' : 'Restaurant added successfully')),
                              );
                            }
                            _loadDishes();
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Failed to save details'), backgroundColor: Colors.redAccent),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00B4DB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(isEdit ? 'Update Restaurant' : 'Create Restaurant', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _showMenuDialog({Map<String, dynamic>? menuItem}) async {
    final isEdit = menuItem != null;
    final mNameEn = TextEditingController(text: isEdit ? menuItem['name_en'] : '');
    final mNameBn = TextEditingController(text: isEdit ? menuItem['name_bn'] : '');
    final mPrice = TextEditingController(text: isEdit ? menuItem['price']?.toString() : '');
    final mImage = TextEditingController(text: isEdit ? menuItem['image'] : '');

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEdit ? 'Edit Menu Item' : 'Add Menu Item'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: mNameEn, decoration: const InputDecoration(labelText: 'Dish Name (English)')),
                    const SizedBox(height: 8),
                    TextField(controller: mNameBn, decoration: const InputDecoration(labelText: 'Dish Name (Bangla)')),
                    const SizedBox(height: 8),
                    TextField(controller: mPrice, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (৳)')),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: mImage,
                            decoration: const InputDecoration(labelText: 'Image URL'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.upload_file, color: Color(0xFF00B4DB)),
                          onPressed: () => _pickAndUploadImage(mImage, context, setDialogState),
                          tooltip: 'Upload Image',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                TextButton(
                  onPressed: () {
                    if (mNameEn.text.isEmpty || mNameBn.text.isEmpty || mPrice.text.isEmpty) {
                      return;
                    }
                    Navigator.pop(context, {
                      'name_en': mNameEn.text.trim(),
                      'name_bn': mNameBn.text.trim(),
                      'price': int.tryParse(mPrice.text.trim()) ?? 0,
                      'image': mImage.text.trim().isNotEmpty
                          ? mImage.text.trim()
                          : 'https://images.unsplash.com/photo-1553618551-fba689030290?auto=format&fit=crop&w=400&q=80',
                    });
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRestaurantDetailsSheet(Map<String, dynamic> restaurant, LanguageProvider langProvider) {
    final name = langProvider.isBangla ? restaurant['name_bn'] : restaurant['name_en'];
    final address = restaurant['address'] ?? '';
    final phone = restaurant['phone'] ?? '';
    final menuType = restaurant['menu_type'] ?? 'list';
    final menuImage = restaurant['menu_image'] ?? '';
    final menu = restaurant['menu'] as List? ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final onSurface = Theme.of(context).colorScheme.onSurface;
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name ?? '',
                          style: TextStyle(
                            color: onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: onSurface.withAlpha(153)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  if (address.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            address,
                            style: TextStyle(color: onSurface.withAlpha(153), fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (phone.isNotEmpty) ...[
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => _callRestaurant(phone, context),
                      icon: const Icon(Icons.phone),
                      label: Text(
                        langProvider.isBangla ? 'অর্ডার করতে কল করুন' : 'Call to Order',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Divider(color: Theme.of(context).dividerColor),
                  Text(
                    langProvider.isBangla ? 'খাবার মেনু:' : 'Food Menu:',
                    style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        if (menuType == 'image') {
                          if (menuImage.isEmpty) {
                            return _buildNoMenuFallback(context, langProvider, phone);
                          }
                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FullScreenImageViewer(imageUrl: menuImage),
                                ),
                              );
                            },
                            child: Card(
                              clipBehavior: Clip.antiAlias,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Image.network(
                                      menuImage,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Center(child: Icon(Icons.broken_image, size: 48)),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 12,
                                    right: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withAlpha(150),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.zoom_in, color: Colors.white, size: 16),
                                          const SizedBox(width: 4),
                                          Text(
                                            langProvider.isBangla ? 'বড় করে দেখুন' : 'Tap to Zoom',
                                            style: const TextStyle(color: Colors.white, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else {
                          // menuType == 'list'
                          if (menu.isEmpty) {
                            return _buildNoMenuFallback(context, langProvider, phone);
                          }
                          return ListView.builder(
                            controller: scrollController,
                            itemCount: menu.length,
                            itemBuilder: (context, index) {
                              final item = menu[index];
                              final mName = langProvider.isBangla ? item['name_bn'] : item['name_en'];
                              final price = item['price'];
                              final mImage = item['image'] ?? '';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).scaffoldBackgroundColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        mImage,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            Container(color: Colors.white10, width: 50, height: 50),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            mName ?? '',
                                            style: TextStyle(
                                              color: onSurface,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '৳$price',
                                            style: const TextStyle(
                                              color: Color(0xFF00B4DB),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (phone.isNotEmpty)
                                      IconButton(
                                        icon: const Icon(Icons.phone_in_talk, color: Colors.green),
                                        onPressed: () => _callRestaurant(phone, context),
                                        tooltip: 'Order this item',
                                      ),
                                  ],
                                ),
                              );
                            },
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNoMenuFallback(BuildContext context, LanguageProvider langProvider, String phone) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.restaurant_menu_rounded, size: 48, color: onSurface.withAlpha(76)),
        const SizedBox(height: 12),
        Text(
          langProvider.isBangla
              ? 'কোনো খাবারের মেনু যুক্ত করা হয়নি।'
              : 'No food menu added yet.',
          style: TextStyle(color: onSurface.withAlpha(127), fontSize: 13),
        ),
        const SizedBox(height: 6),
        Text(
          langProvider.isBangla
              ? 'আজকের মেনু ও খাবারের অর্ডার করতে কল করুন।'
              : 'Please call to ask about the menu and order.',
          style: TextStyle(color: onSurface.withAlpha(178), fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void _showCartSheet(LanguageProvider langProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final onSurface = Theme.of(context).colorScheme.onSurface;
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                // Calculate local pricing inside bottomsheet
                int localTotalPrice = 0;
                _cart.forEach((key, qty) {
                  final parts = key.split(':::');
                  final dishId = parts[0];
                  final restName = parts[1];
                  final dish = _dishes.firstWhere((element) => element['id'] == dishId || element['_id'] == dishId);
                  final offer = (dish['offers'] as List).firstWhere((o) => o['restaurant'] == restName);
                  localTotalPrice += (offer['price'] as int) * qty;
                });

                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            langProvider.translate('cart'),
                            style: TextStyle(
                              color: onSurface,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: onSurface.withOpacity(0.6)),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      Divider(color: Theme.of(context).dividerColor),
                      
                      // Cart Items
                      Expanded(
                        child: _cart.isEmpty
                            ? Center(
                                child: Text(
                                  langProvider.locale == 'en' ? 'Cart is empty' : 'কার্ট খালি আছে',
                                  style: TextStyle(color: onSurface.withOpacity(0.5)),
                                ),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: _cart.length,
                                itemBuilder: (context, index) {
                                  final entry = _cart.entries.elementAt(index);
                                  final parts = entry.key.split(':::');
                                  final dishId = parts[0];
                                  final restName = parts[1];

                                  final dish = _dishes.firstWhere((e) => e['id'] == dishId || e['_id'] == dishId);
                                  final offer = (dish['offers'] as List).firstWhere((o) => o['restaurant'] == restName);
                                  
                                  final name = langProvider.locale == 'en' ? dish['name_en'] : dish['name_bn'];

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            dish['image'] ?? '',
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) =>
                                                Container(color: Colors.white10, width: 50, height: 50),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name ?? '',
                                                style: TextStyle(
                                                    color: onSurface, fontWeight: FontWeight.bold, fontSize: 14),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                restName,
                                                style: const TextStyle(color: Color(0xFF00B4DB), fontSize: 11),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '৳${offer['price']} x ${entry.value}',
                                                style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF00B4DB)),
                                              onPressed: () {
                                                _removeFromCart(dishId, restName);
                                                setModalState(() {});
                                                setState(() {});
                                              },
                                            ),
                                            Text(
                                              '${entry.value}',
                                              style: TextStyle(color: onSurface, fontSize: 16),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.add_circle_outline, color: Color(0xFF00B4DB)),
                                              onPressed: () {
                                                _addToCart(dishId, restName);
                                                setModalState(() {});
                                                setState(() {});
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                      
                      // Bottom Pricing and Checkout Button
                      if (_cart.isNotEmpty) ...[
                        Divider(color: Theme.of(context).dividerColor),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                           child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                langProvider.translate('total'),
                                style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 16),
                              ),
                              Text(
                                '৳$localTotalPrice',
                                style: TextStyle(
                                  color: onSurface,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00B4DB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            _showCheckoutDialog(langProvider);
                          },
                          child: Text(
                            langProvider.translate('place_order'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showCheckoutDialog(LanguageProvider langProvider) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final tableController = TextEditingController();
    final checkoutFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        final onSurface = Theme.of(context).colorScheme.onSurface;
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            langProvider.translate('place_order'),
            style: TextStyle(color: onSurface),
          ),
          content: Form(
            key: checkoutFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  style: TextStyle(color: onSurface),
                  decoration: _dialogInputDecoration(
                    label: langProvider.translate('name'),
                    icon: Icons.person_outline,
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(color: onSurface),
                  decoration: _dialogInputDecoration(
                    label: langProvider.translate('phone'),
                    icon: Icons.phone_android,
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: tableController,
                  style: TextStyle(color: onSurface),
                  decoration: _dialogInputDecoration(
                    label: langProvider.locale == 'en' ? 'Table No / Beach Umbrella No' : 'টেবিল নম্বর / ছাতা নম্বর',
                    icon: Icons.umbrella_outlined,
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                langProvider.translate('close'),
                style: TextStyle(color: onSurface.withOpacity(0.6)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B4DB),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (!checkoutFormKey.currentState!.validate()) return;

                Navigator.pop(context); // close details dialog
                setState(() => _isLoading = true);

                final orderData = {
                  'customerName': nameController.text.trim(),
                  'customerPhone': phoneController.text.trim(),
                  'locationDetails': tableController.text.trim(),
                  'items': _cart.entries.map((e) {
                    final parts = e.key.split(':::');
                    final dishId = parts[0];
                    final restName = parts[1];
                    final dish = _dishes.firstWhere((x) => x['id'] == dishId || x['_id'] == dishId);
                    final offer = (dish['offers'] as List).firstWhere((o) => o['restaurant'] == restName);

                    return {
                      'dishId': dishId,
                      'name': dish['name_en'],
                      'restaurant': restName,
                      'quantity': e.value,
                      'price': offer['price']
                    };
                  }).toList(),
                  'totalPrice': _cartTotalPrice,
                };

                final success = await ApiService.placeFoodOrder(orderData);

                setState(() => _isLoading = false);

                if (success) {
                  _showOrderSuccess(langProvider, false);
                } else {
                  _showOrderSuccess(langProvider, true); // fallback simulation
                }
              },
              child: Text(langProvider.translate('place_order')),
            ),
          ],
        );
      },
    );
  }

  void _showOrderSuccess(LanguageProvider langProvider, bool isOfflineSimulated) {
    setState(() {
      _cart.clear(); // Clear cart on success
    });
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final onSurface = Theme.of(context).colorScheme.onSurface;
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              Text(
                langProvider.translate('success'),
                style: TextStyle(color: onSurface, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                langProvider.translate('order_success'),
                textAlign: TextAlign.center,
                style: TextStyle(color: onSurface.withOpacity(0.7)),
              ),
              if (isOfflineSimulated) ...[
                const SizedBox(height: 8),
                Text(
                  '(${langProvider.translate('offline_mode')})',
                  style: const TextStyle(color: Colors.amber, fontSize: 11, fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00B4DB), foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(langProvider.translate('close')),
            )
          ],
        );
      },
    );
  }

  InputDecoration _dialogInputDecoration({required String label, required IconData icon}) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFF00B4DB), size: 18),
      filled: true,
      fillColor: Theme.of(context).scaffoldBackgroundColor,
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: onSurface.withOpacity(0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF00B4DB)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final isSuperAdmin = userProvider.isSuperAdmin;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(langProvider.translate('food_order')),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: Theme.of(context).appBarTheme.elevation,
        actions: [
          if (isSuperAdmin)
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, size: 28),
              tooltip: 'Add Restaurant',
              onPressed: () => _addOrEditRestaurant(),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00B4DB)))
          : Column(
              children: [
                // Banner header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        langProvider.isBangla ? 'খাবার হোটেলসমূহ' : 'Food Hotels & Restaurants',
                        style: TextStyle(color: onSurface, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        langProvider.locale == 'en'
                            ? 'Select a restaurant to view its menu, or call directly to order food.'
                            : 'রেস্টুরেন্টের মেনু দেখতে অথবা সরাসরি কল করে খাবার অর্ডার করতে যেকোনো একটি হোটেল নির্বাচন করুন।',
                        style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                
                // Restaurants List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _dishes.length,
                    itemBuilder: (context, index) {
                      final restaurant = _dishes[index];
                      final name = langProvider.locale == 'en' ? restaurant['name_en'] : restaurant['name_bn'];
                      final address = restaurant['address'] ?? '';
                      final phone = restaurant['phone'] ?? '';
                      final image = restaurant['image'] ?? '';

                      return Card(
                        color: Theme.of(context).cardColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        margin: const EdgeInsets.only(bottom: 16),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _showRestaurantDetailsSheet(restaurant, langProvider),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                children: [
                                  Image.network(
                                    image,
                                    width: double.infinity,
                                    height: 160,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Container(color: Colors.white10, height: 160),
                                  ),
                                  if (isSuperAdmin)
                                    Positioned(
                                      top: 8,
                                      left: 8,
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundColor: Colors.black.withOpacity(0.7),
                                            child: IconButton(
                                              icon: const Icon(Icons.edit, color: Colors.white, size: 16),
                                              onPressed: () => _addOrEditRestaurant(restaurant: restaurant),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundColor: Colors.black.withOpacity(0.7),
                                            child: IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.redAccent, size: 16),
                                              onPressed: () => _deleteRestaurant(restaurant['_id']),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.all(14.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name ?? '',
                                      style: TextStyle(
                                        color: onSurface,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (address.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              address,
                                              style: TextStyle(
                                                color: onSurface.withOpacity(0.6),
                                                fontSize: 12,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        if (phone.isNotEmpty)
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                padding: const EdgeInsets.symmetric(vertical: 10),
                                              ),
                                              onPressed: () => _callRestaurant(phone, context),
                                              icon: const Icon(Icons.phone, size: 16),
                                              label: Text(
                                                langProvider.isBangla ? 'কল করুন' : 'Call',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                              ),
                                            ),
                                          ),
                                        if (phone.isNotEmpty) const SizedBox(width: 12),
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: const Color(0xFF00B4DB),
                                              side: const BorderSide(color: Color(0xFF00B4DB)),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              padding: const EdgeInsets.symmetric(vertical: 10),
                                            ),
                                            onPressed: () => _showRestaurantDetailsSheet(restaurant, langProvider),
                                            icon: const Icon(Icons.restaurant_menu, size: 16),
                                            label: Text(
                                              langProvider.isBangla ? 'মেনু দেখুন' : 'View Menu',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
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
                  ),
                ),
              ],
            ),
      floatingActionButton: null,
    );
  }

  void _showReviewsModal(BuildContext context, String title, String itemType, String itemId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  ReviewsSection(
                    itemId: itemId,
                    itemType: itemType,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  const FullScreenImageViewer({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image, color: Colors.white, size: 64),
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black.withAlpha(127),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
