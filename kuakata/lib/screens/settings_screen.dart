import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'complaints_screen.dart';
import 'super_admin_hotel_management.dart';
import 'manager_dashboard.dart';

const _kPrimary   = Color(0xFF1E9CE1);
const _kAccent    = Color(0xFFFF6B35);
const _kTextDark  = Color(0xFF1A2B4A);
const _kTextSub   = Color(0xFF637A9F);
const _kCardShadow = Color(0x14000000);

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _urlController.text = ApiService.baseUrl;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _saveBackendUrl() async {
    String url = _urlController.text.trim();
    if (url.isNotEmpty) {
      await ApiService.updateBaseUrl(url);
      if (mounted) {
        final langProvider = Provider.of<LanguageProvider>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(langProvider.translate('save_success')),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(langProvider.translate('settings')),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Theme.of(context).dividerColor),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── User Profile Section ────────────────────────────────────
            if (userProvider.isLoggedIn)
              _buildCard(
                context,
                isDark: isDark,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_kPrimary, Color(0xFF1278B8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.person_rounded, size: 32, color: Colors.white),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userProvider.name,
                                style: TextStyle(
                                  color: onSurface,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(Icons.phone_rounded, size: 12, color: _kTextSub),
                                  const SizedBox(width: 4),
                                  Text(
                                    userProvider.mobile,
                                    style: TextStyle(
                                      color: isDark ? Colors.white54 : _kTextSub,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                            onPressed: () => userProvider.logout(),
                            tooltip: 'Logout',
                          ),
                        ),
                      ],
                    ),
                    if (userProvider.address.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      _buildDetailRow(Icons.location_on_rounded, langProvider.translate('address_field'), userProvider.address, onSurface),
                    ],
                    if (userProvider.hotelName.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildDetailRow(Icons.hotel_rounded, langProvider.translate('hotel_name'), userProvider.hotelName, onSurface),
                    ],
                    if (userProvider.roomNumber.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildDetailRow(Icons.meeting_room_rounded, langProvider.translate('room_number'), userProvider.roomNumber, onSurface),
                    ],
                    if (userProvider.email.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildDetailRow(Icons.email_rounded, langProvider.translate('email_field'), userProvider.email, onSurface),
                    ],
                    if (userProvider.isSuperAdmin) ...[
                      const SizedBox(height: 14),
                      _buildActionButton(
                        icon: Icons.admin_panel_settings_rounded,
                        label: 'Super Admin Panel',
                        color: const Color(0xFF8B5CF6),
                        isDark: isDark,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (context) => const SuperAdminHotelManagement())),
                      ),
                    ],
                    if (userProvider.isManager) ...[
                      const SizedBox(height: 10),
                      _buildActionButton(
                        icon: Icons.dashboard_rounded,
                        label: 'Manager Dashboard',
                        color: const Color(0xFF22C55E),
                        isDark: isDark,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (context) => const ManagerDashboard())),
                      ),
                    ],
                  ],
                ),
              )
            else
              _buildCard(
                context,
                isDark: isDark,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _kPrimary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.person_outline_rounded, size: 44, color: _kPrimary),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      langProvider.isBangla
                          ? 'মতামত ও অভিযোগ জানাতে লগইন করুন'
                          : 'Log in to submit complaints & write reviews',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? Colors.white70 : _kTextSub,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [_kPrimary, Color(0xFF1278B8)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _kPrimary.withOpacity(0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.login_rounded, size: 18, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              langProvider.translate('login'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),

            // ─── Complaint Box ───────────────────────────────────────────
            _buildListTileCard(
              context,
              isDark: isDark,
              icon: Icons.campaign_rounded,
              iconColor: _kAccent,
              iconBg: isDark ? _kAccent.withOpacity(0.12) : const Color(0xFFFFEFE9),
              title: langProvider.isBangla ? 'পাবলিক অভিযোগ বক্স' : 'Public Complaint Box',
              subtitle: langProvider.isBangla
                  ? 'অভিযোগ দেখুন এবং জমা দিন'
                  : 'View public complaints & file your own',
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (context) => const ComplaintsScreen())),
            ),
            const SizedBox(height: 12),

            // ─── Language Selection ──────────────────────────────────────
            _buildCard(
              context,
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(Icons.translate_rounded, langProvider.translate('change_lang'), _kPrimary),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSelector(
                          title: 'English',
                          isSelected: langProvider.locale == 'en',
                          onTap: () => langProvider.setLanguage('en'),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildSelector(
                          title: 'বাংলা',
                          isSelected: langProvider.locale == 'bn',
                          onTap: () => langProvider.setLanguage('bn'),
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ─── Theme Selection ─────────────────────────────────────────
            _buildCard(
              context,
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(Icons.palette_rounded, langProvider.translate('theme_mode'), _kPrimary),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _buildThemeSelector(
                          title: langProvider.translate('light_mode'),
                          icon: Icons.light_mode_rounded,
                          isSelected: !themeProvider.isDarkMode,
                          onTap: () => themeProvider.setTheme(false),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildThemeSelector(
                          title: langProvider.translate('dark_mode'),
                          icon: Icons.dark_mode_rounded,
                          isSelected: themeProvider.isDarkMode,
                          onTap: () => themeProvider.setTheme(true),
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ─── Backend URL (Super Admin only) ──────────────────────────
            if (userProvider.isSuperAdmin) ...[
              _buildCard(
                context,
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(Icons.dns_rounded, langProvider.translate('backend_url'), _kPrimary),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _urlController,
                      style: TextStyle(color: onSurface, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'e.g. http://192.168.1.100:5000',
                        hintStyle: TextStyle(color: onSurface.withOpacity(0.3), fontSize: 13),
                        prefixIcon: const Icon(Icons.link_rounded, color: _kPrimary, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _saveBackendUrl,
                        child: Text(langProvider.translate('save')),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ─── About Kuakata ───────────────────────────────────────────
            _buildCard(
              context,
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(Icons.info_outline_rounded, langProvider.translate('about_kuakata'), _kPrimary),
                  const SizedBox(height: 12),
                  Text(
                    langProvider.translate('about_text'),
                    style: TextStyle(
                      color: isDark ? Colors.white70 : _kTextSub,
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ─── About Us ────────────────────────────────────────────────
            _buildCard(
              context,
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(Icons.groups_rounded, langProvider.translate('about_us'), _kPrimary),
                  const SizedBox(height: 16),
                  _buildPersonRow(
                    context,
                    icon: Icons.person_rounded,
                    roleLabel: langProvider.translate('founder_title'),
                    name: langProvider.translate('founder_name'),
                    desc: langProvider.translate('founder_desc'),
                    onSurface: onSurface,
                    isDark: isDark,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Divider(height: 1),
                  ),
                  _buildPersonRow(
                    context,
                    icon: Icons.code_rounded,
                    roleLabel: langProvider.translate('developer_title'),
                    name: langProvider.translate('developer_name'),
                    desc: null,
                    onSurface: onSurface,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ─── Helper Widgets ─────────────────────────────────────────────────────

  Widget _buildCard(BuildContext context, {required bool isDark, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: _kCardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildListTileCard(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: [
            BoxShadow(
              color: _kCardShadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark ? Colors.white38 : _kTextSub,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 17),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildSelector({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: isSelected
              ? _kPrimary
              : (isDark ? const Color(0xFF243348) : const Color(0xFFF0F6FF)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? _kPrimary : (isDark ? const Color(0xFF3A5270) : const Color(0xFFD6E4F7)),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : (isDark ? Colors.white54 : _kTextSub),
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildThemeSelector({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: isSelected
              ? _kPrimary
              : (isDark ? const Color(0xFF243348) : const Color(0xFFF0F6FF)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? _kPrimary : (isDark ? const Color(0xFF3A5270) : const Color(0xFFD6E4F7)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : (isDark ? Colors.white54 : _kTextSub),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : (isDark ? Colors.white54 : _kTextSub),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? color.withOpacity(0.12) : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 13, color: color.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color onSurface) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _kPrimary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(color: onSurface.withOpacity(0.45), fontSize: 13, fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: onSurface, fontSize: 13, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPersonRow(
    BuildContext context, {
    required IconData icon,
    required String roleLabel,
    required String name,
    required String? desc,
    required Color onSurface,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _kPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _kPrimary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                roleLabel,
                style: TextStyle(
                  color: isDark ? Colors.white38 : _kTextSub,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                style: TextStyle(
                  color: onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (desc != null) ...[
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: TextStyle(
                    color: isDark ? Colors.white54 : _kTextSub,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
