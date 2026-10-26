import 'package:flutter/material.dart';

class AppColors {
  // Identidade principal
  static const Color primary = Color(0xFFD6A84F);
  static const Color primaryLight = Color(0xFFF0C978);
  static const Color primaryDark = Color(0xFFA87928);

  // Azul da viagem
  static const Color navy = Color(0xFF071522);
  static const Color navyLight = Color(0xFF102638);
  static const Color blue = Color(0xFF3B82F6);
  static const Color cyan = Color(0xFF38BDF8);

  // Fundos
  static const Color background = Color(0xFF050B12);
  static const Color surface = Color(0xFF0C1722);
  static const Color surfaceElevated = Color(0xFF122231);
  static const Color surfaceLight = Color(0xFF182B3A);

  // Texto
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF9AA9B8);
  static const Color textMuted = Color(0xFF667789);

  // Estados
  static const Color success = Color(0xFF4ADE80);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFF87171);

  // Bordas
  static const Color border = Color(0xFF203243);
  static const Color borderLight = Color(0xFF2B4154);

  // Gradientes
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF17344B),
      Color(0xFF0C1C2A),
      Color(0xFF07111A),
    ],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF0C978),
      Color(0xFFD6A84F),
      Color(0xFFA87928),
    ],
  );
}