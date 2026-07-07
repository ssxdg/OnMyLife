import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:on_my_life/src/config/amap_config.dart';
import 'package:on_my_life/src/data/mock_life_repository.dart';
import 'package:on_my_life/src/services/amap_place_service.dart';

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
      types: const ['050000'],
      latitude: 31.2309,
      longitude: 121.4741,
      radiusMeters: 2000,
    );

    expect(uri.scheme, 'https');
    expect(uri.host, 'restapi.amap.com');
    expect(uri.path, '/v3/place/around');
    expect(uri.queryParameters['key'], 'web-service-key');
    expect(uri.queryParameters['keywords'], '美食');
    expect(uri.queryParameters['types'], '050000');
    expect(uri.queryParameters['location'], '121.4741,31.2309');
    expect(uri.queryParameters['radius'], '2000');
    expect(uri.queryParameters['sortrule'], 'distance');
    expect(uri.queryParameters['extensions'], 'all');
    expect(uri.queryParameters['output'], 'json');
  });

  test('高德周边搜索首轮无结果时继续扩大半径并返回最近点位', () async {
    const config = AmapConfig(
      webKey: 'web-key',
      webSecurityCode: 'web-security-code',
      webServiceKey: 'web-service-key',
    );
    final requestedRadii = <String>[];
    final client = MockClient((request) async {
      requestedRadii.add(request.url.queryParameters['radius']!);

      if (request.url.queryParameters['radius'] == '1000') {
        return http.Response('{"status":"1","pois":[]}', 200);
      }

      return _jsonResponse('''
        {
          "status": "1",
          "pois": [
            {
              "id": "far-food",
              "name": "远处餐厅",
              "type": "餐饮服务",
              "address": "远处路 9 号",
              "location": "121.5001,31.2501",
              "distance": "9200",
              "tel": "021-6000 9000"
            },
            {
              "id": "near-food",
              "name": "最近餐厅",
              "type": "餐饮服务",
              "address": "身边路 1 号",
              "location": "121.4742,31.2310",
              "distance": "2300",
              "tel": []
            }
          ]
        }
        ''');
    });
    final service = AmapPlaceService(
      config: config,
      client: client,
      searchRadiiMeters: const [1000, 10000],
    );

    final result = await service.searchNearestPlaces(
      category: MockLifeRepository().categoryById('food'),
      latitude: 31.2309,
      longitude: 121.4741,
    );

    expect(requestedRadii, orderedEquals(['1000', '10000']));
    expect(result.radiusMeters, 10000);
    expect(result.places.map((place) => place.name), ['最近餐厅', '远处餐厅']);
    expect(result.places.map((place) => place.distanceMeters), [2300, 9200]);
  });

  test('高德服务可以把手机 GPS 坐标转换为高德坐标', () async {
    const config = AmapConfig(
      webKey: 'web-key',
      webSecurityCode: 'web-security-code',
      webServiceKey: 'web-service-key',
    );
    final client = MockClient((request) async {
      expect(request.url.path, '/v3/assistant/coordinate/convert');
      expect(request.url.queryParameters['coordsys'], 'gps');
      expect(request.url.queryParameters['locations'], '121.4741,31.2309');

      return http.Response(
        '{"status":"1","locations":"121.4785,31.2287"}',
        200,
      );
    });
    final service = AmapPlaceService(config: config, client: client);

    final coordinate = await service.convertGpsToAmap(
      latitude: 31.2309,
      longitude: 121.4741,
    );

    expect(coordinate.latitude, 31.2287);
    expect(coordinate.longitude, 121.4785);
  });

  test('高德服务可以解析当前位置地址和附近地标', () async {
    const config = AmapConfig(
      webKey: 'web-key',
      webSecurityCode: 'web-security-code',
      webServiceKey: 'web-service-key',
    );
    final client = MockClient((request) async {
      expect(request.url.path, '/v3/geocode/regeo');
      expect(request.url.queryParameters['extensions'], 'all');

      return _jsonResponse('''
        {
          "status": "1",
          "regeocode": {
            "formatted_address": "上海市黄浦区人民广场",
            "pois": [
              {"name": "人民广场"},
              {"name": "上海市历史博物馆"}
            ]
          }
        }
        ''');
    });
    final service = AmapPlaceService(config: config, client: client);

    final summary = await service.reverseGeocode(
      latitude: 31.2287,
      longitude: 121.4785,
    );

    expect(summary.formattedAddress, '上海市黄浦区人民广场');
    expect(summary.nearbyLandmarks, ['人民广场', '上海市历史博物馆']);
  });
}

http.Response _jsonResponse(String body) {
  return http.Response.bytes(
    utf8.encode(body),
    200,
    headers: const {'content-type': 'application/json; charset=utf-8'},
  );
}
