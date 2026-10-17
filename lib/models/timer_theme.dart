import 'package:flutter/material.dart';

class TimerThemeData {
  final String id;
  final String name;
  final String description;
  final Color backgroundColor;
  final Color cardColor;
  final Color inkColor;
  final Color accentColor;
  final Color secondaryColor;
  final String? videoAssetPath;
  final String? thumbnailAssetPath;
  final List<Color> paletteColors;

  const TimerThemeData({
    required this.id,
    required this.name,
    required this.description,
    required this.backgroundColor,
    required this.cardColor,
    required this.inkColor,
    required this.accentColor,
    required this.secondaryColor,
    this.videoAssetPath,
    this.thumbnailAssetPath,
    required this.paletteColors,
  });

  bool get isLight => backgroundColor.computeLuminance() > 0.4;
  bool get hasVideo => videoAssetPath != null && videoAssetPath!.isNotEmpty;
}

const List<TimerThemeData> kTimerThemes = [
  // 1. Forest Spring Petals — DEFAULT (cedar, rust, coral amber)
  TimerThemeData(
    id: 'forest_petals',
    name: 'Spring Petals',
    description: 'Falling blossom petals amidst deep cedar and autumn hues',
    backgroundColor: Color(0xFF2E1314),
    cardColor: Color(0xFF471C1B),
    inkColor: Color(0xFFFFF7ED),
    accentColor: Color(0xFFF97316), // Coral Amber
    secondaryColor: Color(0xFFCB6F48),
    videoAssetPath: 'assets/gifs/forest_spring_petals.mp4',
    thumbnailAssetPath: 'assets/images/background_thumbs/forest_spring_petals_thumb.jpg',
    paletteColors: [
      Color(0xFF471C1B),
      Color(0xFF892B19),
      Color(0xFF5C5D77),
      Color(0xFFCB6F48),
    ],
  ),

  // 2. Studio Light (Crisp Modulix paper workspace)
  TimerThemeData(
    id: 'studio_light',
    name: 'Studio Light',
    description: 'Crisp paper workspace & medical brand purple',
    backgroundColor: Color(0xFFFCFBF8),
    cardColor: Color(0xFFFFFFFF),
    inkColor: Color(0xFF0F172A),
    accentColor: Color(0xFF6C3BAA),
    secondaryColor: Color(0xFF8B5CF6),
    videoAssetPath: null,
    thumbnailAssetPath: null,
    paletteColors: [
      Color(0xFFFCFBF8),
      Color(0xFF6C3BAA),
      Color(0xFF8B5CF6),
      Color(0xFF0F172A),
    ],
  ),

  // 3. Window Moon (Deep moonlight indigo / cyan)
  TimerThemeData(
    id: 'window_moon',
    name: 'Midnight Moon',
    description: 'Serene moonlit window with cool twilight glow',
    backgroundColor: Color(0xFF0A1926),
    cardColor: Color(0xFF102635),
    inkColor: Color(0xFFE0F2FE),
    accentColor: Color(0xFF38BDF8), // Electric Cyan
    secondaryColor: Color(0xFF567DA0),
    videoAssetPath: 'assets/gifs/window_moon.mp4',
    thumbnailAssetPath: 'assets/images/background_thumbs/window_moon_thumb.jpg',
    paletteColors: [
      Color(0xFF051215),
      Color(0xFF102635),
      Color(0xFF234461),
      Color(0xFF567DA0),
    ],
  ),

  // 4. Sunset Twilight (Warm terracotta & dusk violet)
  TimerThemeData(
    id: 'sunset',
    name: 'Golden Sunset',
    description: 'Warm twilight terracotta, dusk violet, and golden skies',
    backgroundColor: Color(0xFF2B1C26),
    cardColor: Color(0xFF382833),
    inkColor: Color(0xFFFFF1F2),
    accentColor: Color(0xFFFB7185), // Warm Rose
    secondaryColor: Color(0xFFBD8074),
    videoAssetPath: 'assets/gifs/sunset.mp4',
    thumbnailAssetPath: 'assets/images/background_thumbs/sunset_thumb.jpg',
    paletteColors: [
      Color(0xFF382833),
      Color(0xFF533B52),
      Color(0xFF6B4C69),
      Color(0xFFBD8074),
    ],
  ),

  // 5. Anime Guy Study (Vibrant matcha, lime & mint foliage)
  TimerThemeData(
    id: 'anime_guy',
    name: 'Matcha Study',
    description: 'Refreshing anime room with sunlit matcha & mint greenery',
    backgroundColor: Color(0xFF192A13),
    cardColor: Color(0xFF253D1C),
    inkColor: Color(0xFFF0FDF4),
    accentColor: Color(0xFF4ADE80), // Vivid Mint Green
    secondaryColor: Color(0xFFB3D780),
    videoAssetPath: 'assets/gifs/anime_guy.mp4',
    thumbnailAssetPath: 'assets/images/background_thumbs/anime_guy_thumb.jpg',
    paletteColors: [
      Color(0xFF74934D),
      Color(0xFFB3D780),
      Color(0xFFD2ECC8),
      Color(0xFFE1F2ED),
    ],
  ),

  // 6. Cat Desk Lo-Fi (Calm monochrome ash & silver desk)
  TimerThemeData(
    id: 'cat_desk',
    name: 'Cozy Cat Desk',
    description: 'Peaceful lo-fi study desk with sleeping feline companion',
    backgroundColor: Color(0xFF1E1E22),
    cardColor: Color(0xFF2C2C33),
    inkColor: Color(0xFFF4F4F6),
    accentColor: Color(0xFFA78BFA), // Pastel Violet
    secondaryColor: Color(0xFFA8A3A9),
    videoAssetPath: 'assets/gifs/cat_desk.mp4',
    thumbnailAssetPath: 'assets/images/background_thumbs/cat_desk_thumb.jpg',
    paletteColors: [
      Color(0xFF1E1E22),
      Color(0xFFA8A3A9),
      Color(0xFFCDCDCE),
      Color(0xFFE3E3E4),
    ],
  ),

  // 7. City Skyline (Dark urban noir & asphalt charcoal)
  TimerThemeData(
    id: 'city_skyline',
    name: 'Urban Night',
    description: 'Moody cityscape noir overlooking rain-slicked city streets',
    backgroundColor: Color(0xFF0D1013),
    cardColor: Color(0xFF1A1F24),
    inkColor: Color(0xFFF8FAFC),
    accentColor: Color(0xFF38BDF8), // Neon Blue
    secondaryColor: Color(0xFF6D6765),
    videoAssetPath: 'assets/gifs/city_background.mp4',
    thumbnailAssetPath: 'assets/images/background_thumbs/city_background_thumb.jpg',
    paletteColors: [
      Color(0xFF07090A),
      Color(0xFF101314),
      Color(0xFF24282A),
      Color(0xFF6D6765),
    ],
  ),
];
