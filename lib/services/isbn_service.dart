import 'dart:convert';
import 'package:http/http.dart' as http;

class IsbnService {
  Future<Map<String, dynamic>?> fetchBookByIsbn(String isbn) async {
    final url = Uri.parse(
        "https://www.googleapis.com/books/v1/volumes?q=isbn:$isbn");

    final res = await http.get(url);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      if (data["items"] != null) {
        final book = data["items"][0]["volumeInfo"];

        return {
          "titre": book["title"] ?? "",
          "auteur": (book["authors"] != null)
              ? (book["authors"] as List).join(", ")
              : "",
          "imageUrl": book["imageLinks"]?["thumbnail"],
          "resume": book["description"] ?? "",
        };
      }
    }
    return null;
  }
}