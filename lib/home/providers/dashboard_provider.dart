import 'package:flutter/foundation.dart';

import '../../services/api_client.dart';
import '../models/dashboard_models.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  DashboardData? _dashboardData;
  bool _loading = false;
  String? _error;
  bool _hasLoadedOnce = false;

  DashboardData? get dashboardData => _dashboardData;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasData => _dashboardData != null;
  bool get hasLoadedOnce => _hasLoadedOnce;

  Future<void> loadData({required String token}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _dashboardData = await _api.getDashboard(token: token);
      _hasLoadedOnce = true;
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> refresh({required String token}) => loadData(token: token);

  void reset() {
    _dashboardData = null;
    _loading = false;
    _error = null;
    _hasLoadedOnce = false;
    notifyListeners();
  }
}
