// ==================== ABRIR URL - EXPORTAÇÃO CONDICIONAL ====================
// Seleciona automaticamente a implementação correta para cada plataforma:
// - Web: usa dart:html diretamente (evita MissingPluginException)
// - Mobile/Desktop: usa url_launcher

export 'abrir_url_stub.dart' if (dart.library.html) 'abrir_url_web.dart';
