import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Singleton that downloads PDFs once and keeps them in the device temp dir.
/// Deduplicates concurrent download requests for the same URL.
class PdfCacheService {
  PdfCacheService._internal();
  static final PdfCacheService instance = PdfCacheService._internal();
  factory PdfCacheService() => instance;

  /// In-memory map: URL → local absolute file path
  final Map<String, String> _memoryCache = {};

  /// In-progress futures so concurrent callers share a single download
  final Map<String, Future<String?>> _inFlight = {};

  // ──────────────────────────────────────────────
  //  Public API
  // ──────────────────────────────────────────────

  /// Returns a local file path for the given [url].
  /// Downloads and caches on first access; returns the cached path on repeat calls.
  Future<String?> getLocalPath(String url) async {
    // 1. In-memory hit
    if (_memoryCache.containsKey(url)) {
      final path = _memoryCache[url]!;
      if (await File(path).exists()) return path;
      _memoryCache.remove(url); // stale entry
    }

    // 2. Deduplicate concurrent requests
    if (_inFlight.containsKey(url)) return _inFlight[url];

    final future = _downloadToCache(url);
    _inFlight[url] = future;
    final result = await future;
    _inFlight.remove(url);
    return result;
  }

  /// Remove [url] from cache so the next call to [getLocalPath] re-downloads it.
  /// Useful after an annotated PDF has been saved to the server.
  Future<void> invalidate(String url) async {
    final path = _memoryCache.remove(url);
    if (path != null) {
      try {
        final f = File(path);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
  }

  // ──────────────────────────────────────────────
  //  Internal
  // ──────────────────────────────────────────────

  Future<String?> _downloadToCache(String url) async {
    try {
      final dir = await getTemporaryDirectory();
      // Stable filename derived from URL hash so we survive warm restarts
      final filename = '${url.hashCode.abs()}.pdf';
      final file = File('${dir.path}/$filename');

      // Disk-level cache hit
      if (await file.exists()) {
        _memoryCache[url] = file.path;
        return file.path;
      }

      debugPrint('PdfCacheService: downloading $url');
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        _memoryCache[url] = file.path;
        debugPrint('PdfCacheService: cached to ${file.path}');
        return file.path;
      }
      debugPrint('PdfCacheService: download failed (${response.statusCode})');
      return null;
    } catch (e) {
      debugPrint('PdfCacheService error: $e');
      return null;
    }
  }
}
