import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/features/analytics/models/analytics_models.dart';
import 'package:delivery_app/features/analytics/models/analytics_enums.dart';
import 'package:delivery_app/features/analytics/services/analytics_repository.dart';

class AnalyticsState {
  final AnalyticsData? data;
  final bool isLoading;
  final String? error;
  final AnalyticsPeriod period;
  final int year;
  final int? month;
  final int? day;

  const AnalyticsState({
    this.data,
    this.isLoading = false,
    this.error,
    this.period = AnalyticsPeriod.year,
    required this.year,
    this.month,
    this.day,
  });

  AnalyticsState copyWith({
    AnalyticsData? data,
    bool? isLoading,
    String? error,
    AnalyticsPeriod? period,
    int? year,
    int? month,
    int? day,
    bool clearMonth = false,
    bool clearDay = false,
  }) {
    return AnalyticsState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      period: period ?? this.period,
      year: year ?? this.year,
      month: clearMonth ? null : (month ?? this.month),
      day: clearDay ? null : (day ?? this.day),
    );
  }
}

final analyticsProvider =
    StateNotifierProvider<AnalyticsNotifier, AnalyticsState>((ref) {
  return AnalyticsNotifier(AnalyticsRepository());
});

class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  final AnalyticsRepository _repository;

  AnalyticsNotifier(this._repository)
      : super(AnalyticsState(year: DateTime.now().year));

  Future<void> load({
    AnalyticsPeriod? period,
    int? year,
    int? month,
    int? day,
  }) async {
    final p = period ?? state.period;
    final y = year ?? state.year;
    int? m = month ?? state.month;
    int? d = day ?? state.day;

    // Корректируем вложенность периодов
    if (p == AnalyticsPeriod.year) {
      m = null;
      d = null;
    } else if (p == AnalyticsPeriod.month) {
      m ??= DateTime.now().month;
      d = null;
    } else {
      m ??= DateTime.now().month;
      d ??= DateTime.now().day;
    }

    state = state.copyWith(
      isLoading: true,
      period: p,
      year: y,
      month: m,
      day: d,
      clearMonth: m == null,
      clearDay: d == null,
      error: null,
    );

    try {
      final data = await _repository.getData(
        year: y,
        month: m,
        day: d,
        period: p,
      );
      state = state.copyWith(data: data, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => load();
}