import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payflex_mobile/features/auth/widgets/auth_kit.dart';

Widget _wrap(Widget c) => MaterialApp(home: MediaQuery(data: const MediaQueryData(disableAnimations: true), child: Scaffold(body: Center(child: c))));

void main() {
  testWidgets('PfLiquidButton : libellés selon l’état et tap', (t) async {
    var taps = 0;
    await t.pumpWidget(_wrap(PfLiquidButton(label: 'Se connecter', onPressed: () => taps++)));
    expect(find.text('Se connecter'), findsOneWidget);
    await t.tap(find.text('Se connecter'));
    expect(taps, 1);
    await t.pumpWidget(_wrap(PfLiquidButton(label: 'Se connecter', state: PfLiquidState.error, onPressed: () {})));
    await t.pumpAndSettle();
    expect(find.text('Réessayez'), findsOneWidget);
  });

  testWidgets('PfEyeToggle bascule la visibilité', (t) async {
    bool? v;
    await t.pumpWidget(_wrap(PfEyeToggle(visible: false, onChanged: (x) => v = x)));
    await t.tap(find.byType(IconButton));
    expect(v, isTrue);
  });

  testWidgets('PfSecuritySteps affiche les 3 étapes', (t) async {
    await t.pumpWidget(_wrap(const SizedBox(width: 360, child: PfSecuritySteps(step: 2))));
    expect(find.text('Identifiants'), findsOneWidget);
    expect(find.text('Authentification'), findsOneWidget);
  });
}
