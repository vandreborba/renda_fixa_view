// ==================== CARD DE BANCO ====================
// Widget que representa o card de uma instituição financeira na tela
// de resumo por banco, com indicador visual de proximidade do limite FGC.

import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import '../models/resumo_banco_model.dart';
import '../parametros/parametros_gerais.dart';
import '../animation/minhas_animacoes.dart';
import '../utils_geral/formatadores.dart';

/// Card que exibe o resumo de investimentos de uma instituição financeira.
/// A cor do card reflete a proximidade do limite FGC, criando uma
/// escala visual de verde (seguro) a vermelho (no limite).
class CardBancoWidget extends StatelessWidget {
  /// Dados do banco a ser exibido
  final ResumoBancoModel resumoBanco;

  /// Índice na lista (usado para animação de entrada escalonada)
  final int indice;

  /// Callback ao tocar no card para ver detalhes
  final VoidCallback? aoToccar;

  const CardBancoWidget({
    super.key,
    required this.resumoBanco,
    this.indice = 0,
    this.aoToccar,
  });

  @override
  Widget build(BuildContext context) {
    final temaTexto = Theme.of(context).textTheme;
    final esquemaCores = Theme.of(context).colorScheme;

    // Calcula a cor do card baseado no FGC (ou usa cor neutra sem FGC)
    final temFgc = resumoBanco.temCoberturFgc;
    final corCard = temFgc
        ? ParametrosGerais.calcularCorFgc(resumoBanco.totalPosicao)
        : esquemaCores.surfaceContainerHigh;
    final corTexto = temFgc
        ? _calcularCorTexto(corCard)
        : esquemaCores.onSurface;
    final corTextoSecundario = corTexto.withValues(alpha: 0.75);
    final percentualFgc = resumoBanco.percentualFgc;

    return MinhasAnimacoes.escalaAoPressionar(
      aoPresssionar: aoToccar ?? () {},
      filho: Card(
        elevation: 2,
        color: corCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================== LINHA PRINCIPAL: nome + valor + badge ====================
              Row(
                children: [
                  // Ícone do banco
                  Icon(
                    resumoBanco.banco == 'Tesouro Nacional'
                        ? MdiIcons.bank
                        : MdiIcons.bankOutline,
                    color: corTexto,
                    size: 16,
                  ),
                  const SizedBox(width: 6),

                  // Nome do banco
                  Expanded(
                    child: Text(
                      _formatarNomeBanco(resumoBanco.banco),
                      style: temaTexto.titleSmall?.copyWith(
                        color: corTexto,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Valor total + quantidade de produtos
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Formatadores.moeda(resumoBanco.totalPosicao),
                        style: temaTexto.bodyLarge?.copyWith(
                          color: corTexto,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${resumoBanco.quantidadeProdutos} '
                        '${resumoBanco.quantidadeProdutos == 1 ? 'produto' : 'produtos'}',
                        style: temaTexto.bodySmall?.copyWith(
                          color: corTextoSecundario,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 8),

                  // Badge FGC
                  _BadgeFgc(
                    temCobertura: resumoBanco.temCoberturFgc,
                    corTexto: corTexto,
                  ),
                ],
              ),

              // ==================== BARRA FGC (apenas se tem cobertura) ====================
              if (temFgc) ...[
                const SizedBox(height: 6),
                _BarraFgc(
                  percentualFgc: percentualFgc,
                  corBarra: corTexto.withValues(alpha: 0.9),
                  corFundo: corTexto.withValues(alpha: 0.2),
                  corTexto: corTexto,
                  corTextoSecundario: corTextoSecundario,
                  temaTexto: temaTexto,
                  descricaoRisco: resumoBanco.descricaoRisco,
                ),
              ],

              // ==================== INDICADOR DE TOQUE ====================
              const SizedBox(height: 4),
              Row(
                children: [
                  // Próximo vencimento — exibido de forma discreta
                  Expanded(
                    child: _ProximoVencimentoInfo(
                      resumoBanco: resumoBanco,
                      corTexto: corTextoSecundario,
                      temaTexto: temaTexto,
                    ),
                  ),

                  // "Ver detalhes ›"
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Ver detalhes',
                        style: temaTexto.labelSmall?.copyWith(
                          color: corTextoSecundario,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        MdiIcons.chevronRight,
                        color: corTextoSecundario,
                        size: 14,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Formata nomes de banco longos para melhor exibição
  String _formatarNomeBanco(String banco) {
    return banco
        .split(' ')
        .map(
          (palavra) => palavra.isEmpty
              ? ''
              : '${palavra[0].toUpperCase()}${palavra.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  /// Calcula se o texto deve ser preto ou branco com base na luminância do fundo.
  Color _calcularCorTexto(Color corFundo) {
    final luminancia =
        0.299 * corFundo.r + 0.587 * corFundo.g + 0.114 * corFundo.b;
    return luminancia > 0.5 ? Colors.black87 : Colors.white;
  }
}

// ==================== PRÓXIMO VENCIMENTO INFO ====================

/// Widget que exibe discretamente o próximo vencimento e seu valor no card.
/// Mostra apenas quando há pelo menos um investimento com data de vencimento.
class _ProximoVencimentoInfo extends StatelessWidget {
  final ResumoBancoModel resumoBanco;
  final Color corTexto;
  final TextTheme temaTexto;

  const _ProximoVencimentoInfo({
    required this.resumoBanco,
    required this.corTexto,
    required this.temaTexto,
  });

  @override
  Widget build(BuildContext context) {
    final proximo = resumoBanco.proximoVencimento;
    if (proximo == null || proximo.dataVencimento == null) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(MdiIcons.calendarClockOutline, size: 11, color: corTexto),
        const SizedBox(width: 3),
        Text(
          'Próx. vcto: ${proximo.dataVencimento} · ${Formatadores.moeda(proximo.posicao)}',
          style: temaTexto.labelSmall?.copyWith(
            color: corTexto,
            fontSize: 10,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ==================== BADGE FGC ====================

/// Badge que indica se o investimento tem cobertura do FGC
class _BadgeFgc extends StatelessWidget {
  final bool temCobertura;
  final Color corTexto;

  const _BadgeFgc({required this.temCobertura, required this.corTexto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: corTexto.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: corTexto.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            temCobertura ? MdiIcons.shieldCheck : MdiIcons.shieldOff,
            size: 12,
            color: corTexto.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 4),
          Text(
            temCobertura ? 'FGC' : 'Sem FGC',
            style: TextStyle(
              fontSize: 11,
              color: corTexto.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== BARRA DE PROGRESSO FGC ====================

/// Barra de progresso animada que mostra o percentual do limite FGC atingido
class _BarraFgc extends StatelessWidget {
  final double percentualFgc;
  final Color corBarra;
  final Color corFundo;
  final Color corTexto;
  final Color corTextoSecundario;
  final TextTheme temaTexto;
  final String descricaoRisco;

  const _BarraFgc({
    required this.percentualFgc,
    required this.corBarra,
    required this.corFundo,
    required this.corTexto,
    required this.corTextoSecundario,
    required this.temaTexto,
    required this.descricaoRisco,
  });

  @override
  Widget build(BuildContext context) {
    // Layout compacto: percentual + barra + descrição de risco em linha
    return Row(
      children: [
        // Percentual do FGC
        Text(
          Formatadores.percentual(percentualFgc),
          style: temaTexto.labelSmall?.copyWith(
            color: corTextoSecundario,
            fontSize: 10,
          ),
        ),
        const SizedBox(width: 6),

        // Barra animada (ocupa o espaço disponível)
        Expanded(
          child: MinhasAnimacoes.barraProgressoAnimada(
            percentual: percentualFgc,
            cor: corBarra,
            corFundo: corFundo,
            altura: 4,
          ),
        ),

        const SizedBox(width: 6),

        // Descrição de risco
        Text(
          descricaoRisco,
          style: temaTexto.labelSmall?.copyWith(
            color: corTexto,
            fontWeight: FontWeight.w600,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
