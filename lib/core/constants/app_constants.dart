class AppConstants {
  // App Info
  static const String appName = 'Orça+';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Orçamentos Profissionais';

  // Free Tier Limits
  static const int freeBudgetLimit = 5;
  static const String freeTierName = 'Gratuito';
  static const String freeWatermarkText = 'Gerado com Orça+ - Versão Gratuita';

  // Pro Subscription
  static const String proTierName = 'Pro';
  static const double proMonthlyPrice = 19.90;
  static const String proCurrency = 'BRL';
  static const String proProductId = 'orcamais_pro_monthly';
  static const String stripePublishableKey =
      'pk_test_51Syz9dInxIuKwyuipk7u2Igizr10uvL1THJ62PhN2uucCr8kF3F2fEZZrpele0ltGwKI3kl0HFO6KV1friTwLVwF00PIN94g6j'; // TODO: Add Stripe Publishable Key
  static const String stripeProMonthlyUrl =
      'https://buy.stripe.com/test_28E14nfXYgCFgrxdFn8og00'; // TODO: Add Stripe Payment Link

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String clientsCollection = 'clients';
  static const String servicesCollection = 'services';
  static const String budgetsCollection = 'budgets';
  static const String subscriptionsCollection = 'subscriptions';

  // Storage Paths
  static const String logosPath = 'user_logos';

  // Default Services (can be used as initial data)
  static const List<Map<String, dynamic>> defaultServices = [
    {
      'name': 'Instalação de Tomada',
      'description': 'Instalação de tomada padrão',
      'unitPrice': 50.0,
    },
    {
      'name': 'Instalação de Interruptor',
      'description': 'Instalação de interruptor simples',
      'unitPrice': 45.0,
    },
    {
      'name': 'Instalação de Luminária',
      'description': 'Instalação de luminária residencial',
      'unitPrice': 80.0,
    },
    {
      'name': 'Troca de Disjuntor',
      'description': 'Substituição de disjuntor no quadro',
      'unitPrice': 120.0,
    },
    {
      'name': 'Instalação de Chuveiro',
      'description': 'Instalação completa de chuveiro elétrico',
      'unitPrice': 150.0,
    },
    {
      'name': 'Passagem de Fio',
      'description': 'Passagem de fio por metro linear',
      'unitPrice': 15.0,
    },
    {
      'name': 'Manutenção de Quadro Elétrico',
      'description': 'Revisão e manutenção de quadro',
      'unitPrice': 200.0,
    },
    {
      'name': 'Instalação de Ventilador de Teto',
      'description': 'Instalação completa de ventilador',
      'unitPrice': 100.0,
    },
  ];

  // Validation
  static const int minPasswordLength = 6;
  static const String phonePattern = r'^\(\d{2}\) \d{4,5}-\d{4}$';
  static const String emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const double cardElevation = 2.0;
  static const Duration animationDuration = Duration(milliseconds: 300);

  // Pagination
  static const int budgetsPerPage = 20;
  static const int servicesPerPage = 50;
}
