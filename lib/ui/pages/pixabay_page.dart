import 'dart:async';

import 'package:demo_pix_app/data/models/pixabaymodel.dart';
import 'package:demo_pix_app/data/repository/pixa_repository.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../widgets/full_screen_image.dart';

class PixabayPage extends StatefulWidget {
  const PixabayPage({Key? key}) : super(key: key);

  @override
  State<PixabayPage> createState() => _PixabayPageState();
}

class _PixabayPageState extends State<PixabayPage> {
  final PixaRepository _pixaRepository = PixaRepository();
  final PagingController<int, Hit> _pagingController =
      PagingController(firstPageKey: 1);
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pagingController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _pagingController.refresh();
    });
  }

  void _openFullScreenImage(String imageUrl) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            FullScreenImage(imageUrl: imageUrl),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final newItems = await _pixaRepository.getPixa(
          page: pageKey, query: _searchController.text);
      final isLastPage = newItems.length < _pixaRepository.itemsPerPage;

      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(newItems, nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sizeMQ = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        title: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: const InputDecoration(
            hintText: 'Search ...',
            border: InputBorder.none,
          ),
          style: const TextStyle(color: Colors.black),
        ),
      ),
      body: PagedGridView<int, Hit>(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: sizeMQ.width > 600 ? 4 : 2,
        ),
        pagingController: _pagingController,
        builderDelegate: PagedChildBuilderDelegate<Hit>(
          firstPageProgressIndicatorBuilder: (_) =>
              const Center(child: CircularProgressIndicator()),
          newPageProgressIndicatorBuilder: (_) =>
              const Center(child: CircularProgressIndicator()),
          itemBuilder: (context, item, index) => GestureDetector(
            onTap: () => _openFullScreenImage(item.largeImageUrl!),
            child: Column(
              children: [
                Image.network(
                  item.largeImageUrl!,
                  fit: BoxFit.fill,
                  height: 150,
                  width: 150,
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.favorite, color: Colors.red, size: 14),
                      Text(item.likes.toString()),
                      const SizedBox(width: 10),
                      const Icon(Icons.remove_red_eye,
                          color: Colors.blue, size: 14),
                      Text(item.views.toString()),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
