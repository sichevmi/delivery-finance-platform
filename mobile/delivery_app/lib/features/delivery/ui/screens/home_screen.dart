import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/logger.dart';
import 'package:delivery_app/features/auth/providers/auth_provider.dart';
import 'package:delivery_app/features/delivery/providers/shift_provider.dart';
import 'package:delivery_app/features/delivery/providers/settings_provider.dart';
import 'package:delivery_app/features/delivery/providers/tab_provider.dart';
import 'package:delivery_app/features/delivery/providers/daily_stats_provider.dart';
import 'package:delivery_app/features/delivery/ui/tabs/orders_tab.dart';
import 'package:delivery_app/features/delivery/ui/tabs/analytics_tab.dart';
import 'package:delivery_app/features/delivery/ui/tabs/directories_tab.dart';
import 'package:delivery_app/features/delivery/ui/tabs/more_tab.dart';
import 'package:delivery_app/features/delivery/providers/sync_provider.dart';
import 'package:delivery_app/core/services/connectivity_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  final List<String> _tabLabels = const [
    'Главная',
    'Заказы',
    'Справочники',
    'Аналитика',
    'Ещё',
  ];

  final List<IconData> _tabIcons = const [
    Icons.home_outlined,
    Icons.shopping_bag_outlined,
    Icons.folder_outlined,
    Icons.bar_chart_outlined,
    Icons.more_horiz,
  ];

  bool _isInitialSyncDone = false;
  bool _isLoading = true;
  bool _syncStarted = false; // ← Флаг, чтобы синхронизация запускалась только один раз

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenToConnectivity();
    _syncOnStart();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Ничего не делаем
  }

  // ===== АВТОМАТИЧЕСКАЯ СИНХРОНИЗАЦИЯ =====
  
  void _listenToConnectivity() {
    final connectivity = ref.read(connectivityServiceProvider);
    connectivity.connectivityStream.listen((result) {
      // Запускаем автосинхронизацию ТОЛЬКО если первичная синхронизация уже завершена
      if (result != ConnectivityResult.none && _isInitialSyncDone) {
        final syncService = ref.read(syncServiceProvider);
        syncService.syncAll().then((_) {
          logMessage('✅ Автосинхронизация выполнена', category: 'SYNC');
        }).catchError((e) {
          logMessage('⚠️ Автосинхронизация: $e', category: 'SYNC', level: LogLevel.error);
        });
      }
    });
  }

  void _syncOnStart() {
  if (_syncStarted) {
    logMessage('⏭️ Синхронизация уже запущена, пропускаем', category: 'SYNC');
    return;
  }
  _syncStarted = true;
  
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final syncService = ref.read(syncServiceProvider);
    
    try {
      await syncService.loadFromServer();
      
      // 🔥 ПРИНУДИТЕЛЬНО ОБНОВЛЯЕМ СТАТИСТИКУ
      ref.invalidate(dailyStatsProvider);
      
      await syncService.syncAll();
      
      if (mounted) {
        setState(() {
          _isInitialSyncDone = true;
          _isLoading = false;
        });
      }
      
      logMessage('✅ Первичная синхронизация выполнена', category: 'SYNC');
    } catch (e) {
      logMessage('⚠️ Первичная синхронизация: $e', category: 'SYNC', level: LogLevel.error);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  });
}

  @override
  Widget build(BuildContext context) {
    // Если идёт загрузка — показываем индикатор
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF6C63FF)),
              SizedBox(height: 16),
              Text(
                'Загрузка данных...',
                style: TextStyle(color: Color(0xFF888888)),
              ),
            ],
          ),
        ),
      );
    }

    final authState = ref.watch(authProvider);
    final shiftState = ref.watch(shiftProvider);
    final selectedTab = ref.watch(selectedTabProvider);
    final settings = ref.watch(settingsProvider);
    final dailyStatsAsync = ref.watch(dailyStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FinFlow Доставка'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF6C63FF),
            child: Text(
              authState.user?.name.isNotEmpty == true
                  ? authState.user!.name[0].toUpperCase()
                  : 'К',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: selectedTab,
        children: [
          _buildHomeTab(shiftState, settings, dailyStatsAsync),
          Navigator(
            key: _navigatorKeys[1],
            onGenerateRoute: (settings) => MaterialPageRoute(
              settings: settings,
              builder: (context) => const OrdersTab(),
            ),
          ),
          Navigator(
            key: _navigatorKeys[2],
            onGenerateRoute: (settings) => MaterialPageRoute(
              settings: settings,
              builder: (context) => const DirectoriesTab(),
            ),
          ),
          Navigator(
            key: _navigatorKeys[3],
            onGenerateRoute: (settings) => MaterialPageRoute(
              settings: settings,
              builder: (context) => const AnalyticsTab(),
            ),
          ),
          Navigator(
            key: _navigatorKeys[4],
            onGenerateRoute: (settings) => MaterialPageRoute(
              settings: settings,
              builder: (context) => const MoreTab(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedTab,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == selectedTab) {
            _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
          } else {
            ref.read(selectedTabProvider.notifier).state = index;
          }
        },
        items: List.generate(
          _tabLabels.length,
          (index) => BottomNavigationBarItem(
            icon: Icon(_tabIcons[index]),
            label: _tabLabels[index],
          ),
        ),
      ),
    );
  }

  // ===== ОСТАЛЬНОЙ КОД БЕЗ ИЗМЕНЕНИЙ =====
  // ... _buildHomeTab, _buildTimeCard, _buildMetricCard, _getTodayDate ...
  // ... и все виджеты _TimeDisplay, _IdleTimeDisplay, _IdleDistanceDisplay ...

  Widget _buildHomeTab(ShiftState shiftState, SettingsState settings, AsyncValue<DailyStats> dailyStatsAsync) {
    final fuelCostPerKm = (settings.fuelConsumption / 100) * settings.fuelPrice;

    return dailyStatsAsync.when(
      data: (stats) => Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Дата и статус смены
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Color(0xFF888888)),
                const SizedBox(width: 6),
                Text(_getTodayDate(), style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: shiftState.isActive ? Colors.green.withOpacity(0.15) : Colors.grey.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: shiftState.isActive ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        shiftState.isActive ? 'Смена активна' : 'Смена не начата',
                        style: TextStyle(
                          fontSize: 10,
                          color: shiftState.isActive ? Colors.green : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Верхняя строка: Время работы и Стоимость пробега
            Row(
              children: [
                _TimeDisplay(
                  shiftState: shiftState,
                  label: 'Время работы (за день)',
                  color: Colors.indigo,
                ),
                const SizedBox(width: 8),
                _buildTimeCard(
                  icon: Icons.attach_money,
                  value: '${fuelCostPerKm.toStringAsFixed(2)} руб',
                  label: 'Стоимость пробега (1 км)',
                  color: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Основные показатели (3 колонки)
            Row(
              children: [
                _buildMetricCard(
                  value: '${stats.netProfit.toStringAsFixed(0)} ₽',
                  label: 'Доход',
                  color: Colors.green,
                ),
                const SizedBox(width: 6),
                _buildMetricCard(
                  value: stats.ordersCount.toString(),
                  label: 'Заказы',
                  color: Colors.blue,
                ),
                const SizedBox(width: 6),
                _buildMetricCard(
                  value: '${stats.avgDistancePerOrder.toStringAsFixed(2)} км',
                  label: 'Ср. пробег/заказ',
                  color: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _buildMetricCard(
                  value: stats.formattedAvgTimePerOrder,
                  label: 'Ср. время/заказ',
                  color: Colors.purple,
                ),
                const SizedBox(width: 6),
                _buildMetricCard(
                  value: '${stats.avgCheck.toStringAsFixed(0)} ₽',
                  label: 'Ср. чек',
                  color: Colors.teal,
                ),
                const SizedBox(width: 6),
                _buildMetricCard(
                  value: '${stats.totalDistance.toStringAsFixed(1)} км',
                  label: 'Пробег (всего)',
                  color: Colors.cyan,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _IdleDistanceDisplay(
                  shiftState: shiftState,
                  label: 'Холостой пробег',
                  color: Colors.red,
                ),
                const SizedBox(width: 6),
                _IdleTimeDisplay(
                  shiftState: shiftState,
                  label: 'Время простоя',
                  color: Colors.red.shade300,
                ),
                const Spacer(),
              ],
            ),
            const Spacer(),

            // Кнопка начала/остановки смены
            SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final notifier = ref.read(shiftProvider.notifier);
                  if (shiftState.isActive) {
                    notifier.stopShift();
                  } else {
                    notifier.startShift();
                  }
                  ref.invalidate(dailyStatsProvider);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: shiftState.isActive ? Colors.red : const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  shiftState.isActive ? 'Остановить работу' : 'Начать работу',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
      loading: () => Container(
        padding: const EdgeInsets.all(12),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
        ),
      ),
      error: (error, stack) => Container(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Ошибка загрузки статистики: $error',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(dailyStatsProvider),
                child: const Text('Обновить'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF2C2C2C)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF888888),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF2C2C2C)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                color: Color(0xFF888888),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _getTodayDate() {
    final now = DateTime.now();
    const weekdays = ['Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота', 'Воскресенье'];
    const months = ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'];
    return '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }
}

// ============================================================
// ВИДЖЕТ ДЛЯ ВРЕМЕНИ РАБОТЫ
// ============================================================
class _TimeDisplay extends StatefulWidget {
  final ShiftState shiftState;
  final String label;
  final Color color;

  const _TimeDisplay({
    required this.shiftState,
    required this.label,
    required this.color,
  });

  @override
  State<_TimeDisplay> createState() => _TimeDisplayState();
}

class _TimeDisplayState extends State<_TimeDisplay> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant _TimeDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shiftState.isActive != oldWidget.shiftState.isActive) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.shiftState.isActive) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {});
      });
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final String formattedTime;
    if (widget.shiftState.isActive && widget.shiftState.shiftStartTime != null) {
      final now = DateTime.now();
      final duration = widget.shiftState.totalWorkTime + now.difference(widget.shiftState.shiftStartTime!);
      formattedTime = _formatDuration(duration);
    } else {
      formattedTime = _formatDuration(widget.shiftState.totalWorkTime);
    }

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF2C2C2C)),
        ),
        child: Row(
          children: [
            Icon(Icons.timer, size: 16, color: widget.color),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formattedTime,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: widget.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF888888),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

// ============================================================
// ВИДЖЕТ ДЛЯ ВРЕМЕНИ ПРОСТОЯ
// ============================================================
class _IdleTimeDisplay extends StatefulWidget {
  final ShiftState shiftState;
  final String label;
  final Color color;

  const _IdleTimeDisplay({
    required this.shiftState,
    required this.label,
    required this.color,
  });

  @override
  State<_IdleTimeDisplay> createState() => _IdleTimeDisplayState();
}

class _IdleTimeDisplayState extends State<_IdleTimeDisplay> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant _IdleTimeDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shiftState.isActive != oldWidget.shiftState.isActive ||
        widget.shiftState.isOnOrder != oldWidget.shiftState.isOnOrder) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.shiftState.isActive && !widget.shiftState.isOnOrder) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {});
      });
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final String formattedTime;
    if (widget.shiftState.isActive && 
        !widget.shiftState.isOnOrder && 
        widget.shiftState.idleStartTime != null) {
      final now = DateTime.now();
      final duration = widget.shiftState.totalIdleTime + 
          now.difference(widget.shiftState.idleStartTime!);
      formattedTime = _formatDuration(duration);
    } else {
      formattedTime = _formatDuration(widget.shiftState.totalIdleTime);
    }

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF2C2C2C)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formattedTime,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: widget.color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 9,
                color: Color(0xFF888888),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

// ============================================================
// ВИДЖЕТ ДЛЯ ХОЛОСТОГО ПРОБЕГА
// ============================================================
class _IdleDistanceDisplay extends StatefulWidget {
  final ShiftState shiftState;
  final String label;
  final Color color;

  const _IdleDistanceDisplay({
    required this.shiftState,
    required this.label,
    required this.color,
  });

  @override
  State<_IdleDistanceDisplay> createState() => _IdleDistanceDisplayState();
}

class _IdleDistanceDisplayState extends State<_IdleDistanceDisplay> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant _IdleDistanceDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shiftState.isActive != oldWidget.shiftState.isActive ||
        widget.shiftState.isOnOrder != oldWidget.shiftState.isOnOrder) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.shiftState.isActive && !widget.shiftState.isOnOrder) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {});
      });
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final distance = widget.shiftState.totalIdleDistance;
    final formattedDistance = distance.toStringAsFixed(1);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF2C2C2C)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${formattedDistance} км',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: widget.color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 9,
                color: Color(0xFF888888),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}