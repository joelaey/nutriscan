import 'dart:io';
import '../models/nutrition_data.dart';
import '../models/user_data.dart';
import '../models/scan_result.dart';
import 'nutrition_parser.dart';
import 'risk_analyzer.dart';
import 'ocr_service_mobile.dart';
import 'gemini_vision_service.dart';

/// Hasil scan dari NutriScanService
class NutriScanResult {
  final NutritionData nutrition;
  final RiskAnalysisResult analysis;
  final String rawOcrText;
  final DateTime scanTime;
  final String? imagePath;
  final String? productName;
  final bool usedGemini; // Flag apakah menggunakan Gemini atau offline

  NutriScanResult({
    required this.nutrition,
    required this.analysis,
    required this.rawOcrText,
    required this.scanTime,
    this.imagePath,
    this.productName,
    this.usedGemini = false,
  });

  /// Convert to ScanResult model for storage
  /// PENTING: Semua parameter nutrisi ditampilkan, yang tidak ter-scan nilainya kosong (-)
  ScanResult toScanResult({String? overrideProductName}) {
    return ScanResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      productName: overrideProductName ?? productName ?? 'Produk Scan',
      scanDate: scanTime,
      status: _convertRiskStatus(analysis.overallRisk),
      nutrients: _convertNutrients(),
      warningMessage: analysis.summary,
      imageUrl: imagePath,
      servingInfo: _getServingInfo(),
    );
  }

  RiskStatus _convertRiskStatus(RiskLevel level) {
    switch (level) {
      case RiskLevel.safe:
        return RiskStatus.safe;
      case RiskLevel.caution:
        return RiskStatus.caution;
      case RiskLevel.danger:
        return RiskStatus.danger;
    }
  }

  /// Get serving info
  Map<String, String> _getServingInfo() {
    return {
      'Takaran Saji': nutrition.servingSize.isNotEmpty ? nutrition.servingSize : '-',
      'Sajian per Kemasan': nutrition.servingsPerContainer > 0 
          ? '${nutrition.servingsPerContainer}' 
          : '-',
    };
  }

  /// Convert nutrients to display items
  /// HANYA menampilkan nutrisi yang terdeteksi (value > 0)
  /// Urutan sesuai standard label Indonesia (BPOM format)
  List<NutritionItem> _convertNutrients() {
    final items = <NutritionItem>[];
    
    // Helper function untuk add item jika value > 0
    void addIfDetected({
      required String name,
      required double value,
      required String unit,
      bool isHigh = false,
      double? dailyValuePercent,
      String? category,
    }) {
      if (value > 0) {
        items.add(NutritionItem(
          name: name,
          value: value,
          unit: unit,
          isHigh: isHigh,
          dailyValuePercent: dailyValuePercent,
          category: category,
        ));
      }
    }

    // === URUTAN SESUAI LABEL INDONESIA (BPOM) ===
    
    // 1. Energi Total
    addIfDetected(
      name: 'Energi Total',
      value: nutrition.calories,
      unit: 'kkal',
      isHigh: analysis.warnings.any((w) => w.nutrient == 'Kalori'),
      dailyValuePercent: nutrition.calories > 0 ? (nutrition.calories / 2150) * 100 : null,
      category: 'Energi',
    );
    
    // 2. Energi dari Lemak
    addIfDetected(
      name: 'Energi dari Lemak',
      value: nutrition.caloriesFromFat,
      unit: 'kkal',
      category: 'Energi',
    );

    // 3. Lemak Total
    addIfDetected(
      name: 'Lemak Total',
      value: nutrition.fat,
      unit: 'g',
      isHigh: analysis.warnings.any((w) => w.nutrient == 'Lemak Total'),
      dailyValuePercent: nutrition.fatDV > 0 ? nutrition.fatDV : null,
      category: 'Lemak',
    );

    // 4. Lemak Jenuh
    addIfDetected(
      name: 'Lemak Jenuh',
      value: nutrition.saturatedFat,
      unit: 'g',
      isHigh: analysis.warnings.any((w) => w.nutrient == 'Lemak Jenuh'),
      dailyValuePercent: nutrition.saturatedFatDV > 0 ? nutrition.saturatedFatDV : null,
      category: 'Lemak',
    );

    // 5. Lemak Trans
    addIfDetected(
      name: 'Lemak Trans',
      value: nutrition.transFat,
      unit: 'g',
      isHigh: nutrition.transFat > 0, // Trans fat selalu warning jika ada
      category: 'Lemak',
    );

    // 6. Kolesterol
    addIfDetected(
      name: 'Kolesterol',
      value: nutrition.cholesterol,
      unit: 'mg',
      isHigh: analysis.warnings.any((w) => w.nutrient == 'Kolesterol'),
      dailyValuePercent: nutrition.cholesterolDV > 0 ? nutrition.cholesterolDV : null,
      category: 'Lemak',
    );

    // 7. Protein
    addIfDetected(
      name: 'Protein',
      value: nutrition.protein,
      unit: 'g',
      dailyValuePercent: nutrition.proteinDV > 0 ? nutrition.proteinDV : null,
      category: 'Protein',
    );

    // 8. Karbohidrat Total
    addIfDetected(
      name: 'Karbohidrat Total',
      value: nutrition.carbs,
      unit: 'g',
      dailyValuePercent: nutrition.carbsDV > 0 ? nutrition.carbsDV : null,
      category: 'Karbohidrat',
    );

    // 9. Serat Pangan
    addIfDetected(
      name: 'Serat Pangan',
      value: nutrition.fiber,
      unit: 'g',
      dailyValuePercent: nutrition.fiberDV > 0 ? nutrition.fiberDV : null,
      category: 'Karbohidrat',
    );

    // 10. Gula
    addIfDetected(
      name: 'Gula',
      value: nutrition.sugar,
      unit: 'g',
      isHigh: analysis.warnings.any((w) => w.nutrient == 'Gula'),
      category: 'Karbohidrat',
    );

    // 11. Gula Tambahan
    addIfDetected(
      name: 'Gula Tambahan',
      value: nutrition.addedSugar,
      unit: 'g',
      isHigh: nutrition.addedSugar > 10,
      category: 'Karbohidrat',
    );

    // 12. Garam (Natrium)
    addIfDetected(
      name: 'Garam (Natrium)',
      value: nutrition.sodium,
      unit: 'mg',
      isHigh: analysis.warnings.any((w) => w.nutrient.contains('Garam')),
      dailyValuePercent: nutrition.sodiumDV > 0 ? nutrition.sodiumDV : null,
      category: 'Mineral',
    );

    // === VITAMIN (jika ada) ===
    addIfDetected(name: 'Vitamin A', value: nutrition.vitaminA, unit: '%AKG', category: 'Vitamin');
    addIfDetected(name: 'Vitamin B1', value: nutrition.vitaminB1, unit: '%AKG', category: 'Vitamin');
    addIfDetected(name: 'Vitamin B2', value: nutrition.vitaminB2, unit: '%AKG', category: 'Vitamin');
    addIfDetected(name: 'Vitamin B3', value: nutrition.vitaminB3, unit: '%AKG', category: 'Vitamin');
    addIfDetected(name: 'Vitamin B6', value: nutrition.vitaminB6, unit: '%AKG', category: 'Vitamin');
    addIfDetected(name: 'Vitamin B12', value: nutrition.vitaminB12, unit: '%AKG', category: 'Vitamin');
    addIfDetected(name: 'Vitamin C', value: nutrition.vitaminC, unit: '%AKG', category: 'Vitamin');
    addIfDetected(name: 'Vitamin D', value: nutrition.vitaminD, unit: '%AKG', category: 'Vitamin');
    addIfDetected(name: 'Vitamin E', value: nutrition.vitaminE, unit: '%AKG', category: 'Vitamin');

    // === MINERAL (jika ada) ===
    addIfDetected(name: 'Kalsium', value: nutrition.calcium, unit: '%AKG', category: 'Mineral');
    addIfDetected(name: 'Zat Besi', value: nutrition.iron, unit: '%AKG', category: 'Mineral');
    addIfDetected(name: 'Seng', value: nutrition.zinc, unit: '%AKG', category: 'Mineral');
    addIfDetected(name: 'Fosfor', value: nutrition.phosphorus, unit: '%AKG', category: 'Mineral');

    return items;
  }

  bool get isSafe => analysis.isSafe;
  List<String> get warnings => analysis.warnings.map((w) => w.message).toList();
}

/// End-to-End NutriScan Service
/// Menggunakan Gemini Vision API (primary) dengan fallback ke ML Kit (offline)
class NutriScanService {
  final NutritionParser _parser = NutritionParser();
  final RiskAnalyzer _analyzer = RiskAnalyzer();
  final GeminiVisionService _geminiService = GeminiVisionService();
  OCRServiceMobile? _ocrService;

  /// Process image - Gemini primary, ML Kit fallback
  Future<NutriScanResult?> processImage({
    required File image,
    required UserData userData,
    String? productName,
  }) async {
    try {
      // Try Gemini Vision first (better accuracy)
      print('=== Trying Gemini Vision API ===');
      final geminiResult = await _geminiService.extractNutrition(image);
      
      if (geminiResult.success && geminiResult.nutritionData != null) {
        print('=== Gemini Success! ===');
        
        final analysis = _analyzer.analyze(
          nutrition: geminiResult.nutritionData!,
          userData: userData,
        );

        return NutriScanResult(
          nutrition: geminiResult.nutritionData!,
          analysis: analysis,
          rawOcrText: geminiResult.rawText ?? 'Gemini Vision',
          scanTime: DateTime.now(),
          imagePath: image.path,
          productName: productName ?? geminiResult.productName,
          usedGemini: true,
        );
      }
      
      // Fallback ke ML Kit offline
      print('=== Gemini failed, trying ML Kit offline ===');
      print('Gemini error: ${geminiResult.error}');
      
      return await _processWithMLKit(
        image: image,
        userData: userData,
        productName: productName,
      );
    } catch (e) {
      print('NutriScan Error: $e');
      // Fallback ke ML Kit
      return await _processWithMLKit(
        image: image,
        userData: userData,
        productName: productName,
      );
    }
  }

  /// Process dengan ML Kit (offline fallback)
  Future<NutriScanResult?> _processWithMLKit({
    required File image,
    required UserData userData,
    String? productName,
  }) async {
    try {
      // 1. OCR - Extract text dari gambar
      final rawText = await _extractText(image);
      
      print('=== ML Kit OCR Result ===');
      print(rawText);
      print('=========================');
      
      if (rawText.isEmpty) {
        print('OCR returned empty text');
        return null;
      }
      
      // 2. Parse - Convert raw text ke structured data
      final nutrition = _parser.parse(rawText);
      
      // 3. Analyze - Evaluasi risiko berdasarkan kondisi user
      final analysis = _analyzer.analyze(
        nutrition: nutrition,
        userData: userData,
      );

      return NutriScanResult(
        nutrition: nutrition,
        analysis: analysis,
        rawOcrText: rawText,
        scanTime: DateTime.now(),
        imagePath: image.path,
        productName: productName,
        usedGemini: false,
      );
    } catch (e) {
      print('ML Kit Error: $e');
      return null;
    }
  }

  /// Extract text using OCR with ML Kit
  Future<String> _extractText(File image) async {
    try {
      _ocrService ??= OCRServiceMobile();
      final text = await _ocrService!.extractText(image);
      return text;
    } catch (e) {
      print('OCR Error: $e');
      return '';
    }
  }

  /// Clean up resources
  void dispose() {
    _ocrService?.dispose();
    _ocrService = null;
  }

  /// Create mock result for testing (when OCR fails or returns no data)
  /// Contoh format label Indonesia (berdasarkan BPOM)
  NutriScanResult createMockResult(UserData userData, {String? productName}) {
    // Simulate OCR text - Format Indonesia BPOM
    final mockText = '''
    INFORMASI NILAI GIZI / NUTRITION FACTS
    Takaran Saji / Serving Size: 25g (3 keping)
    26 Sajian per Kemasan / Serving per Container
    
    JUMLAH PER SAJIAN / AMOUNT PER SERVING
    Energi Total / Total Energy 120 kkal
    Energi dari Lemak / Energy from Fat 45 kkal
    Energi dari Lemak Jenuh / Energy from Saturated Fat 20 kkal
    
                                    %AKG*/%DV*
    Lemak Total / Total Fat        5 g    8%
    Kolesterol / Cholesterol       0 mg   0%
    Lemak Jenuh / Saturated Fat    2 g   10%
    Protein                        1 g    2%
    Karbohidrat Total              18 g   5%
    Serat Pangan / Dietary Fiber   1 g    5%
    Gula / Sugar                   7 g
    Garam (Natrium) / Salt         60 mg  4%
    
    *) Persen AKG berdasarkan kebutuhan energi 2150 kkal
    ''';

    final nutrition = _parser.parse(mockText);
    final analysis = _analyzer.analyze(
      nutrition: nutrition,
      userData: userData,
    );

    return NutriScanResult(
      nutrition: nutrition,
      analysis: analysis,
      rawOcrText: mockText,
      scanTime: DateTime.now(),
      productName: productName,
    );
  }
}
