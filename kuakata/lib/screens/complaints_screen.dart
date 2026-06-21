import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({Key? key}) : super(key: key);

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _complaints = [];

  final _topFormKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descController = TextEditingController();
  String? _selectedPhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadComplaints() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final list = await ApiService.fetchPublicComplaints();
    if (!mounted) return;
    setState(() {
      _complaints = list;
      _isLoading = false;
    });
  }

  Widget _buildTopComplaintBox(LanguageProvider langProvider, UserProvider userProvider) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    if (!userProvider.isLoggedIn) {
      return Card(
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        color: const Color(0xFF00B4DB).withOpacity(0.06),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const Icon(Icons.lock_person_outlined, size: 48, color: Color(0xFF00B4DB)),
              const SizedBox(height: 12),
              Text(
                langProvider.isBangla ? 'পাবলিক অভিযোগ করতে লগইন করুন' : 'Log in to submit a public complaint',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  ).then((value) {
                    if (value == true) {
                      _loadComplaints();
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B4DB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(langProvider.translate('login')),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFF00B4DB).withOpacity(0.15)),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _topFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00B4DB).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.campaign, color: Color(0xFF00B4DB), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    langProvider.isBangla ? 'পাবলিক অভিযোগ বক্স' : 'Public Complaint Box',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(height: 24),
              
              // Subject
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(
                  labelText: langProvider.translate('subject'),
                  prefixIcon: const Icon(Icons.subtitles_outlined, color: Color(0xFF00B4DB), size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // Description
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: langProvider.translate('description'),
                  prefixIcon: const Icon(Icons.description_outlined, color: Color(0xFF00B4DB), size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // Photo Selector Header
              Text(
                langProvider.translate('photo'),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: onSurface),
              ),
              const SizedBox(height: 8),

              // Photo Placeholder
              Container(
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFF00B4DB).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF00B4DB).withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF00B4DB), size: 22),
                    const SizedBox(width: 8),
                    Text(
                      langProvider.isBangla ? 'ছবি যুক্ত করুন (শীঘ্রই আসছে)' : 'Attach photo (coming soon)',
                      style: const TextStyle(color: Color(0xFF00B4DB), fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Submit Button
              Container(
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
                  ),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    if (!_topFormKey.currentState!.validate()) return;
                    
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(child: CircularProgressIndicator()),
                    );

                    final success = await ApiService.submitComplaint({
                      'userName': userProvider.name,
                      'userMobile': userProvider.mobile,
                      'subject': _subjectController.text.trim(),
                      'description': _descController.text.trim(),
                      'image': _selectedPhotoUrl ?? '',
                    });

                    if (mounted) {
                      Navigator.pop(context); // pop loader
                    }

                    if (success) {
                      _subjectController.clear();
                      _descController.clear();
                      setState(() {
                        _selectedPhotoUrl = null;
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(langProvider.translate('complaint_success')),
                            backgroundColor: Colors.green,
                          ),
                        );
                        _loadComplaints();
                      }
                    }
                  },
                  child: Text(
                    langProvider.translate('submit_complaint'),
                    style: const TextStyle(
                      fontSize: 14,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: Text(langProvider.isBangla ? 'পাবলিক অভিযোগ বক্স' : 'Public Complaint Box'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadComplaints,
              child: ListView(
                children: [
                  _buildTopComplaintBox(langProvider, userProvider),
                  
                  // Section Header for Existing Complaints
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Text(
                      langProvider.isBangla ? 'সাম্প্রতিক পাবলিক অভিযোগ সমূহ' : 'Recent Public Complaints',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: onSurface.withOpacity(0.8),
                      ),
                    ),
                  ),

                  if (_complaints.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40.0),
                        child: Text(
                          langProvider.translate('no_complaints'),
                          style: TextStyle(color: onSurface.withOpacity(0.5)),
                        ),
                      ),
                    )
                  else
                    ..._complaints.map((c) {
                      final subject = c['subject'] ?? '';
                      final description = c['description'] ?? '';
                      final status = c['status'] ?? 'Pending';
                      final imageUrl = c['image'] ?? '';
                      final userName = c['userName'] ?? 'Anonymous';
                      final userMobile = c['userMobile'] ?? '';
                      
                      Color statusColor = Colors.orangeAccent;
                      if (status == 'Resolved') statusColor = Colors.green;
                      if (status == 'Under Investigation') statusColor = Colors.blue;

                      // Format Date
                      String dateStr = '';
                      if (c['createdAt'] != null) {
                        try {
                          final date = DateTime.parse(c['createdAt']);
                          dateStr = '${date.day}/${date.month}/${date.year}';
                        } catch (_) {
                          dateStr = c['createdAt'].toString().split('T')[0];
                        }
                      }

                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (imageUrl.isNotEmpty)
                              Image.network(
                                imageUrl,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, err, stack) => const SizedBox(),
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
                                          subject,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: onSurface,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: statusColor.withOpacity(0.3)),
                                        ),
                                        child: Text(
                                          status,
                                          style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  // Posted by info (obfuscated mobile for privacy)
                                  Row(
                                    children: [
                                      Icon(Icons.person_outline, size: 14, color: onSurface.withOpacity(0.5)),
                                      const SizedBox(width: 4),
                                      Text(
                                        'by $userName (${userMobile.length > 5 ? userMobile.substring(0, 5) + '***' : userMobile})',
                                        style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 11),
                                      ),
                                      const Spacer(),
                                      Text(
                                        dateStr,
                                        style: TextStyle(color: onSurface.withOpacity(0.4), fontSize: 10),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 16),
                                  Text(
                                    description,
                                    style: TextStyle(
                                      color: onSurface.withOpacity(0.8),
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                  // Admin reply if present
                                  if (c['adminReply'] != null && c['adminReply'].toString().isNotEmpty) ...[
                                    const SizedBox(height: 12),
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
                                            children: [
                                              const Icon(Icons.admin_panel_settings, color: Colors.purple, size: 14),
                                              const SizedBox(width: 6),
                                              Text(
                                                langProvider.isBangla ? 'অ্যাডমিন প্রতিক্রিয়া' : 'Admin Response',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.purple,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            c['adminReply'].toString(),
                                            style: TextStyle(
                                              color: onSurface.withOpacity(0.8),
                                              fontSize: 12,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
