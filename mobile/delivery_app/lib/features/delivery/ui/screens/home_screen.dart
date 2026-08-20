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
      logMessage('🔄 [HOME] _loadData() начат', category: 'SYSTEM');
      final apiService = ApiService();
      await apiService.loadAllData();
      logMessage('🔄 [HOME] Данные загружены с сервера', category: 'SYSTEM');
      
      if (mounted) {
        await ref.refreshStats();
        logMessage('🔄 [HOME] Статистика обновлена', category: 'SYSTEM');
      }
      
      if (mounted) {
        setState(() => _isLoading = false);
      }
      logMessage('🔄 [HOME] _loadData() завершён', category: 'SYSTEM');
    } catch (e) {
      logMessage('⚠️ [HOME] Ошибка загрузки данных: $e', category: 'SYSTEM', level: LogLevel.error);
      if (mounted) {
        setState(() => _isLoading = false);
      }
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('FinFlow Доставка'),
        toolbarHeight: 48,
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}, padding: EdgeInsets.zero),
          CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xFF6C63FF),
            child: Text(
              authState.user?.name.isNotEmpty == true ? authState.user!.name[0].toUpperCase() : 'К',
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: IndexedStack(
        index: selectedTab,
        children: [
          _buildHomeTab(shiftState, settings),
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

  Widget _buildHomeTab(ShiftState shiftState, SettingsState settings) {
    final fuelCostPerKm = (settings.fuelConsumption / 100) * settings.fuelPrice;
    final totalCostPerKm = fuelCostPerKm + settings.repairCost;

    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Дата и статус смены
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 12, color: Color(0xFF888888)),
              const SizedBox(width: 4),
              Text(
                _getTodayDate(),
                style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: shiftState.isActive && !shiftState.isPaused && !shiftState.isCompleted 
                      ? Colors.green.withOpacity(0.15) 
                      : shiftState.isPaused 
                          ? Colors.orange.withOpacity(0.15) 
                          : Colors.grey.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: shiftState.isActive && !shiftState.isPaused && !shiftState.isCompleted 
                            ? Colors.green 
                            : shiftState.isPaused 
                                ? Colors.orange 
                                : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      shiftState.isCompleted ? 'Завершена' :
                      shiftState.isPaused ? 'Приостановлена' : 
                      shiftState.isActive ? 'Активна' : 'Не начата',
                      style: TextStyle(
                        fontSize: 10,
                        color: shiftState.isCompleted ? Colors.grey :
                               shiftState.isPaused ? Colors.orange : 
                               shiftState.isActive ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Строка: Время работы + Стоимость пробега
          Row(
            children: [
              const _TimeDisplay(),
              const Spacer(),
              _buildCostPerKm(totalCostPerKm),
            ],
          ),
          const SizedBox(height: 8),

          // ===== ПЕРВАЯ СТРОКА: Доход + Расход =====
          Row(
            children: [
              const _ProfitMetric(),
              const SizedBox(width: 8),
              const _ExpensesMetric(),
            ],
          ),
          const SizedBox(height: 6),

          // ===== ВТОРАЯ СТРОКА: Пробег всего + Заказы =====
          Row(
            children: [
              const _TotalDistanceMetric(),
              const SizedBox(width: 8),
              const _OrdersCountMetric(),
            ],
          ),
          const SizedBox(height: 6),

          // ===== ТРЕТЬЯ СТРОКА: Холостой пробег + Время простоя =====
          Row(
            children: [
              const _IdleDistanceMetric(),
              const SizedBox(width: 8),
              const _IdleTimeMetric(),
            ],
          ),
          const SizedBox(height: 6),

          // ===== ЧЕТВЁРТАЯ СТРОКА: Прибыль на км + Прибыль за час =====
          Row(
            children: [
              const _ProfitPerKmMetric(),
              const SizedBox(width: 8),
              const _ProfitPerHourMetric(),
            ],
          ),
          const Spacer(),

          // Кнопка управления сменой
          SizedBox(
            height: 54,
            width: double.infinity,
            child: _buildShiftButton(shiftState),
          ),
        ],
      ),
    );
  }

  // ===== КНОПКА УПРАВЛЕНИЯ СМЕНОЙ =====
  Widget _buildShiftButton(ShiftState shiftState) {
    if (shiftState.isCompleted || !shiftState.isActive) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Смена завершена',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      );
    }
    
    if (shiftState.isPaused) {
      return ElevatedButton(
        onPressed: () async {
          logMessage('🔄 [HOME] Возобновление работы', category: 'SYSTEM');
          final notifier = ref.read(shiftProvider.notifier);
          await notifier.resumeShift();
          if (mounted) {
            await ref.refreshStats();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_arrow, size: 24),
            SizedBox(width: 8),
            Text('Возобновить работу', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    } else {
      return ElevatedButton(
        onPressed: () async {
          logMessage('🔄 [HOME] Приостановка работы', category: 'SYSTEM');
          final notifier = ref.read(shiftProvider.notifier);
          await notifier.pauseShift();
          if (mounted) {
            await ref.refreshStats();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pause, size: 24),
            SizedBox(width: 8),
            Text('Приостановить работу', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }
  }

  // ===== ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ =====

  String _getTodayDate() {
    final now = DateTime.now();
    const weekdays = ['Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота', 'Воскресенье'];
    const months = ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'];
    return '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  // ===== ВИДЖЕТЫ =====

  Widget _buildCostPerKm(double totalCostPerKm) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.local_gas_station, size: 14, color: Color(0xFF6C63FF)),
        const SizedBox(width: 4),
        Text(
          '${totalCostPerKm.toStringAsFixed(2)} ₽/км',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// КАРТОЧКА МЕТРИКИ
// ============================================================
class _MetricCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _MetricCard({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF2C2C2C), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
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

// ============================================================
// МЕТРИКИ С ТАЙМЕРАМИ (ConsumerStatefulWidget)
// ============================================================

// ---- ДОХОД ----
class _ProfitMetric extends ConsumerStatefulWidget {
  const _ProfitMetric();

  @override
  ConsumerState<_ProfitMetric> createState() => _ProfitMetricState();
}

class _ProfitMetricState extends ConsumerState<_ProfitMetric> {
  Timer? _timer;
  String _value = '0 ₽';

  @override
  void initState() {
    super.initState();
    _updateValue();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateValue();
    });
  }

  void _updateValue() {
    final stats = ref.read(dailyStatsProvider);
    setState(() {
      _value = '${stats.netProfit.toStringAsFixed(0)} ₽';
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _MetricCard(
      value: _value,
      label: 'Доход',
      color: Colors.green,
    );
  }
}

// ---- РАСХОД ----
class _ExpensesMetric extends ConsumerStatefulWidget {
  const _ExpensesMetric();

  @override
  ConsumerState<_ExpensesMetric> createState() => _ExpensesMetricState();
}

class _ExpensesMetricState extends ConsumerState<_ExpensesMetric> {
  Timer? _timer;
  String _value = '0 ₽';

  @override
  void initState() {
    super.initState();
    _updateValue();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateValue();
    });
  }

  void _updateValue() {
    final stats = ref.read(dailyStatsProvider);
    setState(() {
      _value = '${stats.totalExpenses.toStringAsFixed(0)} ₽';
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _MetricCard(
      value: _value,
      label: 'Расход',
      color: Colors.red,
    );
  }
}

// ---- ПРОБЕГ ВСЕГО ----
class _TotalDistanceMetric extends ConsumerStatefulWidget {
  const _TotalDistanceMetric();

  @override
  ConsumerState<_TotalDistanceMetric> createState() => _TotalDistanceMetricState();
}

class _TotalDistanceMetricState extends ConsumerState<_TotalDistanceMetric> {
  Timer? _timer;
  String _value = '0.0 км';

  @override
  void initState() {
    super.initState();
    _updateValue();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateValue();
    });
  }

  void _updateValue() {
    final stats = ref.read(dailyStatsProvider);
    setState(() {
      _value = '${stats.totalDistance.toStringAsFixed(1)} км';
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _MetricCard(
      value: _value,
      label: 'Пробег всего',
      color: Colors.white,
    );
  }
}

// ---- КОЛИЧЕСТВО ЗАКАЗОВ ----
class _OrdersCountMetric extends ConsumerStatefulWidget {
  const _OrdersCountMetric();

  @override
  ConsumerState<_OrdersCountMetric> createState() => _OrdersCountMetricState();
}

class _OrdersCountMetricState extends ConsumerState<_OrdersCountMetric> {
  Timer? _timer;
  String _value = '0';

  @override
  void initState() {
    super.initState();
    _updateValue();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateValue();
    });
  }

  void _updateValue() {
    final stats = ref.read(dailyStatsProvider);
    setState(() {
      _value = stats.ordersCount.toString();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _MetricCard(
      value: _value,
      label: 'Заказы',
      color: Colors.blue,
    );
  }
}

// ---- ХОЛОСТОЙ ПРОБЕГ ----
class _IdleDistanceMetric extends ConsumerStatefulWidget {
  const _IdleDistanceMetric();

  @override
  ConsumerState<_IdleDistanceMetric> createState() => _IdleDistanceMetricState();
}

class _IdleDistanceMetricState extends ConsumerState<_IdleDistanceMetric> {
  Timer? _timer;
  String _value = '0.0 км';

  @override
  void initState() {
    super.initState();
    _updateValue();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateValue();
    });
  }

  void _updateValue() {
    final stats = ref.read(dailyStatsProvider);
    setState(() {
      _value = '${stats.totalIdleDistance.toStringAsFixed(1)} км';
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _MetricCard(
      value: _value,
      label: 'Холостой пробег',
      color: Colors.orange,
    );
  }
}

// ---- ВРЕМЯ ПРОСТОЯ ----
class _IdleTimeMetric extends ConsumerStatefulWidget {
  const _IdleTimeMetric();

  @override
  ConsumerState<_IdleTimeMetric> createState() => _IdleTimeMetricState();
}

class _IdleTimeMetricState extends ConsumerState<_IdleTimeMetric> {
  Timer? _timer;
  String _value = '00:00:00';

  @override
  void initState() {
    super.initState();
    _updateValue();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateValue();
    });
  }

  void _updateValue() {
    final shiftState = ref.read(shiftProvider);
    setState(() {
      _value = shiftState.formattedIdleTime;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _MetricCard(
      value: _value,
      label: 'Время простоя',
      color: Colors.purple,
    );
  }
}

// ---- ПРИБЫЛЬ НА КМ ----
class _ProfitPerKmMetric extends ConsumerStatefulWidget {
  const _ProfitPerKmMetric();

  @override
  ConsumerState<_ProfitPerKmMetric> createState() => _ProfitPerKmMetricState();
}

class _ProfitPerKmMetricState extends ConsumerState<_ProfitPerKmMetric> {
  Timer? _timer;
  String _value = '0.00 ₽/км';

  @override
  void initState() {
    super.initState();
    _updateValue();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateValue();
    });
  }

  void _updateValue() {
    final stats = ref.read(dailyStatsProvider);
    setState(() {
      if (stats.totalDistance <= 0) {
        _value = '0.00 ₽/км';
      } else {
        final profitPerKm = stats.netProfit / stats.totalDistance;
        _value = '${profitPerKm.toStringAsFixed(2)} ₽/км';
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _MetricCard(
      value: _value,
      label: 'Прибыль на км',
      color: Colors.cyan,
    );
  }
}

// ---- ПРИБЫЛЬ ЗА ЧАС ----
class _ProfitPerHourMetric extends ConsumerStatefulWidget {
  const _ProfitPerHourMetric();

  @override
  ConsumerState<_ProfitPerHourMetric> createState() => _ProfitPerHourMetricState();
}

class _ProfitPerHourMetricState extends ConsumerState<_ProfitPerHourMetric> {
  Timer? _timer;
  String _value = '—';

  @override
  void initState() {
    super.initState();
    _updateValue();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateValue();
    });
  }

  void _updateValue() {
    final stats = ref.read(dailyStatsProvider);
    setState(() {
      if (stats.totalWorkTime.inSeconds < 3600) {
        _value = '—';
      } else {
        final hours = stats.totalWorkTime.inSeconds / 3600.0;
        if (hours <= 0) {
          _value = '—';
        } else {
          final profitPerHour = stats.netProfit / hours;
          _value = '${profitPerHour.toStringAsFixed(2)} ₽/ч';
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _MetricCard(
      value: _value,
      label: 'Прибыль за час',
      color: Colors.purple,
    );
  }
}

// ============================================================
// ВРЕМЯ РАБОТЫ
// ============================================================
class _TimeDisplay extends ConsumerStatefulWidget {
  const _TimeDisplay();

  @override
  ConsumerState<_TimeDisplay> createState() => _TimeDisplayState();
}

class _TimeDisplayState extends ConsumerState<_TimeDisplay> {
  Timer? _timer;
  String _formattedTime = '00:00:00';

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
    });
  }

  void _updateTime() {
    final shiftState = ref.read(shiftProvider);
    setState(() {
      _formattedTime = shiftState.formattedWorkTime;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formattedTime,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const Text(
          'Время работы',
          style: TextStyle(
            fontSize: 10,
            color: Color(0xFF888888),
          ),
        ),
      ],
    );
  }
}