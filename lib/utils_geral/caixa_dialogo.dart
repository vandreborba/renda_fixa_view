// ==================== CAIXA DE DIÁLOGO CENTRALIZADA ====================
// Todas as caixas de diálogo e SnackBars do aplicativo devem ser
// exibidas através deste arquivo, garantindo consistência visual.

import 'package:flutter/material.dart';

/// Classe utilitária para exibição centralizada de diálogos e SnackBars.
/// Sempre use estes métodos em vez de `showDialog` diretamente.
class MinhaCaixaDialogo {
  // ==================== DIÁLOGO DE AJUDA ====================

  /// Exibe um diálogo informativo com título e mensagem.
  /// Ideal para exibir instruções, avisos ou informações ao usuário.
  static Future<void> exibirCaixaDialogoAjuda({
    required BuildContext context,
    required String titulo,
    required String mensagem,
    String textoBotao = 'OK',
  }) async {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(textoBotao),
          ),
        ],
      ),
    );
  }

  // ==================== DIÁLOGO DE CONFIRMAÇÃO ====================

  /// Exibe um diálogo de confirmação com botões "Sim" e "Não".
  /// Retorna `true` se o usuário confirmou, `false` caso contrário.
  static Future<bool> exibirCaixaDialogoConfirmacao({
    required BuildContext context,
    required String titulo,
    required String mensagem,
    String textoConfirmar = 'Sim',
    String textoCancelar = 'Não',
  }) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(textoCancelar),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(textoConfirmar),
          ),
        ],
      ),
    );
    return resultado ?? false;
  }

  // ==================== DIÁLOGO COM CAMPO DE TEXTO ====================

  /// Exibe um diálogo com um campo de texto para entrada do usuário.
  /// Retorna o texto digitado, ou `null` se cancelado.
  static Future<String?> exibirCaixaDialogoComCampo({
    required BuildContext context,
    required String titulo,
    String? dica,
    String? valorInicial,
    String textoConfirmar = 'Confirmar',
    String textoCancelar = 'Cancelar',
  }) async {
    final controlador = TextEditingController(text: valorInicial);

    final resultado = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: TextField(
          controller: controlador,
          decoration: InputDecoration(hintText: dica),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text(textoCancelar),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controlador.text),
            child: Text(textoConfirmar),
          ),
        ],
      ),
    );

    controlador.dispose();
    return resultado;
  }

  // ==================== DIÁLOGO COM WIDGET ====================

  /// Exibe um diálogo com um widget customizado como conteúdo.
  static Future<T?> exibirCaixaDialogoWidget<T>({
    required BuildContext context,
    required String titulo,
    required Widget conteudo,
    List<Widget>? acoes,
  }) async {
    return showDialog<T>(
      context: context,
      builder: (ctx) =>
          AlertDialog(title: Text(titulo), content: conteudo, actions: acoes),
    );
  }

  // ==================== SNACKBAR ====================

  /// Exibe um SnackBar na tela atual.
  /// [tipo]: 'info' (padrão), 'sucesso', 'erro', 'aviso'
  static void mostrarSnackBar(
    BuildContext context,
    String mensagem, {
    String tipo = 'info',
    Duration duracao = const Duration(seconds: 3),
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    final Color corFundo;
    final Color corTexto;

    switch (tipo) {
      case 'sucesso':
        corFundo = Colors.green.shade700;
        corTexto = Colors.white;
        break;
      case 'erro':
        corFundo = colorScheme.error;
        corTexto = colorScheme.onError;
        break;
      case 'aviso':
        corFundo = Colors.orange.shade700;
        corTexto = Colors.white;
        break;
      default:
        corFundo = colorScheme.inverseSurface;
        corTexto = colorScheme.onInverseSurface;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem, style: TextStyle(color: corTexto)),
        backgroundColor: corFundo,
        duration: duracao,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
