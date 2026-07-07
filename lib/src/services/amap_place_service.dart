import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/amap_config.dart';
import '../models/life_category.dart';
import '../models/place.dart';

/// 高德坐标点。
///
/// 独立定义轻量坐标模型，是为了让定位、地图和 POI 服务共用同一种数据结构，
/// 避免在业务层直接依赖第三方定位插件返回的具体类型。
class AmapCoordinate {
  const AmapCoordinate({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

/// 当前位置的人类可读信息。
///
/// 逆地理编码不仅返回经纬度，还返回街道地址和附近地标；页面用这些信息解释当前位置，
/// 解决“地图上只有大概方位、没有具体位置说明”的问题。
class AmapLocationSummary {
  const AmapLocationSummary({
    required this.formattedAddress,
    required this.nearbyLandmarks,
  });

  final String formattedAddress;
  final List<String> nearbyLandmarks;
}

/// 周边搜索结果。
///
/// 记录命中的半径，是为了在页面上明确告诉用户结果来自多大范围，
/// 同时验证“先找最近，找不到再扩大范围”的搜索策略。
class AmapPlaceSearchResult {
  const AmapPlaceSearchResult({
    required this.places,
    required this.radiusMeters,
  });

  final List<Place> places;
  final int radiusMeters;
}

/// 高德 WebService 调用异常。
///
/// 使用专门异常类型可以让 UI 精准地区分配置缺失、网络失败和接口返回错误，
/// 后续展示提示或降级到本地模拟数据时不会吞掉真实原因。
class AmapServiceException implements Exception {
  const AmapServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 周边地点服务接口。
///
/// 页面只依赖接口，是为了把真实高德网络请求和页面交互解耦；
/// 测试可以注入固定返回值，正式运行则使用 [AmapPlaceService]。
abstract class NearbyPlaceProvider {
  Future<AmapCoordinate> convertGpsToAmap({
    required double latitude,
    required double longitude,
  });

  Future<AmapLocationSummary> reverseGeocode({
    required double latitude,
    required double longitude,
  });

  Future<AmapPlaceSearchResult> searchNearestPlaces({
    required LifeCategory category,
    required double latitude,
    required double longitude,
  });
}

/// 高德 POI 与地理编码服务。
///
/// 页面只关心“给定类别和坐标返回附近点位”，具体的高德接口参数、坐标转换和解析细节
/// 收敛在这里，避免 UI 直接拼 REST URL 或解析接口 JSON。
class AmapPlaceService implements NearbyPlaceProvider {
  AmapPlaceService({
    required this.config,
    http.Client? client,
    this.searchRadiiMeters = const [1000, 3000, 5000, 10000, 20000, 50000],
  }) : _client = client ?? http.Client();

  final AmapConfig config;
  final http.Client _client;

  /// 搜索半径从小到大递增。
  ///
  /// 用户要的是最近结果，不是固定 5 公里内有就显示、没有就失败；因此先查近处，
  /// 如果没有结果再逐级扩大到 50 公里，命中后仍按接口返回距离排序。
  final List<int> searchRadiiMeters;

  @override
  Future<AmapCoordinate> convertGpsToAmap({
    required double latitude,
    required double longitude,
  }) async {
    final data = await _getJson(
      config.buildCoordinateConvertUri(
        latitude: latitude,
        longitude: longitude,
      ),
    );
    final rawLocations = _stringValue(data['locations']);
    final coordinate = _parseCoordinate(rawLocations);
    if (coordinate == null) {
      throw const AmapServiceException('高德坐标转换结果为空');
    }

    return coordinate;
  }

  @override
  Future<AmapLocationSummary> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final data = await _getJson(
      config.buildReverseGeocodeUri(latitude: latitude, longitude: longitude),
    );
    final regeocode = data['regeocode'];
    if (regeocode is! Map<String, dynamic>) {
      return const AmapLocationSummary(
        formattedAddress: '当前位置',
        nearbyLandmarks: [],
      );
    }

    final pois = regeocode['pois'];
    final landmarks = pois is List
        ? pois
              .map((poi) => poi is Map<String, dynamic> ? poi['name'] : null)
              .map(_stringValue)
              .where((name) => name.isNotEmpty)
              .take(3)
              .toList()
        : <String>[];

    return AmapLocationSummary(
      formattedAddress: _stringValue(regeocode['formatted_address']).isEmpty
          ? '当前位置'
          : _stringValue(regeocode['formatted_address']),
      nearbyLandmarks: landmarks,
    );
  }

  @override
  Future<AmapPlaceSearchResult> searchNearestPlaces({
    required LifeCategory category,
    required double latitude,
    required double longitude,
  }) async {
    _ensureConfig();

    for (final radius in searchRadiiMeters) {
      final data = await _getJson(
        config.buildAroundSearchUri(
          keyword: category.amapKeyword,
          types: category.amapTypes,
          latitude: latitude,
          longitude: longitude,
          radiusMeters: radius,
        ),
      );
      final places = _parsePlaces(data, category.id)
        ..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

      if (places.isNotEmpty) {
        return AmapPlaceSearchResult(places: places, radiusMeters: radius);
      }
    }

    return AmapPlaceSearchResult(
      places: const [],
      radiusMeters: searchRadiiMeters.last,
    );
  }

  void dispose() {
    _client.close();
  }

  void _ensureConfig() {
    if (!config.hasWebServiceConfig) {
      throw const AmapServiceException('缺少高德 WebService Key');
    }
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    _ensureConfig();

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw AmapServiceException('高德接口请求失败：HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw const AmapServiceException('高德接口返回格式异常');
    }

    if (_stringValue(decoded['status']) != '1') {
      final info = _stringValue(decoded['info']);
      throw AmapServiceException(info.isEmpty ? '高德接口返回失败' : info);
    }

    return decoded;
  }

  List<Place> _parsePlaces(Map<String, dynamic> data, String categoryId) {
    final pois = data['pois'];
    if (pois is! List) {
      return const [];
    }

    return pois
        .map(
          (poi) =>
              poi is Map<String, dynamic> ? _parsePlace(poi, categoryId) : null,
        )
        .whereType<Place>()
        .toList();
  }

  Place? _parsePlace(Map<String, dynamic> poi, String categoryId) {
    final coordinate = _parseCoordinate(_stringValue(poi['location']));
    if (coordinate == null) {
      return null;
    }

    final name = _stringValue(poi['name']);
    if (name.isEmpty) {
      return null;
    }

    final id = _stringValue(poi['id']).isEmpty
        ? '$categoryId-${coordinate.longitude}-${coordinate.latitude}-$name'
        : _stringValue(poi['id']);
    final type = _stringValue(poi['type']);

    return Place(
      id: id,
      categoryId: categoryId,
      name: name,
      address: _stringValue(poi['address']).isEmpty
          ? '地址待确认'
          : _stringValue(poi['address']),
      latitude: coordinate.latitude,
      longitude: coordinate.longitude,
      distanceMeters: int.tryParse(_stringValue(poi['distance'])) ?? 0,
      openStatus: type.isEmpty ? '高德 POI' : type,
      phone: _nullableString(poi['tel']),
    );
  }

  AmapCoordinate? _parseCoordinate(String rawLocation) {
    final parts = rawLocation.split(',');
    if (parts.length < 2) {
      return null;
    }

    final longitude = double.tryParse(parts[0]);
    final latitude = double.tryParse(parts[1]);
    if (latitude == null || longitude == null) {
      return null;
    }

    return AmapCoordinate(latitude: latitude, longitude: longitude);
  }

  String _stringValue(Object? value) {
    if (value == null || value is List) {
      return '';
    }

    return value.toString();
  }

  String? _nullableString(Object? value) {
    final text = _stringValue(value);
    return text.isEmpty ? null : text;
  }
}
