// ==================== MODEL DE RESUMO POR BANCO ====================
// Agrupa todos os investimentos de uma mesma instituição financeira
// e fornece o total consolidado para análise do limite FGC.

import 'package:flutter/material.dart';

import '../models/investimento_model.dart';
import '../parametros/parametros_gerais.dart';

/// Representa o agrupamento de investimentos de uma mesma instituição,
/// com o total consolidado e metadados de cobertura FGC.
class ResumoBancoModel {
  // ==================== IDENTIDADE ====================

  /// Nome da instituição financeira (ex: "BMG", "FIBRA", "Tesouro Nacional")
  final String banco;

  /// Lista de investimentos desta instituição
  final List<InvestimentoModel> investimentos;

  const ResumoBancoModel({required this.banco, required this.investimentos});

  // ==================== VALORES CALCULADOS ====================

  /// Soma total da posição a mercado de todos os investimentos desta instituição
  double get totalPosicao =>
      investimentos.fold(0.0, (soma, inv) => soma + inv.posicao);

  /// Quantidade de produtos distintos nesta instituição
  int get quantidadeProdutos => investimentos.length;

  /// Indica se algum investimento desta instituição tem cobertura FGC
  bool get temCoberturFgc => investimentos.any((inv) => inv.temCoberturFgc);

  /// Percentual do limite FGC atingido (0.0 a ∞)
  double get percentualFgc => totalPosicao / ParametrosGerais.limiteFgc;

  /// Cor calculada pela escala de risco FGC
  /// (verde → amarelo → laranja → vermelho conforme aproximação do limite)
  Color? get corFgc {
    // Se não há cobertura FGC, retorna cor neutra
    if (!temCoberturFgc) return null;
    return ParametrosGerais.calcularCorFgc(totalPosicao);
  }

  /// Descrição textual do nível de risco FGC
  String get descricaoRisco {
    if (!temCoberturFgc) return 'Sem FGC';
    return ParametrosGerais.descricaoRiscoFgc(totalPosicao);
  }

  // ==================== PRÓXIMO VENCIMENTO ====================

  /// Retorna o investimento com a data de vencimento mais próxima (futura ou passada).
  /// Retorna null se nenhum investimento tiver data de vencimento válida.
  InvestimentoModel? get proximoVencimento {
    InvestimentoModel? candidato;
    DateTime? dataCandidato;

    for (final inv in investimentos) {
      final dataStr = inv.dataVencimento;
      if (dataStr == null || dataStr.isEmpty) continue;
      try {
        final partes = dataStr.split('/');
        if (partes.length != 3) continue;
        final data = DateTime(
          int.parse(partes[2]),
          int.parse(partes[1]),
          int.parse(partes[0]),
        );
        // Prefere vencimentos futuros; entre dois futuros, o mais próximo
        final agora = DateTime.now();
        final isFuturo = data.isAfter(agora);
        final candidatoEhFuturo =
            dataCandidato != null && dataCandidato.isAfter(agora);

        if (candidato == null) {
          candidato = inv;
          dataCandidato = data;
        } else if (isFuturo && !candidatoEhFuturo) {
          // Troca: data futura tem prioridade sobre passada
          candidato = inv;
          dataCandidato = data;
        } else if (isFuturo == candidatoEhFuturo && data.isBefore(dataCandidato!)) {
          // Mesma categoria (ambos futuros ou ambos passados): prefere o mais próximo
          candidato = inv;
          dataCandidato = data;
        }
      } catch (_) {
        continue;
      }
    }

    return candidato;
  }

  @override
  String toString() =>
      'ResumoBancoModel(banco: $banco, total: $totalPosicao, produtos: $quantidadeProdutos)';
}
