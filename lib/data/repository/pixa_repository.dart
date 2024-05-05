import 'package:demo_pix_app/core/conts/app_consts.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

import '../models/pixabaymodel.dart';

/// Класс PixaRepository отвечает за взаимодействие с API Pixabay.
class PixaRepository {
  final Dio _dio = Dio();
  final int itemsPerPage = 20;

  /// Метод getPixa используется для получения списка изображений с API Pixabay.
  /// Он принимает два необязательных параметра: @[page] (страница) и @[query] (поисковый запрос).
  Future<List<Hit>> getPixa({int page = 1, String query = ''}) async {
    try {
      final response = await _dio.get(
        AppConsts.baseUrl,
        queryParameters: {
          "key": AppConsts.key,
          "page": page.toString(),
          "per_page": itemsPerPage.toString(),
          'q': query
        },
      );

      if (response.statusCode == 200) {
        final postsResult = response.data['hits'] as List;
        final post = postsResult.map((e) => Hit.fromJson(e)).toList();
        return post;
      } else {
        throw Exception('Ошибка при получении данных из сети');
      }
    } catch (e) {
      debugPrint(e.toString());
      throw Exception('Ошибка при получении данных');
    }
  }
}
