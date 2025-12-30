import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _handleStart(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/health-input');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Logo Section
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: AppTheme.buttonShadow,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Image.asset(
                      'assets/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              )
                  .animate()
                  .scale(duration: 500.ms, curve: Curves.easeOutBack)
                  .fadeIn(),
              const SizedBox(height: 20),
              Text(
                'NutriScan',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 8),
              Text(
                'Kenali nutrisi, jaga kesehatanmu',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms),
              const Spacer(flex: 1),
              // Illustration
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Food icons
                    Positioned(
                      top: 30,
                      left: 40,
                      child: _buildFoodIcon('🥗', 50),
                    ),
                    Positioned(
                      top: 50,
                      right: 50,
                      child: _buildFoodIcon('🍎', 40),
                    ),
                    Positioned(
                      bottom: 40,
                      left: 60,
                      child: _buildFoodIcon('🥛', 45),
                    ),
                    Positioned(
                      bottom: 30,
                      right: 40,
                      child: _buildFoodIcon('🍞', 42),
                    ),
                    // Center scan icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner,
                        size: 40,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 600.ms)
                  .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
              const Spacer(flex: 1),
              
              // Feature highlights
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildFeatureRow(Icons.camera_alt_outlined, 'Scan label nutrisi dengan kamera'),
                    const SizedBox(height: 12),
                    _buildFeatureRow(Icons.analytics_outlined, 'Analisis risiko kesehatan otomatis'),
                    const SizedBox(height: 12),
                    _buildFeatureRow(Icons.person_outline, 'Rekomendasi sesuai kondisimu'),
                  ],
                ),
              ).animate().fadeIn(delay: 500.ms),
              
              const Spacer(flex: 1),
              // Single Start Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _handleStart(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Mulai Sekarang',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3, end: 0),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFoodIcon(String emoji, double size) {
    return Text(
      emoji,
      style: TextStyle(fontSize: size),
    )
        .animate(
          onPlay: (controller) => controller.repeat(reverse: true),
        )
        .moveY(
          begin: 0,
          end: -8,
          duration: 2000.ms,
          curve: Curves.easeInOut,
        );
  }
}
