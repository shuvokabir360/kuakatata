import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../providers/language_provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import 'hotel_detail_screen.dart';

class HotelListScreen extends StatefulWidget {
  const HotelListScreen({Key? key}) : super(key: key);

  @override
  State<HotelListScreen> createState() => _HotelListScreenState();
}

class _HotelListScreenState extends State<HotelListScreen> {
  List<Map<String, dynamic>> _hotels = [];
  bool _isLoading = true;

  Future<void> _pickAndUploadImage(TextEditingController controller, BuildContext context, Function setModalState) async {
    final picker = ImagePicker();
    
    // Choose Source: Gallery or Camera
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

      // Crop the Image to a specific size/aspect ratio (e.g. 3:2 aspect ratio, common for hotels)
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Hotel Image',
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
            title: 'Crop Hotel Image',
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

      // Show a loading dialog
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Read image bytes and convert to base64
      final bytes = await croppedFile.readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      // Upload image
      final uploadedUrl = await ApiService.uploadImage(base64Image);

      // Dismiss loading dialog
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

  Future<void> _pickAndUploadGalleryImage(List<String> imagesList, BuildContext context, Function setModalState) async {
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
            toolbarTitle: 'Crop Hotel Image',
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
            title: 'Crop Hotel Image',
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
          imagesList.add(uploadedUrl);
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

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadHotels();
    // Refresh hotels silently in the background every 10 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted && !_isLoading) {
        _loadHotelsBackground();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadHotelsBackground() async {
    try {
      final data = await ApiService.fetchContent('hotel');
      if (mounted) {
        setState(() {
          _hotels = data;
        });
      }
    } catch (e) {
      debugPrint('Background error loading hotels: $e');
    }
  }

  Future<void> _loadHotels() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final data = await ApiService.fetchContent('hotel');
      setState(() {
        _hotels = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading hotels: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteHotel(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this hotel?'),
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
      final success = await ApiService.deleteContent('hotel', id);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hotel deleted successfully')),
          );
        }
        _loadHotels();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete hotel'), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  void _addOrEditHotel({Map<String, dynamic>? hotel}) {
    final isEdit = hotel != null;
    final nameEnController = TextEditingController(text: isEdit ? hotel['name_en'] : '');
    final nameBnController = TextEditingController(text: isEdit ? hotel['name_bn'] : '');
    List<String> hotelImages = isEdit
        ? List<String>.from(hotel['images'] ?? (hotel['image'] != null && hotel['image'].toString().isNotEmpty ? [hotel['image']] : []))
        : [];
    final ratingController = TextEditingController(text: isEdit ? hotel['rating']?.toString() : '4.5');
    final reviewsController = TextEditingController(text: isEdit ? hotel['reviews']?.toString() : '100');
    final distanceEnController = TextEditingController(text: isEdit ? hotel['distance_en'] : '');
    final distanceBnController = TextEditingController(text: isEdit ? hotel['distance_bn'] : '');
    final priceRangeController = TextEditingController(text: isEdit ? hotel['priceRange'] : '');
    final phoneController = TextEditingController(text: isEdit ? hotel['phone'] : '');
    final descEnController = TextEditingController(text: isEdit ? hotel['desc_en'] : '');
    final descBnController = TextEditingController(text: isEdit ? hotel['desc_bn'] : '');
    
    // tags formatting comma separated
    final tagsEnController = TextEditingController(text: isEdit ? (hotel['tags_en'] as List?)?.join(', ') : '');
    final tagsBnController = TextEditingController(text: isEdit ? (hotel['tags_bn'] as List?)?.join(', ') : '');

    List<Map<String, dynamic>> hotelRooms = isEdit 
        ? List<Map<String, dynamic>>.from((hotel['rooms'] as List?)?.map((r) => Map<String, dynamic>.from(r)) ?? [])
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
                            isEdit ? 'Edit Hotel Details' : 'Add New Hotel',
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
                        decoration: const InputDecoration(labelText: 'Hotel Name (English)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nameBnController,
                        decoration: const InputDecoration(labelText: 'Hotel Name (Bangla)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Hotel Gallery Images',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 120,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            GestureDetector(
                              onTap: () => _pickAndUploadGalleryImage(hotelImages, context, setModalState),
                              child: Container(
                                width: 120,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFF00B4DB), width: 1.5),
                                  borderRadius: BorderRadius.circular(12),
                                  color: const Color(0xFF00B4DB).withOpacity(0.05),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate_rounded, color: Color(0xFF00B4DB), size: 32),
                                    SizedBox(height: 6),
                                    Text('Add Image', style: TextStyle(color: Color(0xFF00B4DB), fontSize: 12, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                            ...hotelImages.asMap().entries.map((entry) {
                              final index = entry.key;
                              final url = entry.value;
                              return Stack(
                                children: [
                                  Container(
                                    width: 120,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      image: DecorationImage(
                                        image: NetworkImage(url),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 16,
                                    child: GestureDetector(
                                      onTap: () {
                                        setModalState(() {
                                          hotelImages.removeAt(index);
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                                  if (index == 0)
                                    Positioned(
                                      bottom: 4,
                                      left: 4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF00B4DB),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'Main',
                                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: ratingController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Rating (e.g. 4.8)', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: reviewsController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Reviews Count', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: distanceEnController,
                              decoration: const InputDecoration(labelText: 'Distance (English)', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: distanceBnController,
                              decoration: const InputDecoration(labelText: 'Distance (Bangla)', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: priceRangeController,
                              decoration: const InputDecoration(labelText: 'Price Range (e.g. ৳3,000 - ৳5,000)', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: tagsEnController,
                        decoration: const InputDecoration(labelText: 'Tags English (comma separated)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: tagsBnController,
                        decoration: const InputDecoration(labelText: 'Tags Bangla (comma separated)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descEnController,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'Description (English)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descBnController,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'Description (Bangla)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 20),
                      
                      // ROOMS MANAGEMENT SECTION
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Rooms List',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final room = await _showRoomDialog();
                              if (room != null) {
                                setModalState(() {
                                  hotelRooms.add(room);
                                });
                              }
                            },
                            icon: const Icon(Icons.add, size: 14),
                            label: const Text('Add Room', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00B4DB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      hotelRooms.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Theme.of(context).dividerColor),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Text('No rooms added. Add at least one room.'),
                              ),
                            )
                          : Column(
                              children: hotelRooms.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final r = entry.value;
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  child: ListTile(
                                    leading: Image.network(
                                      r['image'] ?? '',
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => Container(color: Colors.white10, width: 48, height: 48),
                                    ),
                                    title: Text(r['name_en'] ?? ''),
                                    subtitle: Text('৳${r['price']}'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Color(0xFF00B4DB), size: 20),
                                          onPressed: () async {
                                            final updatedRoom = await _showRoomDialog(room: r);
                                            if (updatedRoom != null) {
                                              setModalState(() {
                                                hotelRooms[idx] = updatedRoom;
                                              });
                                            }
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                          onPressed: () {
                                            setModalState(() {
                                              hotelRooms.removeAt(idx);
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                      
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () async {
                          if (nameEnController.text.isEmpty || nameBnController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please fill in both English and Bangla names')),
                            );
                            return;
                          }

                          final item = {
                            'name_en': nameEnController.text.trim(),
                            'name_bn': nameBnController.text.trim(),
                            'image': hotelImages.isNotEmpty
                                ? hotelImages.first
                                : 'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=600&q=80',
                            'images': hotelImages,
                            'rating': double.tryParse(ratingController.text.trim()) ?? 4.5,
                            'reviews': int.tryParse(reviewsController.text.trim()) ?? 100,
                            'distance_en': distanceEnController.text.trim(),
                            'distance_bn': distanceBnController.text.trim(),
                            'priceRange': priceRangeController.text.trim(),
                            'phone': phoneController.text.trim(),
                            'desc_en': descEnController.text.trim(),
                            'desc_bn': descBnController.text.trim(),
                            'tags_en': tagsEnController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
                            'tags_bn': tagsBnController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
                            'rooms': hotelRooms,
                          };

                          bool success = false;
                          if (isEdit) {
                            final res = await ApiService.updateContent(hotel['_id'], item);
                            success = res != null;
                          } else {
                            final res = await ApiService.createContent('hotel', item);
                            success = res != null;
                          }

                          if (success) {
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(isEdit ? 'Hotel updated successfully' : 'Hotel added successfully')),
                              );
                            }
                            _loadHotels();
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Failed to save hotel details'), backgroundColor: Colors.redAccent),
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
                        child: Text(isEdit ? 'Update Hotel' : 'Create Hotel', style: const TextStyle(fontWeight: FontWeight.bold)),
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

  Future<Map<String, dynamic>?> _showRoomDialog({Map<String, dynamic>? room}) async {
    final isEdit = room != null;
    final rNameEn = TextEditingController(text: isEdit ? room['name_en'] : '');
    final rNameBn = TextEditingController(text: isEdit ? room['name_bn'] : '');
    final rPrice = TextEditingController(text: isEdit ? room['price']?.toString() : '');
    final rImage = TextEditingController(text: isEdit ? room['image'] : '');
    final rAmenEn = TextEditingController(text: isEdit ? (room['amenities_en'] as List?)?.join(', ') : '');
    final rAmenBn = TextEditingController(text: isEdit ? (room['amenities_bn'] as List?)?.join(', ') : '');

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEdit ? 'Edit Room' : 'Add New Room'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: rNameEn, decoration: const InputDecoration(labelText: 'Room Name (EN)')),
                    const SizedBox(height: 8),
                    TextField(controller: rNameBn, decoration: const InputDecoration(labelText: 'Room Name (BN)')),
                    const SizedBox(height: 8),
                    TextField(controller: rPrice, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (৳)')),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: rImage,
                            decoration: const InputDecoration(labelText: 'Image URL'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.upload_file, color: Color(0xFF00B4DB)),
                          onPressed: () => _pickAndUploadImage(rImage, context, setDialogState),
                          tooltip: 'Upload Room Image',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(controller: rAmenEn, decoration: const InputDecoration(labelText: 'Amenities (EN, comma separated)')),
                    const SizedBox(height: 8),
                    TextField(controller: rAmenBn, decoration: const InputDecoration(labelText: 'Amenities (BN, comma separated)')),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                if (rNameEn.text.isEmpty || rNameBn.text.isEmpty || rPrice.text.isEmpty) {
                  return;
                }
                Navigator.pop(context, {
                  'name_en': rNameEn.text.trim(),
                  'name_bn': rNameBn.text.trim(),
                  'price': int.tryParse(rPrice.text.trim()) ?? 0,
                  'image': rImage.text.trim().isNotEmpty
                      ? rImage.text.trim()
                      : 'https://images.unsplash.com/photo-1611891405788-d130a84e2d9a?auto=format&fit=crop&w=400&q=80',
                  'amenities_en': rAmenEn.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
                  'amenities_bn': rAmenBn.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
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

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final isSuperAdmin = userProvider.isSuperAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text(langProvider.translate('hotel_booking')),
        actions: [
          if (isSuperAdmin)
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, size: 28),
              tooltip: 'Add Hotel',
              onPressed: () => _addOrEditHotel(),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hotels.isEmpty
              ? Center(
                  child: Text(
                    langProvider.isBangla ? 'কোনো হোটেল পাওয়া যায়নি' : 'No hotels available',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadHotels,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _hotels.length,
                    itemBuilder: (context, index) {
                      final h = _hotels[index];
                      final name = langProvider.isBangla ? h['name_bn'] : h['name_en'];
                      final distance = langProvider.isBangla ? h['distance_bn'] : h['distance_en'];
                      final tags = langProvider.isBangla ? (h['tags_bn'] as List?) : (h['tags_en'] as List?);

                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        margin: const EdgeInsets.only(bottom: 20),
                        clipBehavior: Clip.antiAlias,
                        elevation: 4,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HotelDetailScreen(hotel: h),
                              ),
                            ).then((_) => _loadHotels());
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Hotel image with rating badge
                              Stack(
                                children: [
                                  Image.network(
                                    h['image'] ?? '',
                                    height: 180,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Container(color: Colors.white10, height: 180),
                                  ),
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.75),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${h['rating']}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (isSuperAdmin)
                                    Positioned(
                                      top: 12,
                                      left: 12,
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: Colors.black.withOpacity(0.7),
                                            child: IconButton(
                                              icon: const Icon(Icons.edit, color: Colors.white),
                                              onPressed: () => _addOrEditHotel(hotel: h),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          CircleAvatar(
                                            backgroundColor: Colors.black.withOpacity(0.7),
                                            child: IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                                              onPressed: () => _deleteHotel(h['_id']),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              
                              // Hotel Details info
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    isSuperAdmin
                                        ? GestureDetector(
                                            onTap: () => _addOrEditHotel(hotel: h),
                                            child: Text(
                                              name ?? '',
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.onSurface,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                decoration: TextDecoration.underline,
                                                decorationStyle: TextDecorationStyle.dashed,
                                                decorationColor: const Color(0xFF00B4DB),
                                              ),
                                            ),
                                          )
                                        : Text(
                                            name ?? '',
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.onSurface,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_rounded, color: Color(0xFF00B4DB), size: 14),
                                        const SizedBox(width: 6),
                                        Text(
                                          distance ?? '',
                                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    // Tags wrap
                                    if (tags != null)
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        children: tags.map<Widget>((tag) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF00B4DB).withOpacity(0.08),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: const Color(0xFF00B4DB).withOpacity(0.15)),
                                            ),
                                            child: Text(
                                              tag.toString(),
                                              style: const TextStyle(color: Color(0xFF00B4DB), fontSize: 11),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    Divider(color: Theme.of(context).dividerColor, height: 24),
                                    
                                    // Price & View Rooms button
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              langProvider.isBangla ? 'ভাড়ার রেঞ্জ' : 'Price Range',
                                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 11),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              h['priceRange'] ?? '',
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.onSurface,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(10),
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Text(
                                                langProvider.isBangla ? 'রুম দেখুন' : 'View Rooms',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                                            ],
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
    );
  }
}
