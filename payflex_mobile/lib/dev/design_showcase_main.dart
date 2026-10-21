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
import '../features/auth/welcome_screen.dart';
import '../features/auth/role_selection_screen.dart';
import '../features/auth/registration_screen.dart';
import '../features/auth/registration_success_screen.dart';
import '../features/auth/pin_setup_screen.dart';
import '../features/auth/forgot_password_verify_screen.dart';
import '../features/auth/forgot_password_reset_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/catalogue/cart_screen.dart';
import '../features/catalogue/contribution_config_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/chat/custom_request_screen.dart';
import '../features/notifications/client_notifications_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/profile_edit_screen.dart';
import '../features/profile/notification_preferences_screen.dart';
import '../features/profile/privacy_policy_screen.dart';
import '../features/support/client_report_screen.dart';
import '../features/vitrine/job_offers_screen.dart';
import '../features/dashboard/dashboard_project_detail_screen.dart';
import '../features/history/gap_fill_screen.dart';
import '../features/payment/adhesion_payment_screen.dart';
import '../features/payment/contribution_receipt_screen.dart';
import '../features/agent/agent_main_navigation_screen.dart';
import '../features/agent/agent_client_list_screen.dart';
import '../features/agent/agent_validation_queue_screen.dart';
import '../features/agent/agent_zone_tour_screen.dart';
import '../features/agent/agent_weekly_schedule_screen.dart';
import '../features/agent/agent_registry_screen.dart';
import '../features/agent/agent_profile_screen.dart';
import '../features/agent/agent_change_pin_screen.dart';
import '../features/agent/agent_enrollment_screen.dart';
import '../features/agent/agent_client_detail_screen.dart';
import 'checkout_flow_demo.dart';
import 'otp_flow_demo.dart';
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
        role: Uri.base.queryParameters['role'] ?? 'client',
        accountStatus: (Uri.base.queryParameters['role'] == 'agent') ? 'valide' : 'adhere',
        isAdherent: true,
        adhesionFeePaid: true,
        assignedAgentName: 'Koffi A.',
        city: 'Lomé',
        profession: 'Couturière',
      );

  /// Démo : réponse simulée (1,6 s) ; code 1234 = succès, sinon refus.
  @override
  Future<LoginOutcome> login(String identifier, String pin, {String? loginMode}) async {
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    return pin.trim() == '1234' ? const LoginOutcome.ok() : const LoginOutcome.fail('Identifiants incorrects.');
  }
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
      'welcome' => const WelcomeScreen(),
      'onboarding' => const OnboardingScreen(),
      'role' => const RoleSelectionScreen(),
      'register' => const RegistrationScreen(),
      'register-ok' => const RegistrationSuccessScreen(),
      'pin' => const PinSetupScreen(),
      'forgot' => const ForgotPasswordVerifyScreen(),
      'forgot-reset' => const ForgotPasswordResetScreen(resetToken: 'demo'),
      'cart' => const CartScreen(),
      'contrib-config' => const ContributionConfigScreen(),
      'chat' => const ChatScreen(),
      'custom-request' => const CustomRequestScreen(),
      'notifications' => const ClientNotificationsScreen(),
      'profile' => const ProfileScreen(),
      'profile-edit' => const ProfileEditScreen(),
      'notif-prefs' => const NotificationPreferencesScreen(),
      'privacy' => const PrivacyPolicyScreen(),
      'report' => const ClientReportScreen(),
      'jobs' => const JobOffersScreen(),
      'project' => const DashboardProjectDetailScreen(projectId: '1'),
      'gap-fill' => const GapFillScreen(),
      'adhesion' => const AdhesionPaymentScreen(),
      'receipt' => ContributionReceiptScreen(amount: 1300, reference: 'PF-1761036000', paidAt: DateTime(2026, 10, 21, 9, 12), paymentModeLabel: 'T-Money', slotsCount: 2, clientName: 'Ama Kossiwa Mensah', projectName: 'Machine à coudre Juki Pro', agentName: 'Kodjo Agbeko', projectSaved: 96500, projectTotal: 185000),
      'agent' => const AgentMainNavigationScreen(),
      'agent-clients' => const AgentClientListScreen(),
      'agent-queue' => const AgentValidationQueueScreen(),
      'agent-tour' => const AgentZoneTourScreen(),
      'agent-week' => const AgentWeeklyScheduleScreen(),
      'agent-registry' => const AgentRegistryScreen(),
      'agent-profile' => const AgentProfileScreen(),
      'agent-pin' => const AgentChangePinScreen(),
      'agent-enroll' => const AgentEnrollmentScreen(),
      'agent-client' => const AgentClientDetailScreen(clientId: 7, name: 'Ama Kossiwa Mensah', zone: 'Bè-Kpota'),

      'checkout' => const CheckoutFlowDemo(),
      'otp' => const OtpFlowDemo(),
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
