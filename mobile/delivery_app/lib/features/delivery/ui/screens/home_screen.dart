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
        
        // ===== ПРИНУДИТЕЛЬНО ОБНОВЛЯЕМ ВСЕ МЕТРИКИ =====
        // Триггерим перестройку всех виджетов с таймерами
        await Future.delayed(Duration.zero);
        setState(() {});
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
              _TimeDisplay(ref: ref),
              const Spacer(),
              _buildCostPerKm(totalCostPerKm),
            ],
          ),
          const SizedBox(height: 8),

          // ===== МЕТРИКИ С ПЕРЕДАЧЕЙ ref =====
          Row(
            children: [
              _ProfitMetric(ref: ref),
              const SizedBox(width: 8),
              _ExpensesMetric(ref: ref),
            ],
          ),
          const SizedBox(height: 6),

          Row(
            children: [
              _TotalDistanceMetric(ref: ref),
              const SizedBox(width: 8),
              _IdleDistanceMetric(ref: ref),
            ],
          ),
          const SizedBox(height: 6),

          Row(
            children: [
              _ProfitPerKmMetric(ref: ref),
              const SizedBox(width: 8),
              _ProfitPerHourMetric(ref: ref),
            ],
          ),
          const SizedBox(height: 6),

          // Время простоя
          _buildCompactIdleTimeCard(ref),
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

  Widget _buildCompactIdleTimeCard(WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2C2C2C), width: 0.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.pause_circle_outline, size: 16, color: Color(0xFF6C63FF)),
          const SizedBox(width: 6),
          const Text(
            'Время простоя',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF888888),
            ),
          ),
          const Spacer(),
          _IdleTimeDisplay(ref: ref),
        ],
      ),
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
  final String suffix;

  const _MetricCard({
    required this.value,
    required this.label,
    required this.color,
    this.suffix = '',
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
              '$value$suffix',
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
// МЕТРИКИ С ЛОКАЛЬНЫМИ ТАЙМЕРАМИ
// ============================================================

// ---- ДОХОД ----
class _ProfitMetric extends StatefulWidget {
  final WidgetRef ref;
  const _ProfitMetric({required this.ref});

  @override
  State<_ProfitMetric> createState() => _ProfitMetricState();
}

class _ProfitMetricState extends State<_ProfitMetric> {
  Timer? _timer;
  String _value = '0';
  bool _firstUpdate = true;

  @override
  void initState() {
    super.initState();
    _updateValue();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateValue();
    });
  }

  void _updateValue() {
    final stats = widget.ref.read(dailyStatsProvider);
    final newValue = stats.netProfit.toStringAsFixed(0);
    if (_value != newValue || _firstUpdate) {
      _firstUpdate = false;
      setState(() {
        _value = newValue;
      });
    }
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
      suffix: ' ₽',
    );
  }
}

// ---- РАСХОД ----
class _ExpensesMetric extends StatefulWidget {
  final WidgetRef ref;
  const _ExpensesMetric({required this.ref});

  @override
  State<_ExpensesMetric> createState() => _ExpensesMetricState();
}

class _ExpensesMetricState extends State<_ExpensesMetric> {
  Timer? _timer;
  String _value = '0';
  bool _firstUpdate = true;

  @override
  void initState() {
    super.initState();
    _updateValue();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateValue();
    });
  }

  void _updateValue() {
    final stats = widget.ref.read(dailyStatsProvider);
    final newValue = stats.totalExpenses.toStringAsFixed(0);
    if (_value != newValue || _firstUpdate) {
      _firstUpdate = false;
      setState(() {
        _value = newValue;
      });
    }
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
      suffix: ' ₽',
    );
  }
}

// ---- ПРОБЕГ ВСЕГО ----
class _TotalDistanceMetric extends StatefulWidget {
  final WidgetRef ref;
  const _TotalDistanceMetric({required this.ref});

  @override
  State<_TotalDistanceMetric> createState() => _TotalDistanceMetricState();
}

class _TotalDistanceMetricState extends State<_TotalDistanceMetric> {
  Timer? _timer;
  String _value = '0.0';
  bool _firstUpdate = true;

  @override
  void initState() {
    super.initState();
    _updateValue();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateValue();
    });
  }

  void _updateValue() {
    final stats = widget.ref.read(dailyStatsProvider);
    final newValue = stats.totalDistance.toStringAsFixed(1);
    if (_value != newValue || _firstUpdate) {
      _firstUpdate = false;
      setState(() {
        _value = newValue;
      });
    }
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
      suffix: ' км',
    );
  }
}

// ---- ХОЛОСТОЙ ПРОБЕГ ----
class _IdleDistanceMetric extends StatefulWidget {
  final WidgetRef ref;
  const _IdleDistanceMetric({required this.ref});

  @override
  State<_IdleDistanceMetric> createState() => _IdleDistanceMetricState();
}

class _IdleDistanceMetricState extends State<_IdleDistanceMetric> {
  Timer? _timer;
  String _value = '0.0';
  bool _firstUpdate = true;

  @override
  void initState() {
    super.initState();
    _updateValue();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateValue();
    });
  }

  void _updateValue() {
    final stats = widget.ref.read(dailyStatsProvider);
    final newValue = stats.totalIdleDistance.toStringAsFixed(1);
    if (_value != newValue || _firstUpdate) {
      _firstUpdate = false;
      setState(() {
        _value = newValue;
      });
    }
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
      suffix: ' км',
    );
  }
}

// ---- ПРИБЫЛЬ НА КМ ----
// ---- ПРИБЫЛЬ НА КМ (используем правильные данные) ----
class _ProfitPerKmMetric extends StatefulWidget {
  final WidgetRef ref;
  const _ProfitPerKmMetric({required this.ref});

  @override
  State<_ProfitPerKmMetric> createState() => _ProfitPerKmMetricState();
}

class _ProfitPerKmMetricState extends State<_ProfitPerKmMetric> {
  Timer? _timer;
  String _value = '0.00';
  bool _firstUpdate = true;

  @override
  void initState() {
    super.initState();
    _updateValue();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateValue();
    });
  }

  void _updateValue() {
    final stats = widget.ref.read(dailyStatsProvider);
    String newValue;
    if (stats.totalDistance <= 0) {
      newValue = '0.00';
    } else {
      // ===== ИСПОЛЬЗУЕМ ПРИБЫЛЬ (netProfit) ДЛЯ РАСЧЁТА =====
      // Либо используйте totalIncome если хотите доход на км
      final profit = stats.netProfit; // или stats.totalIncome
      newValue = (profit / stats.totalDistance).toStringAsFixed(2);
    }
    if (_value != newValue || _firstUpdate) {
      _firstUpdate = false;
      setState(() {
        _value = newValue;
      });
    }
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
      label: 'Прибыль на км',  // или 'Доход на км'
      color: Colors.cyan,
      suffix: ' ₽/км',
    );
  }
}

// ---- ПРИБЫЛЬ ЗА ЧАС ----
class _ProfitPerHourMetric extends StatefulWidget {
  final WidgetRef ref;
  const _ProfitPerHourMetric({required this.ref});

  @override
  State<_ProfitPerHourMetric> createState() => _ProfitPerHourMetricState();
}

class _ProfitPerHourMetricState extends State<_ProfitPerHourMetric> {
  Timer? _timer;
  String _value = '—';
  bool _firstUpdate = true;

  @override
  void initState() {
    super.initState();
    _updateValue();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateValue();
    });
  }

  void _updateValue() {
  final stats = widget.ref.read(dailyStatsProvider);
  
  // ===== ЛОГИРУЕМ ДАННЫЕ =====
  //logMessage('📊 [PROFIT_PER_KM] netProfit=${stats.netProfit}, totalDistance=${stats.totalDistance}', category: 'HOME');
  //logMessage('📊 [PROFIT_PER_KM] totalIncome=${stats.totalIncome}, totalExpenses=${stats.totalExpenses}', category: 'HOME');
  
  String newValue;
  if (stats.totalDistance <= 0) {
    newValue = '0.00';
  } else {
    final profit = stats.netProfit; // или stats.totalIncome
    newValue = (profit / stats.totalDistance).toStringAsFixed(2);
  }
  if (_value != newValue || _firstUpdate) {
    _firstUpdate = false;
    setState(() {
      _value = newValue;
    });
  }
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
      suffix: _value == '—' ? '' : ' ₽/ч',
    );
  }
}

// ============================================================
// ВРЕМЯ РАБОТЫ
// ============================================================
class _TimeDisplay extends StatefulWidget {
  final WidgetRef ref;
  const _TimeDisplay({required this.ref});

  @override
  State<_TimeDisplay> createState() => _TimeDisplayState();
}

class _TimeDisplayState extends State<_TimeDisplay> {
  Timer? _timer;
  String _formattedTime = '00:00:00';
  bool _firstUpdate = true;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
    });
  }

  void _updateTime() {
    final shiftState = widget.ref.read(shiftProvider);
    final newValue = shiftState.formattedWorkTime;
    if (_formattedTime != newValue || _firstUpdate) {
      _firstUpdate = false;
      setState(() {
        _formattedTime = newValue;
      });
    }
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

// ============================================================
// ВРЕМЯ ПРОСТОЯ
// ============================================================
class _IdleTimeDisplay extends StatefulWidget {
  final WidgetRef ref;
  const _IdleTimeDisplay({required this.ref});

  @override
  State<_IdleTimeDisplay> createState() => _IdleTimeDisplayState();
}

class _IdleTimeDisplayState extends State<_IdleTimeDisplay> {
  Timer? _timer;
  String _formattedTime = '00:00:00';
  bool _firstUpdate = true;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
    });
  }

  void _updateTime() {
    final shiftState = widget.ref.read(shiftProvider);
    final newValue = shiftState.formattedIdleTime;
    if (_formattedTime != newValue || _firstUpdate) {
      _firstUpdate = false;
      setState(() {
        _formattedTime = newValue;
      });
    }
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
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}