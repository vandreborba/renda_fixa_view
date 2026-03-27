// ==================== PROVIDER DA CARTEIRA ====================
// Gerencia o estado global dos investimentos carregados do arquivo Excel.
// Usa Riverpod Notifier para controle de estado imutável.

import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/investimento_model.dart';
import '../models/resumo_banco_model.dart';
import '../models/grupo_vencimento_model.dart';
import '../services/excel_service.dart';

// ==================== ESTADO DA CARTEIRA ====================

/// Estado imutável da carteira de investimentos.
class CarteiraState {
  /// Lista de todos os investimentos carregados (RF + TD)
  final List<InvestimentoModel> investimentos;

  /// Indica se está carregando um arquivo
  final bool carregando;

  /// Mensagem de erro, se houver
  final String? erro;

  /// Nome do arquivo carregado (para exibição)
  final String? nomeArquivo;

  const CarteiraState({
    this.investimentos = const [],
    this.carregando = false,
    this.erro,
    this.nomeArquivo,
  });

  /// Cria uma cópia com os campos alterados
  CarteiraState copyWith({
    List<InvestimentoModel>? investimentos,
    bool? carregando,
    String? erro,
    String? nomeArquivo,
    bool limparErro = false,
  }) {
    return CarteiraState(
      investimentos: investimentos ?? this.investimentos,
      carregando: carregando ?? this.carregando,
      erro: limparErro ? null : (erro ?? this.erro),
      nomeArquivo: nomeArquivo ?? this.nomeArquivo,
    );
  }

  /// Retorna true se há dados carregados
  bool get temDados => investimentos.isNotEmpty;
}

// ==================== NOTIFIER DA CARTEIRA ====================

/// Notifier responsável por carregar e manter o estado da carteira.
class CarteiraNotifier extends Notifier<CarteiraState> {
  @override
  CarteiraState build() => const CarteiraState();

  /// Carrega e parseia um arquivo Excel de posição detalhada.
  /// [bytes]: conteúdo binário do arquivo .xlsx
  /// [nomeArquivo]: nome do arquivo para exibição
  Future<void> carregarArquivo(Uint8List bytes, String nomeArquivo) async {
    // Inicia carregamento
    state = state.copyWith(carregando: true, limparErro: true);

    try {
      // Parseia em isolate para não travar a UI
      final investimentos = await Future.microtask(
        () => ExcelService.parsearExcel(bytes),
      );

      state = CarteiraState(
        investimentos: investimentos,
        nomeArquivo: nomeArquivo,
      );
    } catch (e) {
      state = CarteiraState(
        erro: 'Erro ao processar o arquivo: ${e.toString()}',
      );
    }
  }

  /// Limpa todos os dados carregados
  void limparDados() {
    state = const CarteiraState();
  }
}

// ==================== PROVIDER PRINCIPAL ====================

/// Provider principal da carteira de investimentos
final carteiraProvider = NotifierProvider<CarteiraNotifier, CarteiraState>(
  CarteiraNotifier.new,
);

// ==================== PROVIDERS DERIVADOS ====================

/// Provider com apenas os investimentos de Renda Fixa
final rendaFixaProvider = Provider<List<InvestimentoModel>>((ref) {
  final estado = ref.watch(carteiraProvider);
  return estado.investimentos
      .where((inv) => inv.categoria == CategoriaInvestimento.rendaFixa)
      .toList();
});

/// Provider com apenas os investimentos de Tesouro Direto
final tesouroDiretoProvider = Provider<List<InvestimentoModel>>((ref) {
  final estado = ref.watch(carteiraProvider);
  return estado.investimentos
      .where((inv) => inv.categoria == CategoriaInvestimento.tesouroDireto)
      .toList();
});

/// Provider com o resumo agrupado por banco/instituição,
/// ordenado pelo total investido (maior primeiro).
final resumoPorBancoProvider = Provider<List<ResumoBancoModel>>((ref) {
  final estado = ref.watch(carteiraProvider);

  if (estado.investimentos.isEmpty) return [];

  // Agrupa investimentos por banco
  final mapa = <String, List<InvestimentoModel>>{};
  for (final investimento in estado.investimentos) {
    mapa.putIfAbsent(investimento.banco, () => []).add(investimento);
  }

  // Converte para lista de ResumoBancoModel e ordena por total (desc)
  final resumos =
      mapa.entries
          .map(
            (entrada) => ResumoBancoModel(
              banco: entrada.key,
              investimentos: entrada.value,
            ),
          )
          .toList()
        ..sort((a, b) => b.totalPosicao.compareTo(a.totalPosicao));

  return resumos;
});

/// Provider com o total geral de todos os investimentos
final totalGeralProvider = Provider<double>((ref) {
  final estado = ref.watch(carteiraProvider);
  return estado.investimentos.fold(0.0, (soma, inv) => soma + inv.posicao);
});

// ==================== PROVIDER DE VENCIMENTO ====================

/// Nomes dos meses em português para formatação do rótulo do grupo.
const _nomesMeses = [
  '',
  'Janeiro',
  'Fevereiro',
  'Março',
  'Abril',
  'Maio',
  'Junho',
  'Julho',
  'Agosto',
  'Setembro',
  'Outubro',
  'Novembro',
  'Dezembro',
];

/// Converte "dd/MM/yyyy" em DateTime para ordenação. Retorna null se inválido.
DateTime? _parsearDataVencimento(String? dataStr) {
  if (dataStr == null || dataStr.trim().isEmpty) return null;
  try {
    final partes = dataStr.trim().split('/');
    if (partes.length != 3) return null;
    return DateTime(
      int.parse(partes[2]), // ano
      int.parse(partes[1]), // mês
      int.parse(partes[0]), // dia
    );
  } catch (_) {
    return null;
  }
}

/// Provider com investimentos agrupados por mês/ano de vencimento,
/// ordenados cronologicamente (vencimento mais próximo primeiro).
/// Dentro de cada grupo os investimentos também são ordenados pela data exata.
/// Investimentos sem data ficam no final.
final porVencimentoProvider = Provider<List<GrupoVencimentoModel>>((ref) {
  final estado = ref.watch(carteiraProvider);
  if (estado.investimentos.isEmpty) return [];

  // Mapa de chave "MM/YYYY" → lista de investimentos
  final mapa = <String, List<InvestimentoModel>>{};
  final semVencimento = <InvestimentoModel>[];

  for (final inv in estado.investimentos) {
    final dataVenc = inv.dataVencimento;
    if (dataVenc == null || dataVenc.trim().isEmpty) {
      semVencimento.add(inv);
      continue;
    }

    // Parseia "dd/MM/yyyy" e agrupa por "MM/YYYY"
    try {
      final partes = dataVenc.trim().split('/');
      if (partes.length == 3) {
        final chave = '${partes[1].padLeft(2, '0')}/${partes[2]}';
        mapa.putIfAbsent(chave, () => []).add(inv);
      } else {
        semVencimento.add(inv);
      }
    } catch (_) {
      semVencimento.add(inv);
    }
  }

  // Converte cada entrada do mapa em GrupoVencimentoModel,
  // ordenando os investimentos de cada grupo pela data exata (mais próxima primeiro)
  final grupos = mapa.entries.map((entrada) {
    final partes = entrada.key.split('/');
    final mes = int.parse(partes[0]);
    final ano = int.parse(partes[1]);
    final mesAno = DateTime(ano, mes, 1);
    final rotulo = '${_nomesMeses[mes]} $ano';

    // Ordena os investimentos do grupo pela data de vencimento exata
    final investimentosOrdenados = List<InvestimentoModel>.from(entrada.value)
      ..sort((a, b) {
        final dataA = _parsearDataVencimento(a.dataVencimento);
        final dataB = _parsearDataVencimento(b.dataVencimento);
        if (dataA == null && dataB == null) return 0;
        if (dataA == null) return 1;
        if (dataB == null) return -1;
        return dataA.compareTo(dataB);
      });

    return GrupoVencimentoModel(
      mesAno: mesAno,
      rotulo: rotulo,
      investimentos: investimentosOrdenados,
    );
  }).toList()
    ..sort((a, b) => a.mesAno!.compareTo(b.mesAno!));

  // Grupo especial "Sem vencimento" ao final
  if (semVencimento.isNotEmpty) {
    grupos.add(
      GrupoVencimentoModel(
        mesAno: null,
        rotulo: 'Sem vencimento',
        investimentos: semVencimento,
      ),
    );
  }

  return grupos;
});
