import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../models/scan_result.dart';
import '../models/user_data.dart';
import '../services/storage_service.dart';
import '../services/nutri_scan_service.dart';

class ProcessingScreen extends StatefulWidget {
  final File? imageFile;
  final String? productName;
  
  const ProcessingScreen({
    super.key, 
    this.imageFile,
    this.productName,
  });

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  int _currentStep = 0;
  String _currentStepText = 'Mempersiapkan...';
  String? _ocrPreview;
  final List<String> _steps = [
    'Membaca label nutrisi (OCR)...',
    'Menganalisis kandungan...',
    'Mengevaluasi risiko kesehatan...',
  ];

  final NutriScanService _nutriscanService = NutriScanService();

  @override
  void initState() {
    super.initState();
    _startProcessing();
  }

  @override
  void dispose() {
    _nutriscanService.dispose();
    super.dispose();
  }

  Future<void> _startProcessing() async {
    final storage = await StorageService.getInstance();
    final userData = storage.getUserData() ?? UserData();

    // Step 1: Reading label with OCR
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() {
        _currentStep = 1;
        _currentStepText = _steps[0];
      });
    }

    // Process the actual image with OCR if provided
    ScanResult result;
    
    if (widget.imageFile != null) {
      try {
        final scanResult = await _nutriscanService.processImage(
          image: widget.imageFile!,
          userData: userData,
          productName: widget.productName,
        );
        
        // Step 2: Analyzing content
        if (mounted) {
          setState(() {
            _currentStep = 2;
            _currentStepText = _steps[1];
            if (scanResult != null) {
              _ocrPreview = scanResult.rawOcrText.isNotEmpty 
                  ? 'Text ditemukan: ${scanResult.rawOcrText.length} karakter'
                  : 'Tidak ada text terdeteksi';
            }
          });
        }
        
        await Future.delayed(const Duration(milliseconds: 800));
        
        // Step 3: Evaluating risk
        if (mounted) {
          setState(() {
            _currentStep = 3;
            _currentStepText = _steps[2];
          });
        }
        
        await Future.delayed(const Duration(milliseconds: 600));
        
        if (scanResult != null && scanResult.nutrition.hasData) {
          result = scanResult.toScanResult(overrideProductName: widget.productName);
        } else {
          // Fallback to mock if OCR fails or returns no data
          final mockResult = _nutriscanService.createMockResult(
            userData,
            productName: widget.productName,
          );
          result = mockResult.toScanResult(overrideProductName: widget.productName);
        }
      } catch (e) {
        print('Processing error: $e');
        // Step update even on error
        if (mounted) {
          setState(() {
            _currentStep = 2;
            _currentStepText = 'Menggunakan data sampel...';
          });
        }
        await Future.delayed(const Duration(milliseconds: 500));
        
        final mockResult = _nutriscanService.createMockResult(
          userData,
          productName: widget.productName,
        );
        result = mockResult.toScanResult(overrideProductName: widget.productName);
      }
    } else {
      // No image provided, use mock data
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        setState(() {
          _currentStep = 2;
          _currentStepText = _steps[1];
        });
      }
      
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        setState(() {
          _currentStep = 3;
          _currentStepText = _steps[2];
        });
      }
      
      await Future.delayed(const Duration(milliseconds: 400));
      
      final mockResult = _nutriscanService.createMockResult(
        userData,
        productName: widget.productName,
      );
      result = mockResult.toScanResult(overrideProductName: widget.productName);
    }

    // Save to history
    await storage.saveScanResult(result);

    // Navigate to result
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        '/result',
        arguments: result,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundColor,
              AppTheme.primaryLight.withOpacity(0.3),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // Animated scanning icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Rotating ring
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryColor,
                        ),
                        backgroundColor: AppTheme.primaryLight,
                      ),
                    )
                        .animate(
                          onPlay: (c) => c.repeat(),
                        )
                        .rotate(duration: 2000.ms),
                    // Center icon
                    const Icon(
                      Icons.document_scanner_outlined,
                      size: 40,
                      color: AppTheme.primaryColor,
                    )
                        .animate(
                          onPlay: (c) => c.repeat(reverse: true),
                        )
                        .scaleXY(
                          begin: 0.9,
                          end: 1.1,
                          duration: 1000.ms,
                          curve: Curves.easeInOut,
                        ),
                  ],
                ),
              ).animate().fadeIn().scale(
                    begin: const Offset(0.8, 0.8),
                    curve: Curves.easeOutBack,
                  ),
              const SizedBox(height: 40),

              // Product name if provided
              if (widget.productName != null && widget.productName!.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.productName!,
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ).animate().fadeIn(delay: 100.ms),
              if (widget.productName != null) const SizedBox(height: 16),

              // Processing text
              Text(
                'Menganalisis...',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 8),
              Text(
                _currentStepText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ).animate().fadeIn(delay: 300.ms),
              
              // OCR preview text
              if (_ocrPreview != null) ...[
                const SizedBox(height: 8),
                Text(
                  _ocrPreview!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryColor,
                      ),
                ),
              ],
              const SizedBox(height: 48),

              // Progress steps
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: _steps.asMap().entries.map((entry) {
                    final index = entry.key;
                    final step = entry.value;
                    final isCompleted = _currentStep > index;
                    final isCurrent = _currentStep == index + 1;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          // Status icon
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? AppTheme.primaryColor
                                  : isCurrent
                                      ? AppTheme.primaryLight
                                      : Colors.grey.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: isCompleted
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                : isCurrent
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            AppTheme.primaryColor,
                                          ),
                                        ),
                                      )
                                    : null,
                          ),
                          const SizedBox(width: 14),
                          // Step text
                          Expanded(
                            child: Text(
                              step,
                              style: TextStyle(
                                color: isCompleted || isCurrent
                                    ? AppTheme.textPrimary
                                    : AppTheme.textLight,
                                fontWeight: isCurrent
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
