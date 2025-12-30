import '../models/nutrition_data.dart';

/// Advanced Nutrition Parser dengan Line-Based Table Parsing
/// 
/// Strategi parsing:
/// 1. Split text menjadi lines
/// 2. Identifikasi setiap line sebagai key-value pair
/// 3. Fuzzy matching untuk keyword recognition
/// 4. Context-aware value extraction
/// 
/// Akurasi ditingkatkan dengan:
/// - Multiple pattern variations
/// - Fuzzy keyword matching (typo tolerance)
/// - Line-by-line extraction
/// - Smart number/unit parsing
class NutritionParser {
  
  NutritionData parse(String text) {
    // Normalize dan split menjadi lines
    final normalizedText = _normalizeText(text);
    final lines = _splitToLines(normalizedText);
    
    print('=== PARSING ${lines.length} LINES ===');
    for (int i = 0; i < lines.length; i++) {
      print('[$i] ${lines[i]}');
    }
    print('================================');
    
    // Parse setiap line untuk extract key-value
    final extracted = <String, ExtractedValue>{};
    
    for (final line in lines) {
      _extractFromLine(line, extracted);
    }
    
    // Fallback: extract dari full text untuk yang belum ketemu
    _extractFromFullText(normalizedText, extracted);
    
    // Build NutritionData
    return NutritionData(
      servingSize: _extractServingSize(normalizedText),
      servingsPerContainer: _extractServingsPerContainer(normalizedText),
      
      // Energy
      calories: extracted['calories']?.value ?? 0,
      caloriesFromFat: extracted['caloriesFromFat']?.value ?? 0,
      caloriesFromSatFat: extracted['caloriesFromSatFat']?.value ?? 0,
      
      // Fat
      fat: extracted['fat']?.value ?? 0,
      saturatedFat: extracted['saturatedFat']?.value ?? 0,
      transFat: extracted['transFat']?.value ?? 0,
      cholesterol: extracted['cholesterol']?.value ?? 0,
      
      // Carbs
      carbs: extracted['carbs']?.value ?? 0,
      sugar: extracted['sugar']?.value ?? 0,
      addedSugar: extracted['addedSugar']?.value ?? 0,
      fiber: extracted['fiber']?.value ?? 0,
      
      // Others
      protein: extracted['protein']?.value ?? 0,
      sodium: extracted['sodium']?.value ?? 0,
      
      // Vitamins
      vitaminA: extracted['vitaminA']?.value ?? 0,
      vitaminB1: extracted['vitaminB1']?.value ?? 0,
      vitaminB2: extracted['vitaminB2']?.value ?? 0,
      vitaminB3: extracted['vitaminB3']?.value ?? 0,
      vitaminB6: extracted['vitaminB6']?.value ?? 0,
      vitaminB12: extracted['vitaminB12']?.value ?? 0,
      vitaminC: extracted['vitaminC']?.value ?? 0,
      vitaminD: extracted['vitaminD']?.value ?? 0,
      vitaminE: extracted['vitaminE']?.value ?? 0,
      
      // Minerals
      calcium: extracted['calcium']?.value ?? 0,
      iron: extracted['iron']?.value ?? 0,
      zinc: extracted['zinc']?.value ?? 0,
      phosphorus: extracted['phosphorus']?.value ?? 0,
      
      // %AKG
      fatDV: extracted['fatDV']?.value ?? 0,
      saturatedFatDV: extracted['saturatedFatDV']?.value ?? 0,
      cholesterolDV: extracted['cholesterolDV']?.value ?? 0,
      carbsDV: extracted['carbsDV']?.value ?? 0,
      fiberDV: extracted['fiberDV']?.value ?? 0,
      proteinDV: extracted['proteinDV']?.value ?? 0,
      sodiumDV: extracted['sodiumDV']?.value ?? 0,
    );
  }

  /// Normalize text
  String _normalizeText(String text) {
    return text
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(':', ' ')
      .replaceAll('/', ' ')
      .trim();
  }

  /// Split text ke lines (by newline atau pattern)
  List<String> _splitToLines(String text) {
    // Try to split by common delimiters
    var lines = text.split(RegExp(r'[\n\r]+'));
    
    // If only 1 line, try to split by keyword boundaries
    if (lines.length <= 2) {
      lines = _smartSplit(text);
    }
    
    return lines
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();
  }

  /// Smart split berdasarkan keyword nutrisi
  List<String> _smartSplit(String text) {
    final result = <String>[];
    final keywords = [
      'energi total', 'total energy', 'energi dari',
      'lemak total', 'total fat', 'lemak jenuh', 'lemak trans',
      'karbohidrat total', 'total carbohydrate',
      'gula', 'sugar', 'serat', 'fiber',
      'protein', 'garam', 'natrium', 'sodium',
      'kolesterol', 'cholesterol',
      'vitamin a', 'vitamin b', 'vitamin c', 'vitamin d', 'vitamin e',
      'kalsium', 'calcium', 'zat besi', 'iron', 'seng', 'zinc',
    ];
    
    String remaining = text;
    for (final kw in keywords) {
      final idx = remaining.toLowerCase().indexOf(kw);
      if (idx > 0) {
        result.add(remaining.substring(0, idx).trim());
        remaining = remaining.substring(idx);
      }
    }
    if (remaining.isNotEmpty) {
      result.add(remaining.trim());
    }
    
    return result.isEmpty ? [text] : result;
  }

  /// Extract nutrient dari single line
  void _extractFromLine(String line, Map<String, ExtractedValue> extracted) {
    // Cek setiap nutrient definition
    for (final def in _nutrientDefinitions) {
      if (extracted.containsKey(def.key)) continue; // Already found
      
      // Fuzzy match keyword
      if (_fuzzyContains(line, def.keywords)) {
        // Extract value dengan unit yang sesuai
        final value = _extractValueFromLine(line, def.expectedUnits);
        if (value != null && value > 0) {
          extracted[def.key] = ExtractedValue(value: value, source: line);
          print('Found ${def.key}: $value from "$line"');
          
          // Also try to extract DV%
          if (def.dvKey != null) {
            final dv = _extractDVFromLine(line);
            if (dv != null && dv > 0) {
              extracted[def.dvKey!] = ExtractedValue(value: dv, source: line);
            }
          }
        }
      }
    }
  }

  /// Fuzzy contains - toleran terhadap typo
  bool _fuzzyContains(String text, List<String> keywords) {
    final lowerText = text.toLowerCase();
    
    for (final kw in keywords) {
      // Exact match
      if (lowerText.contains(kw)) return true;
      
      // Fuzzy match (1-2 karakter berbeda)
      if (_fuzzyMatch(lowerText, kw, maxDistance: 2)) return true;
    }
    
    return false;
  }

  /// Simple fuzzy match dengan Levenshtein-like check
  bool _fuzzyMatch(String text, String keyword, {int maxDistance = 2}) {
    // Skip jika keyword terlalu pendek
    if (keyword.length < 4) return text.contains(keyword);
    
    // Check setiap substring dengan panjang keyword
    for (int i = 0; i <= text.length - keyword.length; i++) {
      final sub = text.substring(i, i + keyword.length);
      int diff = 0;
      for (int j = 0; j < keyword.length && diff <= maxDistance; j++) {
        if (sub[j] != keyword[j]) diff++;
      }
      if (diff <= maxDistance) return true;
    }
    
    return false;
  }

  /// Extract numeric value dari line dengan expected units
  double? _extractValueFromLine(String line, List<String> expectedUnits) {
    // Pattern: number + unit
    for (final unit in expectedUnits) {
      final pattern = RegExp(
        r'(\d+(?:[,\.]\d+)?)\s*' + unit,
        caseSensitive: false,
      );
      final match = pattern.firstMatch(line);
      if (match != null) {
        return _parseNumber(match.group(1)!);
      }
    }
    
    // Fallback: just find any number
    final numPattern = RegExp(r'(\d+(?:[,\.]\d+)?)');
    final matches = numPattern.allMatches(line).toList();
    if (matches.isNotEmpty) {
      // Return first reasonable number
      for (final m in matches) {
        final val = _parseNumber(m.group(1)!);
        if (val > 0 && val < 10000) return val;
      }
    }
    
    return null;
  }

  /// Extract %DV dari line
  double? _extractDVFromLine(String line) {
    final pattern = RegExp(r'(\d+(?:[,\.]\d+)?)\s*%');
    final match = pattern.firstMatch(line);
    if (match != null) {
      final val = _parseNumber(match.group(1)!);
      if (val > 0 && val <= 200) return val;
    }
    return null;
  }

  /// Fallback: Extract dari full text
  void _extractFromFullText(String text, Map<String, ExtractedValue> extracted) {
    for (final def in _nutrientDefinitions) {
      if (extracted.containsKey(def.key)) continue;
      
      for (final kw in def.keywords) {
        // Pattern: keyword ... value unit
        final pattern = RegExp(
          kw + r'[^\d]{0,20}(\d+(?:[,\.]\d+)?)\s*(?:' + def.expectedUnits.join('|') + ')?',
          caseSensitive: false,
        );
        final match = pattern.firstMatch(text);
        if (match != null) {
          final value = _parseNumber(match.group(1)!);
          if (value > 0) {
            extracted[def.key] = ExtractedValue(value: value, source: 'fulltext');
            print('Found ${def.key} (fallback): $value');
            break;
          }
        }
      }
    }
  }

  /// Extract serving size
  String _extractServingSize(String text) {
    final patterns = [
      RegExp(r'takaran saji\s*(\d+\s*g?\s*\([^)]+\))', caseSensitive: false),
      RegExp(r'takaran saji\s*(\d+\s*(?:g|ml|gram))', caseSensitive: false),
      RegExp(r'serving size\s*(\d+\s*(?:g|ml))', caseSensitive: false),
    ];
    
    for (final p in patterns) {
      final m = p.firstMatch(text);
      if (m != null) return m.group(1)?.trim() ?? '';
    }
    return '';
  }

  /// Extract servings per container
  int _extractServingsPerContainer(String text) {
    final patterns = [
      RegExp(r'(\d+)\s*sajian', caseSensitive: false),
      RegExp(r'(\d+)\s*serving', caseSensitive: false),
    ];
    
    for (final p in patterns) {
      final m = p.firstMatch(text);
      if (m != null) return int.tryParse(m.group(1) ?? '0') ?? 0;
    }
    return 0;
  }

  /// Parse number string
  double _parseNumber(String s) {
    return double.tryParse(s.replaceAll(',', '.')) ?? 0;
  }

  /// Nutrient definitions dengan keywords dan expected units
  static final _nutrientDefinitions = <_NutrientDef>[
    // Energy
    _NutrientDef('calories', ['energi total', 'total energy', 'energi', 'energy', 'kalori', 'calorie'], ['kkal', 'kcal', 'cal']),
    _NutrientDef('caloriesFromFat', ['energi dari lemak', 'energy from fat', 'kalori dari lemak'], ['kkal', 'kcal']),
    _NutrientDef('caloriesFromSatFat', ['energi dari lemak jenuh'], ['kkal', 'kcal']),
    
    // Fat
    _NutrientDef('fat', ['lemak total', 'total fat', 'lemak'], ['g', 'gram'], dvKey: 'fatDV'),
    _NutrientDef('saturatedFat', ['lemak jenuh', 'saturated fat', 'saturated'], ['g', 'gram'], dvKey: 'saturatedFatDV'),
    _NutrientDef('transFat', ['lemak trans', 'trans fat'], ['g', 'gram']),
    _NutrientDef('cholesterol', ['kolesterol', 'cholesterol'], ['mg', 'miligram'], dvKey: 'cholesterolDV'),
    
    // Carbs
    _NutrientDef('carbs', ['karbohidrat total', 'total carbohydrate', 'karbohidrat', 'carbohydrate'], ['g', 'gram'], dvKey: 'carbsDV'),
    _NutrientDef('sugar', ['gula total', 'total sugar', 'gula', 'sugar'], ['g', 'gram']),
    _NutrientDef('addedSugar', ['gula tambahan', 'added sugar'], ['g', 'gram']),
    _NutrientDef('fiber', ['serat pangan', 'dietary fiber', 'serat', 'fiber'], ['g', 'gram'], dvKey: 'fiberDV'),
    
    // Protein & Sodium
    _NutrientDef('protein', ['protein'], ['g', 'gram'], dvKey: 'proteinDV'),
    _NutrientDef('sodium', ['garam natrium', 'garam', 'natrium', 'sodium', 'salt'], ['mg', 'miligram'], dvKey: 'sodiumDV'),
    
    // Vitamins
    _NutrientDef('vitaminA', ['vitamin a', 'vit a'], ['%', 'mcg', 'µg', 'iu']),
    _NutrientDef('vitaminB1', ['vitamin b1', 'thiamin', 'tiamin'], ['%', 'mg']),
    _NutrientDef('vitaminB2', ['vitamin b2', 'riboflavin'], ['%', 'mg']),
    _NutrientDef('vitaminB3', ['vitamin b3', 'niasin', 'niacin'], ['%', 'mg']),
    _NutrientDef('vitaminB6', ['vitamin b6', 'piridoksin'], ['%', 'mg']),
    _NutrientDef('vitaminB12', ['vitamin b12', 'kobalamin'], ['%', 'mcg']),
    _NutrientDef('vitaminC', ['vitamin c', 'vit c'], ['%', 'mg']),
    _NutrientDef('vitaminD', ['vitamin d', 'vit d'], ['%', 'mcg', 'iu']),
    _NutrientDef('vitaminE', ['vitamin e', 'vit e'], ['%', 'mg', 'iu']),
    
    // Minerals
    _NutrientDef('calcium', ['kalsium', 'calcium'], ['%', 'mg']),
    _NutrientDef('iron', ['zat besi', 'iron', 'besi'], ['%', 'mg']),
    _NutrientDef('zinc', ['seng', 'zinc'], ['%', 'mg']),
    _NutrientDef('phosphorus', ['fosfor', 'phosphorus'], ['%', 'mg']),
  ];
}

class _NutrientDef {
  final String key;
  final List<String> keywords;
  final List<String> expectedUnits;
  final String? dvKey;
  
  _NutrientDef(this.key, this.keywords, this.expectedUnits, {this.dvKey});
}

class ExtractedValue {
  final double value;
  final String source;
  
  ExtractedValue({required this.value, required this.source});
}
