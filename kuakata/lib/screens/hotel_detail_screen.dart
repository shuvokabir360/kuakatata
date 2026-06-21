import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/language_provider.dart';
import 'booking_screen.dart';
import 'reviews_section.dart';

class HotelDetailScreen extends StatelessWidget {
  final Map<String, dynamic> hotel;

  const HotelDetailScreen({
    Key? key,
    required this.hotel,
  }) : super(key: key);

  Future<void> _callHotel(String phone, BuildContext context) async {
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
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final hotelName = langProvider.isBangla ? hotel['name_bn'] : hotel['name_en'];
    final hotelDesc = langProvider.isBangla ? hotel['desc_bn'] : hotel['desc_en'];
    final phoneNum = hotel['phone'];
    final List rooms = hotel['rooms'];
    final List<String> images = hotel['images'] != null
        ? List<String>.from(hotel['images'])
        : (hotel['image'] != null && hotel['image'].toString().isNotEmpty
            ? [hotel['image'].toString()]
            : []);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header Cover Image
          SliverAppBar(
            expandedHeight: 280.0,
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                hotelName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  shadows: [
                    Shadow(blurRadius: 8, color: Colors.black, offset: Offset(0, 1)),
                  ],
                ),
              ),
              background: HotelImageSlider(images: images),
            ),
          ),

          // Hotel Info Panel
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Actions Bar (Call & Location info)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00C9FF).withOpacity(0.12),
                            foregroundColor: const Color(0xFF00C9FF),
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () => _callHotel(phoneNum, context),
                          icon: const Icon(Icons.call_rounded),
                          label: Text(
                            langProvider.isBangla ? 'সরাসরি কল করুন' : 'Call Hotel to Book',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // About Section
                  Text(
                    langProvider.translate('about_kuakata'),
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hotelDesc,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  Divider(color: Theme.of(context).dividerColor, height: 32),

                  // Rooms List Section Title
                  Text(
                    langProvider.isBangla ? 'রুম ও বুকিং অপশন' : 'Select a Room to Book',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Room Cards list
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final r = rooms[index];
                  final roomName = langProvider.isBangla ? r['name_bn'] : r['name_en'];
                  final amenities = langProvider.isBangla ? r['amenities_bn'] : r['amenities_en'];

                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    margin: const EdgeInsets.only(bottom: 20),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Room image
                        Image.network(
                          r['image'],
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(color: Colors.white12, height: 140),
                        ),
                        
                        // Room text details
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
                                      roomName,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurface,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '৳${r['price']}/${langProvider.isBangla ? 'রাত' : 'night'}',
                                    style: const TextStyle(
                                      color: Color(0xFF00B4DB),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              // Amenities list
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: amenities.map<Widget>((amenity) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      amenity,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                        fontSize: 11,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              Divider(color: Theme.of(context).dividerColor, height: 24),
                              
                              // Booking actions
                              Row(
                                children: [
                                  // Call to Book option
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFF00C9FF),
                                        side: const BorderSide(color: Color(0xFF00C9FF)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      onPressed: () => _callHotel(phoneNum, context),
                                      icon: const Icon(Icons.phone_callback_rounded, size: 16),
                                      label: Text(
                                        langProvider.isBangla ? 'কল করে বুকিং' : 'Call to Book',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  
                                  // Online Book option
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF00B4DB),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => BookingScreen(
                                              serviceId: 'hotel',
                                              serviceName: '${hotelName} - ${roomName}',
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                                      label: Text(
                                        langProvider.translate('book_now'),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              // Room Reviews Expansion
                              Theme(
                                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                child: ExpansionTile(
                                  tilePadding: EdgeInsets.zero,
                                  title: Row(
                                    children: [
                                      const Icon(Icons.rate_review_outlined, color: Color(0xFF00B4DB), size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        langProvider.translate('room_reviews'),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: ReviewsSection(
                                        itemId: '${hotel['id'] ?? 'hotel'}_${r['name_en'] ?? 'room'}',
                                        itemType: 'room',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
                childCount: rooms.length,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: ReviewsSection(
                itemId: hotel['id'] ?? 'hotel',
                itemType: 'hotel',
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

class HotelImageSlider extends StatefulWidget {
  final List<String> images;

  const HotelImageSlider({Key? key, required this.images}) : super(key: key);

  @override
  State<HotelImageSlider> createState() => _HotelImageSliderState();
}

class _HotelImageSliderState extends State<HotelImageSlider> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Container(
        color: Colors.white10,
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: widget.images.length,
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
          },
          itemBuilder: (context, index) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullScreenImageSlider(
                      images: widget.images,
                      initialPage: index,
                    ),
                  ),
                );
              },
              child: Image.network(
                widget.images[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.white10,
                  child: const Icon(Icons.error, color: Colors.redAccent),
                ),
              ),
            );
          },
        ),
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.2),
                  Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
                ],
              ),
            ),
          ),
        ),
        if (widget.images.length > 1)
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: widget.images.asMap().entries.map((entry) {
                final index = entry.key;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _currentPage == index ? 16.0 : 8.0,
                  height: 8.0,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4.0),
                    color: _currentPage == index
                        ? const Color(0xFF00B4DB)
                        : Colors.white.withOpacity(0.5),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class FullScreenImageSlider extends StatefulWidget {
  final List<String> images;
  final int initialPage;

  const FullScreenImageSlider({
    Key? key,
    required this.images,
    required this.initialPage,
  }) : super(key: key);

  @override
  State<FullScreenImageSlider> createState() => _FullScreenImageSliderState();
}

class _FullScreenImageSliderState extends State<FullScreenImageSlider> {
  late PageController _pageController;
  late int _currentPage;
  final List<TransformationController> _transformationControllers = [];

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage);
    for (int i = 0; i < widget.images.length; i++) {
      _transformationControllers.add(TransformationController());
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _transformationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _resetZoom(int pageIndex) {
    if (pageIndex >= 0 && pageIndex < _transformationControllers.length) {
      _transformationControllers[pageIndex].value = Matrix4.identity();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
              for (int i = 0; i < widget.images.length; i++) {
                if (i != index) {
                  _resetZoom(i);
                }
              }
            },
            itemBuilder: (context, index) {
              return Center(
                child: InteractiveViewer(
                  transformationController: _transformationControllers[index],
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: Image.network(
                    widget.images[index],
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.error, color: Colors.white54, size: 48),
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentPage + 1} / ${widget.images.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
