import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../providers/language_provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({Key? key}) : super(key: key);

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _hotel;
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final hotelId = userProvider.managedHotelId;

    if (hotelId.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // Load hotels and find this manager's hotel
      final hotels = await ApiService.fetchContent('hotel');
      final matchedHotel = hotels.firstWhere(
        (h) => h['_id'] == hotelId,
        orElse: () => <String, dynamic>{},
      );

      // Load bookings for this hotel
      final bookingsList = await ApiService.fetchManagerBookings(hotelId);

      setState(() {
        _hotel = matchedHotel.isNotEmpty ? matchedHotel : null;
        _bookings = bookingsList;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading manager dashboard data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateBookingStatus(String bookingId, String newStatus) async {
    final success = await ApiService.updateBookingStatus(bookingId, newStatus);
    if (success != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking status updated to $newStatus')),
        );
      }
      _loadDashboardData();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update booking status'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

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
            toolbarTitle: 'Crop Room Image',
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
            title: 'Crop Room Image',
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

  void _addOrEditRoom({Map<String, dynamic>? room, int? index}) {
    if (_hotel == null) return;

    final isEdit = room != null;
    final nameEnController = TextEditingController(text: isEdit ? room['name_en'] : '');
    final nameBnController = TextEditingController(text: isEdit ? room['name_bn'] : '');
    final priceController = TextEditingController(text: isEdit ? room['price']?.toString() : '');
    final imageController = TextEditingController(text: isEdit ? room['image'] : '');
    final amenitiesEnController = TextEditingController(text: isEdit ? (room['amenities_en'] as List?)?.join(', ') : '');
    final amenitiesBnController = TextEditingController(text: isEdit ? (room['amenities_bn'] as List?)?.join(', ') : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                            isEdit ? 'Edit Room Details' : 'Add New Room',
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
                        decoration: const InputDecoration(labelText: 'Room Name (English)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nameBnController,
                        decoration: const InputDecoration(labelText: 'Room Name (Bangla)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Price (৳ / Night)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: imageController,
                              decoration: const InputDecoration(
                                labelText: 'Room Image URL',
                                border: OutlineInputBorder(),
                                hintText: 'Enter URL or upload',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _pickAndUploadImage(imageController, context, setDialogState),
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
                        controller: amenitiesEnController,
                        decoration: const InputDecoration(
                          labelText: 'Amenities (English, comma separated)',
                          hintText: 'e.g. AC, Wifi, TV',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: amenitiesBnController,
                        decoration: const InputDecoration(
                          labelText: 'Amenities (Bangla, comma separated)',
                          hintText: 'e.g. এসি, ওয়াইফাই, টিভি',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () async {
                          if (nameEnController.text.isEmpty ||
                              nameBnController.text.isEmpty ||
                              priceController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please fill all required fields')),
                            );
                            return;
                          }

                          final roomMap = {
                            'name_en': nameEnController.text.trim(),
                            'name_bn': nameBnController.text.trim(),
                            'price': int.tryParse(priceController.text.trim()) ?? 0,
                            'image': imageController.text.trim().isNotEmpty
                                ? imageController.text.trim()
                                : 'https://images.unsplash.com/photo-1611891405788-d130a84e2d9a?auto=format&fit=crop&w=400&q=80',
                            'amenities_en': amenitiesEnController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
                            'amenities_bn': amenitiesBnController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
                          };

                          final updatedRooms = List<Map<String, dynamic>>.from(
                            (_hotel!['rooms'] as List?)?.map((r) => Map<String, dynamic>.from(r)) ?? [],
                          );

                          if (isEdit && index != null) {
                            updatedRooms[index] = roomMap;
                          } else {
                            updatedRooms.add(roomMap);
                          }

                          final updatedHotel = Map<String, dynamic>.from(_hotel!);
                          updatedHotel['rooms'] = updatedRooms;

                          setState(() {
                            _isLoading = true;
                          });

                          final result = await ApiService.updateContent(_hotel!['_id'], updatedHotel);
                          if (result != null) {
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(isEdit ? 'Room updated successfully' : 'Room added successfully')),
                              );
                            }
                            _loadDashboardData();
                          } else {
                            setState(() {
                              _isLoading = false;
                            });
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Failed to save room details'), backgroundColor: Colors.redAccent),
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
                        child: Text(isEdit ? 'Update Room' : 'Create Room', style: const TextStyle(fontWeight: FontWeight.bold)),
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

  void _deleteRoom(int index) async {
    if (_hotel == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this room?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final updatedRooms = List<Map<String, dynamic>>.from(
        (_hotel!['rooms'] as List?)?.map((r) => Map<String, dynamic>.from(r)) ?? [],
      );

      updatedRooms.removeAt(index);

      final updatedHotel = Map<String, dynamic>.from(_hotel!);
      updatedHotel['rooms'] = updatedRooms;

      setState(() {
        _isLoading = true;
      });

      final result = await ApiService.updateContent(_hotel!['_id'], updatedHotel);
      if (result != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Room deleted successfully')),
          );
        }
        _loadDashboardData();
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete room'), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    if (userProvider.managedHotelId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Manager Dashboard')),
        body: const Center(
          child: Text('Error: No hotel assigned to this manager account.', style: TextStyle(color: Colors.redAccent)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_hotel != null ? (langProvider.isBangla ? _hotel!['name_bn'] : _hotel!['name_en']) : 'Hotel Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.book_online), text: 'Bookings'),
            Tab(icon: Icon(Icons.meeting_room), text: 'Rooms'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeaderStats(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBookingsTab(langProvider),
                      _buildRoomsTab(langProvider),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeaderStats() {
    if (_hotel == null) return const SizedBox.shrink();

    final roomCount = (_hotel!['rooms'] as List?)?.length ?? 0;
    final pendingCount = _bookings.where((b) => b['status'] == 'Pending').length;
    final confirmedCount = _bookings.where((b) => b['status'] == 'Confirmed').length;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF00B4DB).withOpacity(0.06),
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard('Total Rooms', roomCount.toString(), Icons.meeting_room, Colors.blue),
          _buildStatCard('Confirmed', confirmedCount.toString(), Icons.check_circle, Colors.green),
          _buildStatCard('Pending', pendingCount.toString(), Icons.hourglass_empty, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String val, IconData icon, Color color) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 6),
                Text(
                  val,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: onSurface),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsTab(LanguageProvider langProvider) {
    if (_bookings.isEmpty) {
      return Center(
        child: Text(
          langProvider.isBangla ? 'কোনো বুকিং পাওয়া যায়নি' : 'No bookings found',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _bookings.length,
        itemBuilder: (context, index) {
          final b = _bookings[index];
          final customerName = b['customerName'] ?? '';
          final customerPhone = b['customerPhone'] ?? '';
          final serviceName = b['serviceName'] ?? '';
          final checkInDate = b['checkInDate'] ?? '';
          final checkOutDate = b['checkOutDate'] ?? '';
          final totalCost = b['totalCost'] ?? 0;
          final status = b['status'] ?? 'Pending';
          final bookingId = b['_id'] ?? b['id'];

          Color statusColor = Colors.orange;
          if (status == 'Confirmed') statusColor = Colors.green;
          if (status == 'Cancelled') statusColor = Colors.red;

          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          serviceName,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildBookingDetailRow(Icons.person, 'Guest: $customerName'),
                  const SizedBox(height: 6),
                  _buildBookingDetailRow(Icons.phone, 'Phone: $customerPhone'),
                  const SizedBox(height: 6),
                  _buildBookingDetailRow(Icons.date_range, 'Check In: $checkInDate'),
                  const SizedBox(height: 6),
                  _buildBookingDetailRow(Icons.date_range, 'Check Out: $checkOutDate'),
                  const SizedBox(height: 6),
                  _buildBookingDetailRow(Icons.monetization_on, 'Total cost: ৳$totalCost'),
                  
                  if (status == 'Pending') ...[
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _updateBookingStatus(bookingId, 'Cancelled'),
                          icon: const Icon(Icons.cancel, color: Colors.red, size: 16),
                          label: const Text('Cancel', style: TextStyle(color: Colors.red)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () => _updateBookingStatus(bookingId, 'Confirmed'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Confirm'),
                        ),
                      ],
                    ),
                  ]
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookingDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildRoomsTab(LanguageProvider langProvider) {
    final rooms = _hotel != null ? (_hotel!['rooms'] as List?) : null;

    if (rooms == null || rooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              langProvider.isBangla ? 'কোনো রুম পাওয়া যায়নি' : 'No rooms added yet',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _addOrEditRoom(),
              icon: const Icon(Icons.add),
              label: const Text('Add Room'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00B4DB), foregroundColor: Colors.white),
            )
          ],
        ),
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditRoom(),
        backgroundColor: const Color(0xFF00B4DB),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: rooms.length,
        itemBuilder: (context, index) {
          final room = Map<String, dynamic>.from(rooms[index]);
          final roomName = langProvider.isBangla ? room['name_bn'] : room['name_en'];
          final price = room['price'] ?? 0;
          final imageUrl = room['image'] ?? '';
          final amenities = langProvider.isBangla ? (room['amenities_bn'] as List?)?.join(', ') : (room['amenities_en'] as List?)?.join(', ');

          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            margin: const EdgeInsets.only(bottom: 16),
            clipBehavior: Clip.antiAlias,
            elevation: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.network(
                  imageUrl,
                  height: 140,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(color: Colors.white10, height: 140),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              roomName ?? '',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            '৳$price / Night',
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF00B4DB),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (amenities != null && amenities.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Amenities: $amenities',
                          style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
                        ),
                      ],
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Color(0xFF00B4DB)),
                            onPressed: () => _addOrEditRoom(room: room, index: index),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () => _deleteRoom(index),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
