import 'package:flutter/material.dart';
import '../services/isbn_service.dart';

class IsbnScannerController {
  final IsbnService _service = IsbnService();

  Future<Map<String, dynamic>?> scanAndFetch(String isbn) async {
    return await _service.fetchBookByIsbn(isbn);
  }
}