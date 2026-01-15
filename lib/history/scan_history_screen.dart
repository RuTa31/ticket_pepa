import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../common/app_colors.dart';

import 'scan_history_provider.dart';

class ScanHistoryScreen extends StatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  String _tab = 'All';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
        elevation: 1,
        centerTitle: true,
        title: const Text('Scan History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear All',
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
                  title: const Text('Clear history?'),
                  content: const Text('This will remove all saved scans.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: AppColors.primaryColor),
                      ),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text(
                        'Clear',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
              if (ok == true && context.mounted) {
                await context.read<ScanHistoryProvider>().clear();
              }
            },
          ),
        ],
      ),
      body: Consumer<ScanHistoryProvider>(
        builder: (context, history, _) {
          if (!history.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = history.items;
          if (items.isEmpty) {
            return const Center(child: Text('No scans yet'));
          }

          final now = DateTime.now();
          bool isToday(DateTime t) =>
              t.year == now.year && t.month == now.month && t.day == now.day;
          final display = _tab == 'All'
              ? items
              : items.where((e) => isToday(e.time)).toList();

          String fmt(DateTime dt) {
            String two(int n) => n.toString().padLeft(2, '0');
            return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: _tab == 'All',
                      onTap: () => setState(() => _tab = 'All'),
                    ),
                    const SizedBox(width: 12),
                    _FilterChip(
                      label: 'Today',
                      selected: _tab == 'Today',
                      onTap: () => setState(() => _tab = 'Today'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: display.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemBuilder: (context, index) {
                    final item = display[index];
                    final fullIndex = items.indexOf(item);
                    final isDark =
                        Theme.of(context).brightness == Brightness.dark;

                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [Colors.grey.shade900, Colors.grey.shade800]
                              : [Colors.white, Colors.grey.shade50],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black26
                                : Colors.grey.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            // Show details or copy action
                            Clipboard.setData(ClipboardData(text: item.value));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 12),
                                    Text('Copied to clipboard'),
                                  ],
                                ),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryColor
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        image: item.eventThumbnail != null
                                            ? DecorationImage(
                                                image: NetworkImage(
                                                  item.eventThumbnail!,
                                                ),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child: item.eventThumbnail == null
                                          ? Icon(
                                              Icons.qr_code_scanner,
                                              color: AppColors.primaryColor,
                                              size: 24,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.eventTitle ?? 'Unknown Event',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black87,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            fmt(item.time),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark
                                                  ? Colors.grey.shade500
                                                  : Colors.grey.shade500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Delete',
                                      icon: Icon(
                                        Icons.delete_outline,
                                        color: Colors.red.shade400,
                                      ),
                                      onPressed: () async {
                                        await context
                                            .read<ScanHistoryProvider>()
                                            .removeAt(fullIndex);
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.grey.shade800.withValues(
                                            alpha: 0.5,
                                          )
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Text('Ticket ID:'),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.confirmation_number_outlined,
                                        size: 18,
                                        color: isDark
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item.value,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            fontFamily: 'monospace',
                                            color: isDark
                                                ? Colors.grey.shade300
                                                : Colors.grey.shade800,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Icon(
                                        Icons.copy,
                                        size: 16,
                                        color: isDark
                                            ? Colors.grey.shade500
                                            : Colors.grey.shade400,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryColor : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
