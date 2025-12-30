import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../models/user_data.dart';
import '../services/storage_service.dart';

class HealthInputScreen extends StatefulWidget {
  const HealthInputScreen({super.key});

  @override
  State<HealthInputScreen> createState() => _HealthInputScreenState();
}

class _HealthInputScreenState extends State<HealthInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  bool _hasDiabetes = false;
  bool _hasHypertension = false;
  bool _isOnDiet = false;
  bool _isLoading = false;
  bool _isEditMode = false; // True jika user sudah punya data

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  /// Load data user yang sudah ada (jika sudah daftar sebelumnya)
  Future<void> _loadExistingData() async {
    final storage = await StorageService.getInstance();
    final existingUser = storage.getUserData();
    
    if (existingUser != null && existingUser.name != null && existingUser.name!.isNotEmpty) {
      setState(() {
        _isEditMode = true;
        _nameController.text = existingUser.name ?? '';
        _ageController.text = existingUser.age?.toString() ?? '';
        _heightController.text = existingUser.height?.toString() ?? '';
        _weightController.text = existingUser.weight?.toString() ?? '';
        _hasDiabetes = existingUser.hasDiabetes;
        _hasHypertension = existingUser.hasHypertension;
        _isOnDiet = existingUser.isOnDiet;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final storage = await StorageService.getInstance();
      
      final userData = UserData(
        name: _nameController.text.trim(),
        age: int.parse(_ageController.text),
        height: double.parse(_heightController.text),
        weight: double.parse(_weightController.text),
        hasDiabetes: _hasDiabetes,
        hasHypertension: _hasHypertension,
        isOnDiet: _isOnDiet,
      );

      await storage.saveUserData(userData);

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _isEditMode ? Icons.edit : Icons.person_add,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEditMode ? 'Edit Profil' : 'Daftar Akun',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isEditMode ? 'Ubah data pribadimu' : 'Lengkapi data untuk personalisasi',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: -0.2, end: 0),
                const SizedBox(height: 32),

                // Personal Info Section
                Text(
                  'Data Pribadi',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 16),

                // Name Input
                _buildInputLabel('Nama Lengkap', true),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Masukkan nama lengkap',
                    prefixIcon: const Icon(Icons.person_outline, color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.dangerColor),
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama wajib diisi';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 150.ms),
                const SizedBox(height: 20),

                // Age Input
                _buildInputLabel('Usia', true),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _ageController,
                  decoration: InputDecoration(
                    hintText: 'Masukkan usia',
                    prefixIcon: const Icon(Icons.cake_outlined, color: AppTheme.textSecondary),
                    suffixText: 'tahun',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.dangerColor),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Usia wajib diisi';
                    }
                    final age = int.tryParse(value);
                    if (age == null || age < 1 || age > 120) {
                      return 'Masukkan usia yang valid';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 20),

                // Height and Weight Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputLabel('Tinggi Badan', true),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _heightController,
                            decoration: InputDecoration(
                              hintText: '165',
                              prefixIcon: const Icon(Icons.height, color: AppTheme.textSecondary),
                              suffixText: 'cm',
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.dangerColor),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Wajib diisi';
                              }
                              final height = double.tryParse(value);
                              if (height == null || height < 50 || height > 250) {
                                return 'Tidak valid';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputLabel('Berat Badan', true),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _weightController,
                            decoration: InputDecoration(
                              hintText: '60',
                              prefixIcon: const Icon(Icons.monitor_weight_outlined, color: AppTheme.textSecondary),
                              suffixText: 'kg',
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.dangerColor),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Wajib diisi';
                              }
                              final weight = double.tryParse(value);
                              if (weight == null || weight < 10 || weight > 300) {
                                return 'Tidak valid';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 250.ms),
                const SizedBox(height: 32),

                // Health Conditions Section
                Text(
                  'Kondisi Kesehatan',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 8),
                Text(
                  'Pilih jika Anda memiliki kondisi berikut (opsional)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 16),

                _buildHealthConditionCard(
                  icon: Icons.water_drop_outlined,
                  title: 'Diabetes',
                  subtitle: 'Gangguan kadar gula darah',
                  value: _hasDiabetes,
                  onChanged: (value) => setState(() => _hasDiabetes = value),
                  color: AppTheme.dangerColor,
                ).animate().fadeIn(delay: 350.ms).slideX(begin: 0.1, end: 0),
                const SizedBox(height: 12),

                _buildHealthConditionCard(
                  icon: Icons.favorite_outline,
                  title: 'Hipertensi',
                  subtitle: 'Tekanan darah tinggi',
                  value: _hasHypertension,
                  onChanged: (value) => setState(() => _hasHypertension = value),
                  color: AppTheme.cautionColor,
                ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1, end: 0),
                const SizedBox(height: 12),

                _buildHealthConditionCard(
                  icon: Icons.fitness_center_outlined,
                  title: 'Sedang Diet',
                  subtitle: 'Program penurunan berat badan',
                  value: _isOnDiet,
                  onChanged: (value) => setState(() => _isOnDiet = value),
                  color: AppTheme.primaryColor,
                ).animate().fadeIn(delay: 450.ms).slideX(begin: 0.1, end: 0),
                const SizedBox(height: 40),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveAndContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.5),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline, size: 22),
                              SizedBox(width: 10),
                              Text(
                                'Daftar & Mulai',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label, bool required) {
    return Row(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
        ),
        if (required)
          Text(
            ' *',
            style: TextStyle(
              color: AppTheme.dangerColor,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  Widget _buildHealthConditionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: value ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: value ? color : Colors.grey.shade200,
            width: value ? 2 : 1,
          ),
          boxShadow: value ? [] : AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              activeColor: color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
