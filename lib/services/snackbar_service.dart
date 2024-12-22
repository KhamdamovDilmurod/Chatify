import 'package:flutter/material.dart';

class SnackBarService {
  late BuildContext _buildContext; // Marked 'late' to indicate it will be initialized later.

  static final SnackBarService instance = SnackBarService();

  SnackBarService();

  set buildContext(BuildContext context) {
    _buildContext = context;
  }

  void showSnackBarError(String message) {
    ScaffoldMessenger.of(_buildContext).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  void showSnackBarSuccess(String message) {
    ScaffoldMessenger.of(_buildContext).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

}
