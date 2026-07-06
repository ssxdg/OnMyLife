import 'package:flutter_test/flutter_test.dart';
import 'package:on_my_life/src/services/navigation_url_builder.dart';

void main() {
  test('为点位生成高德地图导航链接', () {
    final uri = buildAmapNavigationUri(
      name: '小巷咖啡',
      latitude: 31.2309,
      longitude: 121.4741,
    );

    expect(uri.scheme, 'androidamap');
    expect(uri.host, 'route');
    expect(uri.queryParameters['dlat'], '31.2309');
    expect(uri.queryParameters['dlon'], '121.4741');
    expect(uri.queryParameters['dname'], '小巷咖啡');
  });
}
