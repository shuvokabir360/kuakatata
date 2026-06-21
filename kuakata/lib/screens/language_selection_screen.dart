import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import 'home_screen.dart';

const _kPrimary  = Color(0xFF1E9CE1);
const _kAccent   = Color(0xFFFF6B35);
const _kTextDark = Color(0xFF1A2B4A);
const _kTextSub  = Color(0xFF637A9F);

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({Key? key}) : super(key: key);

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String _selectedLang = 'en';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _selectedLang = Provider.of<LanguageProvider>(context, listen: false).locale;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ─── Gradient Background ──────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isLight
                    ? [
                        const Color(0xFFF4F8FD),
                        const Color(0xFFE8F4FD),
                        const Color(0xFFF4F8FD),
                      ]
                    : [
                        const Color(0xFF0D1B2E),
                        const Color(0xFF162336),
                        const Color(0xFF0D1B2E),
                      ],
              ),
            ),
          ),

          // ─── Decorative circles ────────────────────────────────────────
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kPrimary.withOpacity(isLight ? 0.08 : 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kAccent.withOpacity(isLight ? 0.06 : 0.04),
              ),
            ),
          ),

          // ─── Content ──────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 2),

                  // App icon
                  Center(
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_kPrimary, Color(0xFF1278B8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: _kPrimary.withOpacity(0.35),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.explore_rounded,
                        size: 46,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Center(
                    child: Text(
                      _selectedLang == 'en' ? 'Welcome to Kuakata' : 'কুয়াকাটায় আপনাকে স্বাগতম',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: isLight ? _kTextDark : Colors.white,
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: _kAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _kAccent.withOpacity(0.2)),
                      ),
                      child: Text(
                        _selectedLang == 'en' ? '🌊 Daughter of the Ocean' : '🌊 সাগর কন্যা কুয়াকাটা',
                        style: const TextStyle(
                          fontSize: 13,
                          color: _kAccent,
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Prompt
                  Text(
                    _selectedLang == 'en' ? 'Choose Your Language' : 'ভাষা নির্বাচন করুন',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: isLight ? _kTextDark : Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _selectedLang == 'en'
                        ? 'Select your preferred language to continue'
                        : 'অনুগ্রহ করে ভাষা নির্বাচন করে এগিয়ে যান',
                    style: TextStyle(
                      fontSize: 13,
                      color: isLight ? _kTextSub : Colors.white54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Language Cards
                  _buildLanguageCard(
                    title: 'English',
                    subtitle: 'Explore in English',
                    code: 'en',
                    flagEmoji: '🇺🇸',
                    isLight: isLight,
                  ),
                  const SizedBox(height: 12),
                  _buildLanguageCard(
                    title: 'বাংলা',
                    subtitle: 'বাংলায় অন্বেষণ করুন',
                    code: 'bn',
                    flagEmoji: '🇧🇩',
                    isLight: isLight,
                  ),

                  const Spacer(flex: 3),

                  // Continue Button
                  Container(
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [_kPrimary, Color(0xFF1278B8)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _kPrimary.withOpacity(0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () async {
                        await langProvider.setLanguage(_selectedLang);
                        await langProvider.setFirstTimeCompleted();
                        if (context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const HomeScreen()),
                          );
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _selectedLang == 'en' ? 'Continue' : 'এগিয়ে যান',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageCard({
    required String title,
    required String subtitle,
    required String code,
    required String flagEmoji,
    required bool isLight,
  }) {
    final isSelected = _selectedLang == code;

    return GestureDetector(
      onTap: () => setState(() => _selectedLang = code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isLight ? Colors.white : const Color(0xFF162336))
              : (isLight ? Colors.white.withOpacity(0.6) : const Color(0xFF0D1B2E).withOpacity(0.5)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _kPrimary : (isLight ? const Color(0xFFE2EAF5) : const Color(0xFF243348)),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _kPrimary.withOpacity(0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isLight ? const Color(0xFFF4F8FD) : const Color(0xFF162336),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(flagEmoji, style: const TextStyle(fontSize: 26)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: isLight ? _kTextDark : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isLight ? _kTextSub : Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? _kPrimary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? _kPrimary : (isLight ? const Color(0xFFCDD9EC) : const Color(0xFF3A5270)),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
