// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:renda_fixa_view/main.dart';

void main() {
  testWidgets('App inicia sem erros', (WidgetTester tester) async {
    // Constrói o app e verifica que carrega sem erros.
    await tester.pumpWidget(const ProviderScope(child: AppRendaFixa()));

    // Verifica que a tela de boas-vindas é exibida
    expect(find.text('Analisador de Renda Fixa'), findsOneWidget);
  });
}
