// ==================== FORMATADORES AUXILIARES ====================
// Funções utilitárias para formatação de números, datas e textos
// usados em toda a aplicação de análise de renda fixa.

import 'package:intl/intl.dart';

/// Formatadores reutilizáveis para o app de renda fixa.
class Formatadores {
  // ==================== FORMATAÇÃO MONETÁRIA ====================

  /// Formatador padrão de moeda brasileira (BRL)
  static final _formatadorMoeda = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  /// Formatador compacto para valores grandes (ex: R$ 1,5 M)
  static final _formatadorMoedaCompacto = NumberFormat.compactCurrency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  /// Formata um valor como moeda brasileira (ex: R$ 11.856,63)
  static String moeda(double valor) => _formatadorMoeda.format(valor);

  /// Formata um valor como moeda compacta (ex: R$ 11,9 mil)
  static String moedaCompacta(double valor) =>
      _formatadorMoedaCompacto.format(valor);

  // ==================== FORMATAÇÃO DE PERCENTUAL ====================

  /// Formatador de percentual com 1 casa decimal
  static final _formatadorPercentual = NumberFormat('#,##0.0', 'pt_BR');

  /// Formata um valor entre 0.0 e 1.0 como percentual (ex: "75,3%")
  static String percentual(double valor) =>
      '${_formatadorPercentual.format(valor * 100)}%';

  /// Formata um valor direto como percentual (ex: percentual(0.753) → "75,3%")
  static String percentualDireto(double valor) =>
      '${_formatadorPercentual.format(valor)}%';

  // ==================== FORMATAÇÃO DE DATA ====================

  /// Formata uma data no padrão brasileiro (dd/MM/yyyy)
  static String data(DateTime data) =>
      DateFormat('dd/MM/yyyy', 'pt_BR').format(data);

  /// Formata uma string de data para exibição amigável, retornando
  /// o próprio valor se não for possível parsear.
  static String dataString(String? dataStr) {
    if (dataStr == null || dataStr.trim().isEmpty) return '-';
    return dataStr;
  }
}
