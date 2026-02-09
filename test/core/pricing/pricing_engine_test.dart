import 'package:flutter_test/flutter_test.dart';
import 'package:orcamais/core/pricing/pricing_engine.dart';

void main() {
  group('PricingEngine Tests', () {
    test('calculateUnitPrice should apply all multipliers correctly', () {
      const basePrice = 100.0;
      const difficultyMultiplier = 1.3; // Médio
      const environmentMultiplier = 1.2; // Cozinha
      const distanceMultiplier = 1.25; // 6-10m

      final result = PricingEngine.calculateUnitPrice(
        basePrice: basePrice,
        difficultyMultiplier: difficultyMultiplier,
        environmentMultiplier: environmentMultiplier,
        distanceMultiplier: distanceMultiplier,
      );

      // 100 * 1.3 * 1.2 * 1.25 = 156 * 1.25 = 195
      expect(result, 195.0);
    });

    test('getDifficultyMultiplier should return correct values', () {
      expect(PricingEngine.getDifficultyMultiplier('Fácil'), 1.0);
      expect(PricingEngine.getDifficultyMultiplier('Médio'), 1.3);
      expect(PricingEngine.getDifficultyMultiplier('Difícil'), 1.6);
      expect(PricingEngine.getDifficultyMultiplier('Unknown'), 1.0);
    });

    test('getEnvironmentMultiplier should return correct values', () {
      expect(PricingEngine.getEnvironmentMultiplier('Sala/Quarto'), 1.0);
      expect(PricingEngine.getEnvironmentMultiplier('Cozinha'), 1.2);
      expect(PricingEngine.getEnvironmentMultiplier('Banheiro'), 1.3);
      expect(PricingEngine.getEnvironmentMultiplier('Área Externa'), 1.4);
      expect(PricingEngine.getEnvironmentMultiplier('Forro/Sótão'), 1.6);
      expect(PricingEngine.getEnvironmentMultiplier('Unknown'), 1.0);
    });

    test('getDistanceMultiplier should return correct values', () {
      expect(PricingEngine.getDistanceMultiplier(3), 1.0);
      expect(PricingEngine.getDistanceMultiplier(8), 1.25);
      expect(PricingEngine.getDistanceMultiplier(15), 1.5);
      expect(PricingEngine.getDistanceMultiplier(25), 1.8);
    });
  });
}
