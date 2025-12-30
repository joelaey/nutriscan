import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../models/scan_result.dart';
import '../models/user_data.dart';
import '../services/storage_service.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  ScanResult? _result;
  UserData? _userData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _result = ModalRoute.of(context)?.settings.arguments as ScanResult?;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final storage = await StorageService.getInstance();
    setState(() {
      _userData = storage.getUserData();
    });
  }

  void _scanAgain() {
    Navigator.pushReplacementNamed(context, '/scan');
  }

  void _goHome() {
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (_result == null) {
      return const Scaffold(
        body: Center(
          child: Text('Tidak ada data hasil'),
        ),
      );
    }

    final result = _result!;
    
    // Get status color and gradient
    Color statusColor;
    LinearGradient statusGradient;
    IconData statusIcon;
    
    switch (result.status) {
      case RiskStatus.safe:
        statusColor = AppTheme.safeColor;
        statusGradient = AppTheme.safeGradient;
        statusIcon = Icons.check_circle;
        break;
      case RiskStatus.caution:
        statusColor = AppTheme.cautionColor;
        statusGradient = AppTheme.cautionGradient;
        statusIcon = Icons.warning_rounded;
        break;
      case RiskStatus.danger:
        statusColor = AppTheme.dangerColor;
        statusGradient = AppTheme.dangerGradient;
        statusIcon = Icons.dangerous_rounded;
        break;
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Status Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                bottom: 30,
                left: 24,
                right: 24,
              ),
              decoration: BoxDecoration(
                gradient: statusGradient,
              ),
              child: Column(
                children: [
                  // Close button row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: _goHome,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Status icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Icon(
                      statusIcon,
                      size: 45,
                      color: statusColor,
                    ),
                  )
                      .animate()
                      .scale(
                        duration: 500.ms,
                        curve: Curves.easeOutBack,
                      )
                      .fadeIn(),
                  const SizedBox(height: 16),
                  // Status text
                  Text(
                    result.statusEmoji,
                    style: const TextStyle(fontSize: 28),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 8),
                  Text(
                    result.statusText,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
                  if (result.productName != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      result.productName!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ).animate().fadeIn(delay: 400.ms),
                  ],
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Serving Info Section
                  if (result.servingInfo != null) ...[
                    _buildServingInfoCard(result),
                    const SizedBox(height: 20),
                  ],

                  // Nutrition Facts Table Header
                  _buildNutritionFactsHeader(result),
                  const SizedBox(height: 12),

                  // Nutrition Facts Table - Indonesian Format
                  _buildNutritionFactsTable(result),
                  const SizedBox(height: 20),

                  // AKG Note
                  _buildAKGNote(),
                  const SizedBox(height: 20),

                  // Personal Warning
                  if (result.warningMessage != null) ...[
                    _buildSectionTitle('Rekomendasi Personal'),
                    const SizedBox(height: 12),
                    _buildWarningCard(result, statusColor),
                    const SizedBox(height: 24),
                  ],

                  // User conditions
                  if (_userData?.hasHealthConditions == true) ...[
                    _buildSectionTitle('Kondisi Kesehatanmu'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (_userData!.hasDiabetes)
                          _buildConditionChip('Diabetes', AppTheme.dangerColor),
                        if (_userData!.hasHypertension)
                          _buildConditionChip('Hipertensi', AppTheme.cautionColor),
                        if (_userData!.isOnDiet)
                          _buildConditionChip('Diet', AppTheme.primaryColor),
                      ],
                    ).animate().fadeIn(delay: 900.ms),
                    const SizedBox(height: 24),
                  ],

                  // Disclaimer
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info,
                          size: 18,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Aplikasi ini bukan pengganti diagnosis medis. Konsultasikan dengan dokter untuk rekomendasi kesehatan.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                  height: 1.3,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 1000.ms),
                  const SizedBox(height: 32),

                  // Action buttons
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _scanAgain,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text(
                        'Scan Lagi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 1100.ms)
                      .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _goHome,
                      icon: const Icon(Icons.home),
                      label: const Text(
                        'Kembali ke Home',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 1200.ms).slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServingInfoCard(ScanResult result) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.restaurant_menu, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Informasi Takaran',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Takaran Saji',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.servingSizeDisplay,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey.shade200,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sajian per Kemasan',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        result.servingsPerContainerDisplay,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildNutritionFactsHeader(ScanResult result) {
    return Row(
      children: [
        Text(
          'INFORMASI NILAI GIZI',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${result.scannedNutrientsCount}/${result.totalNutrientsCount}',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildNutritionFactsTable(ScanResult result) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Expanded(
                  flex: 3,
                  child: Text(
                    'Nutrisi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Nilai',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    '%AKG',
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 13,
                      color: AppTheme.primaryColor,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          // Table rows
          ...result.nutrients.asMap().entries.map((entry) {
            final index = entry.key;
            final nutrient = entry.value;
            final isLast = index == result.nutrients.length - 1;
            
            return Column(
              children: [
                _buildNutrientTableRow(nutrient, index)
                    .animate()
                    .fadeIn(delay: Duration(milliseconds: 550 + (index * 50))),
                if (!isLast)
                  Divider(height: 1, color: Colors.grey.shade100),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildNutrientTableRow(NutritionItem nutrient, int index) {
    // Determine indentation based on nutrient type
    final isSubItem = [
      'Energi dari Lemak', 
      'Energi dari Lemak Jenuh',
      'Lemak Jenuh', 
      'Lemak Trans', 
      'Kolesterol',
      'Serat Pangan', 
      'Gula', 
      'Gula Tambahan',
    ].contains(nutrient.name);
    
    return Padding(
      padding: EdgeInsets.only(
        left: isSubItem ? 28 : 16,
        right: 16,
        top: 12,
        bottom: 12,
      ),
      child: Row(
        children: [
          // Nutrient name with indicator
          Expanded(
            flex: 3,
            child: Row(
              children: [
                if (nutrient.wasScanned)
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: nutrient.isHigh ? AppTheme.cautionColor : AppTheme.safeColor,
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    nutrient.name,
                    style: TextStyle(
                      fontSize: isSubItem ? 13 : 14,
                      fontWeight: isSubItem ? FontWeight.normal : FontWeight.w500,
                      color: nutrient.wasScanned 
                          ? AppTheme.textPrimary 
                          : AppTheme.textLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Value
          Expanded(
            flex: 2,
            child: Text(
              nutrient.displayValue,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: nutrient.wasScanned
                    ? (nutrient.isHigh ? AppTheme.cautionColor : AppTheme.textPrimary)
                    : AppTheme.textLight,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // %AKG
          Expanded(
            flex: 1,
            child: Text(
              nutrient.dvDisplay ?? '-',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: nutrient.wasScanned 
                    ? AppTheme.primaryColor 
                    : AppTheme.textLight,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAKGNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Text(
        '* Persen AKG berdasarkan kebutuhan energi 2150 kkal.\n  Kebutuhan energi Anda mungkin lebih tinggi atau lebih rendah.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppTheme.textSecondary,
          fontStyle: FontStyle.italic,
          height: 1.4,
        ),
      ),
    ).animate().fadeIn(delay: 900.ms);
  }

  Widget _buildWarningCard(ScanResult result, Color statusColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              result.status == RiskStatus.safe
                  ? Icons.thumb_up
                  : Icons.info_outline,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.status == RiskStatus.safe
                      ? 'Pilihan Baik!'
                      : 'Perhatian',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  result.warningMessage!,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                        color: AppTheme.textPrimary,
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 950.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildConditionChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
