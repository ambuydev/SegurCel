import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segurcel/main.dart';
import 'package:segurcel/services/vault_service.dart';

void main() {
  testWidgets('App initialization test', (WidgetTester tester) async {
    final vaultService = VaultService();
    await tester.pumpWidget(SegurCelApp(
      vaultService: vaultService,
    ));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
