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
import 'package:delivery_app/core/services/api_service.dart';

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

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final apiService = ApiService();
      await apiService.loadAllData();
      setState(() => _isLoading = false);
      logMessage('✅ Данные загружены с сервера', category: 'SYSTEM');
    } catch (e) {
      logMessage('⚠️ Ошибка загрузки данных: $e', category: 'SYSTEM', level: LogLevel.error);
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF6C63FF)),
              SizedBox(height: 16),
              Text('Загрузка данных...', style: TextStyle(color: Color(0xFF888888))),
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
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF6C63FF),
            child: Text(
              authState.user?.name.isNotEmpty == true ? authState.user!.name[0].toUpperCase() : 'К',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: selectedTab,
        children: [
          _buildHomeTab(shiftState, settings, dailyStatsAsync),
          Navigator(key: _navigatorKeys[1], onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => const OrdersTab())),
          Navigator(key: _navigatorKeys[2], onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => const DirectoriesTab())),
          Navigator(key: _navigatorKeys[3], onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => const AnalyticsTab())),
          Navigator(key: _navigatorKeys[4], onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => const MoreTab())),
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
        items: List.generate(_tabLabels.length, (index) => BottomNavigationBarItem(
          icon: Icon(_tabIcons[index]),
          label: _tabLabels[index],
        )),
      ),
    );
  }

  Widget _buildHomeTab(ShiftState shiftState, SettingsState settings, AsyncValue<DailyStats> dailyStatsAsync) {
    return dailyStatsAsync.when(
      data: (stats) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Дата и статус смены
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Color(0xFF888888)),
                const SizedBox(width: 6),
                Text(
                  _getTodayDate(),
                  style: const TextStyle(fontSize: 13, color: Color(0xFF888888)),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: shiftState.isActive ? Colors.green.withOpacity(0.15) : Colors.grey.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: shiftState.isActive ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        shiftState.isActive ? 'Смена активна' : 'Смена не начата',
                        style: TextStyle(
                          fontSize: 12,
                          color: shiftState.isActive ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Строка: Время работы + Стоимость пробега
            Row(
              children: [
                // Время работы (крупно)
                _TimeDisplay(
                  shiftState: shiftState,
                  label: 'Время работы',
                  color: Colors.white,
                ),
                const Spacer(),
                // Стоимость пробега за км (крупно)
                _buildCostPerKm(settings),
              ],
            ),
            const SizedBox(height: 16),

            // Блоки 2x2 — увеличенные
            Row(
              children: [
                _buildBigMetricCard(
                  value: '${stats.netProfit.toStringAsFixed(0)} ₽',
                  label: 'Доход',
                  color: Colors.green,
                ),
                const SizedBox(width: 12),
                _buildBigMetricCard(
                  value: '${stats.totalExpenses.toStringAsFixed(0)} ₽',
                  label: 'Расход',
                  color: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                _buildBigMetricCard(
                  value: '${stats.totalDistance.toStringAsFixed(1)} км',
                  label: 'Пробег всего',
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                _buildBigMetricCard(
                  value: '${stats.totalIdleDistance.toStringAsFixed(1)} км',
                  label: 'Холостой пробег',
                  color: Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                _buildBigMetricCard(
                  value: _calculateProfitPerKm(stats, settings),
                  label: 'Прибыль на км',
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                _buildBigMetricCard(
                  value: _calculateProfitPerHour(stats),
                  label: 'Прибыль за час',
                  color: Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Время простоя — большая плашка
            _buildIdleTimeCard(shiftState),
            const Spacer(),

            // Кнопка начала/остановки смены
            SizedBox(
              height: 54,
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  shiftState.isActive ? 'Остановить работу' : 'Начать работу',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
      loading: () => Container(
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
        ),
      ),
      error: (error, stack) => Container(
        padding: const EdgeInsets.all(16),
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

  // ===== ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ =====

  String _getTodayDate() {
    final now = DateTime.now();
    const weekdays = ['Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота', 'Воскресенье'];
    const months = ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'];
    return '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  String _calculateProfitPerKm(DailyStats stats, SettingsState settings) {
    if (stats.totalDistance <= 0) return '0.00 ₽/км';
    final profitPerKm = stats.netProfit / stats.totalDistance;
    return '${profitPerKm.toStringAsFixed(2)} ₽/км';
  }

  String _calculateProfitPerHour(DailyStats stats) {
    if (stats.totalWorkTime.inSeconds <= 0) return '0.00 ₽/ч';
    final hours = stats.totalWorkTime.inSeconds / 3600.0;
    if (hours <= 0) return '0.00 ₽/ч';
    final profitPerHour = stats.netProfit / hours;
    return '${profitPerHour.toStringAsFixed(2)} ₽/ч';
  }

  // ===== ВИДЖЕТЫ =====

  Widget _buildCostPerKm(SettingsState settings) {
    final fuelCostPerKm = (settings.fuelConsumption / 100) * settings.fuelPrice;
    final totalCostPerKm = fuelCostPerKm + settings.repairCost;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_gas_station, size: 16, color: Color(0xFF6C63FF)),
            const SizedBox(width: 6),
            Text(
              '${totalCostPerKm.toStringAsFixed(2)} ₽/км',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const Text(
          'Стоимость 1 км',
          style: TextStyle(
            fontSize: 10,
            color: Color(0xFF888888),
          ),
        ),
      ],
    );
  }

  Widget _buildBigMetricCard({
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2C2C2C)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
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

  Widget _buildIdleTimeCard(ShiftState shiftState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2C2C2C)),
      ),
      child: Row(
        children: [
          const Icon(Icons.pause_circle_outline, size: 22, color: Color(0xFF6C63FF)),
          const SizedBox(width: 12),
          const Text(
            'Время простоя',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF888888),
            ),
          ),
          const Spacer(),
          _IdleTimeDisplay(shiftState: shiftState),
        ],
      ),
    );
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
        if (mounted) setState(() {});
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          formattedTime,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: widget.color,
          ),
        ),
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF888888),
          ),
        ),
      ],
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

  const _IdleTimeDisplay({
    required this.shiftState,
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
        if (mounted) setState(() {});
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

    return Text(
      formattedTime,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white,
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