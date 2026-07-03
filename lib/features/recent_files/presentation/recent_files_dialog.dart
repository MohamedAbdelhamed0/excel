import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../table_analyzer/presentation/controllers/excel_data_controller.dart';
import '../domain/entities/recent_file.dart';
import 'controllers/recent_files_controller.dart';

/// Modal dialog or bottom sheet for browsing and reopening previously opened spreadsheet files from the local DB.
class RecentFilesDialog extends ConsumerWidget {
  const RecentFilesDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const RecentFilesDialog(),
    );
  }

  static Future<void> showBottomSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: const RecentFilesDialog(),
            );
          },
        );
      },
    );
  }

  Future<void> _openFile(BuildContext context, WidgetRef ref, RecentFile file) async {
    List<int>? bytes = file.cachedBytes;

    if ((bytes == null || bytes.isEmpty) && !kIsWeb && file.filePath != null && file.filePath!.isNotEmpty) {
      try {
        final localFile = File(file.filePath!);
        if (await localFile.exists()) {
          bytes = await localFile.readAsBytes();
        }
      } catch (e) {
        debugPrint('[RecentFilesDialog] Error reading cached file from path: $e');
      }
    }

    if (bytes != null && bytes.isNotEmpty) {
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      await ref.read(excelDataControllerProvider.notifier).loadBytes(
            name: file.fileName,
            bytes: bytes,
            path: file.filePath,
          );
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File content no longer available or was moved.'),
        ),
      );
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentFilesAsync = ref.watch(recentFilesControllerProvider);
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 550,
        height: 500,
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dialog Header
            Row(
              children: [
                Icon(Icons.history_toggle_off, color: theme.colorScheme.primary, size: 24),
                const SizedBox(width: 10),
                Text(
                  'Previously Opened Files',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                recentFilesAsync.when(
                  data: (files) => files.isNotEmpty
                      ? TextButton.icon(
                          onPressed: () {
                            ref.read(recentFilesControllerProvider.notifier).clearAll();
                          },
                          icon: const Icon(Icons.delete_sweep, size: 18),
                          label: const Text('Clear All'),
                        )
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 20),

            // Dialog Content Body
            Expanded(
              child: recentFilesAsync.when(
                data: (files) {
                  if (files.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_open_outlined, size: 48, color: theme.hintColor),
                          const SizedBox(height: 12),
                          const Text(
                            'No History Records',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Opened CSV or Excel files will automatically save here.',
                            style: TextStyle(fontSize: 12, color: theme.hintColor),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: files.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final file = files[index];
                      final isExcel = file.fileName.endsWith('.xlsx') || file.fileName.endsWith('.xls');

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: (isExcel ? Colors.green : Colors.blue).withValues(alpha: 0.15),
                          child: Icon(
                            isExcel ? Icons.table_chart : Icons.description,
                            color: isExcel ? Colors.green : Colors.blue,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          file.fileName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${_formatTimeAgo(file.lastOpened)} • ${_formatSize(file.sizeBytes)} ${file.filePath != null ? "• ${file.filePath}" : ""}',
                          style: TextStyle(fontSize: 11, color: theme.hintColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton(
                              onPressed: () => _openFile(context, ref, file),
                              style: ElevatedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              child: const Text('Open'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              tooltip: 'Remove from history',
                              onPressed: () {
                                ref.read(recentFilesControllerProvider.notifier).removeFile(file.id);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error loading history: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
