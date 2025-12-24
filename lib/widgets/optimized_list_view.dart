import 'package:flutter/material.dart';

/// Performans optimizasyonlu ListView widget'ı
class OptimizedListView<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final EdgeInsets? padding;
  final ScrollController? controller;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final VoidCallback? onLoadMore;
  final bool hasMore;
  final Widget? emptyWidget;
  final Widget? loadingWidget;

  const OptimizedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.padding,
    this.controller,
    this.shrinkWrap = false,
    this.physics,
    this.onLoadMore,
    this.hasMore = false,
    this.emptyWidget,
    this.loadingWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return emptyWidget ??
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('Henüz veri bulunmuyor'),
            ),
          );
    }

    return ListView.builder(
      padding: padding,
      controller: controller,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: items.length + (hasMore ? 1 : 0),
      // Cache extent - görünür alanın dışındaki widget'ları cache'le
      cacheExtent: 500,
      // Item extent - sabit yükseklik varsa performans için kullanılabilir
      // itemExtent: 100,
      itemBuilder: (context, index) {
        // Load more indicator
        if (index == items.length) {
          return _LoadMoreWidget(
            onLoadMore: onLoadMore,
            loadingWidget: loadingWidget,
          );
        }

        return itemBuilder(context, items[index], index);
      },
    );
  }
}

class _LoadMoreWidget extends StatefulWidget {
  final VoidCallback? onLoadMore;
  final Widget? loadingWidget;

  const _LoadMoreWidget({
    this.onLoadMore,
    this.loadingWidget,
  });

  @override
  State<_LoadMoreWidget> createState() => _LoadMoreWidgetState();
}

class _LoadMoreWidgetState extends State<_LoadMoreWidget> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMore();
    });
  }

  void _loadMore() {
    if (!_isLoading && widget.onLoadMore != null) {
      setState(() => _isLoading = true);
      widget.onLoadMore!();
      // Loading state'i reset et
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.loadingWidget ??
        Container(
          padding: const EdgeInsets.all(16),
          alignment: Alignment.center,
          child: _isLoading
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _loadMore,
                  child: const Text('Daha Fazla Yükle'),
                ),
        );
  }
}

/// Virtual scrolling için optimize edilmiş grid view
class OptimizedGridView<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double childAspectRatio;
  final EdgeInsets? padding;
  final ScrollController? controller;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final VoidCallback? onLoadMore;
  final bool hasMore;

  const OptimizedGridView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.crossAxisCount = 2,
    this.crossAxisSpacing = 8.0,
    this.mainAxisSpacing = 8.0,
    this.childAspectRatio = 1.0,
    this.padding,
    this.controller,
    this.shrinkWrap = false,
    this.physics,
    this.onLoadMore,
    this.hasMore = false,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: padding,
      controller: controller,
      shrinkWrap: shrinkWrap,
      physics: physics,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: items.length + (hasMore ? 1 : 0),
      cacheExtent: 500,
      itemBuilder: (context, index) {
        if (index == items.length) {
          return _LoadMoreWidget(onLoadMore: onLoadMore);
        }
        return itemBuilder(context, items[index], index);
      },
    );
  }
}

