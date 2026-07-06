import 'package:flutter_test/flutter_test.dart';
import 'package:on_my_life/src/data/mock_life_repository.dart';

void main() {
  test('提供首版规划中的生活类别和高德查询映射', () {
    final repository = MockLifeRepository();

    expect(repository.categories, hasLength(10));
    expect(repository.categoryById('food').name, '美食');
    expect(repository.categoryById('hospital').amapKeyword, '医院');
    expect(repository.categoryById('toilet').amapKeyword, '公共厕所');
  });

  test('按类别返回按距离排序的模拟点位', () {
    final repository = MockLifeRepository();

    final places = repository.placesForCategory('food');

    expect(places, hasLength(3));
    expect(places.first.name, '小巷咖啡');
    expect(places.first.distanceMeters, 320);
    expect(
      places.map((place) => place.distanceMeters).toList(),
      orderedEquals([320, 680, 980]),
    );
  });

  test('收藏状态可以在当前运行周期内切换', () {
    final repository = MockLifeRepository();

    expect(repository.placeById('food-coffee').isFavorite, isFalse);

    repository.toggleFavorite('food-coffee');
    expect(repository.placeById('food-coffee').isFavorite, isTrue);

    repository.toggleFavorite('food-coffee');
    expect(repository.placeById('food-coffee').isFavorite, isFalse);
  });

  test('收藏状态可以从本地收藏 id 恢复', () {
    final repository = MockLifeRepository(favoritePlaceIds: {'food-coffee'});

    expect(repository.placeById('food-coffee').isFavorite, isTrue);
    expect(repository.favoritePlaceIds, contains('food-coffee'));
  });
}
