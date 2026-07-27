import 'package:flutter_riverpod/flutter_riverpod.dart';

class ShiftState {
  final bool isActive;
  final DateTime? startTime;
  final DateTime? endTime;

  ShiftState({
    this.isActive = false,
    this.startTime,
    this.endTime,
  });

  ShiftState copyWith({
    bool? isActive,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return ShiftState(
      isActive: isActive ?? this.isActive,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}

class ShiftNotifier extends StateNotifier<ShiftState> {
  ShiftNotifier() : super(ShiftState());

  void toggleShift() {
    if (state.isActive) {
      // Завершаем смену
      state = state.copyWith(
        isActive: false,
        endTime: DateTime.now(),
      );
    } else {
      // Начинаем смену
      state = state.copyWith(
        isActive: true,
        startTime: DateTime.now(),
        endTime: null,
      );
    }
  }
}

final shiftProvider = StateNotifierProvider<ShiftNotifier, ShiftState>((ref) {
  return ShiftNotifier();
});