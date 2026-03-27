// ==================== MODEL DE INVESTIMENTO ====================
// Representa um único investimento de renda fixa ou tesouro direto
// extraído do arquivo Excel de posição detalhada.

/// Tipos de categoria de investimento reconhecidos pelo parser.
enum CategoriaInvestimento { rendaFixa, tesouroDireto }

/// Model que representa um investimento individual de renda fixa
/// ou tesouro direto, conforme extraído do arquivo Excel.
class InvestimentoModel {
  // ==================== DADOS BÁSICOS ====================

  /// Nome completo do produto (ex: "CDB FIBRA - MAR/2027")
  final String nome;

  /// Tipo do instrumento extraído do nome (ex: "CDB", "CRA", "DEB", "LFT", "LTN")
  final String tipo;

  /// Nome da instituição financeira emissora / custodiante
  final String banco;

  // ==================== VALORES ====================

  /// Valor atual da posição a mercado (em reais)
  final double posicao;

  /// Valor originalmente aplicado (em reais)
  final double? valorAplicado;

  /// Valor líquido após impostos (em reais)
  final double? valorLiquido;

  /// Valor do imposto de renda provisionado
  final double? ir;

  /// Valor do IOF provisionado
  final double? iof;

  // ==================== TAXAS E DATAS ====================

  /// Taxa de remuneração (ex: "IPC-A +4,75%", "CDI +0,86%")
  final String? taxa;

  /// Data de aplicação (formato dd/MM/yyyy)
  final String? dataAplicacao;

  /// Data de vencimento (formato dd/MM/yyyy)
  final String? dataVencimento;

  // ==================== CLASSIFICAÇÃO ====================

  /// Categoria do investimento (renda fixa ou tesouro direto)
  final CategoriaInvestimento categoria;

  /// Indica se este investimento tem cobertura do FGC.
  /// CDB, LCI, LCA, LC e similares têm cobertura.
  /// CRA, CRI, DEB e Tesouro Direto NÃO têm cobertura do FGC.
  final bool temCoberturFgc;

  const InvestimentoModel({
    required this.nome,
    required this.tipo,
    required this.banco,
    required this.posicao,
    required this.categoria,
    required this.temCoberturFgc,
    this.valorAplicado,
    this.valorLiquido,
    this.ir,
    this.iof,
    this.taxa,
    this.dataAplicacao,
    this.dataVencimento,
  });

  /// Retorna o percentual de variação em relação ao valor aplicado.
  double? get percentualVariacao {
    if (valorAplicado == null || valorAplicado == 0) return null;
    return ((posicao - valorAplicado!) / valorAplicado!) * 100;
  }

  @override
  String toString() =>
      'InvestimentoModel(nome: $nome, banco: $banco, posicao: $posicao)';
}
