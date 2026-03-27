// ==================== ABRIR URL - STUB (MOBILE/DESKTOP) ====================
// Implementação para plataformas não-web utilizando url_launcher.

import 'package:url_launcher/url_launcher.dart';

/// Abre uma URL externamente no navegador ou app padrão do sistema.
Future<void> abrirUrlExterna(String url) async {
  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}
