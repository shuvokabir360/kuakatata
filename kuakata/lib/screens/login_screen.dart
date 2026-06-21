import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../providers/language_provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import 'manager_dashboard.dart';
import 'profile_setup_screen.dart';

const _kPrimary   = Color(0xFF1E9CE1);
const _kAccent    = Color(0xFFFF6B35);
const _kTextDark  = Color(0xFF1A2B4A);
const _kTextSub   = Color(0xFF637A9F);

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isRegistering = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _pinVisible = false;
  bool _retypePinVisible = false;

  // Controllers
  final _identifierController = TextEditingController();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _pinController = TextEditingController();
  final _retypePinController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _hotelNameController = TextEditingController();
  final _roomNumberController = TextEditingController();

  @override
  void dispose() {
    _identifierController.dispose();
    _nameController.dispose();
    _mobileController.dispose();
    _pinController.dispose();
    _retypePinController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _hotelNameController.dispose();
    _roomNumberController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final langProvider = Provider.of<LanguageProvider>(context, listen: false);

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: '105167205582-eb29n26pkf345u2hqg3l17mfg87ffje5.apps.googleusercontent.com',
      );
      final GoogleSignInAccount? account = await googleSignIn.signIn();

      if (account != null) {
        await _loginWithGoogleAccount(account.email, account.displayName ?? 'Google User', account.id);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Google Sign-In API error: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = langProvider.isBangla
            ? 'গুগল সাইন-ইন ব্যর্থ হয়েছে।'
            : 'Google Sign-In failed. Please try again.';
      });
    }
  }

  Future<void> _loginWithGoogleAccount(String email, String name, String googleId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      final user = await ApiService.loginWithGoogle(
        email: email,
        name: name,
        googleId: googleId,
      );

      if (user != null) {
        await userProvider.login(user);
        final bool isNewProfile = user['mobile'] == null || user['mobile'].toString().trim().isEmpty;

        if (mounted) {
          if (isNewProfile) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileSetupScreen(email: email, name: name),
              ),
            );
          } else {
            _showSuccessSnack(langProvider.isBangla ? 'সফলভাবে লগইন হয়েছে' : 'Logged in successfully!');
            if (userProvider.isManager) {
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (context) => const ManagerDashboard()));
            } else {
              Navigator.pop(context, true);
            }
          }
        }
      } else {
        setState(() {
          _errorMessage = langProvider.isBangla ? 'লগইন ব্যর্থ হয়েছে।' : 'Login failed.';
        });
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      final user = await ApiService.loginUser(
        _identifierController.text.trim(),
        _pinController.text.trim(),
      );

      if (user != null) {
        await userProvider.login(user);
        if (mounted) {
          _showSuccessSnack(langProvider.isBangla ? 'সফলভাবে লগইন হয়েছে' : 'Logged in successfully!');
          if (userProvider.isManager) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => const ManagerDashboard()));
          } else {
            Navigator.pop(context, true);
          }
        }
      } else {
        setState(() {
          _errorMessage = langProvider.isBangla ? 'লগইন ব্যর্থ হয়েছে।' : 'Login failed.';
        });
      }
    } catch (e) {
      setState(() {
        if (e.toString().contains('Incorrect PIN')) {
          _errorMessage = langProvider.isBangla ? 'ভুল পিন / পাসওয়ার্ড' : 'Incorrect PIN / Password';
        } else if (e.toString().contains('not found')) {
          _errorMessage =
              langProvider.isBangla ? 'ভুল ইমেইল অথবা মোবাইল নম্বর' : 'Incorrect email or mobile number';
        } else {
          _errorMessage = e.toString();
        }
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (_pinController.text.trim() != _retypePinController.text.trim()) {
      setState(() {
        _errorMessage =
            langProvider.isBangla ? 'পিন / পাসওয়ার্ড দুটি মেলেনি।' : 'PINs / Passwords do not match.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final registrationData = {
      'name': _nameController.text.trim(),
      'mobile': _mobileController.text.trim(),
      'address': _addressController.text.trim(),
      'pin': _pinController.text.trim(),
      'email': _emailController.text.trim(),
      'hotelName': _hotelNameController.text.trim(),
      'roomNumber': _roomNumberController.text.trim(),
    };

    try {
      final user = await ApiService.registerUser(registrationData);

      if (user != null) {
        await userProvider.login(user);
        if (mounted) {
          _showSuccessSnack(
              langProvider.isBangla ? 'নিবন্ধন সফল হয়েছে!' : 'Registration successful!');
          Navigator.pop(context, true);
        }
      } else {
        setState(() {
          _errorMessage =
              langProvider.isBangla ? 'নিবন্ধন ব্যর্থ হয়েছে।' : 'Registration failed.';
        });
      }
    } catch (e) {
      String msg = e.toString();
      if (langProvider.isBangla) {
        if (msg.contains('mobile number already exists')) {
          msg = 'এই মোবাইল নম্বর দিয়ে ইতিমধ্যে একটি অ্যাকাউন্ট তৈরি করা হয়েছে।';
        } else if (msg.contains('email address already exists')) {
          msg = 'এই ইমেইল ঠিকানা দিয়ে ইতিমধ্যে একটি অ্যাকাউন্ট তৈরি করা হয়েছে।';
        }
      }
      setState(() => _errorMessage = msg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(msg),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildGoogleIcon() {
    return SizedBox(
      width: 22,
      height: 22,
      child: Text(
        'G',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 18,
          foreground: Paint()
            ..shader = const LinearGradient(
              colors: [Colors.red, Colors.orange, Colors.green, Colors.blue],
            ).createShader(const Rect.fromLTWH(0, 0, 22, 22)),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          langProvider.isBangla
              ? (_isRegistering ? 'নিবন্ধন করুন' : 'লগইন করুন')
              : (_isRegistering ? 'Create Account' : 'Sign In'),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Theme.of(context).dividerColor),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Header ──────────────────────────────────────────────
              Center(
                child: Container(
                  height: 76,
                  width: 76,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_kPrimary, Color(0xFF1278B8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: _kPrimary.withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.travel_explore_rounded, size: 40, color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                langProvider.isBangla ? 'কুয়াকাটা ট্রাভেল গাইড' : 'Kuakata Travel Guide',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : _kTextDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                langProvider.isBangla
                    ? 'ভ্রমণ নির্দেশিকা ও হোটেল বুকিং অ্যাপ'
                    : 'Travel Guide & Hotel Booking App',
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? Colors.white38 : _kTextSub,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // ─── Error Box ───────────────────────────────────────────
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              // ─── Google Sign In ──────────────────────────────────────
              SizedBox(
                height: 50,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF1E2F42) : Colors.white,
                    foregroundColor: onSurface,
                    side: BorderSide(
                      color: isDark ? const Color(0xFF3A5270) : const Color(0xFFD6E4F7),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildGoogleIcon(),
                      const SizedBox(width: 10),
                      Text(
                        langProvider.isBangla ? 'গুগল দিয়ে সাইন ইন করুন' : 'Continue with Google',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : _kTextDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ─── OR divider ──────────────────────────────────────────
              Row(
                children: [
                  Expanded(child: Divider(color: Theme.of(context).dividerColor)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0),
                    child: Text(
                      langProvider.isBangla ? 'অথবা' : 'OR',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white30 : _kTextSub.withOpacity(0.7),
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Theme.of(context).dividerColor)),
                ],
              ),
              const SizedBox(height: 20),

              // ─── Form Fields ─────────────────────────────────────────
              if (!_isRegistering) ...[
                _buildField(
                  controller: _identifierController,
                  label: langProvider.isBangla ? 'ইমেইল অথবা মোবাইল নম্বর' : 'Email or Mobile Number',
                  icon: Icons.person_outline_rounded,
                  isDark: isDark,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? (langProvider.isBangla ? 'প্রয়োজনীয় ক্ষেত্র' : 'Required')
                      : null,
                ),
                const SizedBox(height: 14),
                _buildField(
                  controller: _pinController,
                  label: langProvider.isBangla ? 'পিন / পাসওয়ার্ড' : 'PIN / Password',
                  icon: Icons.lock_outline_rounded,
                  isDark: isDark,
                  obscureText: !_pinVisible,
                  keyboardType: TextInputType.visiblePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _pinVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: isDark ? Colors.white38 : _kTextSub,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _pinVisible = !_pinVisible),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return langProvider.isBangla ? 'প্রয়োজনীয় ক্ষেত্র' : 'Required';
                    }
                    if (v.length < 6) {
                      return langProvider.isBangla
                          ? 'কমপক্ষে ৬ অক্ষর'
                          : 'Minimum 6 characters';
                    }
                    return null;
                  },
                ),
              ] else ...[
                _buildField(
                  controller: _nameController,
                  label: langProvider.isBangla ? 'পূর্ণ নাম' : 'Full Name',
                  icon: Icons.person_outline_rounded,
                  isDark: isDark,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? (langProvider.isBangla ? 'প্রয়োজনীয় ক্ষেত্র' : 'Required')
                      : null,
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _mobileController,
                  label: langProvider.isBangla ? 'মোবাইল নম্বর' : 'Mobile Number',
                  icon: Icons.phone_outlined,
                  isDark: isDark,
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? (langProvider.isBangla ? 'প্রয়োজনীয় ক্ষেত্র' : 'Required')
                      : null,
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _emailController,
                  label: langProvider.isBangla ? 'ইমেইল ঠিকানা' : 'Email Address',
                  icon: Icons.email_outlined,
                  isDark: isDark,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return langProvider.isBangla ? 'প্রয়োজনীয় ক্ষেত্র' : 'Required';
                    }
                    if (!v.contains('@') || !v.contains('.')) {
                      return langProvider.isBangla ? 'সঠিক ইমেইল লিখুন' : 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _addressController,
                  label: langProvider.isBangla ? 'ঠিকানা' : 'Address',
                  icon: Icons.location_on_outlined,
                  isDark: isDark,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? (langProvider.isBangla ? 'প্রয়োজনীয় ক্ষেত্র' : 'Required')
                      : null,
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _hotelNameController,
                  label: langProvider.isBangla ? 'হোটেল নাম (ঐচ্ছিক)' : 'Hotel Name (Optional)',
                  icon: Icons.hotel_outlined,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _roomNumberController,
                  label: langProvider.isBangla ? 'রুম নম্বর (ঐচ্ছিক)' : 'Room Number (Optional)',
                  icon: Icons.meeting_room_outlined,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _pinController,
                  label: langProvider.isBangla
                      ? 'পিন / পাসওয়ার্ড (কমপক্ষে ৬ অক্ষর)'
                      : 'PIN / Password (min 6 chars)',
                  icon: Icons.lock_outline_rounded,
                  isDark: isDark,
                  obscureText: !_pinVisible,
                  keyboardType: TextInputType.visiblePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _pinVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: isDark ? Colors.white38 : _kTextSub,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _pinVisible = !_pinVisible),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return langProvider.isBangla ? 'প্রয়োজনীয় ক্ষেত্র' : 'Required';
                    }
                    if (v.length < 6) {
                      return langProvider.isBangla
                          ? 'কমপক্ষে ৬ অক্ষর'
                          : 'Minimum 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _retypePinController,
                  label: langProvider.isBangla ? 'পিন পুনরায় টাইপ করুন' : 'Confirm PIN / Password',
                  icon: Icons.lock_outline_rounded,
                  isDark: isDark,
                  obscureText: !_retypePinVisible,
                  keyboardType: TextInputType.visiblePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _retypePinVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: isDark ? Colors.white38 : _kTextSub,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _retypePinVisible = !_retypePinVisible),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return langProvider.isBangla ? 'প্রয়োজনীয় ক্ষেত্র' : 'Required';
                    }
                    if (v != _pinController.text) {
                      return langProvider.isBangla
                          ? 'পিন দুটি মেলেনি'
                          : 'PINs do not match';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 26),

              // ─── Submit Button ────────────────────────────────────────
              Container(
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [_kPrimary, Color(0xFF1278B8)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _kPrimary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isLoading
                      ? null
                      : (_isRegistering ? _handleRegister : _handleLogin),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          langProvider.isBangla
                              ? (_isRegistering ? 'নিবন্ধন করুন' : 'সাইন ইন করুন')
                              : (_isRegistering ? 'Create Account' : 'Sign In'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // ─── Toggle Register/Login ────────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isRegistering = !_isRegistering;
                      _errorMessage = null;
                      _pinController.clear();
                      _retypePinController.clear();
                    });
                  },
                  child: RichText(
                    text: TextSpan(
                      text: langProvider.isBangla
                          ? (_isRegistering ? 'ইতিমধ্যেই অ্যাকাউন্ট আছে? ' : 'নতুন অ্যাকাউন্ট তৈরি করবেন? ')
                          : (_isRegistering ? 'Already have an account? ' : "Don't have an account? "),
                      style: TextStyle(
                        color: isDark ? Colors.white54 : _kTextSub,
                        fontSize: 13.5,
                      ),
                      children: [
                        TextSpan(
                          text: langProvider.isBangla
                              ? (_isRegistering ? 'লগইন করুন' : 'নিবন্ধন করুন')
                              : (_isRegistering ? 'Sign In' : 'Register'),
                          style: const TextStyle(
                            color: _kPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLength: maxLength,
      validator: validator,
      enableInteractiveSelection: true,
      style: TextStyle(
        color: isDark ? Colors.white : _kTextDark,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        prefixIcon: Icon(icon, color: _kPrimary, size: 20),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF3A5270) : const Color(0xFFD6E4F7),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.withOpacity(0.5)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E2F42) : const Color(0xFFF0F6FF),
        labelStyle: TextStyle(
          color: isDark ? Colors.white38 : _kTextSub,
          fontSize: 13.5,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}
