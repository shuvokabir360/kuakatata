import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../providers/language_provider.dart';
import '../services/api_service.dart';


class SuperAdminHotelManagement extends StatefulWidget {
  const SuperAdminHotelManagement({Key? key}) : super(key: key);

  @override
  State<SuperAdminHotelManagement> createState() => _SuperAdminHotelManagementState();
}

class _SuperAdminHotelManagementState extends State<SuperAdminHotelManagement> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _hotels = [];
  List<Map<String, dynamic>> _managers = [];
  List<Map<String, dynamic>> _reviews = [];
  List<Map<String, dynamic>> _complaints = [];
  List<Map<String, dynamic>> _spots = [];
  List<Map<String, dynamic>> _slides = [];
  List<Map<String, dynamic>> _bikes = [];
  List<Map<String, dynamic>> _vans = [];
  List<Map<String, dynamic>> _boards = [];
  List<Map<String, dynamic>> _boats = [];
  List<Map<String, dynamic>> _foods = [];
  bool _isLoading = true;
  String _activeSubTab = 'reviews';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 10, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final hotelsData = await ApiService.fetchContent('hotel');
      final managersData = await ApiService.fetchManagers();
      final reviewsData = await ApiService.fetchAdminReviews();
      final complaintsData = await ApiService.fetchAdminComplaints();
      final spotsData = await ApiService.fetchContent('spot');
      final slidesData = await ApiService.fetchContent('slider');
      
      final bikesData = await ApiService.fetchContent('bike');
      final vansData = await ApiService.fetchContent('van');
      final boardsData = await ApiService.fetchContent('board');
      final boatsData = await ApiService.fetchContent('boat');
      final foodsData = await ApiService.fetchContent('food');

      setState(() {
        _hotels = hotelsData;
        _managers = managersData;
        _reviews = reviewsData;
        _complaints = complaintsData;
        _spots = spotsData;
        _slides = slidesData;
        _bikes = bikesData;
        _vans = vansData;
        _boards = boardsData;
        _boats = boatsData;
        _foods = foodsData;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading management data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showCreateManagerDialog() {
    if (_hotels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one hotel first!'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final nameController = TextEditingController();
    final mobileController = TextEditingController();
    final pinController = TextEditingController();
    final emailController = TextEditingController();
    final addressController = TextEditingController();
    String? selectedHotelId = _hotels.first['_id'];

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
                          const Text(
                            'Create Hotel Manager',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Manager Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: mobileController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Mobile Number',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: pinController,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        maxLength: 6,
                        decoration: const InputDecoration(
                          labelText: '6-digit PIN',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email Address (Optional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: addressController,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedHotelId,
                        decoration: const InputDecoration(
                          labelText: 'Assign Hotel',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.hotel),
                        ),
                        items: _hotels.map((h) {
                          return DropdownMenuItem<String>(
                            value: h['_id'],
                            child: Text(h['name_en'] ?? 'Unnamed Hotel'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            selectedHotelId = val;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () async {
                          if (nameController.text.isEmpty ||
                              mobileController.text.isEmpty ||
                              pinController.text.length != 6 ||
                              addressController.text.isEmpty ||
                              selectedHotelId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill all fields and enter a 6-digit PIN'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                            return;
                          }

                          final selectedHotel = _hotels.firstWhere((h) => h['_id'] == selectedHotelId);
                          final hotelName = selectedHotel['name_en'] ?? '';

                          final managerData = {
                            'name': nameController.text.trim(),
                            'mobile': mobileController.text.trim(),
                            'pin': pinController.text.trim(),
                            'email': emailController.text.trim(),
                            'address': addressController.text.trim(),
                            'managedHotelId': selectedHotelId,
                            'hotelName': hotelName,
                          };

                          final result = await ApiService.createManager(managerData);
                          if (result != null) {
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Manager account created successfully')),
                              );
                            }
                            _loadData();
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to create manager. Account may already exist.'),
                                  backgroundColor: Colors.redAccent,
                                ),
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
                        child: const Text('Create Manager Account', style: TextStyle(fontWeight: FontWeight.bold)),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hotel & App Management'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.hotel), text: 'Hotels Directory'),
            Tab(icon: Icon(Icons.people), text: 'Manager Accounts'),
            Tab(icon: Icon(Icons.rate_review), text: 'Reviews & Complaints'),
            Tab(icon: Icon(Icons.explore), text: 'Popular Spots'),
            Tab(icon: Icon(Icons.photo_library), text: 'Home Slider'),
            Tab(icon: Icon(Icons.motorcycle), text: 'Bikes Directory'),
            Tab(icon: Icon(Icons.electric_car), text: 'Vans Directory'),
            Tab(icon: Icon(Icons.directions_boat), text: 'Speedboats Directory'),
            Tab(icon: Icon(Icons.sailing), text: 'Boats Directory'),
            Tab(icon: Icon(Icons.restaurant), text: 'Restaurants & Food'),
          ],
        ),
      ),
      floatingActionButton: () {
        if (_tabController.index == 1) {
          return FloatingActionButton(
            onPressed: _showCreateManagerDialog,
            backgroundColor: const Color(0xFF00B4DB),
            child: const Icon(Icons.person_add, color: Colors.white),
          );
        } else if (_tabController.index == 2) {
          return null;
        } else if (_tabController.index == 3) {
          return FloatingActionButton(
            onPressed: () => _showAddEditSpotDialog(langProvider, null),
            backgroundColor: const Color(0xFF00B4DB),
            child: const Icon(Icons.add_location_alt_rounded, color: Colors.white),
          );
        } else if (_tabController.index == 4) {
          return FloatingActionButton(
            onPressed: () => _showAddEditSlideDialog(langProvider, null),
            backgroundColor: const Color(0xFF00B4DB),
            child: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white),
          );
        } else if (_tabController.index == 5) {
          return FloatingActionButton(
            onPressed: () => _showAddEditBikeDialog(langProvider, null),
            backgroundColor: const Color(0xFF00B4DB),
            child: const Icon(Icons.motorcycle, color: Colors.white),
          );
        } else if (_tabController.index == 6) {
          return FloatingActionButton(
            onPressed: () => _showAddEditVanDialog(langProvider, null),
            backgroundColor: const Color(0xFF00B4DB),
            child: const Icon(Icons.electric_car, color: Colors.white),
          );
        } else if (_tabController.index == 7) {
          return FloatingActionButton(
            onPressed: () => _showAddEditBoardDialog(langProvider, null),
            backgroundColor: const Color(0xFF00B4DB),
            child: const Icon(Icons.directions_boat, color: Colors.white),
          );
        } else if (_tabController.index == 8) {
          return FloatingActionButton(
            onPressed: () => _showAddEditBoatDialog(langProvider, null),
            backgroundColor: const Color(0xFF00B4DB),
            child: const Icon(Icons.sailing, color: Colors.white),
          );
        } else if (_tabController.index == 9) {
          return FloatingActionButton(
            onPressed: () => _showAddEditFoodDialog(langProvider, null),
            backgroundColor: const Color(0xFF00B4DB),
            child: const Icon(Icons.restaurant, color: Colors.white),
          );
        }
        return null;
      }(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildHotelsDirectoryTab(langProvider),
                _buildManagersTab(),
                _buildReviewsComplaintsTab(langProvider),
                _buildSpotsTab(langProvider),
                _buildSliderTab(langProvider),
                _buildBikesTab(langProvider),
                _buildVansTab(langProvider),
                _buildSpeedboatsTab(langProvider),
                _buildBoatsTab(langProvider),
                _buildFoodsTab(langProvider),
              ],
            ),
    );
  }

  Widget _buildHotelsDirectoryTab(LanguageProvider langProvider) {
    if (_hotels.isEmpty) {
      return Center(
        child: Text(
          langProvider.isBangla ? 'কোনো হোটেল পাওয়া যায়নি' : 'No hotels available',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _hotels.length,
        itemBuilder: (context, index) {
          final hotel = _hotels[index];
          final hotelId = hotel['_id'];
          final hotelName = langProvider.isBangla ? hotel['name_bn'] : hotel['name_en'];
          
          // Find manager for this hotel
          final hotelManagers = _managers.where((m) => m['managedHotelId'] == hotelId).toList();

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00B4DB).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.hotel, color: Color(0xFF00B4DB), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          hotelName ?? '',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  if (hotelManagers.isEmpty)
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.orange, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          langProvider.isBangla ? 'কোনো ম্যানেজার নিযুক্ত নেই' : 'No manager assigned',
                          style: const TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          langProvider.isBangla ? 'ম্যানেজার বিবরণ:' : 'Assigned Manager:',
                          style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        ...hotelManagers.map((m) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Row(
                              children: [
                                const Icon(Icons.person, size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  m['name'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '(${m['mobile']})',
                                  style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildManagersTab() {
    if (_managers.isEmpty) {
      return const Center(
        child: Text(
          'No manager accounts created yet.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _managers.length,
        itemBuilder: (context, index) {
          final manager = _managers[index];
          final name = manager['name'] ?? '';
          final mobile = manager['mobile'] ?? '';
          final email = manager['email'] ?? '';
          final hotelName = manager['hotelName'] ?? 'Unassigned';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF00B4DB),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'M',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(mobile, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.email, size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(email, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.hotel, size: 14, color: Color(0xFF00B4DB)),
                      const SizedBox(width: 6),
                      Text(
                        hotelName,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF00B4DB)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReviewsComplaintsTab(LanguageProvider langProvider) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    
    return Column(
      children: [
        // Premium Sliding Toggle
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: theme.dividerColor.withOpacity(0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _activeSubTab = 'reviews';
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        gradient: _activeSubTab == 'reviews'
                            ? const LinearGradient(
                                colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
                              )
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'User Reviews (${_reviews.length})',
                        style: TextStyle(
                          color: _activeSubTab == 'reviews' ? Colors.white : onSurface.withOpacity(0.7),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _activeSubTab = 'complaints';
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        gradient: _activeSubTab == 'complaints'
                            ? const LinearGradient(
                                colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
                              )
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Complaints (${_complaints.length})',
                        style: TextStyle(
                          color: _activeSubTab == 'complaints' ? Colors.white : onSurface.withOpacity(0.7),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Tab Content
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: _activeSubTab == 'reviews'
                ? _buildReviewsSubList(langProvider)
                : _buildComplaintsSubList(langProvider),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsSubList(LanguageProvider langProvider) {
    if (_reviews.isEmpty) {
      return const Center(
        child: Text(
          'No reviews found.',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _reviews.length,
      itemBuilder: (context, index) {
        final review = _reviews[index];
        final id = review['_id'] ?? review['id'] ?? '';
        final itemId = review['itemId'] ?? '';
        final itemType = review['itemType'] ?? '';
        final userName = review['userName'] ?? 'Anonymous';
        final rating = review['rating'] ?? 5;
        final comment = review['comment'] ?? '';
        final adminReply = review['adminReply'] ?? '';
        
        // Format Date
        String dateStr = '';
        if (review['createdAt'] != null) {
          try {
            final date = DateTime.parse(review['createdAt']);
            dateStr = '${date.day}/${date.month}/${date.year}';
          } catch (_) {
            dateStr = review['createdAt'].toString().split('T')[0];
          }
        }

        IconData typeIcon = Icons.star;
        if (itemType == 'hotel') typeIcon = Icons.hotel;
        if (itemType == 'room') typeIcon = Icons.meeting_room;
        if (itemType == 'food') typeIcon = Icons.restaurant;
        if (itemType == 'bike') typeIcon = Icons.motorcycle;
        if (itemType == 'board') typeIcon = Icons.directions_boat;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(typeIcon, color: const Color(0xFF00B4DB), size: 18),
                        const SizedBox(width: 6),
                        Text(
                          '${itemType.toUpperCase()} ($itemId)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF00B4DB)),
                        ),
                      ],
                    ),
                    Text(
                      dateStr,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Row(
                      children: List.generate(5, (starIdx) {
                        return Icon(
                          Icons.star,
                          color: starIdx < rating ? Colors.amber : Colors.grey.shade300,
                          size: 16,
                        );
                      }),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'by $userName',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  comment,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
                const Divider(height: 24),
                if (adminReply.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.purple.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.admin_panel_settings, color: Colors.purple, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'Admin Response',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple, fontSize: 12),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.purple, size: 16),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _showReplyDialog(id, 'review', currentReply: adminReply),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          adminReply,
                          style: const TextStyle(fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () => _showReplyDialog(id, 'review'),
                      icon: const Icon(Icons.reply, size: 14),
                      label: const Text('Reply'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.withOpacity(0.12),
                        foregroundColor: Colors.purple,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildComplaintsSubList(LanguageProvider langProvider) {
    if (_complaints.isEmpty) {
      return const Center(
        child: Text(
          'No complaints found.',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _complaints.length,
      itemBuilder: (context, index) {
        final complaint = _complaints[index];
        final id = complaint['_id'] ?? complaint['id'] ?? '';
        final userName = complaint['userName'] ?? 'Unknown';
        final userMobile = complaint['userMobile'] ?? '';
        final subject = complaint['subject'] ?? '';
        final description = complaint['description'] ?? '';
        final image = complaint['image'] ?? '';
        final status = complaint['status'] ?? 'Pending';
        final adminReply = complaint['adminReply'] ?? '';

        Color statusColor = Colors.orange;
        if (status == 'Resolved') statusColor = Colors.green;
        if (status == 'Under Investigation') statusColor = Colors.blue;

        String dateStr = '';
        if (complaint['createdAt'] != null) {
          try {
            final date = DateTime.parse(complaint['createdAt']);
            dateStr = '${date.day}/${date.month}/${date.year}';
          } catch (_) {
            dateStr = complaint['createdAt'].toString().split('T')[0];
          }
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
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
                    Text(
                      dateStr,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      userName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '($userMobile)',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Subject: $subject',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, height: 1.3),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
                if (image.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _showImageDialog(image),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        image,
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 100,
                          color: Colors.grey.shade200,
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ],
                const Divider(height: 24),
                if (adminReply.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.purple.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.admin_panel_settings, color: Colors.purple, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'Admin Response',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple, fontSize: 12),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.purple, size: 16),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _showReplyDialog(id, 'complaint', currentReply: adminReply, currentStatus: status),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          adminReply,
                          style: const TextStyle(fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () => _showReplyDialog(id, 'complaint', currentStatus: status),
                      icon: const Icon(Icons.reply, size: 14),
                      label: const Text('Reply & Action'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.withOpacity(0.12),
                        foregroundColor: Colors.purple,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Attachment Preview'),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReplyDialog(String id, String type, {String currentReply = '', String currentStatus = 'Pending'}) {
    final replyController = TextEditingController(text: currentReply);
    String selectedStatus = currentStatus;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(type == 'review' ? 'Reply to Review' : 'Reply to Complaint'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: replyController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Write your response...',
                        border: OutlineInputBorder(),
                        hintText: 'Type reply here',
                      ),
                    ),
                    if (type == 'complaint') ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Update Complaint Status:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedStatus,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                          DropdownMenuItem(value: 'Under Investigation', child: Text('Under Investigation')),
                          DropdownMenuItem(value: 'Resolved', child: Text('Resolved')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedStatus = val;
                            });
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (replyController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please write a reply first!')),
                      );
                      return;
                    }

                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(child: CircularProgressIndicator()),
                    );

                    bool success = false;
                    if (type == 'review') {
                      final res = await ApiService.replyToReview(id, replyController.text.trim());
                      success = res != null;
                    } else {
                      final res = await ApiService.replyToComplaint(
                        id,
                        replyController.text.trim(),
                        selectedStatus,
                      );
                      success = res != null;
                    }

                    if (context.mounted) {
                      Navigator.pop(context); // Pop loader
                      Navigator.pop(context); // Pop reply dialog
                      
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Reply submitted successfully!')),
                        );
                        _loadData();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to submit reply. Please try again.')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00B4DB),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Submit Reply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSpotsTab(LanguageProvider langProvider) {
    if (_spots.isEmpty) {
      return Center(
        child: Text(
          langProvider.isBangla ? 'কোনো পর্যটন স্থান পাওয়া যায়নি' : 'No popular spots found',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _spots.length,
        itemBuilder: (context, index) {
          final spot = _spots[index];
          final title = langProvider.locale == 'en'
              ? (spot['title_en'] ?? spot['title'] ?? '')
              : (spot['title_bn'] ?? spot['title'] ?? '');
          final desc = langProvider.locale == 'en'
              ? (spot['desc_en'] ?? spot['desc'] ?? '')
              : (spot['desc_bn'] ?? spot['desc'] ?? '');
          final imageUrl = spot['image'] ?? '';

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(width: 80, height: 80, color: Colors.grey.shade300, child: const Icon(Icons.broken_image)),
                          )
                        : Container(width: 80, height: 80, color: Colors.grey.shade300, child: const Icon(Icons.image)),
                  ),
                  const SizedBox(width: 16),
                  // Title and Desc
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          desc,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Actions Column
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Color(0xFF00B4DB)),
                        onPressed: () => _showAddEditSpotDialog(langProvider, spot),
                        tooltip: 'Edit Spot',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => _confirmDeleteSpot(langProvider, spot),
                        tooltip: 'Delete Spot',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddEditSpotDialog(LanguageProvider langProvider, Map<String, dynamic>? spot) {
    final isEdit = spot != null;
    final formKey = GlobalKey<FormState>();

    // Initialize Controllers
    final titleEnCtrl = TextEditingController(text: isEdit ? spot['title_en'] ?? '' : '');
    final titleBnCtrl = TextEditingController(text: isEdit ? spot['title_bn'] ?? '' : '');
    final descEnCtrl = TextEditingController(text: isEdit ? spot['desc_en'] ?? '' : '');
    final descBnCtrl = TextEditingController(text: isEdit ? spot['desc_bn'] ?? '' : '');
    final imageCtrl = TextEditingController(text: isEdit ? spot['image'] ?? '' : '');
    
    final aboutEnCtrl = TextEditingController(text: isEdit ? spot['about_en'] ?? '' : '');
    final aboutBnCtrl = TextEditingController(text: isEdit ? spot['about_bn'] ?? '' : '');
    final tipsEnCtrl = TextEditingController(text: isEdit ? spot['tips_en'] ?? '' : '');
    final tipsBnCtrl = TextEditingController(text: isEdit ? spot['tips_bn'] ?? '' : '');
    final locEnCtrl = TextEditingController(text: isEdit ? spot['location_en'] ?? '' : '');
    final locBnCtrl = TextEditingController(text: isEdit ? spot['location_bn'] ?? '' : '');
    final timingsEnCtrl = TextEditingController(text: isEdit ? spot['timings_en'] ?? '' : '');
    final timingsBnCtrl = TextEditingController(text: isEdit ? spot['timings_bn'] ?? '' : '');
    final transEnCtrl = TextEditingController(text: isEdit ? spot['transport_en'] ?? '' : '');
    final transBnCtrl = TextEditingController(text: isEdit ? spot['transport_bn'] ?? '' : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit
                          ? (langProvider.isBangla ? 'পর্যটন স্থান সম্পাদন করুন' : 'Edit Tourist Spot')
                          : (langProvider.isBangla ? 'নতুন পর্যটন স্থান যোগ করুন' : 'Add New Tourist Spot'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              
              // Scrollable Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Section: General Info
                        _buildSectionHeader(langProvider.isBangla ? 'সাধারণ তথ্য' : 'General Info'),
                        const SizedBox(height: 12),
                        _buildTextField(titleEnCtrl, 'Title (English)', true),
                        const SizedBox(height: 12),
                        _buildTextField(titleBnCtrl, 'Title (Bangla / বাংলা)', true),
                        const SizedBox(height: 12),
                        _buildTextField(descEnCtrl, 'Short Description (English)', true),
                        const SizedBox(height: 12),
                        _buildTextField(descBnCtrl, 'Short Description (Bangla / বাংলা)', true),
                        const SizedBox(height: 12),
                        _buildTextField(imageCtrl, 'Image URL', true),
                        
                        const SizedBox(height: 24),
                        // Section: English Details
                        _buildSectionHeader('English Details'),
                        const SizedBox(height: 12),
                        _buildTextField(aboutEnCtrl, 'Detailed About (English)', false, maxLines: 4),
                        const SizedBox(height: 12),
                        _buildTextField(tipsEnCtrl, 'Travel Tips (English, bullet points)', false, maxLines: 3),
                        const SizedBox(height: 12),
                        _buildTextField(locEnCtrl, 'Location (English)', false),
                        const SizedBox(height: 12),
                        _buildTextField(timingsEnCtrl, 'Timings (English)', false),
                        const SizedBox(height: 12),
                        _buildTextField(transEnCtrl, 'Transport Info (English)', false, maxLines: 2),

                        const SizedBox(height: 24),
                        // Section: Bangla Details
                        _buildSectionHeader('বাংলা বিস্তারিত (Bangla Details)'),
                        const SizedBox(height: 12),
                        _buildTextField(aboutBnCtrl, 'Detailed About (Bangla)', false, maxLines: 4),
                        const SizedBox(height: 12),
                        _buildTextField(tipsBnCtrl, 'Travel Tips (Bangla, bullet points)', false, maxLines: 3),
                        const SizedBox(height: 12),
                        _buildTextField(locBnCtrl, 'Location (Bangla)', false),
                        const SizedBox(height: 12),
                        _buildTextField(timingsBnCtrl, 'Timings (Bangla)', false),
                        const SizedBox(height: 12),
                        _buildTextField(transBnCtrl, 'Transport Info (Bangla)', false, maxLines: 2),

                        const SizedBox(height: 32),
                        // Save Button
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
                            ),
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;
                              
                              final body = {
                                'title_en': titleEnCtrl.text.trim(),
                                'title_bn': titleBnCtrl.text.trim(),
                                'desc_en': descEnCtrl.text.trim(),
                                'desc_bn': descBnCtrl.text.trim(),
                                'image': imageCtrl.text.trim(),
                                'about_en': aboutEnCtrl.text.trim(),
                                'about_bn': aboutBnCtrl.text.trim(),
                                'tips_en': tipsEnCtrl.text.trim(),
                                'tips_bn': tipsBnCtrl.text.trim(),
                                'location_en': locEnCtrl.text.trim(),
                                'location_bn': locBnCtrl.text.trim(),
                                'timings_en': timingsEnCtrl.text.trim(),
                                'timings_bn': timingsBnCtrl.text.trim(),
                                'transport_en': transEnCtrl.text.trim(),
                                'transport_bn': transBnCtrl.text.trim(),
                              };

                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const Center(child: CircularProgressIndicator()),
                              );

                              Map<String, dynamic>? result;
                              if (isEdit) {
                                result = await ApiService.updateContent(spot['_id'], {
                                  ...spot,
                                  ...body,
                                });
                              } else {
                                result = await ApiService.createContent('spot', body);
                              }

                              if (context.mounted) {
                                Navigator.pop(context); // pop progress indicator
                                Navigator.pop(context); // pop bottom sheet
                              }

                              if (result != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(isEdit ? 'Spot updated successfully!' : 'Spot added successfully!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                _loadData();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Failed to save spot details.'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            },
                            child: Text(
                              langProvider.isBangla ? 'সংরক্ষণ করুন' : 'Save Details',
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteSpot(LanguageProvider langProvider, Map<String, dynamic> spot) {
    final title = langProvider.locale == 'en'
        ? (spot['title_en'] ?? spot['title'] ?? '')
        : (spot['title_bn'] ?? spot['title'] ?? '');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(langProvider.isBangla ? 'মুছে ফেলার নিশ্চিতকরণ' : 'Confirm Delete'),
          content: Text(
            langProvider.isBangla
                ? '"$title" কি আপনি মুছে ফেলতে চান?'
                : 'Are you sure you want to delete "$title"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(langProvider.isBangla ? 'বাতিল' : 'Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // pop confirm dialog
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator()),
                );

                final success = await ApiService.deleteContent('spot', spot['_id']);

                if (context.mounted) {
                  Navigator.pop(context); // pop loading
                }

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Spot deleted successfully!'), backgroundColor: Colors.green),
                  );
                  _loadData();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to delete spot.'), backgroundColor: Colors.redAccent),
                  );
                }
              },
              child: Text(
                langProvider.isBangla ? 'মুছে ফেলুন' : 'Delete',
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF00B4DB)),
        ),
        const Divider(height: 12),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, bool isRequired, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      validator: isRequired
          ? (v) => v == null || v.trim().isEmpty ? 'Field is required' : null
          : null,
    );
  }

  Widget _buildSliderTab(LanguageProvider langProvider) {
    if (_slides.isEmpty) {
      return Center(
        child: Text(
          langProvider.isBangla ? 'কোনো স্লাইডার ছবি পাওয়া যায়নি' : 'No slider slides found',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _slides.length,
        itemBuilder: (context, index) {
          final slide = _slides[index];
          final title = langProvider.locale == 'en'
              ? (slide['title_en'] ?? slide['title'] ?? '')
              : (slide['title_bn'] ?? slide['title'] ?? '');
          final imageUrl = slide['image'] ?? '';

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            width: 120,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(width: 120, height: 60, color: Colors.grey.shade300, child: const Icon(Icons.broken_image)),
                          )
                        : Container(width: 120, height: 60, color: Colors.grey.shade300, child: const Icon(Icons.image)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Color(0xFF00B4DB)),
                        onPressed: () => _showAddEditSlideDialog(langProvider, slide),
                        tooltip: 'Edit Slide',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => _confirmDeleteSlide(langProvider, slide),
                        tooltip: 'Delete Slide',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddEditSlideDialog(LanguageProvider langProvider, Map<String, dynamic>? slide) {
    final isEdit = slide != null;
    final formKey = GlobalKey<FormState>();

    final titleEnCtrl = TextEditingController(text: isEdit ? slide['title_en'] ?? '' : '');
    final titleBnCtrl = TextEditingController(text: isEdit ? slide['title_bn'] ?? '' : '');
    final imageCtrl = TextEditingController(text: isEdit ? slide['image'] ?? '' : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? 'Edit Slide Details' : 'Add New Slide',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTextField(titleEnCtrl, 'Slide Title (English) *', true),
                        const SizedBox(height: 16),
                        _buildTextField(titleBnCtrl, 'Slide Title (Bangla) *', true),
                        const SizedBox(height: 16),
                        _buildTextField(imageCtrl, 'Image URL *', true),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00B4DB),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;

                              final body = {
                                'title_en': titleEnCtrl.text.trim(),
                                'title_bn': titleBnCtrl.text.trim(),
                                'image': imageCtrl.text.trim(),
                              };

                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const Center(child: CircularProgressIndicator()),
                              );

                              Map<String, dynamic>? result;
                              if (isEdit) {
                                result = await ApiService.updateContent(slide['_id'], {
                                  ...slide,
                                  ...body,
                                });
                              } else {
                                result = await ApiService.createContent('slider', body);
                              }

                              if (context.mounted) {
                                Navigator.pop(context); // pop progress indicator
                                Navigator.pop(context); // pop bottom sheet
                              }

                              if (result != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(isEdit ? 'Slide updated successfully!' : 'Slide added successfully!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                _loadData();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Failed to save slide details.'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            },
                            child: Text(
                              langProvider.isBangla ? 'সংরক্ষণ করুন' : 'Save Details',
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteSlide(LanguageProvider langProvider, Map<String, dynamic> slide) {
    final title = langProvider.locale == 'en'
        ? (slide['title_en'] ?? slide['title'] ?? '')
        : (slide['title_bn'] ?? slide['title'] ?? '');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(langProvider.isBangla ? 'মুছে ফেলার নিশ্চিতকরণ' : 'Confirm Delete'),
          content: Text(
            langProvider.isBangla
                ? '"$title" স্লাইডটি কি আপনি মুছে ফেলতে চান?'
                : 'Are you sure you want to delete slide "$title"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(langProvider.isBangla ? 'বাতিল' : 'Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // pop confirm dialog
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator()),
                );

                final success = await ApiService.deleteContent('slider', slide['_id']);

                if (context.mounted) {
                  Navigator.pop(context); // pop loading
                }

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Slide deleted successfully!'), backgroundColor: Colors.green),
                  );
                  _loadData();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to delete slide.'), backgroundColor: Colors.redAccent),
                  );
                }
              },
              child: Text(
                langProvider.isBangla ? 'মুছে ফেলুন' : 'Delete',
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  // NEW CRUD IMPLEMENTATIONS FOR BIKES, VANS, SPEEDBOATS, BOATS, FOODS

  Widget _buildBikesTab(LanguageProvider langProvider) {
    if (_bikes.isEmpty) {
      return Center(
        child: Text(
          langProvider.isBangla ? 'কোনো বাইকার পাওয়া যায়নি' : 'No bikers available',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _bikes.length,
        itemBuilder: (context, index) {
          final bike = _bikes[index];
          final name = langProvider.isBangla ? (bike['name_bn'] ?? bike['name_en'] ?? '') : (bike['name_en'] ?? '');
          final bikeName = langProvider.isBangla ? (bike['bike_bn'] ?? bike['bike_en'] ?? '') : (bike['bike_en'] ?? '');
          final price = langProvider.isBangla ? (bike['price_bn'] ?? bike['price_en'] ?? '') : (bike['price_en'] ?? '');
          final imageUrl = bike['image'] ?? '';

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(width: 80, height: 80, color: Colors.grey.shade300, child: const Icon(Icons.broken_image)),
                          )
                        : Container(width: 80, height: 80, color: Colors.grey.shade300, child: const Icon(Icons.image)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          bikeName,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF00B4DB), fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          price,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Color(0xFF00B4DB)),
                        onPressed: () => _showAddEditBikeDialog(langProvider, bike),
                        tooltip: 'Edit Bike',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => _confirmDeleteContent(langProvider, 'bike', bike),
                        tooltip: 'Delete Bike',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVansTab(LanguageProvider langProvider) {
    if (_vans.isEmpty) {
      return Center(
        child: Text(
          langProvider.isBangla ? 'কোনো ভ্যান চালক পাওয়া যায়নি' : 'No vans available',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _vans.length,
        itemBuilder: (context, index) {
          final van = _vans[index];
          final name = langProvider.isBangla ? (van['name_bn'] ?? van['name_en'] ?? '') : (van['name_en'] ?? '');
          final vanType = langProvider.isBangla ? (van['van_bn'] ?? van['van_en'] ?? '') : (van['van_en'] ?? '');
          final price = langProvider.isBangla ? (van['price_bn'] ?? van['price_en'] ?? '') : (van['price_en'] ?? '');
          final imageUrl = van['image'] ?? '';

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(width: 80, height: 80, color: Colors.grey.shade300, child: const Icon(Icons.broken_image)),
                          )
                        : Container(width: 80, height: 80, color: Colors.grey.shade300, child: const Icon(Icons.image)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          vanType,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF00B4DB), fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          price,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Color(0xFF00B4DB)),
                        onPressed: () => _showAddEditVanDialog(langProvider, van),
                        tooltip: 'Edit Van',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => _confirmDeleteContent(langProvider, 'van', van),
                        tooltip: 'Delete Van',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSpeedboatsTab(LanguageProvider langProvider) {
    if (_boards.isEmpty) {
      return Center(
        child: Text(
          langProvider.isBangla ? 'কোনো স্পিডবোট পাওয়া যায়নি' : 'No speedboats available',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _boards.length,
        itemBuilder: (context, index) {
          final board = _boards[index];
          final name = langProvider.isBangla ? (board['name_bn'] ?? board['name_en'] ?? '') : (board['name_en'] ?? '');
          final boatDetails = langProvider.isBangla ? (board['boat_bn'] ?? board['boat_en'] ?? '') : (board['boat_en'] ?? '');
          final price = langProvider.isBangla ? (board['price_bn'] ?? board['price_en'] ?? '') : (board['price_en'] ?? '');
          final imageUrl = board['image'] ?? '';

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(width: 80, height: 80, color: Colors.grey.shade300, child: const Icon(Icons.broken_image)),
                          )
                        : Container(width: 80, height: 80, color: Colors.grey.shade300, child: const Icon(Icons.image)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          boatDetails,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF00B4DB), fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          price,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Color(0xFF00B4DB)),
                        onPressed: () => _showAddEditBoardDialog(langProvider, board),
                        tooltip: 'Edit Speedboat',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => _confirmDeleteContent(langProvider, 'board', board),
                        tooltip: 'Delete Speedboat',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBoatsTab(LanguageProvider langProvider) {
    if (_boats.isEmpty) {
      return Center(
        child: Text(
          langProvider.isBangla ? 'কোনো ট্রলার/নৌকা পাওয়া যায়নি' : 'No boats available',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _boats.length,
        itemBuilder: (context, index) {
          final boat = _boats[index];
          final name = langProvider.isBangla ? (boat['name_bn'] ?? boat['name_en'] ?? '') : (boat['name_en'] ?? '');
          final boatDetails = langProvider.isBangla ? (boat['boat_bn'] ?? boat['boat_en'] ?? '') : (boat['boat_en'] ?? '');
          final price = langProvider.isBangla ? (boat['price_bn'] ?? boat['price_en'] ?? '') : (boat['price_en'] ?? '');
          final imageUrl = boat['image'] ?? '';

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(width: 80, height: 80, color: Colors.grey.shade300, child: const Icon(Icons.broken_image)),
                          )
                        : Container(width: 80, height: 80, color: Colors.grey.shade300, child: const Icon(Icons.image)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          boatDetails,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF00B4DB), fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          price,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Color(0xFF00B4DB)),
                        onPressed: () => _showAddEditBoatDialog(langProvider, boat),
                        tooltip: 'Edit Boat',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => _confirmDeleteContent(langProvider, 'boat', boat),
                        tooltip: 'Delete Boat',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFoodsTab(LanguageProvider langProvider) {
    if (_foods.isEmpty) {
      return Center(
        child: Text(
          langProvider.isBangla ? 'কোনো রেস্টুরেন্ট পাওয়া যায়নি' : 'No restaurants available',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _foods.length,
        itemBuilder: (context, index) {
          final food = _foods[index];
          final name = langProvider.isBangla ? (food['name_bn'] ?? food['name_en'] ?? '') : (food['name_en'] ?? '');
          final address = food['address'] ?? '';
          final imageUrl = food['image'] ?? '';

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(width: 80, height: 80, color: Colors.grey.shade300, child: const Icon(Icons.broken_image)),
                          )
                        : Container(width: 80, height: 80, color: Colors.grey.shade300, child: const Icon(Icons.image)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          address,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Color(0xFF00B4DB)),
                        onPressed: () => _showAddEditFoodDialog(langProvider, food),
                        tooltip: 'Edit Restaurant',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => _confirmDeleteContent(langProvider, 'food', food),
                        tooltip: 'Delete Restaurant',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddEditBikeDialog(LanguageProvider langProvider, Map<String, dynamic>? bike) {
    final isEdit = bike != null;
    final formKey = GlobalKey<FormState>();

    final nameEnController = TextEditingController(text: isEdit ? bike['name_en'] : '');
    final nameBnController = TextEditingController(text: isEdit ? bike['name_bn'] : '');
    final bikeEnController = TextEditingController(text: isEdit ? bike['bike_en'] : '');
    final bikeBnController = TextEditingController(text: isEdit ? bike['bike_bn'] : '');
    final priceEnController = TextEditingController(text: isEdit ? bike['price_en'] : '');
    final priceBnController = TextEditingController(text: isEdit ? bike['price_bn'] : '');
    final phoneController = TextEditingController(text: isEdit ? bike['phone'] : '');
    final imageController = TextEditingController(text: isEdit ? bike['image'] : '');
    final expEnController = TextEditingController(text: isEdit ? bike['experience_en'] : '');
    final expBnController = TextEditingController(text: isEdit ? bike['experience_bn'] : '');
    final ratingController = TextEditingController(text: isEdit ? bike['rating']?.toString() : '4.8');
    final ridesController = TextEditingController(text: isEdit ? bike['rides']?.toString() : '100');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? 'Edit Biker Details' : 'Add New Biker',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTextField(nameEnController, 'Biker Name (English) *', true),
                        const SizedBox(height: 12),
                        _buildTextField(nameBnController, 'Biker Name (Bangla) *', true),
                        const SizedBox(height: 12),
                        _buildTextField(bikeEnController, 'Bike Name/Model (English)', false),
                        const SizedBox(height: 12),
                        _buildTextField(bikeBnController, 'Bike Name/Model (Bangla)', false),
                        const SizedBox(height: 12),
                        _buildTextField(priceEnController, 'Rental Price (English, e.g. ৳1,000 / day)', false),
                        const SizedBox(height: 12),
                        _buildTextField(priceBnController, 'Rental Price (Bangla, e.g. ৳১,০০০ / দিন)', false),
                        const SizedBox(height: 12),
                        _buildTextField(phoneController, 'Phone Number *', true),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(imageController, 'Profile Image URL', false),
                            ),
                            const SizedBox(width: 8),
                            StatefulBuilder(
                              builder: (context, setModalState) {
                                return ElevatedButton.icon(
                                  onPressed: () => _pickAndUploadImage(imageController, context, setModalState),
                                  icon: const Icon(Icons.upload_file, size: 16),
                                  label: const Text('Upload', style: TextStyle(fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00B4DB),
                                    foregroundColor: Colors.white,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(expEnController, 'Experience (English)', false),
                        const SizedBox(height: 12),
                        _buildTextField(expBnController, 'Experience (Bangla)', false),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(ratingController, 'Rating', false),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(ridesController, 'Rides Count', false),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            final body = {
                              'name_en': nameEnController.text.trim(),
                              'name_bn': nameBnController.text.trim(),
                              'bike_en': bikeEnController.text.trim(),
                              'bike_bn': bikeBnController.text.trim(),
                              'price_en': priceEnController.text.trim(),
                              'price_bn': priceBnController.text.trim(),
                              'phone': phoneController.text.trim(),
                              'image': imageController.text.trim().isNotEmpty
                                  ? imageController.text.trim()
                                  : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80',
                              'experience_en': expEnController.text.trim(),
                              'experience_bn': expBnController.text.trim(),
                              'rating': double.tryParse(ratingController.text.trim()) ?? 4.8,
                              'rides': int.tryParse(ridesController.text.trim()) ?? 100,
                            };

                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(child: CircularProgressIndicator()),
                            );

                            Map<String, dynamic>? result;
                            if (isEdit) {
                              result = await ApiService.updateContent(bike['_id'], {
                                ...bike,
                                ...body,
                              });
                            } else {
                              result = await ApiService.createContent('bike', body);
                            }

                            if (context.mounted) {
                              Navigator.pop(context); // pop indicator
                              Navigator.pop(context); // pop bottom sheet
                            }

                            if (result != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isEdit ? 'Biker updated successfully!' : 'Biker added successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _loadData();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to save biker details.'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00B4DB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Save Details', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddEditVanDialog(LanguageProvider langProvider, Map<String, dynamic>? van) {
    final isEdit = van != null;
    final formKey = GlobalKey<FormState>();

    final nameEnController = TextEditingController(text: isEdit ? van['name_en'] : '');
    final nameBnController = TextEditingController(text: isEdit ? van['name_bn'] : '');
    final vanEnController = TextEditingController(text: isEdit ? van['van_en'] : '');
    final vanBnController = TextEditingController(text: isEdit ? van['van_bn'] : '');
    final priceEnController = TextEditingController(text: isEdit ? van['price_en'] : '');
    final priceBnController = TextEditingController(text: isEdit ? van['price_bn'] : '');
    final phoneController = TextEditingController(text: isEdit ? van['phone'] : '');
    final imageController = TextEditingController(text: isEdit ? van['image'] : '');
    final detailsEnController = TextEditingController(text: isEdit ? van['details_en'] : '');
    final detailsBnController = TextEditingController(text: isEdit ? van['details_bn'] : '');
    final ratingController = TextEditingController(text: isEdit ? van['rating']?.toString() : '4.7');
    final tripsController = TextEditingController(text: isEdit ? van['trips']?.toString() : '100');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? 'Edit Van Details' : 'Add New Van',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTextField(nameEnController, 'Owner Name (English) *', true),
                        const SizedBox(height: 12),
                        _buildTextField(nameBnController, 'Owner Name (Bangla) *', true),
                        const SizedBox(height: 12),
                        _buildTextField(vanEnController, 'Van type (English)', false),
                        const SizedBox(height: 12),
                        _buildTextField(vanBnController, 'Van type (Bangla)', false),
                        const SizedBox(height: 12),
                        _buildTextField(priceEnController, 'Rental Price (English, e.g. ৳150 / hour)', false),
                        const SizedBox(height: 12),
                        _buildTextField(priceBnController, 'Rental Price (Bangla, e.g. ৳১৫০ / ঘণ্টা)', false),
                        const SizedBox(height: 12),
                        _buildTextField(phoneController, 'Phone Number *', true),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(imageController, 'Owner Image URL', false),
                            ),
                            const SizedBox(width: 8),
                            StatefulBuilder(
                              builder: (context, setModalState) {
                                return ElevatedButton.icon(
                                  onPressed: () => _pickAndUploadImage(imageController, context, setModalState),
                                  icon: const Icon(Icons.upload_file, size: 16),
                                  label: const Text('Upload', style: TextStyle(fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00B4DB),
                                    foregroundColor: Colors.white,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(detailsEnController, 'Details/Bio (English)', false),
                        const SizedBox(height: 12),
                        _buildTextField(detailsBnController, 'Details/Bio (Bangla)', false),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(ratingController, 'Rating', false),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(tripsController, 'Trips Count', false),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            final body = {
                              'name_en': nameEnController.text.trim(),
                              'name_bn': nameBnController.text.trim(),
                              'van_en': vanEnController.text.trim(),
                              'van_bn': vanBnController.text.trim(),
                              'price_en': priceEnController.text.trim(),
                              'price_bn': priceBnController.text.trim(),
                              'phone': phoneController.text.trim(),
                              'image': imageController.text.trim().isNotEmpty
                                  ? imageController.text.trim()
                                  : 'https://images.unsplash.com/photo-1542909168-82c3e7fdca5c?auto=format&fit=crop&w=300&q=80',
                              'details_en': detailsEnController.text.trim(),
                              'details_bn': detailsBnController.text.trim(),
                              'rating': double.tryParse(ratingController.text.trim()) ?? 4.7,
                              'trips': int.tryParse(tripsController.text.trim()) ?? 100,
                            };

                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(child: CircularProgressIndicator()),
                            );

                            Map<String, dynamic>? result;
                            if (isEdit) {
                              result = await ApiService.updateContent(van['_id'], {
                                ...van,
                                ...body,
                              });
                            } else {
                              result = await ApiService.createContent('van', body);
                            }

                            if (context.mounted) {
                              Navigator.pop(context); // pop indicator
                              Navigator.pop(context); // pop bottom sheet
                            }

                            if (result != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isEdit ? 'Van updated successfully!' : 'Van added successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _loadData();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to save van details.'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00B4DB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Save Details', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddEditBoardDialog(LanguageProvider langProvider, Map<String, dynamic>? board) {
    final isEdit = board != null;
    final formKey = GlobalKey<FormState>();

    final nameEnController = TextEditingController(text: isEdit ? board['name_en'] : '');
    final nameBnController = TextEditingController(text: isEdit ? board['name_bn'] : '');
    final boatEnController = TextEditingController(text: isEdit ? board['boat_en'] : '');
    final boatBnController = TextEditingController(text: isEdit ? board['boat_bn'] : '');
    final priceEnController = TextEditingController(text: isEdit ? board['price_en'] : '');
    final priceBnController = TextEditingController(text: isEdit ? board['price_bn'] : '');
    final phoneController = TextEditingController(text: isEdit ? board['phone'] : '');
    final imageController = TextEditingController(text: isEdit ? board['image'] : '');
    final detailsEnController = TextEditingController(text: isEdit ? board['details_en'] : '');
    final detailsBnController = TextEditingController(text: isEdit ? board['details_bn'] : '');
    final ratingController = TextEditingController(text: isEdit ? board['rating']?.toString() : '4.9');
    final tripsController = TextEditingController(text: isEdit ? board['trips']?.toString() : '100');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
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
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTextField(nameEnController, 'Driver Name (English) *', true),
                        const SizedBox(height: 12),
                        _buildTextField(nameBnController, 'Driver Name (Bangla) *', true),
                        const SizedBox(height: 12),
                        _buildTextField(boatEnController, 'Speedboat details (English)', false),
                        const SizedBox(height: 12),
                        _buildTextField(boatBnController, 'Speedboat details (Bangla)', false),
                        const SizedBox(height: 12),
                        _buildTextField(priceEnController, 'Rental Price (English, e.g. ৳1,500 / trip)', false),
                        const SizedBox(height: 12),
                        _buildTextField(priceBnController, 'Rental Price (Bangla, e.g. ৳১,৫০০ / ট্রিপ)', false),
                        const SizedBox(height: 12),
                        _buildTextField(phoneController, 'Phone Number *', true),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(imageController, 'Driver Image URL', false),
                            ),
                            const SizedBox(width: 8),
                            StatefulBuilder(
                              builder: (context, setModalState) {
                                return ElevatedButton.icon(
                                  onPressed: () => _pickAndUploadImage(imageController, context, setModalState),
                                  icon: const Icon(Icons.upload_file, size: 16),
                                  label: const Text('Upload', style: TextStyle(fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00B4DB),
                                    foregroundColor: Colors.white,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(detailsEnController, 'Experience/Details (English)', false),
                        const SizedBox(height: 12),
                        _buildTextField(detailsBnController, 'Experience/Details (Bangla)', false),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(ratingController, 'Rating', false),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(tripsController, 'Trips Count', false),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            final body = {
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

                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(child: CircularProgressIndicator()),
                            );

                            Map<String, dynamic>? result;
                            if (isEdit) {
                              result = await ApiService.updateContent(board['_id'], {
                                ...board,
                                ...body,
                              });
                            } else {
                              result = await ApiService.createContent('board', body);
                            }

                            if (context.mounted) {
                              Navigator.pop(context); // pop indicator
                              Navigator.pop(context); // pop bottom sheet
                            }

                            if (result != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isEdit ? 'Driver updated successfully!' : 'Driver added successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _loadData();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to save driver details.'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00B4DB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Save Details', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddEditBoatDialog(LanguageProvider langProvider, Map<String, dynamic>? boat) {
    final isEdit = boat != null;
    final formKey = GlobalKey<FormState>();

    final nameEnController = TextEditingController(text: isEdit ? boat['name_en'] : '');
    final nameBnController = TextEditingController(text: isEdit ? boat['name_bn'] : '');
    final boatEnController = TextEditingController(text: isEdit ? boat['boat_en'] : '');
    final boatBnController = TextEditingController(text: isEdit ? boat['boat_bn'] : '');
    final priceEnController = TextEditingController(text: isEdit ? boat['price_en'] : '');
    final priceBnController = TextEditingController(text: isEdit ? boat['price_bn'] : '');
    final phoneController = TextEditingController(text: isEdit ? boat['phone'] : '');
    final imageController = TextEditingController(text: isEdit ? boat['image'] : '');
    final detailsEnController = TextEditingController(text: isEdit ? boat['details_en'] : '');
    final detailsBnController = TextEditingController(text: isEdit ? boat['details_bn'] : '');
    final ratingController = TextEditingController(text: isEdit ? boat['rating']?.toString() : '4.7');
    final tripsController = TextEditingController(text: isEdit ? boat['trips']?.toString() : '100');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
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
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTextField(nameEnController, 'Boatman Name (English) *', true),
                        const SizedBox(height: 12),
                        _buildTextField(nameBnController, 'Boatman Name (Bangla) *', true),
                        const SizedBox(height: 12),
                        _buildTextField(boatEnController, 'Boat details (English)', false),
                        const SizedBox(height: 12),
                        _buildTextField(boatBnController, 'Boat details (Bangla)', false),
                        const SizedBox(height: 12),
                        _buildTextField(priceEnController, 'Rental Price (English, e.g. ৳800 / hour)', false),
                        const SizedBox(height: 12),
                        _buildTextField(priceBnController, 'Rental Price (Bangla, e.g. ৳৮০০ / ঘণ্টা)', false),
                        const SizedBox(height: 12),
                        _buildTextField(phoneController, 'Phone Number *', true),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(imageController, 'Boatman Image URL', false),
                            ),
                            const SizedBox(width: 8),
                            StatefulBuilder(
                              builder: (context, setModalState) {
                                return ElevatedButton.icon(
                                  onPressed: () => _pickAndUploadImage(imageController, context, setModalState),
                                  icon: const Icon(Icons.upload_file, size: 16),
                                  label: const Text('Upload', style: TextStyle(fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00B4DB),
                                    foregroundColor: Colors.white,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(detailsEnController, 'Details/Bio (English)', false),
                        const SizedBox(height: 12),
                        _buildTextField(detailsBnController, 'Details/Bio (Bangla)', false),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(ratingController, 'Rating', false),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(tripsController, 'Trips Count', false),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            final body = {
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

                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(child: CircularProgressIndicator()),
                            );

                            Map<String, dynamic>? result;
                            if (isEdit) {
                              result = await ApiService.updateContent(boat['_id'], {
                                ...boat,
                                ...body,
                              });
                            } else {
                              result = await ApiService.createContent('boat', body);
                            }

                            if (context.mounted) {
                              Navigator.pop(context); // pop indicator
                              Navigator.pop(context); // pop bottom sheet
                            }

                            if (result != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isEdit ? 'Boatman updated successfully!' : 'Boatman added successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _loadData();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to save boatman details.'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00B4DB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Save Details', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddEditFoodDialog(LanguageProvider langProvider, Map<String, dynamic>? restaurant) {
    final isEdit = restaurant != null;
    final formKey = GlobalKey<FormState>();

    final nameEnController = TextEditingController(text: isEdit ? restaurant['name_en'] : '');
    final nameBnController = TextEditingController(text: isEdit ? restaurant['name_bn'] : '');
    final addressController = TextEditingController(text: isEdit ? restaurant['address'] : '');
    final phoneController = TextEditingController(text: isEdit ? restaurant['phone'] : '');
    final imageController = TextEditingController(text: isEdit ? restaurant['image'] : '');
    final menuImageController = TextEditingController(text: isEdit ? restaurant['menu_image'] : '');

    String menuType = isEdit ? (restaurant['menu_type'] ?? 'image') : 'image';
    List<Map<String, dynamic>> restaurantMenu = [];
    if (isEdit && restaurant['menu'] != null) {
      restaurantMenu = List<Map<String, dynamic>>.from(
        (restaurant['menu'] as List).map((x) => Map<String, dynamic>.from(x)),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
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
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildTextField(nameEnController, 'Restaurant Name (English) *', true),
                            const SizedBox(height: 12),
                            _buildTextField(nameBnController, 'Restaurant Name (Bangla) *', true),
                            const SizedBox(height: 12),
                            _buildTextField(addressController, 'Address (ঠিকানা)', false),
                            const SizedBox(height: 12),
                            _buildTextField(phoneController, 'Phone Number *', true),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(imageController, 'Cover Image URL', false),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () => _pickAndUploadImage(imageController, context, setModalState),
                                  icon: const Icon(Icons.upload_file, size: 16),
                                  label: const Text('Upload', style: TextStyle(fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00B4DB),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
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
                                    ),
                                    onPressed: () {
                                      setModalState(() {
                                        menuType = 'list';
                                      });
                                    },
                                    icon: Icon(Icons.format_list_bulleted, color: menuType == 'list' ? const Color(0xFF00B4DB) : Colors.grey),
                                    label: Text(
                                      langProvider.isBangla ? 'খাবারের তালিকা' : 'Food List',
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
                                    child: _buildTextField(menuImageController, 'Menu Image URL', false),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: () => _pickAndUploadImage(menuImageController, context, setModalState),
                                    icon: const Icon(Icons.upload_file, size: 16),
                                    label: const Text('Upload', style: TextStyle(fontSize: 12)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF00B4DB),
                                      foregroundColor: Colors.white,
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
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      final menuItem = await _showMenuDialog(context);
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
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              restaurantMenu.isEmpty
                                  ? Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.2)),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(langProvider.isBangla ? 'কোনো খাবার তালিকা যোগ করা হয়নি' : 'No menu items added yet.'),
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
                                              child: (m['image'] != null && (m['image'] as String).isNotEmpty)
                                                  ? Image.network(
                                                      m['image'],
                                                      width: 40,
                                                      height: 40,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (c, e, s) => Container(color: Colors.grey.shade300, width: 40, height: 40),
                                                    )
                                                  : Container(color: Colors.grey.shade300, width: 40, height: 40),
                                            ),
                                            title: Text(langProvider.isBangla ? (m['name_bn'] ?? m['name_en'] ?? '') : (m['name_en'] ?? '')),
                                            subtitle: Text('৳${m['price']}'),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit, color: Color(0xFF00B4DB), size: 20),
                                                  onPressed: () async {
                                                    final updatedMenuItem = await _showMenuDialog(context, menuItem: m);
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
                                if (!formKey.currentState!.validate()) return;
                                final body = {
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

                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => const Center(child: CircularProgressIndicator()),
                                );

                                Map<String, dynamic>? result;
                                if (isEdit) {
                                  result = await ApiService.updateContent(restaurant['_id'], {
                                    ...restaurant,
                                    ...body,
                                  });
                                } else {
                                  result = await ApiService.createContent('food', body);
                                }

                                if (context.mounted) {
                                  Navigator.pop(context); // pop indicator
                                  Navigator.pop(context); // pop bottom sheet
                                }

                                if (result != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(isEdit ? 'Restaurant updated successfully!' : 'Restaurant added successfully!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  _loadData();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Failed to save details.'),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00B4DB),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Save Details', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
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

  void _confirmDeleteContent(LanguageProvider langProvider, String type, Map<String, dynamic> item) {
    final title = langProvider.locale == 'en'
        ? (item['name_en'] ?? item['title_en'] ?? item['title'] ?? '')
        : (item['name_bn'] ?? item['title_bn'] ?? item['title'] ?? '');
    
    final typeDisplay = type == 'bike' ? 'biker'
                      : type == 'van' ? 'van'
                      : type == 'board' ? 'speedboat'
                      : type == 'boat' ? 'boatman'
                      : type == 'food' ? 'restaurant'
                      : type;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(langProvider.isBangla ? 'মুছে ফেলার নিশ্চিতকরণ' : 'Confirm Delete'),
          content: Text(
            langProvider.isBangla
                ? '"$title" কি আপনি মুছে ফেলতে চান?'
                : 'Are you sure you want to delete "$title"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(langProvider.isBangla ? 'বাতিল' : 'Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // pop confirm dialog
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator()),
                );

                final success = await ApiService.deleteContent(type, item['_id']);

                if (context.mounted) {
                  Navigator.pop(context); // pop loading
                }

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(langProvider.isBangla 
                          ? 'সফলভাবে মুছে ফেলা হয়েছে!' 
                          : '${typeDisplay[0].toUpperCase()}${typeDisplay.substring(1)} deleted successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadData();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(langProvider.isBangla 
                          ? 'মুছে ফেলতে ব্যর্থ হয়েছে।' 
                          : 'Failed to delete $typeDisplay.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              child: Text(
                langProvider.isBangla ? 'মুছে ফেলুন' : 'Delete',
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );
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

  Future<Map<String, dynamic>?> _showMenuDialog(BuildContext context, {Map<String, dynamic>? menuItem}) async {
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
                    if (mNameEn.text.isEmpty || mPrice.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill English Name and Price')),
                      );
                      return;
                    }
                    Navigator.pop(context, {
                      'name_en': mNameEn.text.trim(),
                      'name_bn': mNameBn.text.trim().isNotEmpty ? mNameBn.text.trim() : mNameEn.text.trim(),
                      'price': double.tryParse(mPrice.text.trim()) ?? 0.0,
                      'image': mImage.text.trim().isNotEmpty
                          ? mImage.text.trim()
                          : 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=150&q=80',
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
}

