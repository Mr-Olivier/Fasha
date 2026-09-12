import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';

/// Renders an image served by an AUTHENTICATED endpoint (KYC documents,
/// booking photos) - the kind of thing that's deliberately never reachable
/// through the public "/uploads/**" path avatars use, and so can't just be
/// an `Image.network(url)`, which has no way to attach the Authorization
/// header. Fetches the raw bytes through the app's own Dio instance (same
/// one ApiClient's auth interceptor already wraps) and renders them with
/// Image.memory instead.
class SecureNetworkImage extends ConsumerStatefulWidget {
  const SecureNetworkImage({super.key, required this.path, this.fit = BoxFit.cover, this.width, this.height});

  /// A path relative to the API base (e.g. "/bookings/$id/photos/$photoId"),
  /// same convention every other *Api class's Dio calls already use.
  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  ConsumerState<SecureNetworkImage> createState() => _SecureNetworkImageState();
}

class _SecureNetworkImageState extends ConsumerState<SecureNetworkImage> {
  late Future<Uint8List> _bytesFuture;

  @override
  void initState() {
    super.initState();
    _bytesFuture = _fetch();
  }

  @override
  void didUpdateWidget(covariant SecureNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _bytesFuture = _fetch();
    }
  }

  Future<Uint8List> _fetch() async {
    final dio = ref.read(apiClientProvider).dio;
    final response = await dio.get<List<int>>(widget.path, options: Options(responseType: ResponseType.bytes));
    return Uint8List.fromList(response.data!);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _bytesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return SizedBox(
            width: widget.width,
            height: widget.height,
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return SizedBox(
            width: widget.width,
            height: widget.height,
            child: const Center(child: Icon(Icons.broken_image_outlined)),
          );
        }
        return Image.memory(snapshot.data!, width: widget.width, height: widget.height, fit: widget.fit);
      },
    );
  }
}
