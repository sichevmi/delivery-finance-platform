import 'package:flutter/material.dart';
import 'directories/expenses_directory.dart';
import 'directories/x5_directory.dart';
import 'directories/other_directory.dart';

class DirectoriesTab extends StatefulWidget {
  const DirectoriesTab({super.key});

  @override
  State<DirectoriesTab> createState() => _DirectoriesTabState();
}

class _DirectoriesTabState extends State<DirectoriesTab> {
  int _selectedIndex = 0;
  bool _isLoading = true;

  final List<String> _tabs = ['Расходы', 'X5', 'Иное'];
  final List<Widget> _pages = const [
    ExpensesDirectory(),
    X5Directory(),
    OtherDirectory(),
  ];

  @override
  void initState() {
    super.initState();
    _simulateLoading();
  }

  Future<void> _simulateLoading() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2C2C2C), width: 1),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: List.generate(
                _tabs.length,
                (index) => Expanded(
                  child: GestureDetector(
                    onTap: _isLoading
                        ? null
                        : () {
                            setState(() {
                              _selectedIndex = index;
                            });
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedIndex == index
                            ? const Color(0xFF6C63FF)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _tabs[index],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _selectedIndex == index
                              ? Colors.white
                              : const Color(0xFF888888),
                          fontWeight: _selectedIndex == index
                              ? FontWeight.w600
                              : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _pages[_selectedIndex],
        ),
      ],
    );
  }
}