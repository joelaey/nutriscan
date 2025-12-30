import 'dart:io';
import 'dart:math';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

/// Advanced OCR Service dengan Multi-Pass Recognition
/// Menggunakan berbagai teknik preprocessing untuk akurasi maksimal
/// 
/// Strategi:
/// 1. Multi-pass dengan berbagai level preprocessing
/// 2. Block-based text extraction (memahami struktur)
/// 3. Line grouping untuk format tabel
/// 4. Confidence scoring untuk pilih hasil terbaik
class OCRServiceMobile {
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  /// Extract text dengan multi-pass untuk akurasi maksimal
  Future<String> extractText(File image) async {
    try {
      // Strategy: Coba berbagai preprocessing dan pilih hasil terbaik
      final results = <OCRResult>[];
      
      // Pass 1: Original image (untuk gambar yang sudah bagus)
      results.add(await _extractWithConfig(image, 'original'));
      
      // Pass 2: High contrast + sharpen (untuk blur)
      results.add(await _extractWithPreprocessing(image, 
        contrast: 1.5, sharpen: true, name: 'high_contrast'));
      
      // Pass 3: Grayscale + normalize (untuk lighting tidak merata)
      results.add(await _extractWithPreprocessing(image,
        grayscale: true, normalize: true, name: 'grayscale'));
      
      // Pass 4: Binarization (untuk teks dengan background kompleks)
      results.add(await _extractWithPreprocessing(image,
        binarize: true, threshold: 128, name: 'binarize'));
      
      // Pilih hasil terbaik berdasarkan scoring
      final bestResult = _selectBestResult(results);
      
      print('=== BEST OCR RESULT (${bestResult.configName}) ===');
      print('Score: ${bestResult.score}');
      print('Text length: ${bestResult.text.length}');
      print(bestResult.text);
      print('==================');
      
      return bestResult.text;
    } catch (e) {
      print('OCR Error: $e');
      return await _fallbackExtract(image);
    }
  }

  /// Extract dengan block structure untuk tabel
  Future<OCRTableResult> extractWithStructure(File image) async {
    try {
      // Preprocess untuk tabel
      final processedFile = await _preprocessForTable(image);
      final inputImage = InputImage.fromFile(processedFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      // Clean up
      if (processedFile.path != image.path) {
        try { await processedFile.delete(); } catch (_) {}
      }
      
      // Parse dengan struktur
      return _parseTableStructure(recognizedText);
    } catch (e) {
      print('Structure extraction error: $e');
      return OCRTableResult(rawText: '', lines: [], nutritionPairs: {});
    }
  }

  /// Extract dengan konfigurasi tertentu
  Future<OCRResult> _extractWithConfig(File image, String configName) async {
    try {
      final inputImage = InputImage.fromFile(image);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      final cleanText = _postProcessText(recognizedText.text);
      final score = _calculateScore(recognizedText, cleanText);
      
      return OCRResult(
        text: cleanText, 
        configName: configName, 
        score: score,
        blockCount: recognizedText.blocks.length,
      );
    } catch (e) {
      return OCRResult(text: '', configName: configName, score: 0, blockCount: 0);
    }
  }

  /// Extract dengan preprocessing tertentu
  Future<OCRResult> _extractWithPreprocessing(
    File imageFile, {
    double contrast = 1.0,
    double brightness = 1.0,
    bool sharpen = false,
    bool grayscale = false,
    bool normalize = false,
    bool binarize = false,
    int threshold = 128,
    required String name,
  }) async {
    File? processedFile;
    try {
      final bytes = await imageFile.readAsBytes();
      var image = img.decodeImage(bytes);
      if (image == null) {
        return OCRResult(text: '', configName: name, score: 0, blockCount: 0);
      }
      
      // Apply transformations
      if (grayscale) {
        image = img.grayscale(image);
      }
      
      if (contrast != 1.0 || brightness != 1.0) {
        image = img.adjustColor(image, 
          contrast: contrast, 
          brightness: brightness,
        );
      }
      
      if (normalize) {
        image = img.normalize(image, min: 0, max: 255);
      }
      
      if (sharpen) {
        image = img.convolution(image, filter: [
          0, -1, 0,
          -1, 5, -1,
          0, -1, 0,
        ], div: 1);
      }
      
      if (binarize) {
        image = img.grayscale(image);
        // Simple threshold binarization
        for (int y = 0; y < image.height; y++) {
          for (int x = 0; x < image.width; x++) {
            final pixel = image.getPixel(x, y);
            final gray = img.getLuminance(pixel);
            if (gray > threshold) {
              image.setPixel(x, y, img.ColorRgba8(255, 255, 255, 255));
            } else {
              image.setPixel(x, y, img.ColorRgba8(0, 0, 0, 255));
            }
          }
        }
      }
      
      // Save and process
      final processedBytes = img.encodeJpg(image, quality: 95);
      final tempDir = Directory.systemTemp;
      processedFile = File('${tempDir.path}/ocr_${name}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await processedFile.writeAsBytes(processedBytes);
      
      final result = await _extractWithConfig(processedFile, name);
      
      return result;
    } catch (e) {
      return OCRResult(text: '', configName: name, score: 0, blockCount: 0);
    } finally {
      if (processedFile != null) {
        try { await processedFile.delete(); } catch (_) {}
      }
    }
  }

  /// Preprocessing khusus untuk tabel nutrisi
  Future<File> _preprocessForTable(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      var image = img.decodeImage(bytes);
      if (image == null) return imageFile;
      
      // Optimal untuk tabel: grayscale + high contrast + sharpen
      image = img.grayscale(image);
      image = img.adjustColor(image, contrast: 1.4, brightness: 1.05);
      image = img.normalize(image, min: 0, max: 255);
      image = img.convolution(image, filter: [
        0, -1, 0,
        -1, 5, -1,
        0, -1, 0,
      ], div: 1);
      
      final processedBytes = img.encodeJpg(image, quality: 95);
      final tempDir = Directory.systemTemp;
      final processedFile = File('${tempDir.path}/ocr_table_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await processedFile.writeAsBytes(processedBytes);
      
      return processedFile;
    } catch (e) {
      return imageFile;
    }
  }

  /// Parse struktur tabel dari RecognizedText
  OCRTableResult _parseTableStructure(RecognizedText recognizedText) {
    final lines = <OCRLine>[];
    final nutritionPairs = <String, String>{};
    
    // Group text by Y position (lines)
    final lineGroups = <int, List<TextElement>>{};
    
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final y = (line.boundingBox.top / 20).round() * 20; // Group by 20px
        lineGroups.putIfAbsent(y, () => []);
        
        for (final element in line.elements) {
          lineGroups[y]!.add(element);
        }
      }
    }
    
    // Sort each line by X position (left to right)
    lineGroups.forEach((y, elements) {
      elements.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
      
      final lineText = elements.map((e) => e.text).join(' ');
      lines.add(OCRLine(y: y.toDouble(), text: lineText, elements: elements));
      
      // Try to extract key-value pairs
      final pair = _extractKeyValuePair(lineText);
      if (pair != null) {
        nutritionPairs[pair.key] = pair.value;
      }
    });
    
    // Sort lines by Y position
    lines.sort((a, b) => a.y.compareTo(b.y));
    
    return OCRTableResult(
      rawText: recognizedText.text,
      lines: lines,
      nutritionPairs: nutritionPairs,
    );
  }

  /// Extract key-value pair dari line tabel
  _KeyValuePair? _extractKeyValuePair(String line) {
    // Pattern: "Nutrient Name   value unit   %DV"
    // Example: "Lemak Total     7 g         10%"
    
    final patterns = [
      // "Key value unit %"
      RegExp(r'^(.+?)\s+(\d+(?:[,\.]\d+)?)\s*(g|mg|kkal|kcal|mcg|µg)?\s*(\d+%)?$', caseSensitive: false),
      // "Key : value unit"
      RegExp(r'^(.+?)[\s:]+(\d+(?:[,\.]\d+)?)\s*(g|mg|kkal|kcal|mcg|µg)?', caseSensitive: false),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(line.trim());
      if (match != null) {
        final key = match.group(1)?.trim() ?? '';
        final value = match.group(2) ?? '';
        final unit = match.group(3) ?? '';
        
        if (key.isNotEmpty && value.isNotEmpty) {
          return _KeyValuePair(key: key.toLowerCase(), value: '$value$unit');
        }
      }
    }
    
    return null;
  }

  /// Calculate quality score untuk OCR result
  double _calculateScore(RecognizedText recognizedText, String cleanText) {
    double score = 0;
    
    // 1. Text length (lebih panjang = lebih baik, sampai batas tertentu)
    score += min(cleanText.length / 500, 1.0) * 30;
    
    // 2. Block count (lebih banyak block biasanya lebih terstruktur)
    score += min(recognizedText.blocks.length / 10, 1.0) * 20;
    
    // 3. Keyword presence (ada keyword nutrisi = lebih bagus)
    final keywords = [
      'energi', 'lemak', 'protein', 'karbohidrat', 'gula', 'garam', 
      'natrium', 'serat', 'kalori', 'vitamin', 'kalsium',
      'takaran', 'sajian', 'nutrisi', 'nilai gizi',
      'energy', 'fat', 'sugar', 'sodium', 'carbohydrate',
    ];
    
    int keywordCount = 0;
    final lowerText = cleanText.toLowerCase();
    for (final kw in keywords) {
      if (lowerText.contains(kw)) keywordCount++;
    }
    score += min(keywordCount / 10, 1.0) * 30;
    
    // 4. Number presence (nutrition facts harus ada angka)
    final numberMatches = RegExp(r'\d+').allMatches(cleanText).length;
    score += min(numberMatches / 20, 1.0) * 20;
    
    return score;
  }

  /// Pilih hasil OCR terbaik
  OCRResult _selectBestResult(List<OCRResult> results) {
    if (results.isEmpty) {
      return OCRResult(text: '', configName: 'none', score: 0, blockCount: 0);
    }
    
    // Sort by score descending
    results.sort((a, b) => b.score.compareTo(a.score));
    return results.first;
  }

  /// Fallback extraction
  Future<String> _fallbackExtract(File image) async {
    try {
      final inputImage = InputImage.fromFile(image);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      return _postProcessText(recognizedText.text);
    } catch (e) {
      return '';
    }
  }

  /// Post-process untuk fix OCR errors
  String _postProcessText(String text) {
    var cleanText = text;
    
    // Common OCR substitutions
    final substitutions = {
      // Numbers
      'O': '0', 'o': '0',
      'l': '1', 'I': '1', '|': '1',
      'S': '5', 's': '5',
      'B': '8',
      'Z': '2',
      'G': '6',
      
      // Indonesian keywords
      'gu1a': 'gula', 'guia': 'gula', 'gu|a': 'gula', '9ula': 'gula',
      'natr1um': 'natrium', 'natrIum': 'natrium', 'natrlum': 'natrium',
      'sod1um': 'sodium', 'sodlum': 'sodium',
      '1emak': 'lemak', 'Iemak': 'lemak', '|emak': 'lemak', 'lemok': 'lemak',
      'prote1n': 'protein', 'proteln': 'protein',
      'karbohi drat': 'karbohidrat', 'karboh1drat': 'karbohidrat',
      'ka1ori': 'kalori', 'kaIori': 'kalori',
      'energ1': 'energi', 'energl': 'energi',
      's3rat': 'serat', 'ser4t': 'serat',
      'ko1esterol': 'kolesterol', 'koIesterol': 'kolesterol',
      'v1tamin': 'vitamin', 'vltamin': 'vitamin',
      'ka1sium': 'kalsium', 'kaIsium': 'kalsium',
      'takaran saj1': 'takaran saji',
      
      // Units
      'kka1': 'kkal', 'kkaI': 'kkal', 'kkał': 'kkal',
      'm9': 'mg', 'mq': 'mg', 'rng': 'mg',
      '9ram': 'gram', 'qram': 'gram',
      
      // Fix spacing issues
      '  ': ' ',
    };
    
    substitutions.forEach((wrong, correct) {
      cleanText = cleanText.replaceAll(wrong, correct);
    });
    
    // Fix context-specific errors
    cleanText = _fixContextErrors(cleanText);
    
    return cleanText.trim();
  }

  /// Fix errors berdasarkan konteks
  String _fixContextErrors(String text) {
    // Fix "O" yang seharusnya "0" sebelum unit
    text = text.replaceAllMapped(
      RegExp(r'(\d*)O(\d*)\s*(g|mg|kkal|%)', caseSensitive: false),
      (m) => '${m.group(1)}0${m.group(2)} ${m.group(3)}',
    );
    
    // Fix "g" yang standalone setelah angka → keep as unit
    text = text.replaceAllMapped(
      RegExp(r'(\d+)\s*q\b'),
      (m) => '${m.group(1)} g',
    );
    
    return text;
  }

  void dispose() {
    _textRecognizer.close();
  }
}

/// Result dari single OCR pass
class OCRResult {
  final String text;
  final String configName;
  final double score;
  final int blockCount;
  
  OCRResult({
    required this.text,
    required this.configName,
    required this.score,
    required this.blockCount,
  });
}

/// Result dengan struktur tabel
class OCRTableResult {
  final String rawText;
  final List<OCRLine> lines;
  final Map<String, String> nutritionPairs;
  
  OCRTableResult({
    required this.rawText,
    required this.lines,
    required this.nutritionPairs,
  });
}

/// Single line dari tabel
class OCRLine {
  final double y;
  final String text;
  final List<TextElement> elements;
  
  OCRLine({required this.y, required this.text, required this.elements});
}

class _KeyValuePair {
  final String key;
  final String value;
  _KeyValuePair({required this.key, required this.value});
}
