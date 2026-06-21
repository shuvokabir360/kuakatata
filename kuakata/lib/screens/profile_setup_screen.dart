import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String email;
  final String name;

  const ProfileSetupScreen({
    Key? key,
    required this.email,
    required this.name,
  }) : super(key: key);

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();
  final _hotelNameController = TextEditingController();
  final _roomNumberController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _mobileController.dispose();
    _addressController.dispose();
    _hotelNameController.dispose();
    _roomNumberController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      final updatedUser = await ApiService.updateProfile(
        email: widget.email,
        mobile: _mobileController.text.trim(),
        address: _addressController.text.trim(),
        hotelName: _hotelNameController.text.trim(),
        roomNumber: _roomNumberController.text.trim(),
      );

      if (updatedUser != null) {
        // Fetch current user details from provider to preserve name and googleId
        final currentUserData = {
          'name': widget.name,
          'email': widget.email,
          ...updatedUser,
        };
        await userProvider.login(currentUserData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(langProvider.isBangla ? 'প্রোফাইল সংরক্ষণ করা হয়েছে' : 'Profile saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        setState(() {
          _errorMessage = langProvider.isBangla ? 'সংরক্ষণ করতে ব্যর্থ হয়েছে।' : 'Failed to save profile.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: Text(langProvider.isBangla ? 'প্রোফাইল সেটআপ' : 'Profile Setup'),
        automaticallyImplyLeading: false, // Force them to complete setup
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                Text(
                  langProvider.isBangla ? 'আপনার প্রোফাইল সম্পন্ন করুন' : 'Complete Your Profile',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  langProvider.isBangla 
                      ? 'অ্যাপের সেবাগুলো পেতে প্রোফাইলের তথ্য প্রদান করুন।' 
                      : 'Please provide details below to access all app features.',
                  style: TextStyle(fontSize: 14, color: onSurface.withOpacity(0.6)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.2)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],

                // Mobile
                _buildTextField(
                  controller: _mobileController,
                  label: langProvider.isBangla ? 'মোবাইল নম্বর' : 'Mobile Number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length < 9) return 'Invalid phone number';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Address
                _buildTextField(
                  controller: _addressController,
                  label: langProvider.isBangla ? 'ঠিকানা' : 'Address',
                  icon: Icons.location_on_outlined,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 18),

                // Hotel Name
                _buildTextField(
                  controller: _hotelNameController,
                  label: langProvider.isBangla ? 'হোটেল নাম (ঐচ্ছিক)' : 'Hotel Name (Optional)',
                  icon: Icons.hotel_outlined,
                  hint: 'e.g. Hotel Sea Haven',
                ),
                const SizedBox(height: 18),

                // Room Number
                _buildTextField(
                  controller: _roomNumberController,
                  label: langProvider.isBangla ? 'রুম নম্বর (ঐচ্ছিক)' : 'Room Number (Optional)',
                  icon: Icons.meeting_room_outlined,
                  hint: 'e.g. 302',
                ),
                const SizedBox(height: 36),

                // Save Button
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
                    ),
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _isLoading ? null : _handleSave,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            langProvider.isBangla ? 'সংরক্ষণ করুন' : 'Save Details',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? hint,
    bool obscureText = false,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLength: maxLength,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: maxLength != null ? "" : null,
        prefixIcon: Icon(icon, color: const Color(0xFF00B4DB)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF00B4DB),
            width: 2,
          ),
        ),
      ),
    );
  }
}
