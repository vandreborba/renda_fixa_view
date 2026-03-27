// ==================== TELA: POR VENCIMENTO ====================
// Segunda aba do app: exibe os investimentos agrupados por mês/ano
// de vencimento, em ordem cronológica, com totais por grupo.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import '../models/grupo_vencimento_model.dart';
import '../models/investimento_model.dart';
import '../providers/carteira_provider.dart';
import '../utils_geral/formatadores.dart';

/// Tela que organiza os investimentos por data de vencimento.
/// Cada grupo representa um mês/ano de vencimento com seus investimentos.
class PorVencimentoScreen extends ConsumerWidget {
  const PorVencimentoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grupos = ref.watch(porVencimentoProvider);
    final totalGeral = ref.watch(totalGeralProvider);
    final esquemaCores = Theme.of(context).colorScheme;
    final temaTexto = Theme.of(context).textTheme;

    if (grupos.isEmpty) {
      return _EstadoVazioWidget();
    }

    // Calcula quantos investimentos vencem nos próximos 12 meses
    final agora = DateTime.now();
    final em12Meses = agora.add(const Duration(days: 365));
    final totalProximos12Meses = grupos
        .where(
          (g) =>
              g.mesAno != null &&
              g.mesAno!.isAfter(agora) &&
              g.mesAno!.isBefore(em12Meses),
        )
        .fold(0.0, (soma, g) => soma + g.totalPosicao);

    // Limita largura para monitores ultrawide
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: CustomScrollView(
          slivers: [
            // ==================== CABEÇALHO RESUMO ====================
            SliverToBoxAdapter(
              child: _CardResumoVencimento(
                totalGeral: totalGeral,
                totalProximos12Meses: totalProximos12Meses,
                quantidadeGrupos: grupos.length,
                esquemaCores: esquemaCores,
                temaTexto: temaTexto,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // ==================== LISTA DE GRUPOS ====================
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.builder(
                itemCount: grupos.length,
                itemBuilder: (context, indice) {
                  final grupo = grupos[indice];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _CardGrupoVencimento(grupo: grupo),
                  );
                },
              ),
            ),

            // Espaço final para não sobrepor conteúdo
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}

// ==================== CARD RESUMO DE VENCIMENTO ====================

/// Card de cabeçalho com totais gerais e vencimentos próximos
class _CardResumoVencimento extends StatelessWidget {
  final double totalGeral;
  final double totalProximos12Meses;
  final int quantidadeGrupos;
  final ColorScheme esquemaCores;
  final TextTheme temaTexto;

  const _CardResumoVencimento({
    required this.totalGeral,
    required this.totalProximos12Meses,
    required this.quantidadeGrupos,
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
          // Título do card
          Row(
            children: [
              Icon(
                MdiIcons.calendarClock,
                color: esquemaCores.onPrimaryContainer,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Vencimentos',
                style: temaTexto.bodyMedium?.copyWith(
                  color: esquemaCores.onPrimaryContainer,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Total geral
          Text(
            Formatadores.moeda(totalGeral),
            style: temaTexto.headlineMedium?.copyWith(
              color: esquemaCores.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            '$quantidadeGrupos '
            '${quantidadeGrupos == 1 ? 'período de vencimento' : 'períodos de vencimento'}',
            style: temaTexto.bodySmall?.copyWith(
              color: esquemaCores.onPrimaryContainer.withValues(alpha: 0.75),
            ),
          ),

          // Destaque para vencimentos nos próximos 12 meses
          if (totalProximos12Meses > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: esquemaCores.onPrimaryContainer.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    MdiIcons.calendarAlert,
                    size: 16,
                    color: esquemaCores.onPrimaryContainer.withValues(
                      alpha: 0.85,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Próx. 12 meses: ${Formatadores.moeda(totalProximos12Meses)}',
                      style: temaTexto.bodySmall?.copyWith(
                        color: esquemaCores.onPrimaryContainer.withValues(
                          alpha: 0.85,
                        ),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ==================== CARD DE GRUPO DE VENCIMENTO ====================

/// Card expansível representando um grupo de investimentos do mesmo mês/ano.
/// Exibe o total do grupo no cabeçalho e lista detalhada ao expandir.
class _CardGrupoVencimento extends StatelessWidget {
  final GrupoVencimentoModel grupo;

  const _CardGrupoVencimento({required this.grupo});

  @override
  Widget build(BuildContext context) {
    final esquemaCores = Theme.of(context).colorScheme;
    final temaTexto = Theme.of(context).textTheme;
    final diasRestantes = grupo.diasParaVencimento;
    final corBadge = _corBadgeDias(diasRestantes, esquemaCores);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Theme(
        // Remove o divisor padrão do ExpansionTile
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          shape: const Border(),

          // ==================== ÍCONE LEADING ====================
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: grupo.semVencimento
                  ? esquemaCores.surfaceContainerHighest
                  : corBadge.fundo.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              grupo.semVencimento
                  ? MdiIcons.calendarRemoveOutline
                  : MdiIcons.calendarCheckOutline,
              color: grupo.semVencimento
                  ? esquemaCores.onSurface.withValues(alpha: 0.4)
                  : corBadge.icone,
              size: 22,
            ),
          ),

          // ==================== TÍTULO DO GRUPO ====================
          title: Text(
            grupo.rotulo,
            style: temaTexto.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),

          // ==================== SUBTÍTULO (TOTAL + BADGE DIAS) ====================
          subtitle: Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                Formatadores.moeda(grupo.totalPosicao),
                style: temaTexto.bodySmall?.copyWith(
                  color: esquemaCores.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (!grupo.semVencimento && diasRestantes != null)
                _BadgeDias(
                  diasRestantes: diasRestantes,
                  corFundo: corBadge.fundo,
                  corTexto: corBadge.texto,
                  temaTexto: temaTexto,
                ),
            ],
          ),

          // ==================== BADGE QUANTIDADE ====================
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${grupo.quantidadeInvestimentos}',
                style: temaTexto.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: esquemaCores.onSurface,
                ),
              ),
              Text(
                grupo.quantidadeInvestimentos == 1 ? 'produto' : 'produtos',
                style: temaTexto.labelSmall?.copyWith(
                  color: esquemaCores.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),

          // ==================== LISTA DE INVESTIMENTOS DO GRUPO ====================
          children: grupo.investimentos
              .map((inv) => _ItemVencimento(investimento: inv))
              .toList(),
        ),
      ),
    );
  }

  /// Determina as cores do badge de acordo com os dias para vencimento.
  ({Color fundo, Color texto, Color icone}) _corBadgeDias(
    int? diasRestantes,
    ColorScheme esquemaCores,
  ) {
    if (diasRestantes == null) {
      return (
        fundo: esquemaCores.surfaceContainerHighest,
        texto: esquemaCores.onSurface,
        icone: esquemaCores.onSurface.withValues(alpha: 0.5),
      );
    }
    if (diasRestantes < 0) {
      return (
        fundo: esquemaCores.errorContainer,
        texto: esquemaCores.onErrorContainer,
        icone: esquemaCores.error,
      );
    }
    if (diasRestantes <= 90) {
      return (
        fundo: Colors.orange.shade100,
        texto: Colors.orange.shade900,
        icone: Colors.orange.shade700,
      );
    }
    if (diasRestantes <= 180) {
      return (
        fundo: Colors.amber.shade100,
        texto: Colors.amber.shade900,
        icone: Colors.amber.shade700,
      );
    }
    if (diasRestantes <= 365) {
      return (
        fundo: Colors.lightGreen.shade100,
        texto: Colors.lightGreen.shade900,
        icone: Colors.lightGreen.shade700,
      );
    }
    return (
      fundo: Colors.green.shade100,
      texto: Colors.green.shade900,
      icone: Colors.green.shade700,
    );
  }
}

// ==================== BADGE DE DIAS RESTANTES ====================

/// Badge compacto para exibir a contagem regressiva de dias
class _BadgeDias extends StatelessWidget {
  final int diasRestantes;
  final Color corFundo;
  final Color corTexto;
  final TextTheme temaTexto;

  const _BadgeDias({
    required this.diasRestantes,
    required this.corFundo,
    required this.corTexto,
    required this.temaTexto,
  });

  @override
  Widget build(BuildContext context) {
    final String rotuloDias;
    if (diasRestantes < 0) {
      rotuloDias = 'vencido';
    } else if (diasRestantes == 0) {
      rotuloDias = 'vence hoje';
    } else {
      rotuloDias = '${diasRestantes}d';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: corFundo,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        rotuloDias,
        style: temaTexto.labelSmall?.copyWith(
          color: corTexto,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}

// ==================== ITEM DE INVESTIMENTO ====================

/// Card com as informações de um investimento individual dentro de um grupo.
/// Destaca o nome do banco (pois os itens não estão mais agrupados por banco).
class _ItemVencimento extends StatelessWidget {
  final InvestimentoModel investimento;

  const _ItemVencimento({required this.investimento});

  @override
  Widget build(BuildContext context) {
    final esquemaCores = Theme.of(context).colorScheme;
    final temaTexto = Theme.of(context).textTheme;

    final temDetalhesExtras =
        investimento.valorAplicado != null ||
        (investimento.taxa != null && investimento.taxa!.isNotEmpty);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: esquemaCores.surfaceContainerLowest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: esquemaCores.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================== CABEÇALHO: NOME + BADGE TIPO ====================
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    investimento.nome,
                    style: temaTexto.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _BadgeTipo(tipo: investimento.tipo),
              ],
            ),

            const SizedBox(height: 6),

            // Nome do banco
            Row(
              children: [
                Icon(
                  MdiIcons.bankOutline,
                  size: 13,
                  color: esquemaCores.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 4),
                Text(
                  investimento.banco,
                  style: temaTexto.bodySmall?.copyWith(
                    color: esquemaCores.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ==================== VALOR ATUAL ====================
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
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

                // Cobertura FGC
                _BadgeFgc(
                  temCobertura: investimento.temCoberturFgc,
                  esquemaCores: esquemaCores,
                  temaTexto: temaTexto,
                ),
              ],
            ),

            // ==================== EXTRAS: TAXA E VALOR APLICADO ====================
            if (temDetalhesExtras) ...[
              const Divider(height: 16),
              Row(
                children: [
                  if (investimento.valorAplicado != null)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Aplicado',
                            style: temaTexto.labelSmall?.copyWith(
                              color: esquemaCores.onSurface.withValues(
                                alpha: 0.55,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            Formatadores.moeda(investimento.valorAplicado!),
                            style: temaTexto.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (investimento.taxa != null &&
                      investimento.taxa!.isNotEmpty)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Taxa',
                            style: temaTexto.labelSmall?.copyWith(
                              color: esquemaCores.onSurface.withValues(
                                alpha: 0.55,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            investimento.taxa!,
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

// ==================== BADGE DE TIPO ====================

/// Badge com o tipo do instrumento (CDB, LCI, LCA, CRA, etc.)
class _BadgeTipo extends StatelessWidget {
  final String tipo;

  const _BadgeTipo({required this.tipo});

  @override
  Widget build(BuildContext context) {
    final esquemaCores = Theme.of(context).colorScheme;
    final temaTexto = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: esquemaCores.secondaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        tipo,
        style: temaTexto.labelSmall?.copyWith(
          color: esquemaCores.onSecondaryContainer,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}

// ==================== BADGE DE FGC ====================

/// Badge indicando se o investimento possui ou não cobertura FGC
class _BadgeFgc extends StatelessWidget {
  final bool temCobertura;
  final ColorScheme esquemaCores;
  final TextTheme temaTexto;

  const _BadgeFgc({
    required this.temCobertura,
    required this.esquemaCores,
    required this.temaTexto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: temCobertura
            ? Colors.green.shade100
            : esquemaCores.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            temCobertura ? MdiIcons.shieldCheck : MdiIcons.shieldOffOutline,
            size: 11,
            color: temCobertura
                ? Colors.green.shade800
                : esquemaCores.onSurface.withValues(alpha: 0.45),
          ),
          const SizedBox(width: 3),
          Text(
            temCobertura ? 'FGC' : 'Sem FGC',
            style: temaTexto.labelSmall?.copyWith(
              color: temCobertura
                  ? Colors.green.shade800
                  : esquemaCores.onSurface.withValues(alpha: 0.45),
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== ESTADO VAZIO ====================

/// Exibido como fallback quando não há dados (controlado pela HomeScreen)
class _EstadoVazioWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            MdiIcons.calendarRemoveOutline,
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
