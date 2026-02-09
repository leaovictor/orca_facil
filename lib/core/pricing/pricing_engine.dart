/// Motor de cálculo inteligente para orçamentos de serviços elétricos.
class PricingEngine {
  // Multiplicadores de Dificuldade
  static const double difficultyEasy = 1.0;
  static const double difficultyMedium = 1.3;
  static const double difficultyHard = 1.6;

  // Multiplicadores de Ambiente
  static const double envLivingRoom = 1.0;
  static const double envKitchen = 1.2;
  static const double envBathroom = 1.3;
  static const double envExternal = 1.4;
  static const double envCeiling = 1.6;

  // Multiplicadores de Distância
  static const double dist0to5m = 1.0;
  static const double dist6to10m = 1.25;
  static const double dist11to20m = 1.5;
  static const double distOver20m = 1.8;

  /// Calcula o valor de um item baseado em seus multiplicadores.
  static double calculateItemTotal({
    required double basePrice,
    required double difficultyMultiplier,
    required double environmentMultiplier,
    required double distanceMultiplier,
    required int quantity,
  }) {
    final unitPrice =
        basePrice *
        difficultyMultiplier *
        environmentMultiplier *
        distanceMultiplier;
    return unitPrice * quantity;
  }

  /// Calcula o valor da unidade baseado em seus multiplicadores.
  static double calculateUnitPrice({
    required double basePrice,
    required double difficultyMultiplier,
    required double environmentMultiplier,
    required double distanceMultiplier,
  }) {
    return basePrice *
        difficultyMultiplier *
        environmentMultiplier *
        distanceMultiplier;
  }

  /// Converte string de dificuldade para multiplicador
  static double getDifficultyMultiplier(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'facil':
      case 'fácil':
        return difficultyEasy;
      case 'medio':
      case 'médio':
        return difficultyMedium;
      case 'dificil':
      case 'difícil':
        return difficultyHard;
      default:
        return difficultyEasy;
    }
  }

  /// Converte string de ambiente para multiplicador
  static double getEnvironmentMultiplier(String environment) {
    switch (environment.toLowerCase()) {
      case 'sala':
      case 'quarto':
        return envLivingRoom;
      case 'cozinha':
        return envKitchen;
      case 'banheiro':
        return envBathroom;
      case 'externo':
        return envExternal;
      case 'forro':
      case 'laje':
        return envCeiling;
      default:
        return envLivingRoom;
    }
  }

  /// Calcula multiplicador de distância baseado em metros
  static double getDistanceMultiplier(double meters) {
    if (meters <= 5) return dist0to5m;
    if (meters <= 10) return dist6to10m;
    if (meters <= 20) return dist11to20m;
    return distOver20m;
  }
}
