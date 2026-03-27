// ==================== MODEL DE GRUPO POR VENCIMENTO ====================
// Agrupa investimentos com o mesmo mês/ano de vencimento para
// exibição na aba "Por Vencimento".

import 'investimento_model.dart';

/// Representa um conjunto de investimentos que vencem no mesmo mês/ano.
/// Utilizado na aba "Por Vencimento" para agrupar e totalizar por período.
class GrupoVencimentoModel {
  // ==================== IDENTIDADE DO GRUPO ====================

  /// Data de referência para ordenação (dia 1 do mês/ano).
  /// Null indica grupo especial "Sem vencimento".
  final DateTime? mesAno;

  /// Rótulo legível para o grupo (ex: "Março 2027", "Sem vencimento")
  final String rotulo;

  /// Lista de investimentos deste grupo
  final List<InvestimentoModel> investimentos;

  const GrupoVencimentoModel({
    required this.mesAno,
    required this.rotulo,
    required this.investimentos,
  });

  // ==================== VALORES CALCULADOS ====================

  /// Soma total da posição a mercado dos investimentos neste grupo
  double get totalPosicao =>
      investimentos.fold(0.0, (soma, inv) => soma + inv.posicao);

  /// Quantidade de investimentos neste grupo
  int get quantidadeInvestimentos => investimentos.length;

  /// Retorna true se este grupo é o de investimentos sem data de vencimento
  bool get semVencimento => mesAno == null;

  /// Calcula quantos dias faltam até o fim do mês de vencimento (usando dia 1 + 1 mês - 1).
  /// Retorna null para grupos sem vencimento.
  int? get diasParaVencimento {
    if (mesAno == null) return null;
    // Usa o último dia do mês como referência do grupo
    final ultimoDia = DateTime(mesAno!.year, mesAno!.month + 1, 0);
    return ultimoDia.difference(DateTime.now()).inDays;
  }

  @override
  String toString() =>
      'GrupoVencimentoModel(rotulo: $rotulo, total: $totalPosicao, '
      'investimentos: $quantidadeInvestimentos)';
}
