import 'package:flutter_test/flutter_test.dart';
import 'package:on_my_life/main.dart';
import 'package:on_my_life/src/data/mock_life_repository.dart';
import 'package:on_my_life/src/models/life_category.dart';
import 'package:on_my_life/src/services/amap_place_service.dart';
import 'package:on_my_life/src/services/device_location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
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
