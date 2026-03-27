// ==================== TELA: RESUMO POR BANCO ====================
// Primeira aba do app: exibe o somatório de investimentos agrupados
// por instituição financeira, com indicador visual de limite FGC.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import '../providers/carteira_provider.dart';
import '../widgets/card_banco_widget.dart';
import '../utils_geral/formatadores.dart';
import '../parametros/parametros_gerais.dart';

/// Tela que exibe o somatório de investimentos agrupados por banco/instituição.
/// Exibe cards com escala de cores baseada na proximidade do limite FGC.
class ResumoPorBancoScreen extends ConsumerWidget {
  const ResumoPorBancoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumosBanco = ref.watch(resumoPorBancoProvider);
    final totalGeral = ref.watch(totalGeralProvider);
    final esquemaCores = Theme.of(context).colorScheme;
    final temaTexto = Theme.of(context).textTheme;

    if (resumosBanco.isEmpty) {
      return _EstadoVazioWidget();
    }

    // Limita a largura máxima para monitores ultrawide
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: CustomScrollView(
          slivers: [
            // ==================== CABEÇALHO COM TOTAL GERAL ====================
            SliverToBoxAdapter(
              child: _CardTotalGeral(
                totalGeral: totalGeral,
                quantidadeBancos: resumosBanco.length,
                esquemaCores: esquemaCores,
                temaTexto: temaTexto,
              ),
            ),

            // ==================== LEGENDA DA ESCALA FGC ====================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _LegendaFgc(temaTexto: temaTexto),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // ==================== LISTA DE BANCOS ====================
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.builder(
                itemCount: resumosBanco.length,
                itemBuilder: (context, indice) {
                  final resumo = resumosBanco[indice];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: CardBancoWidget(
                      resumoBanco: resumo,
                      indice: indice,
                      aoToccar: () => _exibirDetalhesBanco(context, resumo),
                    ),
                  );
                },
              ),
            ),

            // Espaço no final para o FAB não cobrir o último item
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  // ==================== DETALHE DO BANCO ====================

  /// Exibe um bottom sheet com os detalhes dos produtos do banco
  void _exibirDetalhesBanco(BuildContext context, resumo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _DetalhesBancoSheet(resumo: resumo),
    );
  }
}

// ==================== CARD DE TOTAL GERAL ====================

/// Card com o total geral de todos os investimentos carregados
class _CardTotalGeral extends StatelessWidget {
  final double totalGeral;
  final int quantidadeBancos;
  final ColorScheme esquemaCores;
  final TextTheme temaTexto;

  const _CardTotalGeral({
    required this.totalGeral,
    required this.quantidadeBancos,
    required this.esquemaCores,
    required this.temaTexto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: esquemaCores.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                MdiIcons.chartBar,
                color: esquemaCores.onPrimaryContainer,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Total em Renda Fixa + Tesouro',
                style: temaTexto.bodyMedium?.copyWith(
                  color: esquemaCores.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            Formatadores.moeda(totalGeral),
            style: temaTexto.headlineMedium?.copyWith(
              color: esquemaCores.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$quantidadeBancos '
            '${quantidadeBancos == 1 ? 'instituição' : 'instituições'}',
            style: temaTexto.bodySmall?.copyWith(
              color: esquemaCores.onPrimaryContainer.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== LEGENDA DA ESCALA FGC ====================

/// Widget com a legenda visual da escala de cores do FGC
class _LegendaFgc extends StatelessWidget {
  final TextTheme temaTexto;

  const _LegendaFgc({required this.temaTexto});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          MdiIcons.informationOutline,
          size: 14,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 4),
        Text(
          'Escala de cor: verde (seguro) → vermelho (próximo ao limite FGC de '
          '${Formatadores.moeda(ParametrosGerais.limiteFgc)})',
          style: temaTexto.bodySmall?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.5),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// ==================== ESTADO VAZIO ====================

/// Exibido quando não há dados carregados — não deveria aparecer
/// na aba (a tela home controla o estado vazio), mas serve de fallback.
class _EstadoVazioWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            MdiIcons.fileExcelOutline,
            size: 64,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum dado carregado',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== ORDENAÇÃO DOS DETALHES ====================

/// Opções de ordenação disponíveis no sheet de detalhes do banco.
enum _OrdenacaoDetalhe { original, vencimento, valor }

// ==================== SHEET DE DETALHES DO BANCO ====================

/// Bottom sheet com a lista de produtos de um banco específico.
/// Permite ordenar os itens por data de vencimento ou por valor atual.
class _DetalhesBancoSheet extends StatefulWidget {
  final dynamic resumo;

  const _DetalhesBancoSheet({required this.resumo});

  @override
  State<_DetalhesBancoSheet> createState() => _DetalhesBancoSheetState();
}

class _DetalhesBancoSheetState extends State<_DetalhesBancoSheet> {
  /// Modo de ordenação selecionado pelo usuário
  _OrdenacaoDetalhe _ordenacao = _OrdenacaoDetalhe.original;

  /// Parseia uma string de data "dd/MM/yyyy" para DateTime.
  /// Retorna null se não for possível.
  DateTime? _parseData(String? dataStr) {
    if (dataStr == null || dataStr.isEmpty) return null;
    try {
      final p = dataStr.split('/');
      if (p.length != 3) return null;
      return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
    } catch (_) {
      return null;
    }
  }

  /// Retorna a lista de investimentos ordenada conforme a opção selecionada.
  List _investimentosOrdenados(List investimentos) {
    final lista = List.from(investimentos);
    switch (_ordenacao) {
      case _OrdenacaoDetalhe.vencimento:
        // Sem data vai para o final; entre datas, a mais próxima primeiro
        lista.sort((a, b) {
          final da = _parseData(a.dataVencimento?.toString());
          final db = _parseData(b.dataVencimento?.toString());
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return da.compareTo(db);
        });
      case _OrdenacaoDetalhe.valor:
        // Maior valor primeiro
        lista.sort((a, b) => (b.posicao as double).compareTo(a.posicao as double));
      case _OrdenacaoDetalhe.original:
        break; // mantém a ordem original
    }
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final esquemaCores = Theme.of(context).colorScheme;
    final temaTexto = Theme.of(context).textTheme;
    final investimentos = widget.resumo.investimentos as List;

    // Formata o nome do banco para Title Case
    final nomeBanco = widget.resumo.banco
        .toString()
        .split(' ')
        .map(
          (p) => p.isEmpty
              ? ''
              : '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}',
        )
        .join(' ');

    final itensOrdenados = _investimentosOrdenados(investimentos);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Alça de arraste
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: esquemaCores.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Título
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  Icon(
                    MdiIcons.bankOutline,
                    color: esquemaCores.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nomeBanco,
                          style: temaTexto.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Total: ${Formatadores.moeda(widget.resumo.totalPosicao)}',
                          style: temaTexto.bodyMedium?.copyWith(
                            color: esquemaCores.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ==================== BOTÕES DE ORDENAÇÃO ====================
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SegmentedButton<_OrdenacaoDetalhe>(
                segments: const [
                  ButtonSegment(
                    value: _OrdenacaoDetalhe.original,
                    icon: Icon(MdiIcons.formatListBulleted, size: 16),
                    label: Text('Padrão'),
                  ),
                  ButtonSegment(
                    value: _OrdenacaoDetalhe.vencimento,
                    icon: Icon(MdiIcons.calendarArrowRight, size: 16),
                    label: Text('Vencimento'),
                  ),
                  ButtonSegment(
                    value: _OrdenacaoDetalhe.valor,
                    icon: Icon(MdiIcons.sortNumericAscending, size: 16),
                    label: Text('Valor'),
                  ),
                ],
                selected: {_ordenacao},
                onSelectionChanged: (selecionados) {
                  setState(() => _ordenacao = selecionados.first);
                },
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),

            const Divider(height: 1),

            // Lista de produtos
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: itensOrdenados.length,
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, i) {
                  final inv = itensOrdenados[i];
                  return _ItemInvestimento(investimento: inv);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ==================== ITEM DE INVESTIMENTO NO SHEET ====================

/// Card com os dados de um investimento individual exibido no bottom sheet.
/// Destaca o valor atual e a data de vencimento com contagem regressiva.
class _ItemInvestimento extends StatelessWidget {
  final dynamic investimento;

  const _ItemInvestimento({required this.investimento});

  /// Calcula quantos dias faltam para o vencimento a partir de hoje.
  /// Retorna null se a data não puder ser processada.
  int? _calcularDiasParaVencimento(String? dataVencimento) {
    if (dataVencimento == null || dataVencimento.isEmpty) return null;
    try {
      final partes = dataVencimento.split('/');
      if (partes.length != 3) return null;
      final dataAlvo = DateTime(
        int.parse(partes[2]), // ano
        int.parse(partes[1]), // mês
        int.parse(partes[0]), // dia
      );
      return dataAlvo.difference(DateTime.now()).inDays;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final esquemaCores = Theme.of(context).colorScheme;
    final temaTexto = Theme.of(context).textTheme;
    final diasRestantes = _calcularDiasParaVencimento(
      investimento.dataVencimento?.toString(),
    );
    final temVencimento = investimento.dataVencimento != null &&
        investimento.dataVencimento.toString().isNotEmpty;
    final temDetalhesExtras = investimento.valorAplicado != null ||
        (investimento.taxa != null &&
            investimento.taxa.toString().isNotEmpty);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================== CABEÇALHO: NOME + BADGE TIPO ====================
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    investimento.nome.toString(),
                    style: temaTexto.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _BadgeTipo(tipo: investimento.tipo.toString()),
              ],
            ),

            const SizedBox(height: 12),

            // ==================== VALOR ATUAL + VENCIMENTO ====================
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Valor atual em destaque
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Valor Atual',
                        style: temaTexto.labelSmall?.copyWith(
                          color: esquemaCores.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        Formatadores.moeda(investimento.posicao),
                        style: temaTexto.titleMedium?.copyWith(
                          color: esquemaCores.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Data de vencimento com badge de dias restantes
                if (temVencimento)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Vencimento',
                        style: temaTexto.labelSmall?.copyWith(
                          color: esquemaCores.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        investimento.dataVencimento.toString(),
                        style: temaTexto.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (diasRestantes != null)
                        _BadgeDiasRestantes(
                          diasRestantes: diasRestantes,
                          esquemaCores: esquemaCores,
                          temaTexto: temaTexto,
                        ),
                    ],
                  ),
              ],
            ),

            // ==================== EXTRAS: TAXA E VALOR APLICADO ====================
            if (temDetalhesExtras) ...[
              const Divider(height: 16),
              Row(
                children: [
                  // Valor aplicado
                  if (investimento.valorAplicado != null)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Aplicado',
                            style: temaTexto.labelSmall?.copyWith(
                              color: esquemaCores.onSurface
                                  .withValues(alpha: 0.55),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            Formatadores.moeda(investimento.valorAplicado),
                            style: temaTexto.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Taxa
                  if (investimento.taxa != null &&
                      investimento.taxa.toString().isNotEmpty)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Taxa',
                            style: temaTexto.labelSmall?.copyWith(
                              color: esquemaCores.onSurface
                                  .withValues(alpha: 0.55),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            investimento.taxa.toString(),
                            style: temaTexto.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ==================== BADGE DE DIAS RESTANTES ====================

/// Exibe quantos dias faltam para o vencimento do investimento,
/// com cor indicativa: verde (>180 dias), amarelo (90–180), laranja (<90), vermelho (vencido).
class _BadgeDiasRestantes extends StatelessWidget {
  final int diasRestantes;
  final ColorScheme esquemaCores;
  final TextTheme temaTexto;

  const _BadgeDiasRestantes({
    required this.diasRestantes,
    required this.esquemaCores,
    required this.temaTexto,
  });

  @override
  Widget build(BuildContext context) {
    // Define cor de acordo com proximidade do vencimento
    final Color corFundo;
    final Color corTexto;

    if (diasRestantes < 0) {
      // Vencido
      corFundo = esquemaCores.errorContainer;
      corTexto = esquemaCores.onErrorContainer;
    } else if (diasRestantes < 90) {
      // Próximo do vencimento — atenção
      corFundo = Colors.orange.shade100;
      corTexto = Colors.orange.shade900;
    } else if (diasRestantes < 180) {
      // Moderado
      corFundo = Colors.amber.shade100;
      corTexto = Colors.amber.shade900;
    } else {
      // Confortável
      corFundo = Colors.green.shade100;
      corTexto = Colors.green.shade800;
    }

    final rotulo = diasRestantes < 0
        ? 'Vencido há ${-diasRestantes} d'
        : '$diasRestantes dias';

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: corFundo,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        rotulo,
        style: temaTexto.labelSmall?.copyWith(
          color: corTexto,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}


class _BadgeTipo extends StatelessWidget {
  final String tipo;
  const _BadgeTipo({required this.tipo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        tipo,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
