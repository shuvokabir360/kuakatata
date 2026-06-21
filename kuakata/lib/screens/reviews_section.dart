import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class ReviewsSection extends StatefulWidget {
  final String itemId;
  final String itemType;

  const ReviewsSection({
    Key? key,
    required this.itemId,
    required this.itemType,
  }) : super(key: key);

  @override
  State<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<ReviewsSection> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _reviews = [];
  double _avgRating = 0.0;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final list = await ApiService.fetchReviews(widget.itemType, widget.itemId);
    
    double total = 0;
    for (var r in list) {
      total += (r['rating'] as num).toDouble();
    }
    
    if (!mounted) return;
    setState(() {
      _reviews = list;
      _avgRating = list.isNotEmpty ? (total / list.length) : 0.0;
      _isLoading = false;
    });
  }

  void _showAddReviewDialog() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);

    if (!userProvider.isLoggedIn) {
      _showLoginRequiredDialog();
      return;
    }

    int selectedRating = 5;
    final commentController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        final onSurface = Theme.of(context).colorScheme.onSurface;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(langProvider.translate('write_review')),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Rating Selector (Stars)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starValue = index + 1;
                        return IconButton(
                          icon: Icon(
                            Icons.star_rounded,
                            color: starValue <= selectedRating ? Colors.amber : onSurface.withOpacity(0.2),
                            size: 36,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              selectedRating = starValue;
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    // Comment input
                    TextFormField(
                      controller: commentController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: langProvider.translate('comment'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(langProvider.translate('close')),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    final success = await ApiService.submitReview({
                      'itemId': widget.itemId,
                      'itemType': widget.itemType,
                      'userName': userProvider.name,
                      'rating': selectedRating,
                      'comment': commentController.text.trim(),
                    });

                    if (success) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(langProvider.translate('review_success')),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.pop(context);
                        _loadReviews();
                      }
                    }
                  },
                  child: Text(langProvider.translate('save')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showLoginRequiredDialog() {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(langProvider.translate('login_required')),
          content: Text(langProvider.translate('login_required_desc')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(langProvider.translate('close')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                ).then((value) {
                  if (value == true) {
                    _showAddReviewDialog();
                  }
                });
              },
              child: Text(langProvider.translate('login')),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    langProvider.translate('public_reviews'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        _reviews.isEmpty ? '0.0' : _avgRating.toStringAsFixed(1),
                        style: TextStyle(
                          color: onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${_reviews.length} ${langProvider.isBangla ? 'রিভিউ' : 'reviews'})',
                        style: TextStyle(
                          color: onSurface.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: _showAddReviewDialog,
              icon: const Icon(Icons.rate_review_outlined, size: 16, color: Color(0xFF00B4DB)),
              label: Text(
                langProvider.translate('write_review'),
                style: const TextStyle(color: Color(0xFF00B4DB), fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Reviews list
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _reviews.isEmpty
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    alignment: Alignment.center,
                    child: Text(
                      langProvider.isBangla ? 'কোনো রিভিউ পাওয়া যায়নি।' : 'No reviews posted yet.',
                      style: TextStyle(color: onSurface.withOpacity(0.4), fontSize: 13),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _reviews.length,
                    itemBuilder: (context, index) {
                      final r = _reviews[index];
                      final reviewerName = r['userName'] ?? 'Anonymous';
                      final comment = r['comment'] ?? '';
                      final rating = (r['rating'] as num?)?.toInt() ?? 5;
                      final dateStr = r['createdAt'] ?? '';
                      
                      String formattedDate = '';
                      if (dateStr.isNotEmpty) {
                        try {
                          final date = DateTime.parse(dateStr);
                          formattedDate = '${date.day}/${date.month}/${date.year}';
                        } catch (e) {
                          formattedDate = dateStr;
                        }
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  reviewerName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: onSurface,
                                  ),
                                ),
                                Text(
                                  formattedDate,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: onSurface.withOpacity(0.4),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: List.generate(5, (starIdx) {
                                return Icon(
                                  Icons.star_rounded,
                                  color: starIdx < rating ? Colors.amber : onSurface.withOpacity(0.12),
                                  size: 14,
                                );
                              }),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              comment,
                              style: TextStyle(
                                color: onSurface.withOpacity(0.8),
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                            if (r['adminReply'] != null && r['adminReply'].toString().isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(8),
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
                                    const SizedBox(height: 4),
                                    Text(
                                      r['adminReply'].toString(),
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
                      );
                    },
                  ),
      ],
    );
  }
}
