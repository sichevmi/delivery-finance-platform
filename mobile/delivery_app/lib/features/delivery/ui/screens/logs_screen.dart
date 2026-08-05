// lib/features/delivery/ui/screens/logs_screen.dart
import 'package:flutter/material.dart';
import 'package:delivery_app/features/delivery/services/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/features/delivery/services/logger.dart';
import 'package:delivery_app/features/delivery/providers/logger_provider.dart';

class LogsScreen extends ConsumerStatefulWidget {
  const LogsScreen({super.key});

  @override
  ConsumerState<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends ConsumerState<LogsScreen> {
  String _logs = 'Загрузка...';
  bool _isLoading = true;
  List<File> _logFiles = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    
    try {
      final logger = ref.read(loggerServiceProvider);
      _logFiles = await logger.getLogFiles();
      
      if (_logFiles.isNotEmpty) {
        _logs = await _logFiles.first.readAsString();
      } else {
        _logs = 'Файлы логов не найдены';
      }
    } catch (e) {
      _logs = 'Ошибка загрузки логов: $e';
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _loadLogFile(File file) async {
    try {
      setState(() => _isLoading = true);
      _logs = await file.readAsString();
      setState(() => _isLoading = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки: $e')),
      );
    }
  }

  Future<void> _shareLogs() async {
    // Здесь можно добавить шаринг логов через share_plus
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Функция шаринга будет добавлена')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Логи приложения'),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
            tooltip: 'Обновить',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareLogs,
            tooltip: 'Поделиться',
          ),
        ],
        bottom: _logFiles.isNotEmpty
            ? PreferredSize(
                preferredSize: const Size.fromHeight(40),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _logFiles.map((file) {
                        final isSelected = file.path == _logFiles.first.path;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(
                              file.path.split('/').last.replaceAll('app_log_', '').replaceAll('.txt', ''),
                              style: const TextStyle(fontSize: 10),
                            ),
                            selected: isSelected,
                            onSelected: (_) => _loadLogFile(file),
                            backgroundColor: const Color(0xFF2C2C2C),
                            selectedColor: const Color(0xFF6C63FF).withOpacity(0.3),
                            labelStyle: TextStyle(
                              color: isSelected ? const Color(0xFF6C63FF) : Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
          : Container(
              color: const Color(0xFF1E1E1E),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  _logs,
                  style: const TextStyle(
                    color: Color(0xFF00FF00),
                    fontSize: 10,
                    fontFamily: 'monospace',
                    height: 1.2,
                  ),
                ),
              ),
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            onPressed: () async {
              final logger = ref.read(loggerServiceProvider);
              await logger.cleanOldLogs(keepCount: 10);
              await _loadLogs();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Старые логи очищены')),
              );
            },
            backgroundColor: Colors.red.withOpacity(0.8),
            child: const Icon(Icons.delete_sweep, size: 20),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            onPressed: _loadLogs,
            backgroundColor: const Color(0xFF6C63FF),
            child: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}