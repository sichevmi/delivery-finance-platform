import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/lib/features/auth/providers/auth_provider.dart';
import 'package:delivery_app/lib/features/delivery/providers/shift_provider.dart';
import 'package:delivery_app/lib/features/delivery/providers/tab_provider.dart';
import 'package:delivery_app/lib/features/delivery/ui/widgets/metrics_grid.dart';
import 'package:delivery_app/lib/features/delivery/ui/widgets/start_shift_button.dart';
import 'package:delivery_app/lib/features/delivery/ui/tabs/orders_tab.dart';
import 'package:delivery_app/lib/features/delivery/ui/tabs/analytics_tab.dart';
import 'package:delivery_app/lib/features/delivery/ui/tabs/directories_tab.dart';
import 'package:delivery_app/lib/features/delivery/ui/tabs/more_tab.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(), // Главная
    GlobalKey<NavigatorState>(), // Заказы
    GlobalKey<NavigatorState>(), // Справочники
    GlobalKey<NavigatorState>(), // Аналитика
    GlobalKey<NavigatorState>(), // Ещё
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
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final shiftState = ref.watch(shiftProvider);
    final selectedTab = ref.watch(selectedTabProvider); // <-- слушаем провайдер

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
                  : 'K',
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
          _buildHomeTab(shiftState),
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

  Widget _buildHomeTab(ShiftState shiftState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: Color(0xFF888888)),
              const SizedBox(width: 6),
              Text(_getTodayDate(), style: const TextStyle(fontSize: 14, color: Color(0xFF888888))),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: shiftState.isActive ? Colors.green.withOpacity(0.15) : Colors.grey.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: shiftState.isActive ? Colors.green : Colors.grey, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text(
                      shiftState.isActive ? 'Смена активна' : 'Смена не начата',
                      style: TextStyle(fontSize: 12, color: shiftState.isActive ? Colors.green : Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text('📊 Основные показатели', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              Spacer(),
              Text('За сутки', style: TextStyle(fontSize: 13, color: Color(0xFF888888))),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Expanded(
          flex: 5,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: MetricsGrid(),
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(height: 50, child: StartShiftButton()),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  String _getTodayDate() {
    final now = DateTime.now();
    const weekdays = ['Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота', 'Воскресенье'];
    const months = ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'];
    return '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }
}