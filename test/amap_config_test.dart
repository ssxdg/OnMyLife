import 'package:flutter_test/flutter_test.dart';
import 'package:on_my_life/src/config/amap_config.dart';

void main() {
  test('高德配置能区分 Web 端和 Web 服务 Key 是否完整', () {
    const config = AmapConfig(
      webKey: 'web-key',
      webSecurityCode: 'web-security-code',
      webServiceKey: 'web-service-key',
    );

    expect(config.hasWebConfig, isTrue);
    expect(config.hasWebServiceConfig, isTrue);
  });

  test('高德 Web 服务 Key 能生成周边 POI 查询地址', () {
    const config = AmapConfig(
      webKey: 'web-key',
      webSecurityCode: 'web-security-code',
      webServiceKey: 'web-service-key',
    );

    final uri = config.buildAroundSearchUri(
      keyword: '美食',
      latitude: 31.2309,
      longitude: 121.4741,
      radiusMeters: 2000,
    );

    expect(uri.scheme, 'https');
    expect(uri.host, 'restapi.amap.com');
    expect(uri.path, '/v3/place/around');
    expect(uri.queryParameters['key'], 'web-service-key');
    expect(uri.queryParameters['keywords'], '美食');
    expect(uri.queryParameters['location'], '121.4741,31.2309');
    expect(uri.queryParameters['radius'], '2000');
    expect(uri.queryParameters['output'], 'json');
  });
}
