import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../models/user_data.dart';
import '../models/scan_result.dart';
import '../services/storage_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserData? _userData;
  List<ScanResult> _recentScans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final storage = await StorageService.getInstance();
    setState(() {
      _userData = storage.getUserData();
      _recentScans = storage.getScanHistory().take(3).toList();
      _isLoading = false;
    });
  }

  void _navigateToScan() {
    Navigator.pushNamed(context, '/scan');
  }

  void _navigateToHistory() {
    Navigator.pushNamed(context, '/history');
  }

  void _navigateToProfile() {
    Navigator.pushNamed(context, '/health-input');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Halo, ${_userData?.firstName ?? 'Pengguna'} 👋',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getGreetingSubtitle(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: _navigateToProfile,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn().slideY(begin: -0.1, end: 0),
              const SizedBox(height: 24),

              // Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  boxShadow: AppTheme.buttonShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.tips_and_updates,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Tips Hari Ini',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _getTipMessage(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.95),
                          ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.95, 0.95)),
              const SizedBox(height: 28),

              // Main CTA - Scan Button
              GestureDetector(
                onTap: _navigateToScan,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                    boxShadow: AppTheme.cardShadow,
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: AppTheme.buttonShadow,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Scan Nutrition Facts',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Arahkan kamera ke label nutrisi',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 300.ms)
                  .slideY(begin: 0.2, end: 0)
                  .then()
                  .animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                  )
                  .scaleXY(
                    begin: 1,
                    end: 1.02,
                    duration: 2000.ms,
                    curve: Curves.easeInOut,
                  ),
              const SizedBox(height: 28),

              // User Profile Summary
              if (_userData != null && _userData!.isProfileComplete) ...[
                _buildSectionHeader('Profil Kamu'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Row(
                    children: [
                      _buildProfileStat(
                        icon: Icons.height,
                        label: 'Tinggi',
                        value: '${_userData!.height?.toStringAsFixed(0) ?? "-"} cm',
                        color: AppTheme.primaryColor,
                      ),
                      _buildProfileStat(
                        icon: Icons.monitor_weight_outlined,
                        label: 'Berat',
                        value: '${_userData!.weight?.toStringAsFixed(0) ?? "-"} kg',
                        color: AppTheme.cautionColor,
                      ),
                      _buildProfileStat(
                        icon: Icons.straighten,
                        label: 'BMI',
                        value: _userData!.bmi?.toStringAsFixed(1) ?? '-',
                        color: _getBmiColor(_userData!.bmi),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getBmiColor(_userData!.bmi).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _userData!.bmiCategory,
                            style: TextStyle(
                              color: _getBmiColor(_userData!.bmi),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 350.ms),
                const SizedBox(height: 24),
              ],

              // Health Conditions Summary
              if (_userData?.hasHealthConditions == true) ...[
                _buildSectionHeader('Kondisi Kesehatan'),
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
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 24),
              ],

              // Recent Scans
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionHeader('Riwayat Terakhir'),
                  if (_recentScans.isNotEmpty)
                    TextButton(
                      onPressed: _navigateToHistory,
                      child: const Text(
                        'Lihat Semua',
                        style: TextStyle(color: AppTheme.primaryColor),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              if (_recentScans.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.history,
                        size: 40,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Belum ada riwayat scan',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mulai scan untuk melihat riwayat',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textLight,
                            ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 500.ms)
              else
                Column(
                  children: _recentScans.asMap().entries.map((entry) {
                    final index = entry.key;
                    final scan = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildScanHistoryItem(scan)
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: 500 + (index * 100)))
                          .slideX(begin: 0.1, end: 0),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreetingSubtitle() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Selamat pagi! Sudah sarapan?';
    } else if (hour < 17) {
      return 'Selamat siang! Pilih makan yang sehat';
    } else {
      return 'Selamat malam! Jaga pola makanmu';
    }
  }

  String _getTipMessage() {
    if (_userData?.hasDiabetes == true) {
      return 'Perhatikan kandungan gula pada makanan. Pilih yang rendah gula untuk menjaga kadar gula darahmu.';
    } else if (_userData?.hasHypertension == true) {
      return 'Kurangi asupan garam. Pilih makanan dengan sodium rendah untuk jaga tekanan darahmu.';
    } else if (_userData?.isOnDiet == true) {
      return 'Perhatikan total kalori. Pilih makanan tinggi serat dan rendah lemak untuk dietmu.';
    }
    return 'Scan label nutrisi untuk mengetahui kandungan gizi dan pilih makanan yang lebih sehat! ✨';
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildProfileStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBmiColor(double? bmi) {
    if (bmi == null) return Colors.grey;
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return AppTheme.safeColor;
    if (bmi < 30) return AppTheme.cautionColor;
    return AppTheme.dangerColor;
  }

  Widget _buildConditionChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildScanHistoryItem(ScanResult scan) {
    Color statusColor;
    switch (scan.status) {
      case RiskStatus.safe:
        statusColor = AppTheme.safeColor;
        break;
      case RiskStatus.caution:
        statusColor = AppTheme.cautionColor;
        break;
      case RiskStatus.danger:
        statusColor = AppTheme.dangerColor;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                scan.statusEmoji,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scan.displayName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  scan.formattedDate,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              scan.status == RiskStatus.safe
                  ? 'Aman'
                  : scan.status == RiskStatus.caution
                      ? 'Perhatian'
                      : 'Risiko',
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
