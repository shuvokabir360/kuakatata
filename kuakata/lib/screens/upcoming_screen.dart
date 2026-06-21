import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class UpcomingScreen extends StatelessWidget {
  final String title;

  const UpcomingScreen({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);

    final String heading = langProvider.isBangla ? 'শীঘ্রই আসছে!' : 'Coming Soon!';
    final String description = langProvider.isBangla
        ? 'লঞ্চ এবং জাহাজ বুকিং সেবাটি আমাদের পরবর্তী আপডেটে উপলব্ধ হবে। আমরা এটি নিয়ে কাজ করছি!'
        : 'Launch and Ship booking services will be available in the upcoming version. We are working hard to bring it to you!';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: Theme.of(context).appBarTheme.elevation,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).cardColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 3),
                
                // Glowing Boat/Ship Icon
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00B4DB).withOpacity(0.08),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00B4DB).withOpacity(0.15),
                          blurRadius: 40,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.sailing_rounded,
                      size: 96,
                      color: Color(0xFF00B4DB),
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                
                // Title
                Text(
                  heading,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: langProvider.isBangla ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Description text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      height: 1.5,
                    ),
                  ),
                ),
                
                const Spacer(flex: 3),
                
                // Back to home button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).cardColor,
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                    side: BorderSide(color: Theme.of(context).dividerColor),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    langProvider.isBangla ? 'হোমে ফিরে যান' : 'Back to Home',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
