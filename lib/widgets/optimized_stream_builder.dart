import 'package:flutter/material.dart';
import 'dart:async';

/// Performans optimizasyonlu StreamBuilder
/// - Debounce desteği
/// - Error handling
/// - Loading state management
class OptimizedStreamBuilder<T> extends StatelessWidget {
  final Stream<T> stream;
  final Widget Function(BuildContext, T) builder;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final T? initialData;
  final Duration? debounce;
  final bool showLoadingOnRefresh;

  const OptimizedStreamBuilder({
    super.key,
    required this.stream,
    required this.builder,
    this.loadingWidget,
    this.errorWidget,
    this.initialData,
    this.debounce,
    this.showLoadingOnRefresh = false,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: debounce != null ? _debounceStream(stream, debounce!) : stream,
      initialData: initialData,
      builder: (context, snapshot) {
        // Error state
        if (snapshot.hasError) {
          return errorWidget ??
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Hata: ${snapshot.error}',
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
        }

        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting &&
            (showLoadingOnRefresh || snapshot.data == null)) {
          return loadingWidget ??
              const Center(
                child: CircularProgressIndicator(),
              );
        }

        // Data state
        if (snapshot.hasData) {
          return builder(context, snapshot.data as T);
        }

        // Empty state
        return const Center(
          child: Text('Veri bulunamadı'),
        );
      },
    );
  }

  Stream<T> _debounceStream(Stream<T> stream, Duration delay) {
    StreamController<T>? controller;
    StreamSubscription<T>? subscription;
    Timer? timer;

    controller = StreamController<T>(
      onListen: () {
        subscription = stream.listen(
          (data) {
            timer?.cancel();
            timer = Timer(delay, () {
              controller!.add(data);
            });
          },
          onError: (error) => controller!.addError(error),
          onDone: () => controller!.close(),
          cancelOnError: false,
        );
      },
      onCancel: () {
        timer?.cancel();
        subscription?.cancel();
      },
    );

    return controller.stream;
  }
}

/// Performans optimizasyonlu FutureBuilder
class OptimizedFutureBuilder<T> extends StatelessWidget {
  final Future<T> future;
  final Widget Function(BuildContext, T) builder;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final T? initialData;

  const OptimizedFutureBuilder({
    super.key,
    required this.future,
    required this.builder,
    this.loadingWidget,
    this.errorWidget,
    this.initialData,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      initialData: initialData,
      builder: (context, snapshot) {
        // Error state
        if (snapshot.hasError) {
          return errorWidget ??
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Hata: ${snapshot.error}',
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
        }

        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget ??
              const Center(
                child: CircularProgressIndicator(),
              );
        }

        // Data state
        if (snapshot.hasData) {
          return builder(context, snapshot.data as T);
        }

        // Empty state
        return const Center(
          child: Text('Veri bulunamadı'),
        );
      },
    );
  }
}

