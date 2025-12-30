import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../models/scan_result.dart';
import '../services/storage_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<ScanResult> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final storage = await StorageService.getInstance();
    setState(() {
      _history = storage.getScanHistory();
      _isLoading = false;
    });
  }

  Future<void> _deleteItem(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Riwayat'),
        content: const Text('Yakin ingin menghapus riwayat scan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Hapus',
              style: TextStyle(color: AppTheme.dangerColor),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final storage = await StorageService.getInstance();
      await storage.deleteScanResult(id);
      _loadHistory();
    }
  }

  Future<void> _clearAllHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Semua Riwayat'),
        content: const Text('Yakin ingin menghapus semua riwayat scan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Hapus Semua',
              style: TextStyle(color: AppTheme.dangerColor),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final storage = await StorageService.getInstance();
      await storage.clearScanHistory();
      _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Scan'),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearAllHistory,
              tooltip: 'Hapus Semua',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : _history.isEmpty
              ? _buildEmptyState()
              : _buildHistoryList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history,
                size: 50,
                color: AppTheme.primaryColor.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Belum Ada Riwayat',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Riwayat scan makananmu akan muncul di sini',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/scan'),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Mulai Scan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final scan = _history[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildHistoryCard(scan)
              .animate()
              .fadeIn(delay: Duration(milliseconds: index * 50))
              .slideX(begin: 0.05, end: 0),
        );
      },
    );
  }

  Widget _buildHistoryCard(ScanResult scan) {
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

    return Dismissible(
      key: Key(scan.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.dangerColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        await _deleteItem(scan.id);
        return false;
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(context, '/result', arguments: scan);
            },
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Status indicator
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        scan.statusEmoji,
                        style: const TextStyle(fontSize: 26),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          scan.displayName,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          scan.formattedDate,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        // Nutrient summary
                        Wrap(
                          spacing: 8,
                          children: scan.nutrients.take(3).map((nutrient) {
                            return Text(
                              '${nutrient.name}: ${nutrient.displayValue}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: nutrient.isHigh
                                        ? AppTheme.cautionColor
                                        : AppTheme.textSecondary,
                                    fontWeight: nutrient.isHigh
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  // Arrow
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
