import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/recitation_service.dart';

class InstalledReciters {
  const InstalledReciters(this.ids);
  final Set<int> ids;

  bool contains(int id) => ids.contains(id);

  InstalledReciters add(int id) {
    if (ids.contains(id)) return this;
    return InstalledReciters({...ids, id});
  }

  InstalledReciters remove(int id) {
    if (!ids.contains(id)) return this;
    final next = {...ids}..remove(id);
    return InstalledReciters(next);
  }
}

class InstalledRecitersNotifier extends StateNotifier<InstalledReciters> {
  InstalledRecitersNotifier() : super(const InstalledReciters({}));

  Future<void> markInstalled(int id) async {
    state = state.add(id);
  }

  Future<void> markUninstalled(int id) async {
    state = state.remove(id);
  }

  Future<void> refreshFor(Iterable<int> ids) async {
    final next = <int>{};
    for (final id in ids) {
      if (await RecitationService.instance.isInstalled(id)) next.add(id);
    }
    state = InstalledReciters(next);
  }
}

final installedRecitersProvider =
    StateNotifierProvider<InstalledRecitersNotifier, InstalledReciters>(
        (ref) => InstalledRecitersNotifier());
