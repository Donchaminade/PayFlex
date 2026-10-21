// Vitrine de design (données fictives, sans backend) pour captures et revue UI.
// Lancement : flutter run -d chrome -t lib/dev/design_showcase_main.dart
// URL : ?screen=home|catalogue|pay|suivi|historique|product|login
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/product_model.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/catalogue_provider.dart';
import '../core/providers/client_inbox_provider.dart';
import '../core/providers/client_notifications_provider.dart';
import '../core/providers/finance_provider.dart';
import '../core/providers/navigation_provider.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/login_screen.dart';
import 'checkout_flow_demo.dart';
import '../features/payment/widgets/payment_flow_stage.dart';
import '../features/catalogue/product_detail_screen.dart';
import '../features/main_navigation_screen.dart';
import '../features/payment/payment_success_screen.dart';

String _img(String n) => '${Uri.base.origin}/demo-img/$n.jpg';

final demoProducts = <Product>[
  Product(id: '1', name: 'Machine à coudre Juki Pro', category: 'Couture', price: 185000, dailyMin: 650, imageUrl: _img('couture'), description: 'Machine piqueuse industrielle, moteur silencieux, idéale pour atelier.', isFeatured: true),
  Product(id: '2', name: 'Kit salon Black Series', category: 'Coiffure', price: 120000, dailyMin: 400, imageUrl: _img('coiffure'), description: 'Sèche-cheveux, tondeuse et peignes professionnels.'),
  Product(id: '3', name: 'Poste à souder Inverter 140A', category: 'Soudure', price: 95000, dailyMin: 350, imageUrl: _img('soudure'), description: 'Compact, livré avec masque et gants.'),
  Product(id: '4', name: 'Pack menuiserie ProBuild', category: 'Menuiserie', price: 240000, dailyMin: 800, imageUrl: _img('menuiserie'), description: 'Perceuse sans fil 20V et scie circulaire.'),
  Product(id: '5', name: 'Coffret mécanique 120 pièces', category: 'Mécanique', price: 78000, dailyMin: 300, imageUrl: _img('mecanique'), description: 'Clés mixtes, douilles et cliquets chromés.'),
];

class _DemoAuth extends AuthNotifier {
  @override
  AuthState build() => AuthState(
        isAuthenticated: true,
        userId: 7,
        name: 'Ama Kossiwa Mensah',
        phone: '+228 90 12 34 56',
        role: 'client',
        accountStatus: 'adhere',
        isAdherent: true,
        adhesionFeePaid: true,
        assignedAgentName: 'Koffi A.',
        city: 'Lomé',
        profession: 'Couturière',
      );
}

class _DemoFinance extends FinanceNotifier {
  @override
  FinanceState build() => FinanceState(
        balance: 148500,
        projects: [
          ProjectModel(id: '1', title: 'Machine à coudre Juki Pro', saved: 112000, total: 185000, dailySuggested: 650, progress: 112000 / 185000),
          ProjectModel(id: '3', title: 'Poste à souder Inverter', saved: 36500, total: 95000, dailySuggested: 350, progress: 36500 / 95000),
        ],
        transactions: [
          TransactionModel(id: 'a', title: 'Machine à coudre Juki Pro', date: '21/10/2026', amount: 1300, status: 'validated'),
          TransactionModel(id: 'b', title: 'Poste à souder Inverter', date: '20/10/2026', amount: 700, status: 'pending'),
          TransactionModel(id: 'c', title: 'Machine à coudre Juki Pro', date: '19/10/2026', amount: 650, status: 'validated'),
          TransactionModel(id: 'd', title: 'Machine à coudre Juki Pro', date: '18/10/2026', amount: 650, status: 'rejected'),
        ],
        catchUpOrangeDaysCount: 2,
        calendarStatuses: {for (var d = 1; d <= 21; d++) d: d % 7 == 3 ? 'partial' : (d == 12 || d == 13 ? 'missed' : 'full')},
        estimatedDaysRemaining: 112,
        estimatedEndDate: DateTime(2027, 2, 10),
      );

  @override
  Future<void> reload() async {}
}

class _DemoCatalogue extends CatalogueNotifier {
  @override
  CatalogueState build() => CatalogueState(
        products: demoProducts,
        filteredProducts: demoProducts,
        featuredProducts: [demoProducts.first],
      );

  @override
  Future<void> loadProducts({bool silent = false}) async {}
}

class _DemoInbox extends ClientInboxNotifier {
  @override
  ClientInboxState build() => const ClientInboxState(notificationsUnread: 3, chatUnread: 1);
}

class _DemoNotifs extends ClientNotificationsNotifier {
  @override
  ClientNotificationsState build() => const ClientNotificationsState();
}

void main() {
  final screen = Uri.base.queryParameters['screen'] ?? 'home';
  const tabs = {'home': 0, 'catalogue': 1, 'pay': 2, 'suivi': 3, 'historique': 4};
  runApp(ProviderScope(
    overrides: [
      authProvider.overrideWith(_DemoAuth.new),
      financeProvider.overrideWith(_DemoFinance.new),
      catalogueProvider.overrideWith(_DemoCatalogue.new),
      clientInboxProvider.overrideWith(_DemoInbox.new),
      clientNotificationsProvider.overrideWith(_DemoNotifs.new),
    ],
    child: _ShowcaseApp(screen: screen, tab: tabs[screen]),
  ));
}

class _ShowcaseApp extends ConsumerWidget {
  const _ShowcaseApp({required this.screen, required this.tab});
  final String screen;
  final int? tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tab != null) {
      Future.microtask(() => ref.read(navigationIndexProvider.notifier).setIndex(tab!));
    }
    final Widget home = switch (screen) {
      'product' => ProductDetailScreen(product: demoProducts.first),
      'login' => const LoginScreen(),
      'checkout' => const CheckoutFlowDemo(),
      'verifying' => const Scaffold(body: PaymentVerifyingOverlay()),
      'success' => PaymentSuccessScreen(amount: 1300, awaitingAgentValidation: false, gatewayConfirmed: true, paymentModeLabel: 'Mobile money (T-Money)', slotsCount: 2, productName: 'Machine à coudre Juki Pro', onDone: () {}),
      _ => const MainNavigationScreen(),
    };
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PayFlex — design',
      theme: AppTheme.lightTheme,
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: home,
    );
  }
}
