// ==================== ANIMAÇÕES CENTRALIZADAS ====================
// Todas as animações do aplicativo devem ser implementadas aqui.
// Não crie animações diretamente em outros arquivos.

import 'package:flutter/material.dart';

/// Biblioteca centralizada de animações do aplicativo.
/// Importe e use as funções deste arquivo sempre que precisar de animações.
class MinhasAnimacoes {
  // ==================== TRANSIÇÕES DE TELA ====================

  /// Transição de entrada deslizando da direita para esquerda
  static Widget transicaoSlide({
    required Animation<double> animacao,
    required Widget filho,
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animacao, curve: Curves.easeInOut)),
      child: filho,
    );
  }

  /// Transição de entrada com fade
  static Widget transicaoFade({
    required Animation<double> animacao,
    required Widget filho,
  }) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animacao, curve: Curves.easeIn),
      child: filho,
    );
  }

  // ==================== ANIMAÇÕES DE ENTRADA DE LISTA ====================

  /// Animação de entrada de item em lista (fade + slide de baixo para cima)
  static Widget entradaItem({
    required Animation<double> animacao,
    required Widget filho,
    int indice = 0,
  }) {
    // Atraso baseado no índice do item
    final atraso = indice * 0.05;
    final animacaoComAtraso = CurvedAnimation(
      parent: animacao,
      curve: Interval(
        atraso.clamp(0.0, 0.9),
        (atraso + 0.3).clamp(0.3, 1.0),
        curve: Curves.easeOut,
      ),
    );

    return FadeTransition(
      opacity: animacaoComAtraso,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 0.3),
          end: Offset.zero,
        ).animate(animacaoComAtraso),
        child: filho,
      ),
    );
  }

  // ==================== ANIMAÇÕES DE BARRA DE PROGRESSO ====================

  /// Barra de progresso animada para indicador FGC
  static Widget barraProgressoAnimada({
    required double percentual,
    required Color cor,
    required Color corFundo,
    double altura = 8.0,
    Duration duracao = const Duration(milliseconds: 800),
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: percentual.clamp(0.0, 1.0)),
      duration: duracao,
      curve: Curves.easeOut,
      builder: (context, valor, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(altura / 2),
          child: LinearProgressIndicator(
            value: valor,
            backgroundColor: corFundo,
            valueColor: AlwaysStoppedAnimation<Color>(cor),
            minHeight: altura,
          ),
        );
      },
    );
  }

  // ==================== ANIMAÇÃO DE ESCALA ====================

  /// Efeito de escala ao pressionar (press feedback)
  static Widget escalaAoPressionar({
    required Widget filho,
    required VoidCallback aoPresssionar,
    double escalaMinima = 0.95,
  }) {
    return _WidgetEscalaAoPressionar(
      aoPresssionar: aoPresssionar,
      escalaMinima: escalaMinima,
      child: filho,
    );
  }
}

// ==================== WIDGET AUXILIAR DE ESCALA ====================

/// Widget interno para implementar o efeito de escala ao pressionar
class _WidgetEscalaAoPressionar extends StatefulWidget {
  final Widget child;
  final VoidCallback aoPresssionar;
  final double escalaMinima;

  const _WidgetEscalaAoPressionar({
    required this.child,
    required this.aoPresssionar,
    required this.escalaMinima,
  });

  @override
  State<_WidgetEscalaAoPressionar> createState() =>
      _WidgetEscalaAoPressionarState();
}

class _WidgetEscalaAoPressionarState extends State<_WidgetEscalaAoPressionar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controlador;
  late Animation<double> _animacaoEscala;

  @override
  void initState() {
    super.initState();
    _controlador = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _animacaoEscala = Tween<double>(
      begin: 1.0,
      end: widget.escalaMinima,
    ).animate(_controlador);
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controlador.forward(),
      onTapUp: (_) {
        _controlador.reverse();
        widget.aoPresssionar();
      },
      onTapCancel: () => _controlador.reverse(),
      child: ScaleTransition(scale: _animacaoEscala, child: widget.child),
    );
  }
}
