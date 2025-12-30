import 'dart:convert';

enum RiskStatus { safe, caution, danger }

class NutritionItem {
  final String name;
  final double value;
  final String unit;
  final bool isHigh;
  final double? dailyValuePercent;
  final String? category; // Energi, Lemak, Karbohidrat, Protein, Vitamin, Mineral

  NutritionItem({
    required this.name,
    required this.value,
    required this.unit,
    required this.isHigh,
    this.dailyValuePercent,
    this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      'unit': unit,
      'isHigh': isHigh,
      'dailyValuePercent': dailyValuePercent,
      'category': category,
    };
  }

  factory NutritionItem.fromJson(Map<String, dynamic> json) {
    return NutritionItem(
      name: json['name'],
      value: (json['value'] as num).toDouble(),
      unit: json['unit'],
      isHigh: json['isHigh'] ?? false,
      dailyValuePercent: json['dailyValuePercent']?.toDouble(),
      category: json['category'],
    );
  }

  /// Get display value - tampilkan "-" jika nilai 0
  String get displayValue {
    if (value == 0) return '-';
    return '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)} $unit';
  }
  
  /// Check if this nutrient was scanned (has a value > 0)
  bool get wasScanned => value > 0;
  
  /// Get formatted %AKG display
  String? get dvDisplay {
    if (!wasScanned || dailyValuePercent == null) return null;
    return '${dailyValuePercent!.toStringAsFixed(0)}%';
  }
}

class ScanResult {
  final String id;
  final String? productName;
  final DateTime scanDate;
  final RiskStatus status;
  final List<NutritionItem> nutrients;
  final String? warningMessage;
  final String? imageUrl;
  final Map<String, String>? servingInfo; // NEW: Takaran Saji info

  ScanResult({
    required this.id,
    this.productName,
    required this.scanDate,
    required this.status,
    required this.nutrients,
    this.warningMessage,
    this.imageUrl,
    this.servingInfo,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productName': productName,
      'scanDate': scanDate.toIso8601String(),
      'status': status.name,
      'nutrients': nutrients.map((n) => n.toJson()).toList(),
      'warningMessage': warningMessage,
      'imageUrl': imageUrl,
      'servingInfo': servingInfo,
    };
  }

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      id: json['id'],
      productName: json['productName'],
      scanDate: DateTime.parse(json['scanDate']),
      status: RiskStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => RiskStatus.caution,
      ),
      nutrients: (json['nutrients'] as List)
          .map((n) => NutritionItem.fromJson(n))
          .toList(),
      warningMessage: json['warningMessage'],
      imageUrl: json['imageUrl'],
      servingInfo: json['servingInfo'] != null 
          ? Map<String, String>.from(json['servingInfo'])
          : null,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory ScanResult.fromJsonString(String jsonString) {
    return ScanResult.fromJson(jsonDecode(jsonString));
  }

  // Get status text in Indonesian
  String get statusText {
    switch (status) {
      case RiskStatus.safe:
        return 'AMAN';
      case RiskStatus.caution:
        return 'PERLU DIPERHATIKAN';
      case RiskStatus.danger:
        return 'TIDAK DISARANKAN';
    }
  }

  // Get status emoji
  String get statusEmoji {
    switch (status) {
      case RiskStatus.safe:
        return '🟢';
      case RiskStatus.caution:
        return '🟡';
      case RiskStatus.danger:
        return '🔴';
    }
  }

  // Format scan date
  String get formattedDate {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${scanDate.day} ${months[scanDate.month - 1]} ${scanDate.year}';
  }

  // Get display name
  String get displayName => productName ?? 'Produk Tidak Diketahui';
  
  // Get nutrients grouped by category
  Map<String, List<NutritionItem>> get nutrientsByCategory {
    final grouped = <String, List<NutritionItem>>{};
    for (final nutrient in nutrients) {
      final category = nutrient.category ?? 'Lainnya';
      grouped.putIfAbsent(category, () => []);
      grouped[category]!.add(nutrient);
    }
    return grouped;
  }
  
  // Get scanned nutrients count
  int get scannedNutrientsCount => nutrients.where((n) => n.wasScanned).length;
  
  // Get total nutrients count
  int get totalNutrientsCount => nutrients.length;
  
  // Get serving size display
  String get servingSizeDisplay => servingInfo?['Takaran Saji'] ?? '-';
  
  // Get servings per container display
  String get servingsPerContainerDisplay => servingInfo?['Sajian per Kemasan'] ?? '-';
}
