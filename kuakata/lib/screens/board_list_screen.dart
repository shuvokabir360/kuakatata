import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../providers/language_provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import 'reviews_section.dart';

class BoardListScreen extends StatefulWidget {
  const BoardListScreen({Key? key}) : super(key: key);

  @override
  State<BoardListScreen> createState() => _BoardListScreenState();
}

class _BoardListScreenState extends State<BoardListScreen> {
  List<Map<String, dynamic>> _drivers = [];
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
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final data = await ApiService.fetchContent('board');
      setState(() {
        _drivers = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading speedboards: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _callDriver(String phone, BuildContext context) async {
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

  Future<void> _deleteDriver(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this speedboat driver?'),
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
      final success = await ApiService.deleteContent('board', id);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Driver deleted successfully')),
          );
        }
        _loadDrivers();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete driver'), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  void _addOrEditDriver({Map<String, dynamic>? driver}) {
    final isEdit = driver != null;
    final nameEnController = TextEditingController(text: isEdit ? driver['name_en'] : '');
    final nameBnController = TextEditingController(text: isEdit ? driver['name_bn'] : '');
    final boatEnController = TextEditingController(text: isEdit ? driver['boat_en'] : '');
    final boatBnController = TextEditingController(text: isEdit ? driver['boat_bn'] : '');
    final priceEnController = TextEditingController(text: isEdit ? driver['price_en'] : '');
    final priceBnController = TextEditingController(text: isEdit ? driver['price_bn'] : '');
    final phoneController = TextEditingController(text: isEdit ? driver['phone'] : '');
    final imageController = TextEditingController(text: isEdit ? driver['image'] : '');
    final detailsEnController = TextEditingController(text: isEdit ? driver['details_en'] : '');
    final detailsBnController = TextEditingController(text: isEdit ? driver['details_bn'] : '');
    final ratingController = TextEditingController(text: isEdit ? driver['rating']?.toString() : '4.9');
    final tripsController = TextEditingController(text: isEdit ? driver['trips']?.toString() : '100');

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
                            isEdit ? 'Edit Speedboat Driver Details' : 'Add New Driver',
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
                        decoration: const InputDecoration(labelText: 'Driver Name (English)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nameBnController,
                        decoration: const InputDecoration(labelText: 'Driver Name (Bangla)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: boatEnController,
                              decoration: const InputDecoration(labelText: 'Speedboat details (English)', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: boatBnController,
                              decoration: const InputDecoration(labelText: 'Speedboat details (Bangla)', border: OutlineInputBorder()),
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
                              decoration: const InputDecoration(labelText: 'Price (English, e.g. ৳1,500 / trip)', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: priceBnController,
                              decoration: const InputDecoration(labelText: 'Price (Bangla, e.g. ৳১,৫০০ / ট্রিপ)', border: OutlineInputBorder()),
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
                              decoration: const InputDecoration(labelText: 'Rating (e.g. 4.9)', border: OutlineInputBorder()),
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
                                labelText: 'Driver Image URL',
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
                        decoration: const InputDecoration(labelText: 'Experience/Details (English)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: detailsBnController,
                        decoration: const InputDecoration(labelText: 'Experience/Details (Bangla)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () async {
                          if (nameEnController.text.isEmpty || nameBnController.text.isEmpty || phoneController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please fill in Driver Name and Phone Number')),
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
                                : 'https://images.unsplash.com/photo-1500048993953-d23a436266cf?auto=format&fit=crop&w=300&q=80',
                            'details_en': detailsEnController.text.trim(),
                            'details_bn': detailsBnController.text.trim(),
                            'rating': double.tryParse(ratingController.text.trim()) ?? 4.9,
                            'trips': int.tryParse(tripsController.text.trim()) ?? 100,
                          };

                          bool success = false;
                          if (isEdit) {
                            final res = await ApiService.updateContent(driver['_id'], item);
                            success = res != null;
                          } else {
                            final res = await ApiService.createContent('board', item);
                            success = res != null;
                          }

                          if (success) {
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(isEdit ? 'Driver updated successfully' : 'Driver added successfully')),
                              );
                            }
                            _loadDrivers();
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Failed to save driver details'), backgroundColor: Colors.redAccent),
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
                        child: Text(isEdit ? 'Update Driver' : 'Create Driver', style: const TextStyle(fontWeight: FontWeight.bold)),
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
        title: Text(langProvider.translate('board_booking')),
        actions: [
          if (isSuperAdmin)
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, size: 28),
              tooltip: 'Add Driver',
              onPressed: () => _addOrEditDriver(),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _drivers.isEmpty
              ? Center(
                  child: Text(
                    langProvider.isBangla ? 'কোনো স্পিডবোট চালক পাওয়া যায়নি' : 'No drivers available',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDrivers,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _drivers.length,
                    itemBuilder: (context, index) {
                      final d = _drivers[index];
                      final name = langProvider.isBangla ? d['name_bn'] : d['name_en'];
                      final boatName = langProvider.isBangla ? d['boat_bn'] : d['boat_en'];
                      final price = langProvider.isBangla ? d['price_bn'] : d['price_en'];
                      final details = langProvider.isBangla ? d['details_bn'] : d['details_en'];

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
                                  // Driver Photo with edit/delete controls
                                  Column(
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: const Color(0xFF00B4DB), width: 2),
                                          image: DecorationImage(
                                            image: NetworkImage(d['image'] ?? ''),
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
                                              onPressed: () => _addOrEditDriver(driver: d),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                              onPressed: () => _deleteDriver(d['_id']),
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
                                                    '${d['rating']}',
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
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          langProvider.isBangla ? 'ভাড়া রেঞ্জ' : 'Trip Fare',
                                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 10),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          price ?? '',
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.onSurface,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Reviews Button
                                  TextButton.icon(
                                    onPressed: () => _showReviewsModal(context, name ?? '', 'board', d['name_en'] ?? ''),
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
                                    onPressed: () => _callDriver(d['phone'] ?? '', context),
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
