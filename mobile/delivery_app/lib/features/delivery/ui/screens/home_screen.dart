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

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  Timer? _ticker;

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTicker();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startTicker();
    } else if (state == AppLifecycleState.paused) {
      _ticker?.cancel();
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Принудительно обновляем провайдеры, чтобы UI перестраивался
      ref.invalidate(shiftProvider);
      ref.invalidate(dailyStatsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
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
                _buildTimeCard(
                  icon: Icons.timer,
                  value: stats.formattedWorkTime,
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
                _buildMetricCard(
                  value: '${stats.totalIdleDistance.toStringAsFixed(1)} км',
                  label: 'Холостой пробег',
                  color: Colors.red,
                ),
                const SizedBox(width: 6),
                _buildMetricCard(
                  value: stats.formattedIdleTime,
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