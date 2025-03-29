import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ModelProvider with ChangeNotifier {
  static const String _modelKey = 'selected_model';
  String _selectedModel = 'ConvNexT';

  ModelProvider() {
    _loadSelectedModel();
  }

  String get selectedModel => _selectedModel;

  // Load saved model from SharedPreferences
  Future<void> _loadSelectedModel() async {
    final prefs = await SharedPreferences.getInstance();
    final savedModel = prefs.getString(_modelKey);
    if (savedModel != null) {
      _selectedModel = savedModel;
      notifyListeners();
    }
  }

  void setSelectedModel(String model) {
    if (_selectedModel != model) {
      _selectedModel = model;
      _saveSelectedModel(model); // Save in background
      notifyListeners();
    }
  }

  // Save model to SharedPreferences
  Future<void> _saveSelectedModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modelKey, model);
  }
}
