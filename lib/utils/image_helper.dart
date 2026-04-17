// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart';

// class BookImage extends StatelessWidget {
//   final String? imageUrl;
//   final File? imageFile;

//   const BookImage({super.key, this.imageUrl, this.imageFile});

//   @override
//   Widget build(BuildContext context) {
//     // WEB fallback
//     if (kIsWeb) {
//       if (imageUrl != null && imageUrl!.isNotEmpty) {
//         return Image.network(imageUrl!, fit: BoxFit.cover);
//       }
//       return const Icon(Icons.menu_book, size: 50);
//     }

//     // MOBILE
//     if (imageFile != null) {
//       return Image.file(imageFile!, fit: BoxFit.cover);
//     }

//     if (imageUrl != null && imageUrl!.isNotEmpty) {
//       return Image.network(imageUrl!, fit: BoxFit.cover);
//     }

//     return const Icon(Icons.menu_book, size: 50);
//   }
// }