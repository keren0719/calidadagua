import 'package:flutter/foundation.dart';

import '../data/models/analysis_result.dart';
import '../data/models/analysis_type.dart';
import 'app_services.dart';

/// Historial del usuario con sesión iniciada.
class HistoryController extends ChangeNotifier {
  HistoryController(this._services);

  final AppServices _services;

  String? _userId;
  List<AnalysisResult> _items = const [];
  bool _loading = false;

  List<AnalysisResult> get items => _items;
  bool get loading => _loading;

  int countOf(AnalysisType type) => _items.where((r) => r.type == type).length;

  int get issuesCount => _items.where((r) => r.status != ResultStatus.good).length;

  Future<void> load(String userId) async {
    _userId = userId;
    _loading = true;
    notifyListeners();
    _items = await _services.history.getAll(userId);
    _loading = false;
    notifyListeners();
  }

  /// Guarda un resultado nuevo (si el usuario lo tiene activado en Configuración).
  Future<AnalysisResult> add(
    AnalysisResult result, {
    Uint8List? imageBytes,
    String imageExtension = 'jpg',
  }) async {
    final userId = _userId;
    if (userId == null || !_services.settings.saveHistory) return result;
    final stored = await _services.history.save(
      userId,
      result,
      imageBytes: imageBytes,
      imageExtension: imageExtension,
    );
    _items = [stored, ..._items];
    notifyListeners();
    return stored;
  }

  Future<void> remove(String id) async {
    final userId = _userId;
    if (userId == null) return;
    _items = _items.where((r) => r.id != id).toList();
    notifyListeners();
    await _services.history.delete(userId, id);
  }

  Future<void> clear() async {
    final userId = _userId;
    if (userId == null) return;
    _items = const [];
    notifyListeners();
    await _services.history.clear(userId);
  }

  void reset() {
    _userId = null;
    _items = const [];
    notifyListeners();
  }
}
