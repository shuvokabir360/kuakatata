import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/language_provider.dart';

class HelplineScreen extends StatelessWidget {
  const HelplineScreen({Key? key}) : super(key: key);

  Future<void> _makeCall(String phoneNumber, BuildContext context) async {
    final Uri url = Uri.parse('tel:$phoneNumber');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot place call automatically. Dial manually: $phoneNumber'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    final List<Map<String, String>> helplines = [
      {
        'title_en': 'Tourist Police Kuakata',
        'title_bn': 'ট্যুরিস্ট পুলিশ কুয়াকাটা',
        'subtitle': 'Dedicated tourist assistance and security',
        'subtitle_bn': 'পর্যটকদের নিরাপত্তা ও সহায়তার জন্য নিবেদিত',
        'phone': '01320159090',
        'icon': 'security',
        'color': '0xFF00C9FF',
      },
      {
        'title_en': 'Kuakata Ambulance Service',
        'title_bn': 'কুয়াকাটা অ্যাম্বুলেন্স সার্ভিস',
        'subtitle': '24/7 Medical emergency transit',
        'subtitle_bn': '২৪/৭ জরুরী চিকিৎসা সেবা',
        'phone': '01712345678',
        'icon': 'local_hospital',
        'color': '0xFFFF2E93',
      },
      {
        'title_en': 'National Emergency Helpline',
        'title_bn': 'জাতীয় জরুরী সেবা (৯৯৯)',
        'subtitle': 'Free call for Police, Fire, Ambulance',
        'subtitle_bn': 'পুলিশ, ফায়ার সার্ভিস ও অ্যাম্বুলেন্সের জন্য ফ্রি কল',
        'phone': '999',
        'icon': 'emergency',
        'color': '0xFFFF8C00',
      },
      {
        'title_en': 'Kuakata Police Station',
        'title_bn': 'মহিপুর থানা (কুয়াকাটা)',
        'subtitle': 'Local police jurisdiction support',
        'subtitle_bn': 'স্থানীয় আইন-শৃঙ্খলা রক্ষা ও সহায়তা',
        'phone': '01713374245',
        'icon': 'shield',
        'color': '0xFF3F51B5',
      },
      {
        'title_en': 'Kalapara Fire Service',
        'title_bn': 'কলাপাড়া ফায়ার সার্ভিস',
        'subtitle': 'Fire fighting and rescue operations',
        'subtitle_bn': 'অগ্নিনির্বাপণ ও উদ্ধার কাজের জন্য',
        'phone': '01711123456',
        'icon': 'fire_extinguisher',
        'color': '0xFFE94560',
      },
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(langProvider.translate('emergency')),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: Theme.of(context).appBarTheme.elevation,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instruction Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFF00C9FF), size: 28),
                  const SizedBox(height: 8),
                  Text(
                    langProvider.translate('helpline_desc'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: onSurface.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Contact list
            Expanded(
              child: ListView.builder(
                itemCount: helplines.length,
                itemBuilder: (context, index) {
                  final contact = helplines[index];
                  final title = langProvider.locale == 'en' ? contact['title_en'] : contact['title_bn'];
                  final subtitle = langProvider.locale == 'en' ? contact['subtitle'] : contact['subtitle_bn'];
                  final iconColor = Color(int.parse(contact['color']!));
                  
                  // Pick correct IconData
                  IconData iconData = Icons.phone_in_talk_rounded;
                  if (contact['icon'] == 'security') iconData = Icons.security_rounded;
                  if (contact['icon'] == 'local_hospital') iconData = Icons.local_hospital_rounded;
                  if (contact['icon'] == 'emergency') iconData = Icons.warning_amber_rounded;
                  if (contact['icon'] == 'shield') iconData = Icons.shield_rounded;
                  if (contact['icon'] == 'fire_extinguisher') iconData = Icons.fire_extinguisher_rounded;

                  return Card(
                    color: Theme.of(context).cardColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: iconColor.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              iconData,
                              color: iconColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title!,
                                  style: TextStyle(
                                    color: onSurface,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  subtitle!,
                                  style: TextStyle(
                                    color: onSurface.withOpacity(0.5),
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  contact['phone']!,
                                  style: const TextStyle(
                                    color: Color(0xFF00C9FF),
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: iconColor.withOpacity(0.15),
                              foregroundColor: iconColor,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onPressed: () => _makeCall(contact['phone']!, context),
                            icon: const Icon(Icons.call, size: 14),
                            label: Text(
                              langProvider.translate('call'),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
