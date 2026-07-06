/// 构建高德地图导航链接。
///
/// 首版不依赖高德 Key 调起外部 App，只生成目标点导航 URI；
/// 如果用户未安装高德地图，调用方会继续尝试浏览器地图链接兜底。
Uri buildAmapNavigationUri({
  required String name,
  required double latitude,
  required double longitude,
}) {
  return Uri(
    scheme: 'androidamap',
    host: 'route',
    queryParameters: {
      'sourceApplication': '附近生活',
      'dlat': latitude.toString(),
      'dlon': longitude.toString(),
      'dname': name,
      'dev': '0',
      't': '0',
    },
  );
}

/// 构建浏览器地图兜底链接。
///
/// 该链接用于未安装高德 App 或 URL Scheme 不可用的情况，保证“去这里”不会变成空按钮。
Uri buildWebMapFallbackUri({
  required String name,
  required double latitude,
  required double longitude,
}) {
  return Uri.https('uri.amap.com', '/marker', {
    'position': '$longitude,$latitude',
    'name': name,
  });
}
