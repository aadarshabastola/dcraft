import 'dart:typed_data';
import 'dart:ui';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:path_provider/path_provider.dart';

/// Southwest US region bounds (Arizona, New Mexico, Utah, Colorado, and northern Mexico)
class SouthwestRegion {
  // Approximate bounding box:
  // North: ~42° (southern Wyoming/Colorado border)
  // South: ~28° (northern Mexico)
  // West: ~115° (Nevada/Arizona border)
  // East: ~103° (eastern Colorado/New Mexico)
  static const double north = 42.0;
  static const double south = 28.0;
  static const double west = -115.0;
  static const double east = -103.0;

  // Zoom levels to download (higher = more detail but more tiles)
  // Zoom 6-10 provides good coverage under 100MB
  static const int minZoom = 6;
  static const int maxZoom = 10;
}

/// Progress info for tile downloads
class DownloadProgress {
  final int downloadedTiles;
  final int totalTiles;
  final int downloadedBytes;
  
  DownloadProgress({
    required this.downloadedTiles,
    required this.totalTiles,
    required this.downloadedBytes,
  });
  
  double get progress => totalTiles > 0 ? downloadedTiles / totalTiles : 0.0;
  
  String get downloadedSizeMB => (downloadedBytes / (1024 * 1024)).toStringAsFixed(1);
  
  /// Estimate total size based on average tile size (~15KB per tile)
  String get estimatedTotalSizeMB => ((totalTiles * 15 * 1024) / (1024 * 1024)).toStringAsFixed(0);
}

/// A custom [TileProvider] that caches tiles using Dio + Hive.
/// Tiles are cached indefinitely for offline use.
class CachedTileProvider extends TileProvider {
  CachedTileProvider._internal(this._dio);

  final Dio _dio;

  static CachedTileProvider? _instance;
  static bool _initialized = false;

  /// Initialize the caching tile provider. Call once at app startup.
  static Future<void> init() async {
    if (_initialized) return;

    final cacheDir = await getApplicationDocumentsDirectory();
    final cacheStore = HiveCacheStore('${cacheDir.path}/map_tile_cache');

    final cacheOptions = CacheOptions(
      store: cacheStore,
      policy: CachePolicy.forceCache, // always try cache first
      maxStale: const Duration(days: 365), // keep tiles for a year
    );

    final dio = Dio()
      ..interceptors.add(DioCacheInterceptor(options: cacheOptions));

    _instance = CachedTileProvider._internal(dio);
    _initialized = true;
  }

  /// Get the singleton instance. Must call [init] first.
  static CachedTileProvider get instance {
    if (!_initialized || _instance == null) {
      throw StateError(
          'CachedTileProvider not initialized. Call CachedTileProvider.init() first.');
    }
    return _instance!;
  }

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final url = getTileUrl(coordinates, options);
    return CachedNetworkImageProvider(url, _dio);
  }

  /// Convert latitude to tile Y coordinate
  static int _latToTileY(double lat, int zoom) {
    final latRad = lat * math.pi / 180;
    final n = math.pow(2, zoom);
    return ((1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) /
            2 *
            n)
        .floor();
  }

  /// Convert longitude to tile X coordinate
  static int _lonToTileX(double lon, int zoom) {
    final n = math.pow(2, zoom);
    return ((lon + 180) / 360 * n).floor();
  }

  /// Calculate total tiles for the Southwest region
  static int getTotalTileCount() {
    int total = 0;
    for (int z = SouthwestRegion.minZoom; z <= SouthwestRegion.maxZoom; z++) {
      final minX = _lonToTileX(SouthwestRegion.west, z);
      final maxX = _lonToTileX(SouthwestRegion.east, z);
      final minY = _latToTileY(SouthwestRegion.north, z); // north has smaller Y
      final maxY = _latToTileY(SouthwestRegion.south, z);
      total += (maxX - minX + 1) * (maxY - minY + 1);
    }
    return total;
  }

  /// Download all tiles for the Southwest US region.
  /// Returns a stream of [DownloadProgress] with tile count and bytes.
  static Stream<DownloadProgress> downloadSouthwestRegion() async* {
    if (!_initialized || _instance == null) {
      throw StateError('CachedTileProvider not initialized');
    }

    final dio = _instance!._dio;
    final totalTiles = getTotalTileCount();
    int downloadedTiles = 0;
    int downloadedBytes = 0;

    for (int z = SouthwestRegion.minZoom; z <= SouthwestRegion.maxZoom; z++) {
      final minX = _lonToTileX(SouthwestRegion.west, z);
      final maxX = _lonToTileX(SouthwestRegion.east, z);
      final minY = _latToTileY(SouthwestRegion.north, z);
      final maxY = _latToTileY(SouthwestRegion.south, z);

      for (int x = minX; x <= maxX; x++) {
        for (int y = minY; y <= maxY; y++) {
          final url = 'https://tile.openstreetmap.org/$z/$x/$y.png';
          try {
            final response = await dio.get<List<int>>(
              url,
              options: Options(responseType: ResponseType.bytes),
            );
            if (response.data != null) {
              downloadedBytes += response.data!.length;
            }
          } catch (_) {
            // Skip failed tiles silently
          }
          downloadedTiles++;
          yield DownloadProgress(
            downloadedTiles: downloadedTiles,
            totalTiles: totalTiles,
            downloadedBytes: downloadedBytes,
          );
        }
      }
    }
  }
}

/// An [ImageProvider] that fetches images via Dio (with caching).
class CachedNetworkImageProvider extends ImageProvider<CachedNetworkImageProvider> {
  final String url;
  final Dio dio;

  CachedNetworkImageProvider(this.url, this.dio);

  @override
  Future<CachedNetworkImageProvider> obtainKey(ImageConfiguration configuration) {
    return Future.value(this);
  }

  @override
  ImageStreamCompleter loadImage(
      CachedNetworkImageProvider key, ImageDecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: 1.0,
    );
  }

  Future<Codec> _loadAsync(
      CachedNetworkImageProvider key, ImageDecoderCallback decode) async {
    final response = await dio.get<List<int>>(
      key.url,
      options: Options(responseType: ResponseType.bytes),
    );

    final bytes = Uint8List.fromList(response.data!);
    final buffer = await ImmutableBuffer.fromUint8List(bytes);
    return decode(buffer);
  }

  @override
  bool operator ==(Object other) {
    if (other is CachedNetworkImageProvider) {
      return url == other.url;
    }
    return false;
  }

  @override
  int get hashCode => url.hashCode;
}
