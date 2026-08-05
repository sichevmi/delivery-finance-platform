import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/logger.dart';

final selectedTabProvider = StateProvider<int>((ref) => 0);