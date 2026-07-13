/// 高德开放平台配置。
///
/// 真实 Key 通过 `--dart-define-from-file=env/amap.local.json` 注入，
/// 代码仓库只保留读取入口和示例文件，避免把截图里的真实 Key 提交到 Git。
class AmapConfig {
  const AmapConfig({
    required this.webKey,
    required this.webSecurityCode,
    required this.webServiceKey,
  });

  /// Web端 Key：主要用于高德 JS API 场景，当前原生 Flutter UI 暂不直接使用。
  final String webKey;

  /// Web端安全密钥：和 Web端 Key 配套，当前原生 Flutter UI 暂不直接使用。
  final String webSecurityCode;

  /// Web服务 Key：用于高德 REST API，例如后续的周边 POI 搜索。
  final String webServiceKey;

  bool get hasWebConfig => webKey.isNotEmpty && webSecurityCode.isNotEmpty;

  bool get hasWebServiceConfig => webServiceKey.isNotEmpty;

  Uri buildAroundSearchUri({
    required String keyword,
    List<String> types = const [],
    required double latitude,
    required double longitude,
    int radiusMeters = 2000,
    int page = 1,
    int offset = 20,
  }) {
    final queryParameters = <String, String>{
      'key': webServiceKey,
      'keywords': keyword,
      'location': '$longitude,$latitude',
      'radius': radiusMeters.toString(),
      'sortrule': 'distance',
      'extensions': 'all',
      'page': page.toString(),
      'offset': offset.toString(),
      'output': 'json',
    };
    if (types.isNotEmpty) {
      // 高德支持多个 POI 类型用竖线分隔；保留关键词是为了兼容用户常见类别叫法。
      queryParameters['types'] = types.join('|');
    }

    return Uri.https('restapi.amap.com', '/v3/place/around', queryParameters);
  }

  /// 构造城市限定的文本搜索地址。
  ///
  /// 这里不传周边搜索的距离排序参数，是为了保留高德按综合权重给出的城市推荐顺序；
  /// `citylimit` 则避免同名景点越界召回其他城市结果。
  Uri buildTextSearchUri({
    required String keyword,
    List<String> types = const [],
    required String cityCode,
    int page = 1,
    int offset = 20,
  }) {
    final queryParameters = <String, String>{
      'key': webServiceKey,
      'keywords': keyword,
      'city': cityCode,
      'citylimit': 'true',
      'extensions': 'all',
      'page': page.toString(),
      'offset': offset.toString(),
      'output': 'json',
    };
    if (types.isNotEmpty) {
      queryParameters['types'] = types.join('|');
    }

    return Uri.https('restapi.amap.com', '/v3/place/text', queryParameters);
  }

  /// 构造地点输入提示地址。
  ///
  /// 同时提供城市限制和当前位置偏好，可以先消除“什刹海”等具体地名的歧义；
  /// `datatype=poi` 排除公交线路等不能直接落点的提示类型。
  Uri buildInputTipsUri({
    required String keyword,
    required String cityCode,
    required double latitude,
    required double longitude,
  }) {
    return Uri.https('restapi.amap.com', '/v3/assistant/inputtips', {
      'key': webServiceKey,
      'keywords': keyword,
      'city': cityCode,
      'citylimit': 'true',
      'location': '$longitude,$latitude',
      'datatype': 'poi',
      'output': 'json',
    });
  }

  Uri buildCoordinateConvertUri({
    required double latitude,
    required double longitude,
  }) {
    // 手机系统定位通常返回 GPS/WGS84 坐标；高德地图和 POI 搜索使用高德坐标，
    // 先转换再搜索可以减少国内地图常见的坐标偏移。
    return Uri.https('restapi.amap.com', '/v3/assistant/coordinate/convert', {
      'key': webServiceKey,
      'locations': '$longitude,$latitude',
      'coordsys': 'gps',
      'output': 'json',
    });
  }

  Uri buildReverseGeocodeUri({
    required double latitude,
    required double longitude,
    int radiusMeters = 1000,
  }) {
    // 逆地理编码用于展示当前位置的街道、地址和附近地标，
    // 让用户看到的是可理解的位置描述，而不是只有一个大概方向。
    return Uri.https('restapi.amap.com', '/v3/geocode/regeo', {
      'key': webServiceKey,
      'location': '$longitude,$latitude',
      'radius': radiusMeters.toString(),
      'extensions': 'all',
      'output': 'json',
    });
  }
}

/// 应用运行时读取的高德配置。
///
/// `String.fromEnvironment` 在 Flutter 中通过编译参数注入，适合本地调试和打包时传入 Key。
const amapConfig = AmapConfig(
  webKey: String.fromEnvironment('AMAP_WEB_KEY'),
  webSecurityCode: String.fromEnvironment('AMAP_WEB_SECURITY_CODE'),
  webServiceKey: String.fromEnvironment('AMAP_WEB_SERVICE_KEY'),
);
