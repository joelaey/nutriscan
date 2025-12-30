import '../models/nutrition_data.dart';
import '../models/user_data.dart';

/// Risk Status enum untuk hasil analisis
enum RiskLevel { safe, caution, danger }

/// Warning item dengan detail
class WarningItem {
  final String nutrient;
  final String message;
  final RiskLevel level;
  final double value;
  final double threshold;

  WarningItem({
    required this.nutrient,
    required this.message,
    required this.level,
    required this.value,
    required this.threshold,
  });
}

/// Hasil analisis risiko
class RiskAnalysisResult {
  final RiskLevel overallRisk;
  final List<WarningItem> warnings;
  final String summary;
  final List<String> recommendations;

  RiskAnalysisResult({
    required this.overallRisk,
    required this.warnings,
    required this.summary,
    required this.recommendations,
  });

  bool get isSafe => overallRisk == RiskLevel.safe;
  bool get hasCaution => overallRisk == RiskLevel.caution;
  bool get isDanger => overallRisk == RiskLevel.danger;
}

/// Rule-Based Risk Analyzer - Decision Engine
/// Menganalisis data nutrisi berdasarkan kondisi kesehatan user
class RiskAnalyzer {
  
  // Threshold values (berdasarkan AKG Indonesia 2150 kkal / WHO recommendations)
  static const _thresholds = {
    'sugar': {
      'normal': 25.0,      // WHO: max 25g added sugar per day (50g total)
      'diabetes': 10.0,    // Lebih ketat untuk diabetes
    },
    'sodium': {
      'normal': 400.0,     // ~400mg per serving is moderate (1500mg/day limit)
      'hypertension': 200.0, // Lebih ketat untuk hipertensi
    },
    'calories': {
      'normal': 400.0,     // Per serving (2150 kkal/day)
      'diet': 250.0,       // Lebih ketat untuk diet
    },
    'fat': {
      'normal': 15.0,      // ~67g total per day
      'diet': 10.0,
    },
    'saturatedFat': {
      'normal': 5.0,       // ~20g per day
      'diet': 3.0,
    },
    'cholesterol': {
      'normal': 100.0,     // ~300mg per day
      'heartDisease': 50.0, // Lebih ketat untuk penyakit jantung
    },
    'transFat': {
      'normal': 0.5,       // Sebaiknya 0, tapi toleransi kecil
      'diet': 0.0,
    },
  };

  /// Analyze nutrition data berdasarkan kondisi kesehatan user
  RiskAnalysisResult analyze({
    required NutritionData nutrition,
    required UserData userData,
  }) {
    final warnings = <WarningItem>[];
    var highestRisk = RiskLevel.safe;

    // 1. Analisis Gula
    final sugarThreshold = userData.hasDiabetes 
        ? _thresholds['sugar']!['diabetes']! 
        : _thresholds['sugar']!['normal']!;
    
    if (nutrition.sugar > sugarThreshold) {
      final level = _calculateRiskLevel(nutrition.sugar, sugarThreshold);
      warnings.add(WarningItem(
        nutrient: 'Gula',
        message: userData.hasDiabetes
            ? 'Tinggi gula, tidak disarankan untuk diabetes'
            : 'Kandungan gula cukup tinggi',
        level: level,
        value: nutrition.sugar,
        threshold: sugarThreshold,
      ));
      highestRisk = _maxRisk(highestRisk, level);
    }

    // 2. Analisis Sodium/Garam
    final sodiumThreshold = userData.hasHypertension
        ? _thresholds['sodium']!['hypertension']!
        : _thresholds['sodium']!['normal']!;
    
    if (nutrition.sodium > sodiumThreshold) {
      final level = _calculateRiskLevel(nutrition.sodium, sodiumThreshold);
      warnings.add(WarningItem(
        nutrient: 'Garam (Sodium)',
        message: userData.hasHypertension
            ? 'Tinggi garam, tidak disarankan untuk hipertensi'
            : 'Kandungan garam cukup tinggi',
        level: level,
        value: nutrition.sodium,
        threshold: sodiumThreshold,
      ));
      highestRisk = _maxRisk(highestRisk, level);
    }

    // 3. Analisis Kalori
    final caloriesThreshold = userData.isOnDiet
        ? _thresholds['calories']!['diet']!
        : _thresholds['calories']!['normal']!;
    
    if (nutrition.calories > caloriesThreshold) {
      final level = _calculateRiskLevel(nutrition.calories, caloriesThreshold);
      warnings.add(WarningItem(
        nutrient: 'Kalori',
        message: userData.isOnDiet
            ? 'Tinggi kalori, kurang sesuai untuk diet'
            : 'Kandungan kalori cukup tinggi',
        level: level,
        value: nutrition.calories,
        threshold: caloriesThreshold,
      ));
      highestRisk = _maxRisk(highestRisk, level);
    }

    // 4. Analisis Lemak
    final fatThreshold = userData.isOnDiet
        ? _thresholds['fat']!['diet']!
        : _thresholds['fat']!['normal']!;
    
    if (nutrition.fat > fatThreshold) {
      final level = _calculateRiskLevel(nutrition.fat, fatThreshold);
      warnings.add(WarningItem(
        nutrient: 'Lemak Total',
        message: userData.isOnDiet
            ? 'Tinggi lemak, kurang sesuai untuk diet'
            : 'Kandungan lemak cukup tinggi',
        level: level,
        value: nutrition.fat,
        threshold: fatThreshold,
      ));
      highestRisk = _maxRisk(highestRisk, level);
    }

    // 5. Analisis Lemak Jenuh
    final satFatThreshold = userData.isOnDiet
        ? _thresholds['saturatedFat']!['diet']!
        : _thresholds['saturatedFat']!['normal']!;
    
    if (nutrition.saturatedFat > satFatThreshold) {
      final level = _calculateRiskLevel(nutrition.saturatedFat, satFatThreshold);
      warnings.add(WarningItem(
        nutrient: 'Lemak Jenuh',
        message: 'Kandungan lemak jenuh tinggi',
        level: level,
        value: nutrition.saturatedFat,
        threshold: satFatThreshold,
      ));
      highestRisk = _maxRisk(highestRisk, level);
    }

    // Generate summary dan recommendations
    final summary = _generateSummary(highestRisk, warnings, userData);
    final recommendations = _generateRecommendations(warnings, userData);

    return RiskAnalysisResult(
      overallRisk: highestRisk,
      warnings: warnings,
      summary: summary,
      recommendations: recommendations,
    );
  }

  /// Calculate risk level berdasarkan seberapa jauh melebihi threshold
  RiskLevel _calculateRiskLevel(double value, double threshold) {
    final ratio = value / threshold;
    if (ratio >= 2.0) return RiskLevel.danger;
    if (ratio >= 1.5) return RiskLevel.caution;
    if (ratio > 1.0) return RiskLevel.caution;
    return RiskLevel.safe;
  }

  /// Get maximum risk level
  RiskLevel _maxRisk(RiskLevel a, RiskLevel b) {
    if (a == RiskLevel.danger || b == RiskLevel.danger) return RiskLevel.danger;
    if (a == RiskLevel.caution || b == RiskLevel.caution) return RiskLevel.caution;
    return RiskLevel.safe;
  }

  /// Generate summary berdasarkan hasil analisis
  String _generateSummary(RiskLevel risk, List<WarningItem> warnings, UserData userData) {
    if (warnings.isEmpty) {
      return 'Makanan ini relatif aman untuk kondisi kesehatanmu.';
    }

    final nutrientList = warnings.map((w) => w.nutrient.toLowerCase()).toList();
    final nutrientStr = nutrientList.join(', ');

    switch (risk) {
      case RiskLevel.danger:
        if (userData.hasDiabetes && warnings.any((w) => w.nutrient == 'Gula')) {
          return 'Makanan ini tinggi $nutrientStr dan TIDAK DISARANKAN untuk penderita diabetes.';
        }
        if (userData.hasHypertension && warnings.any((w) => w.nutrient.contains('Garam'))) {
          return 'Makanan ini tinggi $nutrientStr dan TIDAK DISARANKAN untuk penderita hipertensi.';
        }
        return 'Makanan ini tinggi $nutrientStr dan tidak disarankan untuk dikonsumsi.';
      
      case RiskLevel.caution:
        return 'Makanan ini mengandung $nutrientStr yang perlu diperhatikan.';
      
      case RiskLevel.safe:
        return 'Makanan ini relatif aman untuk dikonsumsi.';
    }
  }

  /// Generate recommendations
  List<String> _generateRecommendations(List<WarningItem> warnings, UserData userData) {
    final recommendations = <String>[];

    for (final warning in warnings) {
      if (warning.nutrient == 'Gula') {
        recommendations.add('Batasi konsumsi makanan manis hari ini');
        if (userData.hasDiabetes) {
          recommendations.add('Cek kadar gula darah setelah makan');
        }
      }
      if (warning.nutrient.contains('Garam')) {
        recommendations.add('Minum air putih lebih banyak');
        if (userData.hasHypertension) {
          recommendations.add('Hindari makanan asin lainnya hari ini');
        }
      }
      if (warning.nutrient == 'Kalori' || warning.nutrient.contains('Lemak')) {
        if (userData.isOnDiet) {
          recommendations.add('Seimbangkan dengan aktivitas fisik');
          recommendations.add('Kurangi porsi makan berikutnya');
        }
      }
    }

    if (recommendations.isEmpty) {
      recommendations.add('Tetap jaga pola makan seimbang');
    }

    return recommendations.toSet().toList(); // Remove duplicates
  }

  /// Simple analyze for compatibility with existing code
  List<String> analyzeSimple({
    required bool diabetes,
    required bool hipertensi,
    required bool diet,
    required double sugar,
    required double sodium,
    required double calories,
  }) {
    final List<String> warnings = [];

    if (diabetes && sugar > 10) {
      warnings.add('Tinggi gula - tidak disarankan untuk diabetes');
    }
    if (hipertensi && sodium > 300) {
      warnings.add('Tinggi garam - tidak disarankan untuk hipertensi');
    }
    if (diet && calories > 400) {
      warnings.add('Tinggi kalori - kurang sesuai untuk diet');
    }

    return warnings;
  }
}
