// ==================== SERVIÇO DE LEITURA DO EXCEL ====================
// Responsável por parsear o arquivo Excel de "Posição Detalhada" exportado
// pela corretora, extraindo apenas os investimentos de Renda Fixa e
// Tesouro Direto, enriquecendo com metadados (banco, cobertura FGC, etc).

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';

import '../models/investimento_model.dart';

/// Serviço de parsing do arquivo .xlsx de posição detalhada da corretora.
/// Suporta o formato exportado pela XP e corretoras similares.
class ExcelService {
  // ==================== CONSTANTES DE SEÇÃO ====================

  /// Identificador da seção de Renda Fixa no Excel
  static const String _nomeSecaoRendaFixa = 'Renda Fixa';

  /// Identificador da seção de Tesouro Direto no Excel
  static const String _nomeSecaoTesouroDireto = 'Tesouro Direto';

  /// Nomes de seções que devem ser ignoradas durante o parsing
  static const List<String> _secoesIgnoradas = [
    'Fundos Imobiliários',
    'Fundos de Investimentos',
    'Ações',
    'BDR',
    'ETF',
  ];

  /// Tipos de instrumento com cobertura pelo FGC
  static const List<String> _tiposComFgc = [
    'CDB',
    'RDB',
    'LCI',
    'LCA',
    'LC',
    'LCP',
    'DPGE',
  ];

  // ==================== PONTO DE ENTRADA ====================

  /// Parseia os bytes de um arquivo .xlsx e retorna a lista de investimentos
  /// de Renda Fixa e Tesouro Direto encontrados.
  ///
  /// Lança [FormatException] se o arquivo não puder ser interpretado.
  static List<InvestimentoModel> parsearExcel(List<int> bytes) {
    try {
      final excel = Excel.decodeBytes(bytes);
      final planilha = excel.tables.values.first;
      return _processarPlanilha(planilha);
    } catch (e) {
      throw FormatException('Não foi possível ler o arquivo Excel: $e');
    }
  }

  // ==================== PROCESSAMENTO DA PLANILHA ====================

  /// Percorre todas as linhas da planilha identificando seções e dados.
  static List<InvestimentoModel> _processarPlanilha(Sheet planilha) {
    final investimentos = <InvestimentoModel>[];

    // Controle de qual seção estamos atualmente processando
    bool emRendaFixa = false;
    bool emTesouroDireto = false;

    for (final linha in planilha.rows) {
      final celulas = _extrairTextoCelulas(linha);
      if (celulas.isEmpty) continue;

      final primeiraCell = celulas[0]?.trim() ?? '';

      // ==================== DETECTAR TROCA DE SEÇÃO ====================
      if (primeiraCell == _nomeSecaoRendaFixa) {
        emRendaFixa = true;
        emTesouroDireto = false;
        continue;
      }

      if (primeiraCell == _nomeSecaoTesouroDireto) {
        emRendaFixa = false;
        emTesouroDireto = true;
        continue;
      }

      // Outra seção conhecida: sair das seções relevantes
      if (_secoesIgnoradas.contains(primeiraCell)) {
        emRendaFixa = false;
        emTesouroDireto = false;
        continue;
      }

      // Se não estamos em seção relevante, pular
      if (!emRendaFixa && !emTesouroDireto) continue;

      // ==================== PULAR CABEÇALHOS E LINHAS EM BRANCO ====================
      // Linhas em branco (todas as células são espaços/null)
      if (_ehLinhaEmBranco(celulas)) continue;

      // Linhas de sub-seção: "39,8% | Inflação", "Pós-Fixado" etc.
      if (_ehLinhaSubsecao(primeiraCell)) continue;

      // ==================== PARSEAR LINHA DE DADOS ====================
      if (!_ehLinhaDeDados(celulas)) continue;

      try {
        InvestimentoModel? investimento;

        if (emRendaFixa) {
          investimento = _parsearLinhaRendaFixa(celulas);
        } else if (emTesouroDireto) {
          investimento = _parsearLinhaTesouroDireto(celulas);
        }

        if (investimento != null) {
          investimentos.add(investimento);
        }
      } catch (e) {
        // Linha malformada: apenas registrar e continuar
        debugPrint('ExcelService: erro ao parsear linha "$primeiraCell": $e');
      }
    }

    return investimentos;
  }

  // ==================== PARSEAR RENDA FIXA ====================
  // Estrutura esperada do cabeçalho:
  // [0] Nome  [1] Posição a mercado  [2] % Alocação  [3] Valor aplicado
  // [4] Valor aplicado original  [5] Taxa a mercado  [6] Data aplicação
  // [7] Data vencimento  [8] Quantidade  [9] Preço Unitário  [10] IR
  // [11] IOF  [12] Valor Líquido

  /// Parseia uma linha de dado de Renda Fixa (CDB, CRA, DEB, etc.)
  static InvestimentoModel? _parsearLinhaRendaFixa(List<String?> celulas) {
    final nome = celulas[0]?.trim() ?? '';
    if (nome.isEmpty) return null;

    final posicao = _parseValorMonetario(celulas.elementAtOrNull(1));
    if (posicao == null) return null;

    final tipo = _extrairTipo(nome);
    final banco = _extrairBanco(nome, tipo);

    return InvestimentoModel(
      nome: nome,
      tipo: tipo,
      banco: banco,
      posicao: posicao,
      categoria: CategoriaInvestimento.rendaFixa,
      temCoberturFgc: _tiposComFgc.contains(tipo.toUpperCase()),
      valorAplicado: _parseValorMonetario(celulas.elementAtOrNull(3)),
      taxa: celulas.elementAtOrNull(5)?.trim(),
      dataAplicacao: celulas.elementAtOrNull(6)?.trim(),
      dataVencimento: celulas.elementAtOrNull(7)?.trim(),
      ir: _parseValorMonetario(celulas.elementAtOrNull(10)),
      iof: _parseValorMonetario(celulas.elementAtOrNull(11)),
      valorLiquido: _parseValorMonetario(celulas.elementAtOrNull(12)),
    );
  }

  // ==================== PARSEAR TESOURO DIRETO ====================
  // Estrutura esperada do cabeçalho:
  // [0] Nome  [1] Posição  [2] % Alocação  [3] Total aplicado
  // [4] Qtd.  [5] Disponível  [6] Vencimento

  /// Parseia uma linha de dado de Tesouro Direto (LFT, LTN, NTN-B, etc.)
  static InvestimentoModel? _parsearLinhaTesouroDireto(List<String?> celulas) {
    final nome = celulas[0]?.trim() ?? '';
    if (nome.isEmpty) return null;

    final posicao = _parseValorMonetario(celulas.elementAtOrNull(1));
    if (posicao == null) return null;

    final tipo = _extrairTipoTesouro(nome);

    return InvestimentoModel(
      nome: nome,
      tipo: tipo,
      banco: 'Tesouro Nacional',
      posicao: posicao,
      categoria: CategoriaInvestimento.tesouroDireto,
      temCoberturFgc: false, // Tesouro Direto não tem FGC
      valorAplicado: _parseValorMonetario(celulas.elementAtOrNull(3)),
      dataVencimento: celulas.elementAtOrNull(6)?.trim(),
    );
  }

  // ==================== FUNÇÕES AUXILIARES ====================

  /// Extrai os textos de cada célula de uma linha do Excel.
  static List<String?> _extrairTextoCelulas(List<Data?> linha) {
    return linha.map((cell) => cell?.value?.toString()).toList();
  }

  /// Verifica se a linha está em branco (todas celulas vazias ou espaços).
  static bool _ehLinhaEmBranco(List<String?> celulas) {
    return celulas.every((c) => c == null || c.trim().isEmpty);
  }

  /// Verifica se a linha é um cabeçalho de sub-seção
  /// (ex: "39,8% | Inflação", "5,3% | Pós-Fixado").
  static bool _ehLinhaSubsecao(String primeiraCell) {
    return primeiraCell.contains('%') && primeiraCell.contains('|');
  }

  /// Verifica se a linha contém dados de investimento:
  /// - Primeira célula tem nome não vazio
  /// - Segunda célula é um valor monetário ("R$ X.XXX,XX")
  static bool _ehLinhaDeDados(List<String?> celulas) {
    if (celulas.isEmpty) return false;
    final nome = celulas[0]?.trim() ?? '';
    if (nome.isEmpty || nome == ' ') return false;
    if (celulas.length < 2) return false;
    final segundaCell = celulas[1]?.trim() ?? '';
    return segundaCell.startsWith('R\$');
  }

  /// Converte uma string monetária ("R$ 11.856,63") para double.
  /// Retorna null se não for possível converter.
  static double? _parseValorMonetario(String? valor) {
    if (valor == null || valor.trim().isEmpty) return null;
    final limpo = valor
        .replaceAll('R\$', '')
        .replaceAll('\u00a0', '') // non-breaking space
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    return double.tryParse(limpo);
  }

  /// Extrai o tipo do instrumento a partir do nome do produto.
  /// Ex: "CDB FIBRA - MAR/2027" → "CDB"
  static String _extrairTipo(String nome) {
    final partes = nome.split(' ');
    if (partes.isEmpty) return nome;
    return partes[0].toUpperCase();
  }

  /// Extrai o tipo para instrumentos de Tesouro Direto.
  /// Ex: "LFT mar/2031" → "LFT", "LTN jan/2029" → "LTN"
  static String _extrairTipoTesouro(String nome) {
    final partes = nome.split(' ');
    if (partes.isEmpty) return nome;
    return partes[0].toUpperCase();
  }

  /// Extrai o nome do banco/emissor a partir do nome do produto.
  /// Ex: "CDB FIBRA - MAR/2027" → "FIBRA"
  ///     "CDB BANCO PAN S/A - JAN/2027" → "BANCO PAN S/A"
  ///     "LFT mar/2031" → "Tesouro Nacional" (tratado externamente)
  static String _extrairBanco(String nome, String tipo) {
    // Remove o tipo (primeira palavra) e o vencimento (após " - ")
    final semVencimento = nome.split(' - ').first.trim();
    final semTipo = semVencimento.substring(tipo.length).trim();

    if (semTipo.isEmpty) return nome;

    // Normaliza alguns nomes conhecidos
    final normalizado = _normalizarNomeBanco(semTipo);
    return normalizado;
  }

  /// Normaliza nomes de instituições para agrupamento consistente.
  static String _normalizarNomeBanco(String nomeBanco) {
    final maiusculo = nomeBanco.toUpperCase().trim();

    // Mapa de normalização para nomes comuns
    const normalizacoes = <String, String>{
      'BANCO PAN S/A': 'BANCO PAN',
      'BANCO PAN': 'BANCO PAN',
      'BTG PACTUAL': 'BTG PACTUAL',
      'NUBANK': 'NUBANK',
    };

    return normalizacoes[maiusculo] ?? nomeBanco.toUpperCase().trim();
  }
}
