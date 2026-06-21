import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../providers/language_provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import 'reviews_section.dart';

class BoatListScreen extends StatefulWidget {
  const BoatListScreen({Key? key}) : super(key: key);

  @override
  State<BoatListScreen> createState() => _BoatListScreenState();
}

class _BoatListScreenState extends State<BoatListScreen> {
  List<Map<String, dynamic>> _boatmen = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

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
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
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

  @override
  void initState() {
    super.initState();
    _loadBoatmen();
    // Refresh boatmen silently in the background every 10 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted && !_isLoading) {
        _loadBoatmenBackground();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadBoatmenBackground() async {
    try {
      final data = await ApiService.fetchContent('boat');
      if (mounted) {
        setState(() {
          _boatmen = data;
        });
      }
    } catch (e) {
      debugPrint('Background error loading boatmen: $e');
    }
  }

  Future<void> _loadBoatmen() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final data = await ApiService.fetchContent('boat');
      setState(() {
        _boatmen = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading boatmen: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _callBoatman(String phone, BuildContext context) async {
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

  Future<void> _deleteBoatman(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this boatman?'),
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
      final success = await ApiService.deleteContent('boat', id);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Boatman deleted successfully')),
          );
        }
        _loadBoatmen();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete boatman'), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  void _addOrEditBoatman({Map<String, dynamic>? boatman}) {
    final isEdit = boatman != null;
    final nameEnController = TextEditingController(text: isEdit ? boatman['name_en'] : '');
    final nameBnController = TextEditingController(text: isEdit ? boatman['name_bn'] : '');
    final boatEnController = TextEditingController(text: isEdit ? boatman['boat_en'] : '');
    final boatBnController = TextEditingController(text: isEdit ? boatman['boat_bn'] : '');
    final priceEnController = TextEditingController(text: isEdit ? boatman['price_en'] : '');
    final priceBnController = TextEditingController(text: isEdit ? boatman['price_bn'] : '');
    final phoneController = TextEditingController(text: isEdit ? boatman['phone'] : '');
    final imageController = TextEditingController(text: isEdit ? boatman['image'] : '');
    final detailsEnController = TextEditingController(text: isEdit ? boatman['details_en'] : '');
    final detailsBnController = TextEditingController(text: isEdit ? boatman['details_bn'] : '');
    final ratingController = TextEditingController(text: isEdit ? boatman['rating']?.toString() : '4.7');
    final tripsController = TextEditingController(text: isEdit ? boatman['trips']?.toString() : '100');

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
                            isEdit ? 'Edit Boatman Details' : 'Add New Boatman',
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
                        decoration: const InputDecoration(labelText: 'Boatman Name (English)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nameBnController,
                        decoration: const InputDecoration(labelText: 'Boatman Name (Bangla)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: boatEnController,
                              decoration: const InputDecoration(labelText: 'Boat details (English)', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: boatBnController,
                              decoration: const InputDecoration(labelText: 'Boat details (Bangla)', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: priceEnController,
                              decoration: const InputDecoration(labelText: 'Price (English, e.g. ৳800 / hour)', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: priceBnController,
                              decoration: const InputDecoration(labelText: 'Price (Bangla, e.g. ৳৮০০ / ঘণ্টা)', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: ratingController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Rating (e.g. 4.7)', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: tripsController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Trips count', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: imageController,
                              decoration: const InputDecoration(
                                labelText: 'Boatman Image URL',
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
                      const SizedBox(height: 12),
                      TextField(
                        controller: detailsEnController,
                        decoration: const InputDecoration(labelText: 'Details/Bio (English)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: detailsBnController,
                        decoration: const InputDecoration(labelText: 'Details/Bio (Bangla)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () async {
                          if (nameEnController.text.isEmpty || nameBnController.text.isEmpty || phoneController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please fill in Name and Phone Number')),
                            );
                            return;
                          }

                          final item = {
                            'name_en': nameEnController.text.trim(),
                            'name_bn': nameBnController.text.trim(),
                            'boat_en': boatEnController.text.trim(),
                            'boat_bn': boatBnController.text.trim(),
                            'price_en': priceEnController.text.trim(),
                            'price_bn': priceBnController.text.trim(),
                            'phone': phoneController.text.trim(),
                            'image': imageController.text.trim().isNotEmpty
                                ? imageController.text.trim()
                                : 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=300&q=80',
                            'details_en': detailsEnController.text.trim(),
                            'details_bn': detailsBnController.text.trim(),
                            'rating': double.tryParse(ratingController.text.trim()) ?? 4.7,
                            'trips': int.tryParse(tripsController.text.trim()) ?? 100,
                          };

                          bool success = false;
                          if (isEdit) {
                            final res = await ApiService.updateContent(boatman['_id'], item);
                            success = res != null;
                          } else {
                            final res = await ApiService.createContent('boat', item);
                            success = res != null;
                          }

                          if (success) {
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(isEdit ? 'Boatman updated successfully' : 'Boatman added successfully')),
                              );
                            }
                            _loadBoatmen();
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Failed to save boatman details'), backgroundColor: Colors.redAccent),
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
                        child: Text(isEdit ? 'Update Boatman' : 'Create Boatman', style: const TextStyle(fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final isSuperAdmin = userProvider.isSuperAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text(langProvider.translate('boat_booking')),
        actions: [
          if (isSuperAdmin)
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, size: 28),
              tooltip: 'Add Boatman',
              onPressed: () => _addOrEditBoatman(),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _boatmen.isEmpty
              ? Center(
                  child: Text(
                    langProvider.isBangla ? 'কোনো নৌযান চালক পাওয়া যায়নি' : 'No boatmen available',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadBoatmen,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _boatmen.length,
                    itemBuilder: (context, index) {
                      final b = _boatmen[index];
                      final name = langProvider.isBangla ? b['name_bn'] : b['name_en'];
                      final boatName = langProvider.isBangla ? b['boat_bn'] : b['boat_en'];
                      final price = langProvider.isBangla ? b['price_bn'] : b['price_en'];
                      final details = langProvider.isBangla ? b['details_bn'] : b['details_en'];

                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        margin: const EdgeInsets.only(bottom: 16),
                        clipBehavior: Clip.antiAlias,
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Boatman Photo with Edit/Delete options for Admin
                                  Column(
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: const Color(0xFF00B4DB), width: 2),
                                          image: DecorationImage(
                                            image: NetworkImage(b['image'] ?? ''),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      if (isSuperAdmin) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit, color: Color(0xFF00B4DB), size: 20),
                                              onPressed: () => _addOrEditBoatman(boatman: b),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                              onPressed: () => _deleteBoatman(b['_id']),
                                            ),
                                          ],
                                        )
                                      ]
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  
                                  // Details Text
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                name ?? '',
                                                style: TextStyle(
                                                  color: Theme.of(context).colorScheme.onSurface,
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${b['rating']}',
                                                    style: TextStyle(
                                                      color: Theme.of(context).colorScheme.onSurface,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          boatName ?? '',
                                          style: const TextStyle(
                                            color: Color(0xFF00B4DB),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          details ?? '',
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Divider(color: Theme.of(context).dividerColor, height: 24),
                              
                              // Bottom Pricing and Call Actions
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        langProvider.isBangla ? 'ভাড়া' : 'Rental Price',
                                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 10),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        price ?? '',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurface,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  // Reviews Button
                                  TextButton.icon(
                                    onPressed: () => _showReviewsModal(context, name ?? '', 'board', b['name_en'] ?? ''), // using 'board' itemType to share reviews space if matching speed boat reviews structure
                                    icon: const Icon(Icons.star_outline_rounded, size: 16, color: Color(0xFF00B4DB)),
                                    label: Text(
                                      langProvider.isBangla ? 'রিভিউ' : 'Reviews',
                                      style: const TextStyle(color: Color(0xFF00B4DB), fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  // Direct Call Button
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF00B4DB),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    ),
                                    onPressed: () => _callBoatman(b['phone'] ?? '', context),
                                    icon: const Icon(Icons.call, size: 14),
                                    label: Text(
                                      langProvider.isBangla ? 'কল করুন' : 'Call Now',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
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
