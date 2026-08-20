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

          // ===== ВЕРХНЯЯ СТРОКА: Время работы | Стоимость км | Время простоя =====
          Row(
            children: [
              const _TimeDisplay(),
              const Spacer(),
              _buildCostPerKm(totalCostPerKm),
              const Spacer(),
              const _IdleTimeDisplay(),
            ],
          ),
          const SizedBox(height: 8),

          // ===== ПЕРВАЯ СТРОКА: Количество заказов (на всю ширину) =====
          const _OrdersCountMetric(),
          const SizedBox(height: 6),

          // ===== ВТОРАЯ И ТРЕТЬЯ СТРОКИ: ДОХОД ПОСЕРЕДИНЕ =====
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Левая колонка (2 строки)
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      const _TotalDistanceMetric(),
                      const SizedBox(height: 6),
                      const _IdleDistanceMetric(),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                // Центральная колонка (доход) — на 2 строки
                Expanded(
                  flex: 1,
                  child: const _ProfitMetric(),
                ),
                const SizedBox(width: 6),
                // Правая колонка (2 строки)
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      const _ExpensesMetric(),
                      const SizedBox(height: 6),
                      const _IdleTimeMetric(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // ===== ЧЕТВЁРТАЯ СТРОКА: Прибыль на км + Прибыль за час =====
          Row(
            children: [
              Expanded(child: const _ProfitPerKmMetric()),
              const SizedBox(width: 8),
              Expanded(child: const _ProfitPerHourMetric()),
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

  // ===== ВСПОМОГАТЕЛЬНЫЙ ВИДЖЕТ =====

  Widget _buildCostPerKm(double totalCostPerKm) {
    return Text(
      '${totalCostPerKm.toStringAsFixed(2)} ₽/км',
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}

// ============================================================
// КАРТОЧКА МЕТРИКИ С ИКОНКОЙ
// ============================================================
class _MetricCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final double? fontSize;

  const _MetricCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF2C2C2C), width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: fontSize ?? 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ДОХОД (БОЛЬШАЯ КАРТОЧКА)
// ============================================================
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6C63FF).withOpacity(0.15),
            const Color(0xFF6C63FF).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.trending_up, size: 16, color: Color(0xFF6C63FF)),
              const SizedBox(width: 6),
              Text(
                _value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const Text(
            'Доход',
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFF888888),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// КОЛИЧЕСТВО ЗАКАЗОВ
// ============================================================
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2C2C2C), width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_bag, size: 20, color: Color(0xFF6C63FF)),
          const SizedBox(width: 8),
          Text(
            _value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Заказов',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF888888),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ОСТАЛЬНЫЕ МЕТРИКИ С ИКОНКАМИ
// ============================================================

// ---- ПРОБЕГ ВСЕГО ----
class _TotalDistanceMetric extends ConsumerStatefulWidget {
  const _TotalDistanceMetric();

  @override
  ConsumerState<_TotalDistanceMetric> createState() => _TotalDistanceMetricState();
}

class _TotalDistanceMetricState extends ConsumerState<_TotalDistanceMetric> {
  Timer? _timer;
  String _value = '0.0';

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
      _value = stats.totalDistance.toStringAsFixed(1);
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
      label: 'км пробег',
      icon: Icons.route,
      color: Colors.blue,
      fontSize: 16,
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
  String _value = '0.0';

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
      _value = stats.totalIdleDistance.toStringAsFixed(1);
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
      label: 'км холостой',
      icon: Icons.ev_station,
      color: Colors.orange,
      fontSize: 16,
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
      _value = stats.totalExpenses.toStringAsFixed(0);
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
      label: '₽ расход',
      icon: Icons.money_off,
      color: Colors.red,
      fontSize: 16,
    );
  }
}

// ---- ВРЕМЯ ПРОСТОЯ (В КАРТОЧКЕ) ----
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
      label: 'время простоя',
      icon: Icons.timer_off,
      color: Colors.purple,
      fontSize: 14,
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
  String _value = '0.00';

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
        _value = '0.00';
      } else {
        _value = (stats.netProfit / stats.totalDistance).toStringAsFixed(2);
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
      label: '₽/км прибыль',
      icon: Icons.speed,
      color: Colors.cyan,
      fontSize: 16,
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
          _value = (stats.netProfit / hours).toStringAsFixed(2);
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
      label: '₽/ч прибыль',
      icon: Icons.access_time,
      color: Colors.purpleAccent,
      fontSize: 16,
    );
  }
}

// ============================================================
// ВРЕМЯ РАБОТЫ (В ВЕРХНЕЙ СТРОКЕ)
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
    return Text(
      _formattedTime,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}

// ============================================================
// ВРЕМЯ ПРОСТОЯ (В ВЕРХНЕЙ СТРОКЕ)
// ============================================================
class _IdleTimeDisplay extends ConsumerStatefulWidget {
  const _IdleTimeDisplay();

  @override
  ConsumerState<_IdleTimeDisplay> createState() => _IdleTimeDisplayState();
}

class _IdleTimeDisplayState extends ConsumerState<_IdleTimeDisplay> {
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
      _formattedTime = shiftState.formattedIdleTime;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _formattedTime,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}