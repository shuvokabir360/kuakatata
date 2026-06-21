import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../services/api_service.dart';
import 'booking_screen.dart';
import 'food_screen.dart';
import 'helpline_screen.dart';
import 'settings_screen.dart';
import 'hotel_list_screen.dart';
import 'biker_list_screen.dart';
import 'van_list_screen.dart';
import 'board_list_screen.dart';
import 'boat_list_screen.dart';
import 'upcoming_screen.dart';
import 'spot_detail_screen.dart';

// ─── Design Constants (consistent with main.dart) ──────────────────────────
const _kPrimary     = Color(0xFF1E9CE1);
const _kAccent      = Color(0xFFFF6B35);
const _kTextDark    = Color(0xFF1A2B4A);
const _kTextSub     = Color(0xFF637A9F);
const _kCardShadow  = Color(0x14000000);

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Widget> tabs = [
      const HomeTab(),
      const BookingsTab(),
      const EmergencyTab(),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF243348) : const Color(0xFFE2EAF5),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : const Color(0xFF1E9CE1).withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.explore_rounded,
                  label: langProvider.translate('home'),
                  isSelected: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _NavItem(
                  icon: Icons.confirmation_num_rounded,
                  label: langProvider.translate('bookings'),
                  isSelected: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _NavItem(
                  icon: Icons.local_phone_rounded,
                  label: langProvider.translate('emergency'),
                  isSelected: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
                _NavItem(
                  icon: Icons.person_rounded,
                  label: langProvider.translate('settings'),
                  isSelected: _currentIndex == 3,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Custom Nav Item ─────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? _kPrimary.withOpacity(0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isSelected ? _kPrimary : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? _kPrimary : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== HOME TAB ====================
class HomeTab extends StatefulWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  late Future<List<Map<String, dynamic>>> _spotsFuture;

  @override
  void initState() {
    super.initState();
    _spotsFuture = ApiService.fetchContent('spot');
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final double screenWidth = MediaQuery.of(context).size.width;
    final double expandedHeight = screenWidth * 9 / 16;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Service cards with refined colors
    final List<Map<String, dynamic>> services = [
      {
        'id': 'hotel',
        'title': langProvider.translate('hotel_booking'),
        'icon': Icons.hotel_rounded,
        'color': const Color(0xFF1E9CE1), // sky blue
        'bg': const Color(0xFFE8F4FD),
      },
      {
        'id': 'bike',
        'title': langProvider.translate('bike_booking'),
        'icon': Icons.motorcycle_rounded,
        'color': const Color(0xFFFF6B35), // warm orange
        'bg': const Color(0xFFFFEFE9),
      },
      {
        'id': 'van',
        'title': langProvider.translate('van_booking'),
        'icon': Icons.electric_rickshaw_rounded,
        'color': const Color(0xFF22C55E), // fresh green
        'bg': const Color(0xFFEBFDF4),
      },
      {
        'id': 'board',
        'title': langProvider.translate('board_booking'),
        'icon': Icons.meeting_room_rounded,
        'color': const Color(0xFF8B5CF6), // violet
        'bg': const Color(0xFFF3EEFF),
      },
      {
        'id': 'boat',
        'title': langProvider.translate('boat_booking'),
        'icon': Icons.directions_boat_rounded,
        'color': const Color(0xFF06B6D4), // teal
        'bg': const Color(0xFFE4F8FB),
      },
      {
        'id': 'ship',
        'title': langProvider.translate('ship_booking'),
        'icon': Icons.directions_run_rounded,
        'color': const Color(0xFF3B82F6), // blue
        'bg': const Color(0xFFEFF5FF),
      },
      {
        'id': 'food',
        'title': langProvider.translate('food_order'),
        'icon': Icons.restaurant_rounded,
        'color': const Color(0xFFF43F5E), // rose
        'bg': const Color(0xFFFFEBEE),
      },
      {
        'id': 'police',
        'title': langProvider.translate('tourist_police'),
        'icon': Icons.local_police_rounded,
        'color': const Color(0xFF14B8A6), // teal-green
        'bg': const Color(0xFFE6F8F6),
      },
    ];

    return RefreshIndicator(
      color: _kPrimary,
      onRefresh: () async {
        setState(() {
          _spotsFuture = ApiService.fetchContent('spot');
        });
      },
      child: CustomScrollView(
        slivers: [
          // ─── Hero Banner ─────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: expandedHeight,
            floating: false,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF162336) : Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 14),
              title: LayoutBuilder(
                builder: (context, constraints) {
                  final double top = constraints.biggest.height;
                  final bool isCollapsed = top <= kToolbarHeight + MediaQuery.of(context).padding.top + 10;
                  return AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: isCollapsed ? 1.0 : 0.0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: _kPrimary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.explore_rounded, color: Colors.white, size: 14),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          langProvider.translate('app_title'),
                          style: TextStyle(
                            color: isDark ? Colors.white : _kTextDark,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  const AutoImageSlider(),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.25),
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    bottom: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _kAccent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            langProvider.isBangla ? 'সাগর কন্যা' : 'Daughter of the Sea',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          langProvider.translate('app_title'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                            shadows: [
                              Shadow(offset: Offset(0, 2), blurRadius: 6, color: Colors.black54),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          langProvider.translate('tagline'),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── Weather Card ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor),
                  boxShadow: [
                    BoxShadow(
                      color: _kCardShadow,
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.wb_sunny_rounded, color: Color(0xFFF59E0B), size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              langProvider.translate('weather_title'),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${langProvider.translate('weather_cond')} • ${langProvider.translate('tide_status')}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _kPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          langProvider.translate('weather_temp'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: _kPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ─── Services Header ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    langProvider.isBangla ? 'আমাদের সেবাসমূহ' : 'Our Services',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    langProvider.isBangla ? 'সব দেখুন' : 'See all',
                    style: const TextStyle(
                      color: _kPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── Services Grid ────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 14,
                crossAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final service = services[index];
                  final Color iconColor = service['color'];
                  final Color bgColor = isDark
                      ? iconColor.withOpacity(0.15)
                      : service['bg'];

                  return GestureDetector(
                    onTap: () => _onServiceTap(context, service),
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Center(
                              child: Icon(
                                service['icon'],
                                color: iconColor,
                                size: 26,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          service['title'],
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
                childCount: services.length,
              ),
            ),
          ),

          // ─── Spots Header ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 26, 16, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    langProvider.translate('explore_spots'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _kAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on_rounded, color: _kAccent, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          langProvider.isBangla ? 'কুয়াকাটা' : 'Kuakata',
                          style: const TextStyle(
                            color: _kAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── Spots Horizontal List ────────────────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 210,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _spotsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2.5),
                    );
                  }
                  if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.landscape_rounded,
                              size: 36, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                          const SizedBox(height: 8),
                          Text(
                            langProvider.isBangla ? 'কোনো স্পট পাওয়া যায়নি' : 'No spots found',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  final spots = snapshot.data!;
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(left: 16, right: 4),
                    itemCount: spots.length,
                    itemBuilder: (context, index) {
                      final spot = spots[index];
                      final spotTitle = langProvider.locale == 'en'
                          ? (spot['title_en'] ?? spot['title'] ?? '')
                          : (spot['title_bn'] ?? spot['title'] ?? '');
                      final spotDesc = langProvider.locale == 'en'
                          ? (spot['desc_en'] ?? spot['desc'] ?? '')
                          : (spot['desc_bn'] ?? spot['desc'] ?? '');

                      return GestureDetector(
                        onTap: () {
                          final mappedSpot = {
                            'title': spotTitle.toString(),
                            'desc': spotDesc.toString(),
                            'image': (spot['image'] ?? '').toString(),
                            'about_en': (spot['about_en'] ?? '').toString(),
                            'about_bn': (spot['about_bn'] ?? '').toString(),
                            'tips_en': (spot['tips_en'] ?? '').toString(),
                            'tips_bn': (spot['tips_bn'] ?? '').toString(),
                            'location_en': (spot['location_en'] ?? '').toString(),
                            'location_bn': (spot['location_bn'] ?? '').toString(),
                            'timings_en': (spot['timings_en'] ?? '').toString(),
                            'timings_bn': (spot['timings_bn'] ?? '').toString(),
                            'transport_en': (spot['transport_en'] ?? '').toString(),
                            'transport_bn': (spot['transport_bn'] ?? '').toString(),
                          };
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SpotDetailScreen(spot: mappedSpot),
                            ),
                          );
                        },
                        child: Container(
                          width: 200,
                          margin: const EdgeInsets.only(right: 12, bottom: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  spot['image'] ?? '',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: isDark
                                          ? const Color(0xFF1E2F42)
                                          : const Color(0xFFE8F4FD),
                                      child: const Icon(Icons.image_rounded,
                                          color: Colors.white30, size: 40),
                                    );
                                  },
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.75),
                                      ],
                                      stops: const [0.45, 1.0],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        spotTitle,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        spotDesc,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 10.5,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  void _onServiceTap(BuildContext context, Map<String, dynamic> service) {
    switch (service['id']) {
      case 'food':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const FoodScreen()));
        break;
      case 'police':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const HelplineScreen()));
        break;
      case 'hotel':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const HotelListScreen()));
        break;
      case 'board':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const BoardListScreen()));
        break;
      case 'boat':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const BoatListScreen()));
        break;
      case 'bike':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const BikerListScreen()));
        break;
      case 'van':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const VanListScreen()));
        break;
      case 'ship':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => UpcomingScreen(title: service['title'])),
        );
        break;
      default:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookingScreen(
              serviceId: service['id'],
              serviceName: service['title'],
            ),
          ),
        );
    }
  }
}

// ==================== BOOKINGS TAB ====================
class BookingsTab extends StatelessWidget {
  const BookingsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;



    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(langProvider.translate('bookings')),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark
                      ? _kPrimary.withOpacity(0.12)
                      : const Color(0xFFE8F4FD),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  size: 52,
                  color: _kPrimary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                langProvider.isBangla ? 'কোনো বুকিং নেই' : 'No Bookings Yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                langProvider.isBangla
                    ? 'আপনার বুকিং এখানে দেখা যাবে'
                    : 'Your bookings will appear here once you make one.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? color.withOpacity(0.12) : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== EMERGENCY TAB ====================
class EmergencyTab extends StatelessWidget {
  const EmergencyTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const HelplineScreen();
  }
}

// ==================== AUTO IMAGE SLIDER ====================
class AutoImageSlider extends StatefulWidget {
  const AutoImageSlider({Key? key}) : super(key: key);

  @override
  State<AutoImageSlider> createState() => _AutoImageSliderState();
}

class _AutoImageSliderState extends State<AutoImageSlider> {
  late final PageController _pageController;
  Timer? _sliderTimer;
  int _currentPage = 0;

  final List<Map<String, dynamic>> _fallbackSlides = [
    {
      'title_en': 'Sunset at Kuakata Beach',
      'title_bn': 'কুয়াকাটা সৈকতে মনোরম সূর্যাস্ত',
      'image': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80',
    },
    {
      'title_en': 'Gangamati Mangrove Forest',
      'title_bn': 'গঙ্গামতির সংরক্ষিত ম্যানগ্রোভ বন',
      'image': 'https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&w=800&q=80',
    },
    {
      'title_en': 'Scenic Jhau Forest',
      'title_bn': 'মনোরম ঝাউবন ও ঝাউগাছের সৈকত',
      'image': 'https://images.unsplash.com/photo-1502082553048-f009c37129b9?auto=format&fit=crop&w=800&q=80',
    },
    {
      'title_en': 'Red Crab Beach Sanctuary',
      'title_bn': 'লাল কাঁকড়ার অভয়ারণ্য সৈকত',
      'image': 'https://images.unsplash.com/photo-1601662528567-526cd06f6582?auto=format&fit=crop&w=800&q=80',
    },
    {
      'title_en': 'Misripara Buddhist Temple',
      'title_bn': 'ঐতিহাসিক মিশ্রিপাড়া বৌদ্ধ মন্দির',
      'image': 'https://images.unsplash.com/photo-1609137144814-4c4f34cf33fb?auto=format&fit=crop&w=800&q=80',
    },
  ];

  List<Map<String, dynamic>> _slides = [];

  @override
  void initState() {
    super.initState();
    _slides = List.from(_fallbackSlides);
    _pageController = PageController(initialPage: 0);
    _fetchSlides();
    _startTimer();
  }

  Future<void> _fetchSlides() async {
    try {
      final fetched = await ApiService.fetchContent('slider');
      if (fetched.isNotEmpty && mounted) {
        setState(() {
          _slides = fetched;
        });
      }
    } catch (e) {
      debugPrint('Error loading slider slides: $e');
    }
  }

  void _startTimer() {
    _sliderTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients && _slides.isNotEmpty) {
        final nextPage = (_pageController.page!.round() + 1) % _slides.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _sliderTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);

    if (_slides.isEmpty) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1278B8), Color(0xFF1E9CE1)],
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: _slides.length,
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
          },
          itemBuilder: (context, index) {
            final slide = _slides[index];
            final imageUrl = (slide['image'] ?? '').toString();
            return Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1278B8), Color(0xFF1E9CE1)],
                    ),
                  ),
                );
              },
            );
          },
        ),
        // Dots indicator
        Positioned(
          bottom: 72,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _slides.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 4,
                width: _currentPage == index ? 18 : 4,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? Colors.white
                      : Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
