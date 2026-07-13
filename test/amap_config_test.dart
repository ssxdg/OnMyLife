import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:on_my_life/src/config/amap_config.dart';
import 'package:on_my_life/src/data/mock_life_repository.dart';
import 'package:on_my_life/src/models/life_category.dart';
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

  test('城市景点查询启用城市限制并保留高德综合排序', () {
    const config = AmapConfig(
      webKey: 'web-key',
      webSecurityCode: 'web-security-code',
      webServiceKey: 'web-service-key',
    );

    final uri = config.buildTextSearchUri(
      keyword: '景点',
      types: const ['110200'],
      cityCode: '010',
      offset: 10,
    );

    expect(uri.path, '/v3/place/text');
    expect(uri.queryParameters['city'], '010');
    expect(uri.queryParameters['citylimit'], 'true');
    expect(uri.queryParameters['types'], '110200');
    expect(uri.queryParameters['offset'], '10');
    expect(uri.queryParameters.containsKey('sortrule'), isFalse);
  });

  test('输入提示查询携带城市、位置偏好和 POI 限制', () {
    const config = AmapConfig(
      webKey: 'web-key',
      webSecurityCode: 'web-security-code',
      webServiceKey: 'web-service-key',
    );

    final uri = config.buildInputTipsUri(
      keyword: '什刹海',
      cityCode: '010',
      latitude: 39.9042,
      longitude: 116.4074,
    );

    expect(uri.path, '/v3/assistant/inputtips');
    expect(uri.queryParameters['keywords'], '什刹海');
    expect(uri.queryParameters['city'], '010');
    expect(uri.queryParameters['citylimit'], 'true');
    expect(uri.queryParameters['location'], '116.4074,39.9042');
    expect(uri.queryParameters['datatype'], 'poi');
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

  test('自由关键词搜索不附带固定 POI 分类编码', () async {
    const config = AmapConfig(
      webKey: 'web-key',
      webSecurityCode: 'web-security-code',
      webServiceKey: 'web-service-key',
    );
    final client = MockClient((request) async {
      expect(request.url.queryParameters['keywords'], '博物馆');
      expect(request.url.queryParameters.containsKey('types'), isFalse);
      return http.Response('{"status":"1","pois":[]}', 200);
    });
    final service = AmapPlaceService(
      config: config,
      client: client,
      searchRadiiMeters: const [1000],
    );

    final result = await service.searchNearestPlaces(
      category: LifeCategory.keywordSearch('博物馆'),
      latitude: 31.2309,
      longitude: 121.4741,
    );

    expect(result.places, isEmpty);
    expect(result.radiusMeters, 1000);
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
            "formatted_address": "北京市东城区天安门广场",
            "addressComponent": {
              "province": "北京市",
              "city": [],
              "citycode": "010",
              "adcode": "110101"
            },
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

    expect(summary.formattedAddress, '北京市东城区天安门广场');
    expect(summary.cityName, '北京市');
    expect(summary.cityCode, '010');
    expect(summary.adCode, '110101');
    expect(summary.nearbyLandmarks, ['人民广场', '上海市历史博物馆']);
  });

  test('城市景点过滤内部点位和纯公园，去重后保持推荐顺序并限制十条', () async {
    const config = AmapConfig(
      webKey: 'web-key',
      webSecurityCode: 'web-security-code',
      webServiceKey: 'web-service-key',
    );
    final pois = <Map<String, String>>[
      _poi('forbidden-city', '故宫博物院', '110200', ''),
      _poi('inner-gate', '故宫午门', '110200', 'forbidden-city'),
      _poi('park', '普通公园', '110101', ''),
      _poi('duplicate-id', '颐和园', '110202', ''),
      _poi('duplicate-id', '颐和园西门', '110202', ''),
      ...List.generate(
        12,
        (index) => _poi('scenic-$index', '推荐景点$index', '110200', ''),
      ),
    ];
    final client = MockClient((request) async {
      expect(request.url.path, '/v3/place/text');
      expect(request.url.queryParameters['city'], '010');
      return _jsonResponse(jsonEncode({'status': '1', 'pois': pois}));
    });
    final service = AmapPlaceService(config: config, client: client);

    final result = await service.searchCityPlaces(
      category: MockLifeRepository().categoryById('scenic'),
      cityCode: '010',
      latitude: 39.9042,
      longitude: 116.4074,
      topLevelScenicOnly: true,
      limit: 10,
    );

    expect(result.radiusMeters, isNull);
    expect(result.places, hasLength(10));
    expect(
      result.places.take(3).map((place) => place.name),
      orderedEquals(['故宫博物院', '颐和园', '推荐景点0']),
    );
    expect(result.places.map((place) => place.name), isNot(contains('故宫午门')));
    expect(result.places.map((place) => place.name), isNot(contains('普通公园')));
  });

  test('地点候选只保留有效 POI 并返回最多八条', () async {
    const config = AmapConfig(
      webKey: 'web-key',
      webSecurityCode: 'web-security-code',
      webServiceKey: 'web-service-key',
    );
    final tips = <Map<String, Object?>>[
      {
        'id': 'shichahai',
        'name': '什刹海',
        'district': '北京市西城区',
        'address': '地安门西大街49号',
        'location': '116.3854,39.9419',
      },
      {'id': '', 'name': '无坐标提示', 'location': []},
      ...List.generate(
        10,
        (index) => {
          'id': 'tip-$index',
          'name': '什刹海候选$index',
          'district': '北京市西城区',
          'address': '候选路$index号',
          'location': '116.38$index,39.94$index',
        },
      ),
    ];
    final client = MockClient(
      (request) async =>
          _jsonResponse(jsonEncode({'status': '1', 'tips': tips})),
    );
    final service = AmapPlaceService(config: config, client: client);

    final suggestions = await service.searchPlaceSuggestions(
      keyword: '什刹海',
      cityCode: '010',
      latitude: 39.9042,
      longitude: 116.4074,
    );

    expect(suggestions, hasLength(8));
    expect(suggestions.first.name, '什刹海');
    expect(suggestions.first.district, '北京市西城区');
    expect(suggestions.first.distanceMeters, greaterThan(0));
  });
}

Map<String, String> _poi(
  String id,
  String name,
  String typeCode,
  String parent,
) {
  return {
    'id': id,
    'name': name,
    'type': '风景名胜',
    'typecode': typeCode,
    'parent': parent,
    'address': '北京市测试地址',
    'location': '116.3970,39.9080',
  };
}

http.Response _jsonResponse(String body) {
  return http.Response.bytes(
    utf8.encode(body),
    200,
    headers: const {'content-type': 'application/json; charset=utf-8'},
  );
}
