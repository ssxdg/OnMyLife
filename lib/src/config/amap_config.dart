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
    required double latitude,
    required double longitude,
    int radiusMeters = 2000,
  }) {
    return Uri.https('restapi.amap.com', '/v3/place/around', {
      'key': webServiceKey,
      'keywords': keyword,
      'location': '$longitude,$latitude',
      'radius': radiusMeters.toString(),
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
