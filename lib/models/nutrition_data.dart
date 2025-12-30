/// Model untuk data nutrisi yang di-extract dari label
/// Diperluas untuk mendukung format Informasi Nilai Gizi Indonesia
class NutritionData {
  // === SERVING INFO ===
  final String servingSize;       // Takaran Saji (e.g., "25g (3 keping)")
  final int servingsPerContainer; // Sajian per Kemasan
  
  // === ENERGY INFO ===
  final double calories;          // Energi Total dalam kkal
  final double caloriesFromFat;   // Energi dari Lemak dalam kkal
  final double caloriesFromSatFat;// Energi dari Lemak Jenuh dalam kkal
  
  // === FAT INFO ===
  final double fat;               // Lemak Total dalam gram
  final double saturatedFat;      // Lemak Jenuh dalam gram
  final double transFat;          // Lemak Trans dalam gram
  final double cholesterol;       // Kolesterol dalam mg
  
  // === CARBOHYDRATE INFO ===
  final double carbs;             // Karbohidrat Total dalam gram
  final double sugar;             // Gula dalam gram
  final double addedSugar;        // Gula Tambahan dalam gram
  final double fiber;             // Serat Pangan dalam gram
  
  // === OTHER NUTRIENTS ===
  final double protein;           // Protein dalam gram
  final double sodium;            // Garam/Natrium dalam mg
  
  // === VITAMINS & MINERALS (common in Indonesian labels) ===
  final double vitaminA;          // Vitamin A dalam %AKG
  final double vitaminB1;         // Vitamin B1 (Thiamin) dalam %AKG
  final double vitaminB2;         // Vitamin B2 (Riboflavin) dalam %AKG
  final double vitaminB3;         // Vitamin B3 (Niasin) dalam %AKG
  final double vitaminB6;         // Vitamin B6 dalam %AKG
  final double vitaminB12;        // Vitamin B12 dalam %AKG
  final double vitaminC;          // Vitamin C dalam %AKG
  final double vitaminD;          // Vitamin D dalam %AKG
  final double vitaminE;          // Vitamin E dalam %AKG
  final double calcium;           // Kalsium dalam %AKG atau mg
  final double iron;              // Zat Besi dalam %AKG atau mg
  final double zinc;              // Seng dalam %AKG atau mg
  final double phosphorus;        // Fosfor dalam %AKG atau mg
  
  // === %AKG (Angka Kecukupan Gizi) / %DV (Daily Value) ===
  final double fatDV;             // %AKG Lemak Total
  final double saturatedFatDV;    // %AKG Lemak Jenuh
  final double cholesterolDV;     // %AKG Kolesterol
  final double carbsDV;           // %AKG Karbohidrat
  final double fiberDV;           // %AKG Serat
  final double proteinDV;         // %AKG Protein
  final double sodiumDV;          // %AKG Natrium

  NutritionData({
    // Serving info
    this.servingSize = '',
    this.servingsPerContainer = 0,
    // Energy
    this.calories = 0,
    this.caloriesFromFat = 0,
    this.caloriesFromSatFat = 0,
    // Fat
    this.fat = 0,
    this.saturatedFat = 0,
    this.transFat = 0,
    this.cholesterol = 0,
    // Carbs
    this.carbs = 0,
    this.sugar = 0,
    this.addedSugar = 0,
    this.fiber = 0,
    // Other
    this.protein = 0,
    this.sodium = 0,
    // Vitamins & Minerals
    this.vitaminA = 0,
    this.vitaminB1 = 0,
    this.vitaminB2 = 0,
    this.vitaminB3 = 0,
    this.vitaminB6 = 0,
    this.vitaminB12 = 0,
    this.vitaminC = 0,
    this.vitaminD = 0,
    this.vitaminE = 0,
    this.calcium = 0,
    this.iron = 0,
    this.zinc = 0,
    this.phosphorus = 0,
    // %AKG / %DV
    this.fatDV = 0,
    this.saturatedFatDV = 0,
    this.cholesterolDV = 0,
    this.carbsDV = 0,
    this.fiberDV = 0,
    this.proteinDV = 0,
    this.sodiumDV = 0,
  });

  /// Check if any nutrition data was extracted
  bool get hasData {
    return calories > 0 || fat > 0 || sugar > 0 || sodium > 0 || protein > 0 || carbs > 0;
  }
  
  /// Check if serving info exists
  bool get hasServingInfo {
    return servingSize.isNotEmpty || servingsPerContainer > 0;
  }

  /// Convert to map for display - Structured Indonesian Format
  Map<String, dynamic> toDisplayMap() {
    return {
      // Main nutrients
      'Energi Total': {'value': calories, 'unit': 'kkal', 'dv': null},
      'Energi dari Lemak': {'value': caloriesFromFat, 'unit': 'kkal', 'dv': null},
      'Lemak Total': {'value': fat, 'unit': 'g', 'dv': fatDV},
      'Lemak Jenuh': {'value': saturatedFat, 'unit': 'g', 'dv': saturatedFatDV},
      'Lemak Trans': {'value': transFat, 'unit': 'g', 'dv': null},
      'Kolesterol': {'value': cholesterol, 'unit': 'mg', 'dv': cholesterolDV},
      'Protein': {'value': protein, 'unit': 'g', 'dv': proteinDV},
      'Karbohidrat Total': {'value': carbs, 'unit': 'g', 'dv': carbsDV},
      'Serat Pangan': {'value': fiber, 'unit': 'g', 'dv': fiberDV},
      'Gula': {'value': sugar, 'unit': 'g', 'dv': null},
      'Gula Tambahan': {'value': addedSugar, 'unit': 'g', 'dv': null},
      'Garam (Natrium)': {'value': sodium, 'unit': 'mg', 'dv': sodiumDV},
    };
  }
  
  /// Get vitamins and minerals map
  Map<String, dynamic> toVitaminMineralMap() {
    return {
      'Vitamin A': {'value': vitaminA, 'unit': '%AKG'},
      'Vitamin B1': {'value': vitaminB1, 'unit': '%AKG'},
      'Vitamin B2': {'value': vitaminB2, 'unit': '%AKG'},
      'Vitamin B3': {'value': vitaminB3, 'unit': '%AKG'},
      'Vitamin B6': {'value': vitaminB6, 'unit': '%AKG'},
      'Vitamin B12': {'value': vitaminB12, 'unit': '%AKG'},
      'Vitamin C': {'value': vitaminC, 'unit': '%AKG'},
      'Vitamin D': {'value': vitaminD, 'unit': '%AKG'},
      'Vitamin E': {'value': vitaminE, 'unit': '%AKG'},
      'Kalsium': {'value': calcium, 'unit': '%AKG'},
      'Zat Besi': {'value': iron, 'unit': '%AKG'},
      'Seng': {'value': zinc, 'unit': '%AKG'},
      'Fosfor': {'value': phosphorus, 'unit': '%AKG'},
    };
  }
  
  /// Get serving info display
  Map<String, String> getServingInfo() {
    return {
      'Takaran Saji': servingSize,
      'Sajian per Kemasan': servingsPerContainer > 0 ? '$servingsPerContainer' : '-',
    };
  }

  /// Create a copy with updated values
  NutritionData copyWith({
    String? servingSize,
    int? servingsPerContainer,
    double? calories,
    double? caloriesFromFat,
    double? caloriesFromSatFat,
    double? fat,
    double? saturatedFat,
    double? transFat,
    double? cholesterol,
    double? carbs,
    double? sugar,
    double? addedSugar,
    double? fiber,
    double? protein,
    double? sodium,
    double? vitaminA,
    double? vitaminB1,
    double? vitaminB2,
    double? vitaminB3,
    double? vitaminB6,
    double? vitaminB12,
    double? vitaminC,
    double? vitaminD,
    double? vitaminE,
    double? calcium,
    double? iron,
    double? zinc,
    double? phosphorus,
    double? fatDV,
    double? saturatedFatDV,
    double? cholesterolDV,
    double? carbsDV,
    double? fiberDV,
    double? proteinDV,
    double? sodiumDV,
  }) {
    return NutritionData(
      servingSize: servingSize ?? this.servingSize,
      servingsPerContainer: servingsPerContainer ?? this.servingsPerContainer,
      calories: calories ?? this.calories,
      caloriesFromFat: caloriesFromFat ?? this.caloriesFromFat,
      caloriesFromSatFat: caloriesFromSatFat ?? this.caloriesFromSatFat,
      fat: fat ?? this.fat,
      saturatedFat: saturatedFat ?? this.saturatedFat,
      transFat: transFat ?? this.transFat,
      cholesterol: cholesterol ?? this.cholesterol,
      carbs: carbs ?? this.carbs,
      sugar: sugar ?? this.sugar,
      addedSugar: addedSugar ?? this.addedSugar,
      fiber: fiber ?? this.fiber,
      protein: protein ?? this.protein,
      sodium: sodium ?? this.sodium,
      vitaminA: vitaminA ?? this.vitaminA,
      vitaminB1: vitaminB1 ?? this.vitaminB1,
      vitaminB2: vitaminB2 ?? this.vitaminB2,
      vitaminB3: vitaminB3 ?? this.vitaminB3,
      vitaminB6: vitaminB6 ?? this.vitaminB6,
      vitaminB12: vitaminB12 ?? this.vitaminB12,
      vitaminC: vitaminC ?? this.vitaminC,
      vitaminD: vitaminD ?? this.vitaminD,
      vitaminE: vitaminE ?? this.vitaminE,
      calcium: calcium ?? this.calcium,
      iron: iron ?? this.iron,
      zinc: zinc ?? this.zinc,
      phosphorus: phosphorus ?? this.phosphorus,
      fatDV: fatDV ?? this.fatDV,
      saturatedFatDV: saturatedFatDV ?? this.saturatedFatDV,
      cholesterolDV: cholesterolDV ?? this.cholesterolDV,
      carbsDV: carbsDV ?? this.carbsDV,
      fiberDV: fiberDV ?? this.fiberDV,
      proteinDV: proteinDV ?? this.proteinDV,
      sodiumDV: sodiumDV ?? this.sodiumDV,
    );
  }

  @override
  String toString() {
    return '''NutritionData(
  servingSize: $servingSize,
  servings: $servingsPerContainer,
  calories: $calories kkal,
  fat: $fat g (${fatDV}%),
  saturatedFat: $saturatedFat g,
  cholesterol: $cholesterol mg,
  carbs: $carbs g,
  sugar: $sugar g,
  fiber: $fiber g,
  protein: $protein g,
  sodium: $sodium mg
)''';
  }
  
  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'servingSize': servingSize,
      'servingsPerContainer': servingsPerContainer,
      'calories': calories,
      'caloriesFromFat': caloriesFromFat,
      'caloriesFromSatFat': caloriesFromSatFat,
      'fat': fat,
      'saturatedFat': saturatedFat,
      'transFat': transFat,
      'cholesterol': cholesterol,
      'carbs': carbs,
      'sugar': sugar,
      'addedSugar': addedSugar,
      'fiber': fiber,
      'protein': protein,
      'sodium': sodium,
      'vitaminA': vitaminA,
      'vitaminB1': vitaminB1,
      'vitaminB2': vitaminB2,
      'vitaminB3': vitaminB3,
      'vitaminB6': vitaminB6,
      'vitaminB12': vitaminB12,
      'vitaminC': vitaminC,
      'vitaminD': vitaminD,
      'vitaminE': vitaminE,
      'calcium': calcium,
      'iron': iron,
      'zinc': zinc,
      'phosphorus': phosphorus,
      'fatDV': fatDV,
      'saturatedFatDV': saturatedFatDV,
      'cholesterolDV': cholesterolDV,
      'carbsDV': carbsDV,
      'fiberDV': fiberDV,
      'proteinDV': proteinDV,
      'sodiumDV': sodiumDV,
    };
  }
  
  /// Create from JSON
  factory NutritionData.fromJson(Map<String, dynamic> json) {
    return NutritionData(
      servingSize: json['servingSize'] ?? '',
      servingsPerContainer: json['servingsPerContainer'] ?? 0,
      calories: (json['calories'] ?? 0).toDouble(),
      caloriesFromFat: (json['caloriesFromFat'] ?? 0).toDouble(),
      caloriesFromSatFat: (json['caloriesFromSatFat'] ?? 0).toDouble(),
      fat: (json['fat'] ?? 0).toDouble(),
      saturatedFat: (json['saturatedFat'] ?? 0).toDouble(),
      transFat: (json['transFat'] ?? 0).toDouble(),
      cholesterol: (json['cholesterol'] ?? 0).toDouble(),
      carbs: (json['carbs'] ?? 0).toDouble(),
      sugar: (json['sugar'] ?? 0).toDouble(),
      addedSugar: (json['addedSugar'] ?? 0).toDouble(),
      fiber: (json['fiber'] ?? 0).toDouble(),
      protein: (json['protein'] ?? 0).toDouble(),
      sodium: (json['sodium'] ?? 0).toDouble(),
      vitaminA: (json['vitaminA'] ?? 0).toDouble(),
      vitaminB1: (json['vitaminB1'] ?? 0).toDouble(),
      vitaminB2: (json['vitaminB2'] ?? 0).toDouble(),
      vitaminB3: (json['vitaminB3'] ?? 0).toDouble(),
      vitaminB6: (json['vitaminB6'] ?? 0).toDouble(),
      vitaminB12: (json['vitaminB12'] ?? 0).toDouble(),
      vitaminC: (json['vitaminC'] ?? 0).toDouble(),
      vitaminD: (json['vitaminD'] ?? 0).toDouble(),
      vitaminE: (json['vitaminE'] ?? 0).toDouble(),
      calcium: (json['calcium'] ?? 0).toDouble(),
      iron: (json['iron'] ?? 0).toDouble(),
      zinc: (json['zinc'] ?? 0).toDouble(),
      phosphorus: (json['phosphorus'] ?? 0).toDouble(),
      fatDV: (json['fatDV'] ?? 0).toDouble(),
      saturatedFatDV: (json['saturatedFatDV'] ?? 0).toDouble(),
      cholesterolDV: (json['cholesterolDV'] ?? 0).toDouble(),
      carbsDV: (json['carbsDV'] ?? 0).toDouble(),
      fiberDV: (json['fiberDV'] ?? 0).toDouble(),
      proteinDV: (json['proteinDV'] ?? 0).toDouble(),
      sodiumDV: (json['sodiumDV'] ?? 0).toDouble(),
    );
  }
}
