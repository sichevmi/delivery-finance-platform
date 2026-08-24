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

// ============================================================
// ГЛОБАЛЬНЫЙ МЕНЕДЖЕР ДЛЯ КОЛИЧЕСТВА ЗАКАЗОВ
// ============================================================
class OrdersCountManager extends ChangeNotifier {
  static final OrdersCountManager _instance = OrdersCountManager._internal();
  factory OrdersCountManager() => _instance;
  OrdersCountManager._internal();

  int _count = 0;
  int get count => _count;

  void updateCount(int newCount) {
    if (_count != newCount) {
      _count = newCount;
      notifyListeners();
    }
  }
}

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
    
    // Подписываемся на изменения dailyStatsProvider для обновления менеджера заказов
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listen<DailyStats>(
        dailyStatsProvider,
        (previous, next) {
          // Обновляем только менеджер заказов
          OrdersCountManager().updateCount(next.ordersCount);
        },
      );
    });
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
        // Инициализируем менеджер заказов после загрузки данных
        final stats = ref.read(dailyStatsProvider);
        OrdersCountManager().updateCount(stats.ordersCount);
        
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
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Дата и статус смены
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 13, color: Color(0xFF888888)),
              const SizedBox(width: 6),
              Text(
                _getTodayDate(),
                style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: shiftState.isActive && !shiftState.isPaused && !shiftState.isCompleted 
                      ? Colors.green.withOpacity(0.15) 
                      : shiftState.isPaused 
                          ? Colors.orange.withOpacity(0.15) 
                          : Colors.grey.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: shiftState.isActive && !shiftState.isPaused && !shiftState.isCompleted 
                            ? Colors.green 
                            : shiftState.isPaused 
                                ? Colors.orange 
                                : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      shiftState.isCompleted ? 'Завершена' :
                      shiftState.isPaused ? 'Приостановлена' : 
                      shiftState.isActive ? 'Активна' : 'Не начата',
                      style: TextStyle(
                        fontSize: 11,
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
          const SizedBox(height: 8),

          // ===== ВЕРХНЯЯ СТРОКА: Время работы | Стоимость км | Время простоя =====
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _TimeDisplay(),
              _buildCostPerKm(totalCostPerKm),
              const _IdleTimeDisplay(),
            ],
          ),
          const SizedBox(height: 12),

          // ===== ПЕРВАЯ СТРОКА: Количество заказов =====
          const _OrdersCountMetric(),
          const SizedBox(height: 10),

          // ===== ВТОРАЯ И ТРЕТЬЯ СТРОКИ =====
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      const _TotalDistanceMetric(),
                      const SizedBox(height: 8),
                      const _IdleDistanceMetric(),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: const _ProfitMetric(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      const _ProfitPerKmMetric(),
                      const SizedBox(height: 8),
                      const _ProfitPerHourMetric(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          const _ExpensesMetric(),
          
          const Expanded(child: SizedBox()),

          SizedBox(
            height: 56,
            width: double.infinity,
            child: _buildShiftButton(shiftState),
          ),
        ],
      ),
    );
  }

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

  String _getTodayDate() {
    final now = DateTime.now();
    const weekdays = ['Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота', 'Воскресенье'];
    const months = ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'];
    return '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  Widget _buildCostPerKm(double totalCostPerKm) {
    return Text(
      '${totalCostPerKm.toStringAsFixed(2)} ₽/км',
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2C2C2C), width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: fontSize ?? 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
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
        ],
      ),
    );
  }
}

// ============================================================
// КОЛИЧЕСТВО ЗАКАЗОВ (ПОЛНОСТЬЮ НЕЗАВИСИМЫЙ ВИДЖЕТ)
// ============================================================
class _OrdersCountMetric extends StatefulWidget {
  const _OrdersCountMetric({super.key});

  @override
  State<_OrdersCountMetric> createState() => _OrdersCountMetricState();
}

class _OrdersCountMetricState extends State<_OrdersCountMetric> {
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _count = OrdersCountManager().count;
    OrdersCountManager().addListener(_onCountChanged);
  }

  void _onCountChanged() {
    if (mounted) {
      final newCount = OrdersCountManager().count;
      if (_count != newCount) {
        setState(() {
          _count = newCount;
        });
      }
    }
  }

  @override
  void dispose() {
    OrdersCountManager().removeListener(_onCountChanged);
    super.dispose();
  }

  String _getOrdersText(int count) {
    if (count % 10 == 1 && count % 100 != 11) return 'заказ';
    if (count % 10 >= 2 && count % 10 <= 4 && (count % 100 < 10 || count % 100 >= 20)) return 'заказа';
    return 'заказов';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2C2C2C), width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_bag, size: 24, color: Color(0xFF6C63FF)),
          const SizedBox(width: 10),
          Text(
            '$_count',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _getOrdersText(_count),
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF888888),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ПРОБЕГ (НЕЗАВИСИМЫЙ ВИДЖЕТ)
// ============================================================
class _TotalDistanceMetric extends ConsumerStatefulWidget {
  const _TotalDistanceMetric({super.key});

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
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) => _updateValue());
  }

  void _updateValue() {
    final stats = ref.read(dailyStatsProvider);
    final newValue = '${stats.totalDistance.toStringAsFixed(1)} км';
    if (_value != newValue) {
      setState(() => _value = newValue);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: _MetricCard(
        value: _value,
        label: 'Пробег',
        icon: Icons.route,
        color: Colors.blue,
        fontSize: 18,
      ),
    );
  }
}

// ============================================================
// ХОЛОСТОЙ ПРОБЕГ (НЕЗАВИСИМЫЙ ВИДЖЕТ)
// ============================================================
class _IdleDistanceMetric extends ConsumerStatefulWidget {
  const _IdleDistanceMetric({super.key});

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
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) => _updateValue());
  }

  void _updateValue() {
    final stats = ref.read(dailyStatsProvider);
    final newValue = '${stats.totalIdleDistance.toStringAsFixed(1)} км';
    if (_value != newValue) {
      setState(() => _value = newValue);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: _MetricCard(
        value: _value,
        label: 'Холостой',
        icon: Icons.ev_station,
        color: Colors.orange,
        fontSize: 18,
      ),
    );
  }
}

// ============================================================
// ДОХОД (НЕЗАВИСИМЫЙ ВИДЖЕТ)
// ============================================================
class _ProfitMetric extends ConsumerStatefulWidget {
  const _ProfitMetric({super.key});

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
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) => _updateValue());
  }

  void _updateValue() {
    final stats = ref.read(dailyStatsProvider);
    final newValue = '${stats.netProfit.toStringAsFixed(0)} ₽';
    if (_value != newValue) {
      setState(() => _value = newValue);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6C63FF).withOpacity(0.2),
            const Color(0xFF6C63FF).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
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
              const Icon(Icons.trending_up, size: 22, color: Color(0xFF6C63FF)),
              const SizedBox(width: 8),
              Text(
                _value,
                style: const TextStyle(
                  fontSize: 34,
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
              fontSize: 11,
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
// ПРИБЫЛЬ НА КМ (НЕЗАВИСИМЫЙ ВИДЖЕТ)
// ============================================================
class _ProfitPerKmMetric extends ConsumerStatefulWidget {
  const _ProfitPerKmMetric({super.key});

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
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) => _updateValue());
  }

  void _updateValue() {
    final stats = ref.read(dailyStatsProvider);
    String newValue;
    if (stats.totalDistance <= 0) {
      newValue = '0.00 ₽/км';
    } else {
      newValue = '${(stats.netProfit / stats.totalDistance).toStringAsFixed(2)} ₽/км';
    }
    if (_value != newValue) {
      setState(() => _value = newValue);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: _MetricCard(
        value: _value,
        label: 'Прибыль на км',
        icon: Icons.speed,
        color: Colors.cyan,
        fontSize: 16,
      ),
    );
  }
}

// ============================================================
// ПРИБЫЛЬ ЗА ЧАС (НЕЗАВИСИМЫЙ ВИДЖЕТ)
// ============================================================
class _ProfitPerHourMetric extends ConsumerStatefulWidget {
  const _ProfitPerHourMetric({super.key});

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
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) => _updateValue());
  }

  void _updateValue() {
    final stats = ref.read(dailyStatsProvider);
    String newValue;
    if (stats.totalWorkTime.inSeconds < 3600) {
      newValue = '—';
    } else {
      final hours = stats.totalWorkTime.inSeconds / 3600.0;
      if (hours <= 0) {
        newValue = '—';
      } else {
        newValue = '${(stats.netProfit / hours).toStringAsFixed(2)} ₽/ч';
      }
    }
    if (_value != newValue) {
      setState(() => _value = newValue);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: _MetricCard(
        value: _value,
        label: 'Прибыль за час',
        icon: Icons.access_time,
        color: Colors.purpleAccent,
        fontSize: 16,
      ),
    );
  }
}

// ============================================================
// РАСХОД (НЕЗАВИСИМЫЙ ВИДЖЕТ)
// ============================================================
class _ExpensesMetric extends ConsumerStatefulWidget {
  const _ExpensesMetric({super.key});

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
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) => _updateValue());
  }

  void _updateValue() {
    final stats = ref.read(dailyStatsProvider);
    final newValue = '${stats.totalExpenses.toStringAsFixed(0)} ₽';
    if (_value != newValue) {
      setState(() => _value = newValue);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2C2C2C), width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.money_off, size: 24, color: Colors.red),
          const SizedBox(width: 10),
          Text(
            _value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Расход',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF888888),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ВРЕМЯ РАБОТЫ (НЕЗАВИСИМЫЙ ВИДЖЕТ)
// ============================================================
class _TimeDisplay extends ConsumerStatefulWidget {
  const _TimeDisplay({super.key});

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
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) => _updateTime());
  }

  void _updateTime() {
    final shiftState = ref.read(shiftProvider);
    final newTime = shiftState.formattedWorkTime;
    if (_formattedTime != newTime) {
      setState(() => _formattedTime = newTime);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.access_time, size: 18, color: Color(0xFF888888)),
        const SizedBox(width: 6),
        Text(
          _formattedTime,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// ВРЕМЯ ПРОСТОЯ (НЕЗАВИСИМЫЙ ВИДЖЕТ)
// ============================================================
class _IdleTimeDisplay extends ConsumerStatefulWidget {
  const _IdleTimeDisplay({super.key});

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
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) => _updateTime());
  }

  void _updateTime() {
    final shiftState = ref.read(shiftProvider);
    final newTime = shiftState.formattedIdleTime;
    if (_formattedTime != newTime) {
      setState(() => _formattedTime = newTime);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.timer_off, size: 18, color: Color(0xFF888888)),
        const SizedBox(width: 6),
        Text(
          _formattedTime,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}