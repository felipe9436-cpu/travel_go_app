import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:travel_go/main.dart';

void main() {
  testWidgets('WildLife inicia corretamente', (WidgetTester tester) async {
    await tester.pumpWidget(
      const WildLifeApp(supabaseConfigurado: false),
    );

    expect(find.byType(MaterialApp), findsOneWidget);

    final app = tester.widget<MaterialApp>(
      find.byType(MaterialApp),
    );

    expect(app.title, 'WildLife');

    expect(
      find.text('Configure o Supabase para entrar no WildLife'),
      findsOneWidget,
    );
  });
}