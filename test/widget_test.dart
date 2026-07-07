import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:on_my_life/main.dart';
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
}
