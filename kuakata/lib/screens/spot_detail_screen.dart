import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class SpotDetailScreen extends StatelessWidget {
  final Map<String, String> spot;

  const SpotDetailScreen({Key? key, required this.spot}) : super(key: key);

  // Hardcoded premium details for tourist attractions (localized)
  static final Map<String, Map<String, Map<String, String>>> _detailedInfo = {
    'Kuakata Sea Beach': {
      'en': {
        'about': 'Kuakata Beach is a panoramic sandy beach situated in southern Bangladesh. It is one of the rarest beaches in the world that allows visitors to witness both the sunrise and sunset over the Bay of Bengal. The beach is approximately 18 kilometers long and 3 kilometers wide. It is a holy site for both Hindu and Buddhist communities, who come here during festivals like Rash Purnima.',
        'tips': '• Best time for Sunrise is 5:00 AM - 6:00 AM.\n• Avoid littering on the beach to preserve its natural beauty.\n• Beach photography is widely available by local photographers.',
        'location': 'Kuakata, Patuakhali, Bangladesh',
        'timings': 'Open 24 Hours',
        'transport': 'Walking distance from the center, or local rickshaw.',
      },
      'bn': {
        'about': 'কুয়াকাটা সমুদ্র সৈকত বাংলাদেশের দক্ষিণ-পশ্চিমাঞ্চলের একটি অপরূপ বালুময় সৈকত। এটি বিশ্বের অন্যতম বিরল সৈকত যা দর্শনার্থীদের বঙ্গোপসাগরের ওপর একই সাথে সূর্যোদয় এবং সূর্যাস্ত দেখার সুযোগ দেয়। এই সৈকতটি দৈর্ঘ্য প্রায় ১৮ কিলোমিটার এবং প্রস্থে ৩ কিলোমিটার। এটি হিন্দু ও বৌদ্ধ সম্প্রদায়ের জন্য একটি পবিত্র স্থান, যা রাস পূর্ণিমার মতো উত্সবের সময় মুখরিত হয়ে ওঠে।',
        'tips': '• সূর্যোদয়ের সবচেয়ে ভালো সময় হলো ভোর ৫:০০ টা থেকে ৬:০০ টা।\n• সৈকতের প্রাকৃতিক সৌন্দর্য রক্ষা করতে ময়লা-আবর্জনা ফেলা থেকে বিরত থাকুন।\n• স্থানীয় ফটোগ্রাফারদের মাধ্যমে ছবি তোলার সুবিধা রয়েছে।',
        'location': 'কুয়াকাটা, পটুয়াখালী, বাংলাদেশ',
        'timings': '২৪ ঘণ্টা খোলা',
        'transport': 'কেন্দ্রীয় মোড় থেকে হাঁটার দূরত্ব, অথবা ভ্যানে যাওয়া যায়।',
      }
    },
    'কুয়াকাটা সমুদ্র সৈকত': {
      'en': {
        'about': 'Kuakata Beach is a panoramic sandy beach situated in southern Bangladesh. It is one of the rarest beaches in the world that allows visitors to witness both the sunrise and sunset over the Bay of Bengal. The beach is approximately 18 kilometers long and 3 kilometers wide. It is a holy site for both Hindu and Buddhist communities, who come here during festivals like Rash Purnima.',
        'tips': '• Best time for Sunrise is 5:00 AM - 6:00 AM.\n• Avoid littering on the beach to preserve its natural beauty.\n• Beach photography is widely available by local photographers.',
        'location': 'Kuakata, Patuakhali, Bangladesh',
        'timings': 'Open 24 Hours',
        'transport': 'Walking distance from the center, or local rickshaw.',
      },
      'bn': {
        'about': 'কুয়াকাটা সমুদ্র সৈকত বাংলাদেশের দক্ষিণ-পশ্চিমাঞ্চলের একটি অপরূপ বালুময় সৈকত। এটি বিশ্বের অন্যতম বিরল সৈকত যা দর্শনার্থীদের বঙ্গোপসাগরের ওপর একই সাথে সূর্যোদয় এবং সূর্যাস্ত দেখার সুযোগ দেয়। এই সৈকতটি দৈর্ঘ্য প্রায় ১৮ কিলোমিটার এবং প্রস্থে ৩ কিলোমিটার। এটি হিন্দু ও বৌদ্ধ সম্প্রদায়ের জন্য একটি পবিত্র স্থান, যা রাস পূর্ণিমার মতো উত্সবের সময় মুখরিত হয়ে ওঠে।',
        'tips': '• সূর্যোদয়ের সবচেয়ে ভালো সময় হলো ভোর ৫:০০ টা থেকে ৬:০০ টা।\n• সৈকতের প্রাকৃতিক সৌন্দর্য রক্ষা করতে ময়লা-আবর্জনা ফেলা থেকে বিরত থাকুন।\n• স্থানীয় ফটোগ্রাফারদের মাধ্যমে ছবি তোলার সুবিধা রয়েছে।',
        'location': 'কুয়াকাটা, পটুয়াখালী, বাংলাদেশ',
        'timings': '২৪ ঘণ্টা খোলা',
        'transport': 'কেন্দ্রীয় মোড় থেকে হাঁটার দূরত্ব, অথবা ভ্যানে যাওয়া যায়।',
      }
    },
    'Gangamati Forest': {
      'en': {
        'about': 'Gangamati Protected Forest is located on the eastern side of the Kuakata beach. It is a dense mangrove forest that acts as a natural shield for the coastline. Visitors can reach here by walking or taking a motorcycle from the main beach. It is an excellent spot for bird watching, exploring local flora and fauna, and witnessing a pristine sunrise.',
        'tips': '• Ride a local motorcycle for a convenient and fast trip.\n• Visit early in the morning to catch the spectacular sunrise.\n• Carry drinking water and light snacks with you.',
        'location': '10 km East from Kuakata Main Beach',
        'timings': '6:00 AM - 6:00 PM',
        'transport': 'Motorcycle rental, speedboat, or local tourist engine boat.',
      },
      'bn': {
        'about': 'গঙ্গামতি সংরক্ষিত বন কুয়াকাটা সৈকতের পূর্ব দিকে অবস্থিত। এটি একটি ঘন ম্যানগ্রোভ বন যা উপকূলের জন্য প্রাকৃতিক ঢাল হিসেবে কাজ করে। দর্শনার্থীরা হেঁটে বা প্রধান সৈকত থেকে মোটরসাইকেলে এখানে পৌঁছাতে পারেন। এটি পাখি দেখার, স্থানীয় উদ্ভিদ ও প্রাণী অন্বেষণ করার এবং আদিম সূর্যোদয় উপভোগ করার জন্য একটি চমৎকার স্থান।',
        'tips': '• সুবিধাজনক ও দ্রুত যাতায়াতের জন্য স্থানীয় মোটরসাইকেল ব্যবহার করুন।\n• চমৎকার সূর্যোদয় দেখতে খুব ভোরে চলে যান।\n• সাথে খাবার পানি এবং হালকা খাবার রাখুন।',
        'location': 'কুয়াকাটা মূল সৈকত থেকে ১০ কিমি পূর্বে',
        'timings': 'সকাল ৬:০০ টা - সন্ধ্যা ৬:০০ টা',
        'transport': 'মোটরসাইকেল, স্পিডবোট অথবা ট্যুরিস্ট ট্রলার।',
      }
    },
    'গঙ্গামতির জঙ্গল': {
      'en': {
        'about': 'Gangamati Protected Forest is located on the eastern side of the Kuakata beach. It is a dense mangrove forest that acts as a natural shield for the coastline. Visitors can reach here by walking or taking a motorcycle from the main beach. It is an excellent spot for bird watching, exploring local flora and fauna, and witnessing a pristine sunrise.',
        'tips': '• Ride a local motorcycle for a convenient and fast trip.\n• Visit early in the morning to catch the spectacular sunrise.\n• Carry drinking water and light snacks with you.',
        'location': '10 km East from Kuakata Main Beach',
        'timings': '6:00 AM - 6:00 PM',
        'transport': 'Motorcycle rental, speedboat, or local tourist engine boat.',
      },
      'bn': {
        'about': 'গঙ্গামতি সংরক্ষিত বন কুয়াকাটা সৈকতের পূর্ব দিকে অবস্থিত। এটি একটি ঘন ম্যানগ্রোভ বন যা উপকূলের জন্য প্রাকৃতিক ঢাল হিসেবে কাজ করে। দর্শনার্থীরা হেঁটে বা প্রধান সৈকত থেকে মোটরসাইকেলে এখানে পৌঁছাতে পারেন। এটি পাখি দেখার, স্থানীয় উদ্ভিদ ও প্রাণী অন্বেষণ করার এবং আদিম সূর্যোদয় উপভোগ করার জন্য একটি চমৎকার স্থান।',
        'tips': '• সুবিধাজনক ও দ্রুত যাতায়াতের জন্য স্থানীয় মোটরসাইকেল ব্যবহার করুন।\n• চমৎকার সূর্যোদয় দেখতে খুব ভোরে চলে যান।\n• সাথে খাবার পানি এবং হালকা খাবার রাখুন।',
        'location': 'কুয়াকাটা মূল সৈকত থেকে ১০ কিমি পূর্বে',
        'timings': 'সকাল ৬:০০ টা - সন্ধ্যা ৬:০০ টা',
        'transport': 'মোটরসাইকেল, স্পিডবোট অথবা ট্যুরিস্ট ট্রলার।',
      }
    },
    'Jhau Forest': {
      'en': {
        'about': 'Jhau Forest (Casuarina Forest) is located near the beach on the eastern side. It was created by the forest department to prevent soil erosion. The forest provides a cool, shady canopy with the soothing sound of wind passing through the trees. It is a very popular spot for photography, walking, and family picnics.',
        'tips': '• Great spot for photography during late afternoon.\n• Walking through the pine-like trees is highly refreshing.\n• Respect nature and do not disturb the local wildlife.',
        'location': 'Eastern side of Kuakata Beach',
        'timings': 'Sunrise to Sunset',
        'transport': 'Walking distance, or local van/rickshaw.',
      },
      'bn': {
        'about': 'ঝাউবন (ঝাউগাছের বন) পূর্ব দিকের সৈকতের কাছে অবস্থিত। মাটির ক্ষয় রোধে বন বিভাগ এটি তৈরি করে। বনটি গাছের মধ্য দিয়ে বাতাস বয়ে যাওয়ার মৃদু শব্দের সাথে একটি শীতল, ছায়াময় পরিবেশ তৈরি করে। এটি ছবি তোলা, হাঁটাচলা এবং পারিবারিক পিকনিকের জন্য একটি অত্যন্ত জনপ্রিয় স্থান।',
        'tips': '• শেষ বিকেলে ছবি তোলার জন্য এটি চমৎকার একটি স্থান।\n• ঝাউগাছের মধ্য দিয়ে হাঁটা অত্যন্ত সতেজ অনুভূতি দেয়।\n• প্রকৃতির প্রতি যত্নশীল হোন এবং বন্যপ্রাণীদের বিরক্ত করবেন না।',
        'location': 'কুয়াকাটা সৈকতের পূর্ব প্রান্ত',
        'timings': 'সূর্যোদয় থেকে সূর্যাস্ত',
        'transport': 'সহজেই হেঁটে অথবা ভ্যানে যাওয়া যায়।',
      }
    },
    'ঝাউবন': {
      'en': {
        'about': 'Jhau Forest (Casuarina Forest) is located near the beach on the eastern side. It was created by the forest department to prevent soil erosion. The forest provides a cool, shady canopy with the soothing sound of wind passing through the trees. It is a very popular spot for photography, walking, and family picnics.',
        'tips': '• Great spot for photography during late afternoon.\n• Walking through the pine-like trees is highly refreshing.\n• Respect nature and do not disturb the local wildlife.',
        'location': 'Eastern side of Kuakata Beach',
        'timings': 'Sunrise to Sunset',
        'transport': 'Walking distance, or local van/rickshaw.',
      },
      'bn': {
        'about': 'ঝাউবন (ঝাউগাছের বন) পূর্ব দিকের সৈকতের কাছে অবস্থিত। মাটির ক্ষয় রোধে বন বিভাগ এটি তৈরি করে। বনটি গাছের মধ্য দিয়ে বাতাস বয়ে যাওয়ার মৃদু শব্দের সাথে একটি শীতল, ছায়াময় পরিবেশ তৈরি করে। এটি ছবি তোলা, হাঁটাচলা এবং পারিবারিক পিকনিকের জন্য একটি অত্যন্ত জনপ্রিয় স্থান।',
        'tips': '• শেষ বিকেলে ছবি তোলার জন্য এটি চমৎকার একটি স্থান।\n• ঝাউগাছের মধ্য দিয়ে হাঁটা অত্যন্ত সতেজ অনুভূতি দেয়।\n• প্রকৃতির প্রতি যত্নশীল হোন এবং বন্যপ্রাণীদের বিরক্ত করবেন না।',
        'location': 'কুয়াকাটা সৈকতের পূর্ব প্রান্ত',
        'timings': 'সূর্যোদয় থেকে সূর্যাস্ত',
        'transport': 'সহজেই হেঁটে অথবা ভ্যানে যাওয়া যায়।',
      }
    },
    'Red Crab Beach': {
      'en': {
        'about': 'Red Crab Beach (Lal Kakrar Char) is a magical sanctuary situated near the Jhau forest. During low tide, millions of tiny red crabs emerge from their sand holes, coloring the entire beach in a vibrant crimson red. As soon as they sense footsteps, they quickly vanish back into the sand, creating a captivating spectacle.',
        'tips': '• Walk quietly and avoid making loud noises to see the crabs up close.\n• Keep a distance and do not capture or step on the crabs.\n• Check the local tide table before planning your trip.',
        'location': 'Near Jhau Forest, Patuakhali',
        'timings': 'Best viewed during low tide',
        'transport': 'Local motor-bike or boat ride.',
      },
      'bn': {
        'about': 'লাল কাঁকড়ার চর হলো ঝাউবনের কাছে অবস্থিত একটি জাদুকরী অভয়ারণ্য। জোয়ারের পর যখন পানি নেমে যায়, তখন লাখ লাখ ছোট লাল কাঁকড়া তাদের বালির গর্ত থেকে বের হয়ে আসে এবং পুরো সৈকতকে লাল গালিচায় রূপান্তর করে। মানুষের পায়ের শব্দ পাওয়া মাত্রই তারা বালির নিচে লুকিয়ে যায়, যা একটি চমৎকার দৃশ্য তৈরি করে।',
        'tips': '• কাঁকড়াগুলোকে কাছ থেকে দেখতে শান্তভাবে হাঁটুন এবং জোরে শব্দ করা এড়িয়ে চলুন।\n• দূরত্ব বজায় রাখুন এবং কাঁকড়া ধরার বা তাদের উপর পা দেওয়ার চেষ্টা করবেন না।\n• ভ্রমণের পরিকল্পনা করার আগে স্থানীয় জোয়ার-ভাটার সময়সূচী দেখে নিন।',
        'location': 'ঝাউবনের নিকটে, কুয়াকাটা',
        'timings': 'ভাটার সময় সবচেয়ে ভালো দেখা যায়',
        'transport': 'মোটরসাইকেল অথবা নৌকা চালকদের মাধ্যমে যাওয়া যায়।',
      }
    },
    'লাল কাঁকড়ার চর': {
      'en': {
        'about': 'Red Crab Beach (Lal Kakrar Char) is a magical sanctuary situated near the Jhau forest. During low tide, millions of tiny red crabs emerge from their sand holes, coloring the entire beach in a vibrant crimson red. As soon as they sense footsteps, they quickly vanish back into the sand, creating a captivating spectacle.',
        'tips': '• Walk quietly and avoid making loud noises to see the crabs up close.\n• Keep a distance and do not capture or step on the crabs.\n• Check the local tide table before planning your trip.',
        'location': 'Near Jhau Forest, Patuakhali',
        'timings': 'Best viewed during low tide',
        'transport': 'Local motor-bike or boat ride.',
      },
      'bn': {
        'about': 'লাল কাঁকড়ার চর হলো ঝাউবনের কাছে অবস্থিত একটি জাদুকরী অভয়ারণ্য। জোয়ারের পর যখন পানি নেমে যায়, তখন লাখ লাখ ছোট লাল কাঁকড়া তাদের বালির গর্ত থেকে বের হয়ে আসে এবং পুরো সৈকতকে লাল গালিচায় রূপান্তর করে। মানুষের পায়ের শব্দ পাওয়া মাত্রই তারা বালির নিচে লুকিয়ে যায়, যা একটি চমৎকার দৃশ্য তৈরি করে।',
        'tips': '• কাঁকড়াগুলোকে কাছ থেকে দেখতে শান্তভাবে হাঁটুন এবং জোরে শব্দ করা এড়িয়ে চলুন।\n• দূরত্ব বজায় রাখুন এবং কাঁকড়া ধরার বা তাদের উপর পা দেওয়ার চেষ্টা করবেন না।\n• ভ্রমণের পরিকল্পনা করার আগে স্থানীয় জোয়ার-ভাটার সময়সূচী দেখে নিন।',
        'location': 'ঝাউবনের নিকটে, কুয়াকাটা',
        'timings': 'ভাটার সময় সবচেয়ে ভালো দেখা যায়',
        'transport': 'মোটরসাইকেল অথবা নৌকা চালকদের মাধ্যমে যাওয়া যায়।',
      }
    },
    'Misripara Temple': {
      'en': {
        'about': 'Misripara Buddhist Temple is located about 12 kilometers from Kuakata beach. It houses the largest Buddhist statue in the sub-continent, standing at approximately 30 feet tall. The temple reflects the rich cultural heritage and historical presence of the Rakhaine community in this region. There is also an ancient well inside the temple premises.',
        'tips': '• Wear modest clothing and remove shoes before entering the temple.\n• Respect the religious practices of the devotees.\n• You can buy traditional Rakhaine handloom products nearby.',
        'location': 'Misripara Rakhaine Village, Patuakhali',
        'timings': '8:00 AM - 6:00 PM',
        'transport': 'Motorcycle or local auto-rickshaw (Tomtom).',
      },
      'bn': {
        'about': 'মিশ্রিপাড়া বৌদ্ধ মন্দির কুয়াকাটা সৈকত থেকে প্রায় ১২ কিলোমিটার দূরে অবস্থিত। এতে উপমহাদেশে সবচেয়ে বড় বুদ্ধ মূর্তি রয়েছে, যা প্রায় ৩০ ফুট উঁচু। মন্দিরটি এই অঞ্চলে রাখাইন সম্প্রদায়ের সমৃদ্ধ সাংস্কৃতিক ঐতিহ্য এবং ঐতিহাসিক উপস্থিতি প্রতিফলিত করে। মন্দির প্রাঙ্গণে একটি প্রাচীন কূপও রয়েছে।',
        'tips': '• শালীন পোশাক পরিধান করুন এবং মন্দিরে প্রবেশের আগে জুতো খুলে নিন।\n• ভক্তদের ধর্মীয় আচার-অনুষ্ঠানের প্রতি শ্রদ্ধা প্রদর্শন করুন।\n• কাছেই ঐতিহ্যবাহী রাখাইন হস্তশিল্পের তৈরি পণ্য কেনাকাটা করতে পারেন।',
        'location': 'মিশ্রিপাড়া রাখাইন পল্লী, কুয়াকাটা',
        'timings': 'সকাল ৮:০০ টা - সন্ধ্যা ৬:০০ টা',
        'transport': 'মোটরসাইকেল বা ইজি-বাইক (টমটম) দিয়ে যাওয়া যায়।',
      }
    },
    'মিশ্রিপাড়া মন্দির': {
      'en': {
        'about': 'Misripara Buddhist Temple is located about 12 kilometers from Kuakata beach. It houses the largest Buddhist statue in the sub-continent, standing at approximately 30 feet tall. The temple reflects the rich cultural heritage and historical presence of the Rakhaine community in this region. There is also an ancient well inside the temple premises.',
        'tips': '• Wear modest clothing and remove shoes before entering the temple.\n• Respect the religious practices of the devotees.\n• You can buy traditional Rakhaine handloom products nearby.',
        'location': 'Misripara Rakhaine Village, Patuakhali',
        'timings': '8:00 AM - 6:00 PM',
        'transport': 'Motorcycle or local auto-rickshaw (Tomtom).',
      },
      'bn': {
        'about': 'মিশ্রিপাড়া বৌদ্ধ মন্দির কুয়াকাটা সৈকত থেকে প্রায় ১২ কিলোমিটার দূরে অবস্থিত। এতে উপমহাদেশে সবচেয়ে বড় বুদ্ধ মূর্তি রয়েছে, যা প্রায় ৩০ ফুট উঁচু। মন্দিরটি এই অঞ্চলে রাখাইন সম্প্রদায়ের সমৃদ্ধ সাংস্কৃতিক ঐতিহ্য এবং ঐতিহাসিক উপস্থিতি প্রতিফলিত করে। মন্দির প্রাঙ্গণে একটি প্রাচীন কূপও রয়েছে।',
        'tips': '• শালীন পোশাক পরিধান করুন এবং মন্দিরে প্রবেশের আগে জুতো খুলে নিন।\n• ভক্তদের ধর্মীয় আচার-অনুষ্ঠানের প্রতি শ্রদ্ধা প্রদর্শন করুন।\n• কাছেই ঐতিহ্যবাহী রাখাইন হস্তশিল্পের তৈরি পণ্য কেনাকাটা করতে পারেন।',
        'location': 'মিশ্রিপাড়া রাখাইন পল্লী, কুয়াকাটা',
        'timings': 'সকাল ৮:০০ টা - সন্ধ্যা ৬:০০ টা',
        'transport': 'মোটরসাইকেল বা ইজি-বাইক (টমটম) দিয়ে যাওয়া যায়।',
      }
    }
  };

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final isBn = langProvider.isBangla;
    final localeCode = isBn ? 'bn' : 'en';
    final onSurface = Theme.of(context).colorScheme.onSurface;

    // Retrieve details for this spot
    final spotTitle = spot['title'] ?? '';

    // Check if dynamic fields exist (pre-mapped from backend ContentItem)
    final String dynamicAbout = (isBn ? spot['about_bn'] : spot['about_en']) ?? '';
    final String dynamicTips = (isBn ? spot['tips_bn'] : spot['tips_en']) ?? '';
    final String dynamicLocation = (isBn ? spot['location_bn'] : spot['location_en']) ?? '';
    final String dynamicTimings = (isBn ? spot['timings_bn'] : spot['timings_en']) ?? '';
    final String dynamicTransport = (isBn ? spot['transport_bn'] : spot['transport_en']) ?? '';

    final Map<String, String> detailsMap = (dynamicAbout.isNotEmpty)
        ? {
            'about': dynamicAbout,
            'tips': dynamicTips.isNotEmpty ? dynamicTips : (isBn ? '• প্রকৃতির নিয়মাবলী মেনে চলুন।' : '• Follow local safety guidelines.'),
            'location': dynamicLocation.isNotEmpty ? dynamicLocation : (isBn ? 'কুয়াকাটা, বাংলাদেশ' : 'Kuakata, Bangladesh'),
            'timings': dynamicTimings.isNotEmpty ? dynamicTimings : (isBn ? 'সারাদিন' : 'Always open'),
            'transport': dynamicTransport.isNotEmpty ? dynamicTransport : (isBn ? 'ভ্যান অথবা বাইক' : 'Local transport'),
          }
        : (_detailedInfo[spotTitle]?[localeCode] ?? {
            'about': spot['desc'] ?? '',
            'tips': isBn ? '• প্রকৃতির নিয়মাবলী মেনে চলুন।' : '• Follow local safety guidelines.',
            'location': isBn ? 'কুয়াকাটা, বাংলাদেশ' : 'Kuakata, Bangladesh',
            'timings': isBn ? 'সারাদিন' : 'Always open',
            'transport': isBn ? 'ভ্যান অথবা বাইক' : 'Local transport',
          });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Collapsible Image Header
          SliverAppBar(
            expandedHeight: 280.0,
            pinned: true,
            backgroundColor: Theme.of(context).cardColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                spotTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 2),
                      blurRadius: 4,
                      color: Colors.black,
                    ),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    spot['image'] ?? '',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(color: Theme.of(context).cardColor),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Details Body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Info Badges Row
                  Row(
                    children: [
                      _buildInfoBadge(
                        context,
                        icon: Icons.access_time_rounded,
                        text: detailsMap['timings']!,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoBadge(
                          context,
                          icon: Icons.location_on_rounded,
                          text: detailsMap['location']!,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // About Section
                  Text(
                    isBn ? 'দর্শনীয় স্থানটি সম্পর্কে' : 'About the Attraction',
                    style: TextStyle(
                      color: onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    detailsMap['about']!,
                    style: TextStyle(
                      color: onSurface.withOpacity(0.7),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Transportation Guide Section
                  Card(
                    color: Theme.of(context).cardColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.directions_bus_rounded, color: Color(0xFF00B4DB), size: 20),
                              const SizedBox(width: 10),
                              Text(
                                isBn ? 'কিভাবে যাবেন / যাতায়াত' : 'How to Go / Transport',
                                style: TextStyle(
                                  color: onSurface,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Divider(color: Theme.of(context).dividerColor, height: 20),
                          Text(
                            detailsMap['transport']!,
                            style: TextStyle(
                              color: onSurface.withOpacity(0.8),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Travel Tips Section
                  Card(
                    color: Theme.of(context).cardColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.tips_and_updates_rounded, color: Colors.amber, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                isBn ? 'ভ্রমণ টিপস ও সতর্কতা' : 'Travel Tips & Info',
                                style: TextStyle(
                                  color: onSurface,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Divider(color: Theme.of(context).dividerColor, height: 20),
                          Text(
                            detailsMap['tips']!,
                            style: TextStyle(
                              color: onSurface.withOpacity(0.8),
                              fontSize: 13,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBadge(BuildContext context, {required IconData icon, required String text}) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF00B4DB), size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
