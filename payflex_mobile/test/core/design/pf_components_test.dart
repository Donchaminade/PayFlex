import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payflex_mobile/core/design/pf_components.dart';

void main() {
  testWidgets('PfFloatingTabBar affiche le libellé actif et remonte le tap', (tester) async {
    var tapped = -1;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        bottomNavigationBar: PfFloatingTabBar(
          index: 0,
          items: const [
            PfNavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Accueil'),
            PfNavItem(icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view_rounded, label: 'Catalogue'),
          ],
          onTap: (i) => tapped = i,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Accueil'), findsOneWidget);
    expect(find.text('Catalogue'), findsNothing); // inactif = icône seule
    await tester.tap(find.byIcon(Icons.grid_view_outlined));
    expect(tapped, 1);
  });

  testWidgets('PfReveal affiche directement le contenu si animations réduites', (tester) async {
    await tester.pumpWidget(const MediaQuery(
      data: MediaQueryData(disableAnimations: true),
      child: Directionality(textDirection: TextDirection.ltr, child: PfReveal(child: Text('ok'))),
    ));
    final opacity = tester.widget<Opacity>(find.byType(Opacity));
    expect(opacity.opacity, 1);
  });
}
