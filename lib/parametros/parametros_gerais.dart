// ==================== PARÂMETROS GERAIS DO APLICATIVO ====================
// Este arquivo centraliza os parâmetros configuráveis do aplicativo,
// como limites do FGC, faixas de cores e outras configurações globais.

import 'package:flutter/material.dart';

/// Parâmetros gerais do aplicativo de análise de renda fixa.
/// Centraliza valores que podem ser ajustados conforme necessidade.
class ParametrosGerais {
  // ==================== LIMITE FGC ====================

  /// Valor máximo garantido pelo FGC por CPF por instituição (R$ 250.000,00).
  /// O FGC cobre CDB, LCI, LCA, LC e similares até esse valor.
  static const double limiteFgc = 250000.0;

  /// Teto global do FGC por CPF: R$ 1.000.000,00 em um período móvel de 4 anos.
  /// Mesmo distribuindo entre várias instituições, a cobertura total não excede
  /// esse valor — ou seja, ter mais de R$ 1M no total não garante proteção plena.
  static const double limiteFgcGlobal = 1000000.0;

  /// Percentual a partir do qual a cor começa a mudar (zona de atenção).
  /// Corresponde a R$ 200.000,00 (80% do limite).
  static const double percentualZonaAtencao = 0.80;

  /// Percentual do limite máximo para zona de perigo (acima de 90%).
  static const double percentualZonaPerigo = 0.90;

  // ==================== CORES DA ESCALA FGC ====================

  /// Calcula a cor de fundo conforme o percentual do limite FGC atingido.
  /// - 0% a 80% (R$ 0 a R$ 200k): gradiente verde
  /// - 80% a 90% (R$ 200k a R$ 225k): gradiente amarelo-laranja
  /// - 90% a 100% (R$ 225k a R$ 250k): gradiente laranja-vermelho
  /// - Acima de 100% (> R$ 250k): vermelho escuro
  static Color calcularCorFgc(double totalInvestido) {
    if (totalInvestido <= 0) {
      return const Color(0xFF2E7D32); // verde escuro
    }

    final percentual = (totalInvestido / limiteFgc).clamp(0.0, 1.5);

    if (percentual >= 1.0) {
      // Acima ou igual ao limite: vermelho escuro
      return const Color(0xFFB71C1C);
    }

    // Interpolação de matiz HSL: 120° (verde) → 0° (vermelho)
    // A linha dos 80% já está em amarelo (hue ~24)
    final hue = 120.0 * (1.0 - percentual);
    final saturacao = percentual < percentualZonaAtencao ? 0.65 : 0.80;
    final luminosidade = percentual < percentualZonaAtencao ? 0.30 : 0.35;

    return HSLColor.fromAHSL(1.0, hue, saturacao, luminosidade).toColor();
  }

  /// Retorna a cor do texto baseada na cor de fundo calculada para o FGC,
  /// garantindo contraste adequado.
  static Color calcularCorTextFgc(double totalInvestido) {
    final corFundo = calcularCorFgc(totalInvestido);
    // Calcula luminância relativa para decidir preto ou branco
    final luminancia =
        (0.299 * corFundo.r + 0.587 * corFundo.g + 0.114 * corFundo.b);
    return luminancia > 0.5 ? Colors.black87 : Colors.white;
  }

  /// Retorna uma descrição textual do nível de risco FGC.
  static String descricaoRiscoFgc(double totalInvestido) {
    final percentual = totalInvestido / limiteFgc;
    if (percentual < 0.60) return 'Seguro';
    if (percentual < 0.80) return 'Atenção';
    if (percentual < 0.90) return 'Alerta';
    if (percentual < 1.00) return 'Crítico';
    return 'Excede FGC';
  }
}
