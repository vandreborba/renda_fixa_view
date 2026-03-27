// ==================== ABRIR URL - WEB ====================
// Implementação para Flutter Web usando dart:html diretamente,
// evitando o uso do plugin url_launcher que não funciona corretamente
// em alguns contextos web (MissingPluginException).

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Abre uma URL em uma nova aba do navegador.
Future<void> abrirUrlExterna(String url) async {
  html.window.open(url, '_blank');
}
