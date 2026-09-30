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
  final String? gifUrl;
  final List<Color> gradientColors;

  const TimerThemeData({
    required this.id,
    required this.name,
    required this.description,
    required this.backgroundColor,
    required this.cardColor,
    required this.inkColor,
    required this.accentColor,
    required this.secondaryColor,
    this.gifUrl,
    required this.gradientColors,
  });
}

const List<TimerThemeData> kTimerThemes = [
  // 1. Warm Study Desk (Dark cozy ambiance, crisp ink, no white tint)
  TimerThemeData(
    id: 'paper',
    name: 'Warm Study Desk',
    description: 'Cozy dark study atmosphere with warm amber glow',
    backgroundColor: Color(0xFF141416),
    cardColor: Color(0xFF222226),
    inkColor: Color(0xFFF4F4F6),
    accentColor: Color(0xFF6366F1), // Indigo
    secondaryColor: Color(0xFFFBBF24), // Amber
    gifUrl: 'https://images.unsplash.com/photo-1518495973542-4542c06a5843?auto=format&fit=crop&w=1200&q=80',
    gradientColors: [Color(0xFF141416), Color(0xFF1E1E22)],
  ),

  // 2. Midnight Lo-Fi Room (Anime Lo-Fi study atmosphere)
  TimerThemeData(
    id: 'lofi',
    name: 'Midnight Lo-Fi',
    description: 'Deep indigo with cozy neon purple glow',
    backgroundColor: Color(0xFF0F172A),
    cardColor: Color(0xFF1E293B),
    inkColor: Color(0xFFF8FAFC),
    accentColor: Color(0xFFA855F7), // Neon Purple
    secondaryColor: Color(0xFF38BDF8), // Cyan
    gifUrl: 'https://media.giphy.com/media/3oKIPnAiaMCws8nOsE/giphy.gif',
    gradientColors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
  ),

  // 3. Rainy Tokyo Cafe (Cozy rainy cafe window)
  TimerThemeData(
    id: 'rainy_cafe',
    name: 'Rainy Cafe',
    description: 'Moody emerald green & warm amber candle glow',
    backgroundColor: Color(0xFF062828),
    cardColor: Color(0xFF0A3A3A),
    inkColor: Color(0xFFE2E8F0),
    accentColor: Color(0xFF34D399), // Emerald
    secondaryColor: Color(0xFFFBBF24), // Amber
    gifUrl: 'https://media.giphy.com/media/t7Qb8655Z1V9K/giphy.gif',
    gradientColors: [Color(0xFF062828), Color(0xFF0F172A)],
  ),

  // 4. Sunset Doctor\'s Library
  TimerThemeData(
    id: 'sunset_library',
    name: 'Golden Sunset',
    description: 'Warm twilight terracotta & gold bookstacks',
    backgroundColor: Color(0xFF2E1015),
    cardColor: Color(0xFF4C1D24),
    inkColor: Color(0xFFFFF1F2),
    accentColor: Color(0xFFFB7185), // Rose
    secondaryColor: Color(0xFFF59E0B), // Warm Gold
    gifUrl: 'https://media.giphy.com/media/l41lI4bYmcsPJX9Go/giphy.gif',
    gradientColors: [Color(0xFF2E1015), Color(0xFF3B0764)],
  ),
];
