import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:on_my_life/main.dart';
import 'package:on_my_life/src/app/nearby_search_field.dart';
import 'package:on_my_life/src/data/mock_life_repository.dart';
import 'package:on_my_life/src/models/life_category.dart';
import 'package:on_my_life/src/models/place.dart';
import 'package:on_my_life/src/services/amap_place_service.dart';
import 'package:on_my_life/src/services/device_location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('实时定位失败时使用系统最后已知位置', () async {
    final service = DeviceLocationService(
      locationReader: _FallbackLocationReader(),
    );

    final location = await service.currentLocation();

    expect(location.latitude, 31.2201);
    expect(location.longitude, 121.4601);
    expect(location.accuracyMeters, 42);
  });

  testWidgets('搜索框拦截空白输入并限制关键词长度', (tester) async {
    final submittedKeywords = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NearbySearchField(onSubmitted: submittedKeywords.add),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '   ');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();

    expect(submittedKeywords, isEmpty);
    expect(find.text('请输入搜索内容'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField),
      List<String>.filled(81, '景').join(),
    );
    final editableText = tester.widget<EditableText>(find.byType(EditableText));
    expect(editableText.controller.text, hasLength(80));
  });

  testWidgets('搜索框清理关键词并支持一键清空', (tester) async {
    String? submittedKeyword;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NearbySearchField(
            onSubmitted: (keyword) => submittedKeyword = keyword,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '  博物馆  ');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();

    expect(submittedKeyword, '博物馆');

    await tester.tap(find.byTooltip('清空搜索内容'));
    await tester.pump();

    final editableText = tester.widget<EditableText>(find.byType(EditableText));
    expect(editableText.controller.text, isEmpty);
  });

  testWidgets('用户从类别进入地图并查看点位详情', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const NearbyLifeApp(
        locationProvider: _FakeLocationProvider(),
        placeProvider: _FakePlaceProvider(),
      ),
    );

    expect(find.text('附近生活'), findsOneWidget);
    expect(find.text('选择类别'), findsOneWidget);
    expect(find.text('美食'), findsOneWidget);
    expect(find.text('医院'), findsOneWidget);

    await tester.tap(find.text('美食'));
    await tester.pumpAndSettle();

    expect(find.text('定位授权'), findsOneWidget);
    expect(find.text('同意并使用当前位置'), findsOneWidget);

    await tester.tap(find.text('同意并使用当前位置'));
    await tester.pumpAndSettle();

    expect(find.text('附近结果'), findsOneWidget);
    expect(find.text('上海市黄浦区人民广场'), findsOneWidget);
    expect(find.text('小巷咖啡'), findsOneWidget);
    expect(find.text('320m'), findsOneWidget);

    await tester.tap(find.text('小巷咖啡'));
    await tester.pumpAndSettle();

    expect(find.text('去这里'), findsOneWidget);
    expect(find.text('收藏'), findsOneWidget);

    await tester.tap(find.text('收藏'));
    await tester.pumpAndSettle();

    expect(find.text('已收藏'), findsOneWidget);
  });

  testWidgets('首页可以滚动查看新增生活分类', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const NearbyLifeApp(
        locationProvider: _FakeLocationProvider(),
        placeProvider: _FakePlaceProvider(),
      ),
    );

    for (final categoryName in ['景点', '公园', '商场', '超市', '酒店', '公交地铁']) {
      await tester.scrollUntilVisible(
        find.text(categoryName),
        240,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(categoryName), findsOneWidget);
    }
  });

  testWidgets('关键词搜索复用定位授权并可在地图结果页更换关键词', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final placeProvider = _KeywordPlaceProvider();

    await tester.pumpWidget(
      NearbyLifeApp(
        locationProvider: const _FakeLocationProvider(),
        placeProvider: placeProvider,
      ),
    );

    await tester.enterText(find.byType(TextField), '  博物馆  ');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('定位授权'), findsOneWidget);
    await tester.tap(find.text('同意并使用当前位置'));
    await tester.pumpAndSettle();

    expect(placeProvider.lastCategory?.amapKeyword, '博物馆');
    expect(placeProvider.lastCategory?.amapTypes, isEmpty);
    expect(placeProvider.lastCategory?.isKeywordSearch, isTrue);
    expect(find.text('博物馆搜索结果'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '咖啡馆');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(placeProvider.lastCategory?.amapKeyword, '咖啡馆');
    expect(placeProvider.searchAttempts, 2);
    expect(find.text('咖啡馆搜索结果'), findsOneWidget);
    expect(find.text('博物馆搜索结果'), findsNothing);
  });

  testWidgets('首次输入不申请定位，提交后才展示授权说明', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final locationProvider = _CountingLocationProvider();

    await tester.pumpWidget(
      NearbyLifeApp(
        locationProvider: locationProvider,
        placeProvider: const _FakePlaceProvider(),
      ),
    );

    await tester.enterText(find.byType(TextField), '什刹海');
    await tester.pump(const Duration(milliseconds: 500));

    expect(locationProvider.requestCount, 0);
    expect(find.text('定位授权'), findsNothing);

    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(locationProvider.requestCount, 0);
    expect(find.text('定位授权'), findsOneWidget);
  });

  testWidgets('具体地名优先使用城市同名结果，泛关键词继续附近搜索', (tester) async {
    SharedPreferences.setMockInitialValues({'location_consent_accepted': true});
    final placeProvider = _ExactPlaceProvider();

    await tester.pumpWidget(
      NearbyLifeApp(
        locationProvider: const _FakeLocationProvider(),
        placeProvider: placeProvider,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '什刹海');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('什刹海'), findsWidgets);
    expect(find.text('已定位到“什刹海”'), findsOneWidget);
    expect(placeProvider.nearbySearchCount, 0);

    await tester.enterText(find.byType(TextField), '咖啡馆');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('附近咖啡馆'), findsOneWidget);
    expect(placeProvider.nearbySearchCount, 1);
  });

  testWidgets('快速输入时旧候选响应不会覆盖新关键词', (tester) async {
    SharedPreferences.setMockInitialValues({'location_consent_accepted': true});
    final placeProvider = _DelayedSuggestionProvider();

    await tester.pumpWidget(
      NearbyLifeApp(
        locationProvider: const _FakeLocationProvider(),
        placeProvider: placeProvider,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '什刹');
    await tester.pump(const Duration(milliseconds: 350));
    expect(placeProvider.pending, contains('什刹'));

    await tester.enterText(find.byType(TextField), '什刹海');
    await tester.pump(const Duration(milliseconds: 350));
    expect(placeProvider.pending, contains('什刹海'));

    placeProvider.complete('什刹海', '什刹海');
    await tester.pump();
    expect(find.text('什刹海'), findsWidgets);

    placeProvider.complete('什刹', '旧候选');
    await tester.pump();
    expect(find.text('旧候选'), findsNothing);
    expect(find.text('什刹海'), findsWidgets);
  });

  testWidgets('选择同名候选后直接定位，返回键先收起候选层', (tester) async {
    SharedPreferences.setMockInitialValues({'location_consent_accepted': true});
    final placeProvider = _SuggestionPlaceProvider();

    await tester.pumpWidget(
      NearbyLifeApp(
        locationProvider: const _FakeLocationProvider(),
        placeProvider: placeProvider,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '什刹海');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    expect(find.byKey(const ValueKey('place-suggestions')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('place-suggestions')), findsNothing);
    expect(find.text('附近生活'), findsOneWidget);

    await tester.tap(find.byTooltip('清空搜索内容'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '什刹海');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    await tester.tap(find.text('什刹海').last);
    await tester.pumpAndSettle();

    expect(find.text('已定位到“什刹海”'), findsOneWidget);
    expect(placeProvider.citySearchCount, 0);
    expect(placeProvider.nearbySearchCount, 0);
  });

  testWidgets('景点入口使用城市推荐查询并展示综合推荐状态', (tester) async {
    SharedPreferences.setMockInitialValues({'location_consent_accepted': true});
    final placeProvider = _ScenicPlaceProvider();

    await tester.pumpWidget(
      NearbyLifeApp(
        locationProvider: const _FakeLocationProvider(),
        placeProvider: placeProvider,
      ),
    );
    await tester.scrollUntilVisible(
      find.text('景点'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('景点'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('景点'));
    await tester.pumpAndSettle();

    expect(placeProvider.requestedCityCode, '021');
    expect(placeProvider.requestedTopLevelOnly, isTrue);
    expect(placeProvider.requestedLimit, 10);
    expect(find.text('城市著名景点'), findsOneWidget);
    expect(find.text('已按上海市综合推荐展示 1 个景点'), findsOneWidget);
  });

  testWidgets('系统返回先关闭详情，再从结果页返回首页', (tester) async {
    SharedPreferences.setMockInitialValues({'location_consent_accepted': true});

    await tester.pumpWidget(
      const NearbyLifeApp(
        locationProvider: _FakeLocationProvider(),
        placeProvider: _FakePlaceProvider(),
      ),
    );
    await tester.tap(find.text('美食'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('小巷咖啡'));
    await tester.pumpAndSettle();

    expect(find.text('去这里'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('去这里'), findsNothing);
    expect(find.text('附近结果'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('附近生活'), findsOneWidget);
    expect(find.text('附近结果'), findsNothing);
  });

  testWidgets('结果面板可在百分之二十到百分之八十五之间连续拖动', (tester) async {
    SharedPreferences.setMockInitialValues({'location_consent_accepted': true});

    await tester.pumpWidget(
      const NearbyLifeApp(
        locationProvider: _FakeLocationProvider(),
        placeProvider: _FakePlaceProvider(),
      ),
    );
    await tester.tap(find.text('美食'));
    await tester.pumpAndSettle();

    final sheet = find.byKey(const ValueKey('results-sheet'));
    final draggable = find.byType(DraggableScrollableSheet);
    double sheetRatio() =>
        tester.getSize(sheet).height / tester.getSize(draggable).height;

    expect(sheetRatio(), closeTo(0.45, 0.03));

    await tester.drag(
      find.byKey(const ValueKey('results-sheet-handle')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    expect(sheetRatio(), closeTo(0.85, 0.04));

    await tester.drag(
      find.byKey(const ValueKey('results-sheet-handle')),
      const Offset(0, 700),
    );
    await tester.pumpAndSettle();
    expect(sheetRatio(), closeTo(0.20, 0.04));
  });

  testWidgets('自由关键词搜索失败时不展示固定分类模拟点位', (tester) async {
    SharedPreferences.setMockInitialValues({'location_consent_accepted': true});

    await tester.pumpWidget(
      const NearbyLifeApp(
        locationProvider: _FakeLocationProvider(),
        placeProvider: _FailingKeywordPlaceProvider(),
      ),
    );

    await tester.enterText(find.byType(TextField), '博物馆');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('高德服务暂不可用：关键词搜索失败'), findsWidgets);
    expect(find.text('小巷咖啡'), findsNothing);
    expect(find.text('0 个地点'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
  });

  testWidgets('用户暂不授权定位时显示兜底提示', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const NearbyLifeApp(
        locationProvider: _FakeLocationProvider(),
        placeProvider: _FakePlaceProvider(),
      ),
    );

    await tester.tap(find.text('美食'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('暂不授权'));
    await tester.pumpAndSettle();

    expect(find.text('未开启定位'), findsOneWidget);
    expect(find.text('需要前台定位后才能查找附近点位'), findsOneWidget);
  });

  testWidgets('已同意定位后再次进入类别不重复弹应用内授权', (tester) async {
    SharedPreferences.setMockInitialValues({'location_consent_accepted': true});

    await tester.pumpWidget(
      const NearbyLifeApp(
        locationProvider: _FakeLocationProvider(),
        placeProvider: _FakePlaceProvider(),
      ),
    );

    await tester.tap(find.text('美食'));
    await tester.pumpAndSettle();

    expect(find.text('定位授权'), findsNothing);
    expect(find.text('附近结果'), findsOneWidget);
    expect(find.text('小巷咖啡'), findsOneWidget);
  });

  testWidgets('逆地理失败不阻断附近真实搜索', (tester) async {
    SharedPreferences.setMockInitialValues({'location_consent_accepted': true});

    await tester.pumpWidget(
      const NearbyLifeApp(
        locationProvider: _FakeLocationProvider(),
        placeProvider: _ReverseGeocodeFailingPlaceProvider(),
      ),
    );

    await tester.tap(find.text('美食'));
    await tester.pumpAndSettle();

    expect(find.text('定位授权'), findsNothing);
    expect(find.text('真实搜索餐厅'), findsOneWidget);
    expect(find.text('小巷咖啡'), findsNothing);
  });

  testWidgets('搜索失败后可以在结果页重试真实查询', (tester) async {
    SharedPreferences.setMockInitialValues({'location_consent_accepted': true});
    final placeProvider = _RetryablePlaceProvider();

    await tester.pumpWidget(
      NearbyLifeApp(
        locationProvider: const _FakeLocationProvider(),
        placeProvider: placeProvider,
      ),
    );

    await tester.tap(find.text('美食'));
    await tester.pumpAndSettle();

    expect(find.text('高德服务暂不可用：首次搜索失败'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
    expect(find.text('小巷咖啡'), findsOneWidget);

    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();

    expect(find.text('真实搜索餐厅'), findsOneWidget);
    expect(find.text('高德服务暂不可用：首次搜索失败'), findsNothing);
    expect(placeProvider.searchAttempts, 2);
  });
}

class _FallbackLocationReader implements LocationReader {
  @override
  Future<LocationPermission> checkPermission() async {
    return LocationPermission.whileInUse;
  }

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    throw const LocationServiceDisabledException();
  }

  @override
  Future<Position?> getLastKnownPosition() async {
    return Position(
      longitude: 121.4601,
      latitude: 31.2201,
      timestamp: DateTime(2026),
      accuracy: 42,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    return true;
  }

  @override
  Future<LocationPermission> requestPermission() async {
    return LocationPermission.whileInUse;
  }
}

class _FakeLocationProvider implements CurrentLocationProvider {
  const _FakeLocationProvider();

  @override
  Future<DeviceLocation> currentLocation() async {
    return const DeviceLocation(
      latitude: 31.2309,
      longitude: 121.4741,
      accuracyMeters: 18,
    );
  }
}

class _FakePlaceProvider implements NearbyPlaceProvider {
  const _FakePlaceProvider();

  @override
  Future<AmapCoordinate> convertGpsToAmap({
    required double latitude,
    required double longitude,
  }) async {
    return const AmapCoordinate(latitude: 31.2287, longitude: 121.4785);
  }

  @override
  Future<AmapLocationSummary> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    return const AmapLocationSummary(
      formattedAddress: '上海市黄浦区人民广场',
      nearbyLandmarks: ['人民广场', '上海市历史博物馆'],
      cityName: '上海市',
      cityCode: '021',
      adCode: '310101',
    );
  }

  @override
  Future<AmapPlaceSearchResult> searchNearestPlaces({
    required LifeCategory category,
    required double latitude,
    required double longitude,
  }) async {
    return AmapPlaceSearchResult(
      places: MockLifeRepository().placesForCategory(category.id),
      radiusMeters: 10000,
    );
  }

  @override
  Future<AmapPlaceSearchResult> searchCityPlaces({
    required LifeCategory category,
    required String cityCode,
    required double latitude,
    required double longitude,
    bool topLevelScenicOnly = false,
    int limit = 20,
  }) async {
    return AmapPlaceSearchResult(
      places: MockLifeRepository()
          .placesForCategory(category.id)
          .take(limit)
          .toList(),
      radiusMeters: null,
    );
  }

  @override
  Future<List<AmapPlaceSuggestion>> searchPlaceSuggestions({
    required String keyword,
    required String cityCode,
    required double latitude,
    required double longitude,
  }) async => const [];
}

class _ReverseGeocodeFailingPlaceProvider implements NearbyPlaceProvider {
  const _ReverseGeocodeFailingPlaceProvider();

  @override
  Future<AmapCoordinate> convertGpsToAmap({
    required double latitude,
    required double longitude,
  }) async {
    return const AmapCoordinate(latitude: 31.2287, longitude: 121.4785);
  }

  @override
  Future<AmapLocationSummary> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    throw const AmapServiceException('逆地理失败');
  }

  @override
  Future<AmapPlaceSearchResult> searchNearestPlaces({
    required LifeCategory category,
    required double latitude,
    required double longitude,
  }) async {
    return const AmapPlaceSearchResult(
      places: [PlaceFixture.realSearchRestaurant],
      radiusMeters: 1000,
    );
  }

  @override
  Future<AmapPlaceSearchResult> searchCityPlaces({
    required LifeCategory category,
    required String cityCode,
    required double latitude,
    required double longitude,
    bool topLevelScenicOnly = false,
    int limit = 20,
  }) async => const AmapPlaceSearchResult(places: [], radiusMeters: null);

  @override
  Future<List<AmapPlaceSuggestion>> searchPlaceSuggestions({
    required String keyword,
    required String cityCode,
    required double latitude,
    required double longitude,
  }) async => const [];
}

class _RetryablePlaceProvider implements NearbyPlaceProvider {
  int searchAttempts = 0;

  @override
  Future<AmapCoordinate> convertGpsToAmap({
    required double latitude,
    required double longitude,
  }) async {
    return const AmapCoordinate(latitude: 31.2287, longitude: 121.4785);
  }

  @override
  Future<AmapLocationSummary> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    return const AmapLocationSummary(
      formattedAddress: '上海市黄浦区人民广场',
      nearbyLandmarks: ['人民广场'],
    );
  }

  @override
  Future<AmapPlaceSearchResult> searchNearestPlaces({
    required LifeCategory category,
    required double latitude,
    required double longitude,
  }) async {
    searchAttempts += 1;
    if (searchAttempts == 1) {
      throw const AmapServiceException('首次搜索失败');
    }

    return const AmapPlaceSearchResult(
      places: [PlaceFixture.realSearchRestaurant],
      radiusMeters: 1000,
    );
  }

  @override
  Future<AmapPlaceSearchResult> searchCityPlaces({
    required LifeCategory category,
    required String cityCode,
    required double latitude,
    required double longitude,
    bool topLevelScenicOnly = false,
    int limit = 20,
  }) async => const AmapPlaceSearchResult(places: [], radiusMeters: null);

  @override
  Future<List<AmapPlaceSuggestion>> searchPlaceSuggestions({
    required String keyword,
    required String cityCode,
    required double latitude,
    required double longitude,
  }) async => const [];
}

class _KeywordPlaceProvider extends _FakePlaceProvider {
  LifeCategory? lastCategory;
  int searchAttempts = 0;

  @override
  Future<AmapPlaceSearchResult> searchNearestPlaces({
    required LifeCategory category,
    required double latitude,
    required double longitude,
  }) async {
    lastCategory = category;
    searchAttempts += 1;

    return AmapPlaceSearchResult(
      places: [
        Place(
          id: 'keyword-${category.amapKeyword}',
          categoryId: category.id,
          name: '${category.amapKeyword}搜索结果',
          address: '搜索路 1 号',
          latitude: 31.2288,
          longitude: 121.4786,
          distanceMeters: 160,
          openStatus: '高德 POI',
        ),
      ],
      radiusMeters: 1000,
    );
  }
}

class _FailingKeywordPlaceProvider extends _FakePlaceProvider {
  const _FailingKeywordPlaceProvider();

  @override
  Future<AmapPlaceSearchResult> searchNearestPlaces({
    required LifeCategory category,
    required double latitude,
    required double longitude,
  }) async {
    throw const AmapServiceException('关键词搜索失败');
  }
}

class PlaceFixture {
  static const realSearchRestaurant = Place(
    id: 'real-food',
    categoryId: 'food',
    name: '真实搜索餐厅',
    address: '真实路 1 号',
    latitude: 31.2288,
    longitude: 121.4786,
    distanceMeters: 120,
    openStatus: '餐饮服务',
  );

  static const shichahai = Place(
    id: 'shichahai',
    categoryId: LifeCategory.keywordSearchId,
    name: '什刹海',
    address: '北京市西城区地安门西大街49号',
    latitude: 39.9419,
    longitude: 116.3854,
    distanceMeters: 3200,
    openStatus: '风景名胜',
  );
}

class _CountingLocationProvider implements CurrentLocationProvider {
  int requestCount = 0;

  @override
  Future<DeviceLocation> currentLocation() async {
    requestCount += 1;
    return const DeviceLocation(
      latitude: 31.2309,
      longitude: 121.4741,
      accuracyMeters: 18,
    );
  }
}

class _ExactPlaceProvider extends _FakePlaceProvider {
  int nearbySearchCount = 0;

  @override
  Future<AmapPlaceSearchResult> searchCityPlaces({
    required LifeCategory category,
    required String cityCode,
    required double latitude,
    required double longitude,
    bool topLevelScenicOnly = false,
    int limit = 20,
  }) async {
    if (category.amapKeyword == '什刹海') {
      return const AmapPlaceSearchResult(
        places: [PlaceFixture.shichahai],
        radiusMeters: null,
      );
    }
    return const AmapPlaceSearchResult(places: [], radiusMeters: null);
  }

  @override
  Future<AmapPlaceSearchResult> searchNearestPlaces({
    required LifeCategory category,
    required double latitude,
    required double longitude,
  }) async {
    nearbySearchCount += 1;
    return AmapPlaceSearchResult(
      places: [
        Place(
          id: 'nearby-coffee',
          categoryId: category.id,
          name: '附近咖啡馆',
          address: '咖啡路 1 号',
          latitude: 31.2288,
          longitude: 121.4786,
          distanceMeters: 180,
          openStatus: '营业中',
        ),
      ],
      radiusMeters: 1000,
    );
  }
}

class _DelayedSuggestionProvider extends _FakePlaceProvider {
  final Map<String, Completer<List<AmapPlaceSuggestion>>> pending = {};

  @override
  Future<List<AmapPlaceSuggestion>> searchPlaceSuggestions({
    required String keyword,
    required String cityCode,
    required double latitude,
    required double longitude,
  }) {
    final completer = Completer<List<AmapPlaceSuggestion>>();
    pending[keyword] = completer;
    return completer.future;
  }

  void complete(String keyword, String suggestionName) {
    pending[keyword]!.complete([
      AmapPlaceSuggestion(
        id: 'suggestion-$keyword',
        name: suggestionName,
        address: '测试地址',
        district: '上海市黄浦区',
        coordinate: const AmapCoordinate(
          latitude: 31.2288,
          longitude: 121.4786,
        ),
        distanceMeters: 100,
      ),
    ]);
  }
}

class _SuggestionPlaceProvider extends _FakePlaceProvider {
  int citySearchCount = 0;
  int nearbySearchCount = 0;

  @override
  Future<List<AmapPlaceSuggestion>> searchPlaceSuggestions({
    required String keyword,
    required String cityCode,
    required double latitude,
    required double longitude,
  }) async {
    return const [
      AmapPlaceSuggestion(
        id: 'shichahai',
        name: '什刹海',
        address: '地安门西大街49号',
        district: '北京市西城区',
        coordinate: AmapCoordinate(latitude: 39.9419, longitude: 116.3854),
        distanceMeters: 3200,
      ),
    ];
  }

  @override
  Future<AmapPlaceSearchResult> searchCityPlaces({
    required LifeCategory category,
    required String cityCode,
    required double latitude,
    required double longitude,
    bool topLevelScenicOnly = false,
    int limit = 20,
  }) async {
    citySearchCount += 1;
    return const AmapPlaceSearchResult(places: [], radiusMeters: null);
  }

  @override
  Future<AmapPlaceSearchResult> searchNearestPlaces({
    required LifeCategory category,
    required double latitude,
    required double longitude,
  }) async {
    nearbySearchCount += 1;
    return const AmapPlaceSearchResult(places: [], radiusMeters: 1000);
  }
}

class _ScenicPlaceProvider extends _FakePlaceProvider {
  String? requestedCityCode;
  bool? requestedTopLevelOnly;
  int? requestedLimit;

  @override
  Future<AmapPlaceSearchResult> searchCityPlaces({
    required LifeCategory category,
    required String cityCode,
    required double latitude,
    required double longitude,
    bool topLevelScenicOnly = false,
    int limit = 20,
  }) async {
    requestedCityCode = cityCode;
    requestedTopLevelOnly = topLevelScenicOnly;
    requestedLimit = limit;
    return const AmapPlaceSearchResult(
      places: [
        Place(
          id: 'city-scenic',
          categoryId: 'scenic',
          name: '城市著名景点',
          address: '城市中心',
          latitude: 31.2288,
          longitude: 121.4786,
          distanceMeters: 1200,
          openStatus: '风景名胜',
        ),
      ],
      radiusMeters: null,
    );
  }
}
