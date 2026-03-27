// ==================== PONTO DE ENTRADA DO APLICATIVO ====================
// Inicializa o ProviderScope do Riverpod e configura o tema verde escuro.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/home_screen.dart';

/// Ponto de entrada do aplicativo de análise de renda fixa.
void main() {
  runApp(
    // ProviderScope é obrigatório para o Riverpod funcionar
    const ProviderScope(child: AppRendaFixa()),
  );
}

/// Widget raiz do aplicativo com configuração de tema verde escuro.
class AppRendaFixa extends StatelessWidget {
  const AppRendaFixa({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Renda Fixa',
      debugShowCheckedModeBanner: false,

      // ==================== TEMA VERDE ESCURO ====================
      theme: _temaPadrao(),
      darkTheme: _temaEscuroVerde(),

      // Usa o tema escuro como padrão
      themeMode: ThemeMode.dark,

      home: const HomeScreen(),
    );
  }

  /// Tema claro (fallback)
  ThemeData _temaPadrao() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2E7D32),
        brightness: Brightness.light,
      ),
    );
  }

  /// Tema escuro com verde floresta como cor semente.
  /// O Material 3 gera automaticamente a paleta de cores harmônicas.
  ThemeData _temaEscuroVerde() {
    const corSemente = Color(0xFF1B5E20); // verde floresta profundo

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: corSemente,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      cardTheme: const CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }
}
