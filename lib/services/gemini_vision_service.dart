import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/nutrition_data.dart';
import '../config/api_config.dart';

/// Gemini Vision API Service untuk Nutrition Label Scanning
/// Menggunakan Google Gemini 2.5 Flash untuk akurasi tinggi
class GeminiVisionService {
  static String get _apiKey => ApiConfig.geminiApiKey;
  static String get _baseUrl => ApiConfig.geminiBaseUrl;

  /// Extract nutrition data dari gambar menggunakan Gemini Vision
  Future<GeminiNutritionResult> extractNutrition(File imageFile) async {
    try {
      print('=== GEMINI: Starting extraction ===');
      print('Image path: ${imageFile.path}');
      print('API Key: ${_apiKey.substring(0, 10)}...');
      
      // Read image dan convert ke base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      print('Image size: ${bytes.length} bytes');
      print('Base64 length: ${base64Image.length}');
      
      // Determine mime type
      final extension = imageFile.path.split('.').last.toLowerCase();
      final mimeType = extension == 'png' ? 'image/png' : 'image/jpeg';
      print('MIME type: $mimeType');
      
      final url = '$_baseUrl?key=$_apiKey';
      print('URL: $url');
      
      // Build request body
      final requestBody = {
        'contents': [{
          'parts': [
            {'text': _buildPrompt()},
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': base64Image,
              }
            }
          ]
        }],
        'generationConfig': {
          'temperature': 0.1,
          'maxOutputTokens': 2048,
        }
      };
      
      print('=== GEMINI: Sending request ===');
      
      // Make HTTP request with timeout
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          print('=== GEMINI: Request timeout! ===');
          throw Exception('Request timeout after 60 seconds');
        },
      );

      print('=== GEMINI: Response received ===');
      print('Status code: ${response.statusCode}');
      print('Response body length: ${response.body.length}');

      if (response.statusCode == 200) {
        print('=== GEMINI: Parsing response ===');
        final json = jsonDecode(response.body);
        return _parseResponse(json);
      } else {
        print('=== GEMINI: API Error ===');
        print('Status: ${response.statusCode}');
        print('Body: ${response.body}');
        return GeminiNutritionResult(
          success: false,
          error: 'API Error ${response.statusCode}: ${response.body}',
          rawText: response.body,
        );
      }
    } on SocketException catch (e) {
      print('=== GEMINI: SocketException (No Internet?) ===');
      print('Error: $e');
      return GeminiNutritionResult(
        success: false,
        error: 'No internet connection: $e',
      );
    } on HttpException catch (e) {
      print('=== GEMINI: HttpException ===');
      print('Error: $e');
      return GeminiNutritionResult(
        success: false,
        error: 'HTTP error: $e',
      );
    } catch (e) {
      print('=== GEMINI: General Error ===');
      print('Error type: ${e.runtimeType}');
      print('Error: $e');
      return GeminiNutritionResult(
        success: false,
        error: 'Error: $e',
      );
    }
  }

  /// Build prompt untuk Gemini - lengkap untuk label susu
  String _buildPrompt() {
    return '''Ekstrak informasi nutrisi dari gambar label Nutrition Facts/Informasi Nilai Gizi ini.

Kembalikan HANYA JSON (tanpa markdown code block, tanpa penjelasan) dengan format:
{
  "servingSize": "string atau null",
  "servingsPerContainer": number atau null,
  "calories": number atau 0,
  "caloriesFromFat": number atau 0,
  "fat": number atau 0,
  "saturatedFat": number atau 0,
  "transFat": number atau 0,
  "cholesterol": number atau 0,
  "protein": number atau 0,
  "carbs": number atau 0,
  "fiber": number atau 0,
  "sugar": number atau 0,
  "addedSugar": number atau 0,
  "sodium": number atau 0,
  "vitaminA": number atau 0,
  "vitaminB1": number atau 0,
  "vitaminB2": number atau 0,
  "vitaminB3": number atau 0,
  "vitaminB6": number atau 0,
  "vitaminB12": number atau 0,
  "vitaminC": number atau 0,
  "vitaminD": number atau 0,
  "vitaminE": number atau 0,
  "calcium": number atau 0,
  "iron": number atau 0,
  "zinc": number atau 0,
  "phosphorus": number atau 0,
  "fatDV": number atau 0,
  "saturatedFatDV": number atau 0,
  "cholesterolDV": number atau 0,
  "carbsDV": number atau 0,
  "fiberDV": number atau 0,
  "proteinDV": number atau 0,
  "sodiumDV": number atau 0,
  "productName": "string atau null"
}

PENTING:
- sodium/garam/natrium dalam MILLIGRAM (mg)
- gula dalam GRAM (g)
- vitamin/mineral biasanya dalam %AKG atau %DV
- Jika tidak terbaca atau tidak ada, isi 0
- JANGAN buat markdown code block, langsung JSON saja''';
  }

  /// Parse response dari Gemini
  GeminiNutritionResult _parseResponse(Map<String, dynamic> json) {
    try {
      final candidates = json['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        print('=== GEMINI: No candidates ===');
        return GeminiNutritionResult(
          success: false,
          error: 'No response from Gemini',
        );
      }

      final content = candidates[0]['content'];
      final parts = content['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        print('=== GEMINI: No parts ===');
        return GeminiNutritionResult(
          success: false,
          error: 'Empty response from Gemini',
        );
      }

      final text = parts[0]['text'] as String;
      print('=== GEMINI RESPONSE TEXT ===');
      print(text);
      print('============================');

      // Extract JSON - handle markdown code blocks
      String jsonStr = text;
      
      // Remove markdown code blocks if present
      if (text.contains('```json')) {
        final match = RegExp(r'```json\s*([\s\S]*?)\s*```').firstMatch(text);
        if (match != null) {
          jsonStr = match.group(1)!;
        }
      } else if (text.contains('```')) {
        final match = RegExp(r'```\s*([\s\S]*?)\s*```').firstMatch(text);
        if (match != null) {
          jsonStr = match.group(1)!;
        }
      }
      
      // Find JSON object
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(jsonStr);
      if (jsonMatch == null) {
        print('=== GEMINI: No JSON found ===');
        return GeminiNutritionResult(
          success: false,
          error: 'No JSON found in response',
          rawText: text,
        );
      }

      final nutritionJson = jsonDecode(jsonMatch.group(0)!);
      print('=== GEMINI: JSON Parsed ===');
      print(nutritionJson);

      // Build NutritionData
      final nutritionData = NutritionData(
        servingSize: nutritionJson['servingSize']?.toString() ?? '',
        servingsPerContainer: _parseInt(nutritionJson['servingsPerContainer']),
        calories: _parseDouble(nutritionJson['calories']),
        caloriesFromFat: _parseDouble(nutritionJson['caloriesFromFat']),
        caloriesFromSatFat: _parseDouble(nutritionJson['caloriesFromSatFat']),
        fat: _parseDouble(nutritionJson['fat']),
        saturatedFat: _parseDouble(nutritionJson['saturatedFat']),
        transFat: _parseDouble(nutritionJson['transFat']),
        cholesterol: _parseDouble(nutritionJson['cholesterol']),
        carbs: _parseDouble(nutritionJson['carbs']),
        fiber: _parseDouble(nutritionJson['fiber']),
        sugar: _parseDouble(nutritionJson['sugar']),
        addedSugar: _parseDouble(nutritionJson['addedSugar']),
        protein: _parseDouble(nutritionJson['protein']),
        sodium: _parseDouble(nutritionJson['sodium']),
        vitaminA: _parseDouble(nutritionJson['vitaminA']),
        vitaminB1: _parseDouble(nutritionJson['vitaminB1']),
        vitaminB2: _parseDouble(nutritionJson['vitaminB2']),
        vitaminB3: _parseDouble(nutritionJson['vitaminB3']),
        vitaminB6: _parseDouble(nutritionJson['vitaminB6']),
        vitaminB12: _parseDouble(nutritionJson['vitaminB12']),
        vitaminC: _parseDouble(nutritionJson['vitaminC']),
        vitaminD: _parseDouble(nutritionJson['vitaminD']),
        vitaminE: _parseDouble(nutritionJson['vitaminE']),
        calcium: _parseDouble(nutritionJson['calcium']),
        iron: _parseDouble(nutritionJson['iron']),
        zinc: _parseDouble(nutritionJson['zinc']),
        phosphorus: _parseDouble(nutritionJson['phosphorus']),
        fatDV: _parseDouble(nutritionJson['fatDV']),
        saturatedFatDV: _parseDouble(nutritionJson['saturatedFatDV']),
        cholesterolDV: _parseDouble(nutritionJson['cholesterolDV']),
        carbsDV: _parseDouble(nutritionJson['carbsDV']),
        fiberDV: _parseDouble(nutritionJson['fiberDV']),
        proteinDV: _parseDouble(nutritionJson['proteinDV']),
        sodiumDV: _parseDouble(nutritionJson['sodiumDV']),
      );

      print('=== GEMINI: Success! ===');
      return GeminiNutritionResult(
        success: true,
        nutritionData: nutritionData,
        productName: nutritionJson['productName']?.toString(),
        rawText: text,
      );
    } catch (e) {
      print('=== GEMINI: Parse error ===');
      print('Error: $e');
      return GeminiNutritionResult(
        success: false,
        error: 'Parse error: $e',
      );
    }
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.')) ?? 0;
    }
    return 0;
  }

  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

/// Result dari Gemini Vision extraction
class GeminiNutritionResult {
  final bool success;
  final NutritionData? nutritionData;
  final String? productName;
  final String? error;
  final String? rawText;

  GeminiNutritionResult({
    required this.success,
    this.nutritionData,
    this.productName,
    this.error,
    this.rawText,
  });
}
