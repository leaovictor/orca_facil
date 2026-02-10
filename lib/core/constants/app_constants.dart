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

  // Premium Subscription
  static const String premiumTierName = 'Premium';
  static const double premiumMonthlyPrice = 29.90;
  static const String premiumCurrency = 'BRL';
  static const String premiumProductId = 'orcamais_premium_monthly';

  // Stripe Configuration
  static const String stripePublishableKey =
      'pk_test_51Syz9dInxIuKwyuipk7u2Igizr10uvL1THJ62PhN2uucCr8kF3F2fEZZrpele0ltGwKI3kl0HFO6KV1friTwLVwF00PIN94g6j'; // TODO: Update with your actual Stripe Publishable Key

  // Payment Links
  static const String stripeProMonthlyUrl =
      'https://buy.stripe.com/test_28E14nfXYgCFgrxdFn8og00'; // TODO: Update with actual Pro link
  static const String stripePremiumMonthlyUrl =
      'https://buy.stripe.com/test_bJe3cv7rsfyB5MT0SB8og01'; // TODO: Update with actual Premium link

  // Price IDs (for webhook tier identification)
  // TODO: Update these after creating products in Stripe Dashboard
  static const String stripeProPriceId = 'price_pro';
  static const String stripePremiumPriceId = 'price_premium';

  // App URL for redirects
  static const String appUrl =
      'https://orcaplus-1309e.web.app'; // TODO: Update with actual domain

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String clientsCollection = 'clients';
  static const String servicesCollection = 'services';
  static const String budgetsCollection = 'budgets';
  static const String subscriptionsCollection = 'subscriptions';

  // Storage Paths
  static const String logosPath = 'user_logos';
  static const String profileImagesPath = 'profile_images';

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
