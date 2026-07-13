import 'package:flutter_test/flutter_test.dart';
import 'package:on_my_life/src/data/mock_life_repository.dart';
import 'package:on_my_life/src/models/life_category.dart';

void main() {
  test('提供首版规划中的生活类别和高德查询映射', () {
    final repository = MockLifeRepository();

    expect(repository.categories, hasLength(16));
    expect(repository.categoryById('food').name, '美食');
    expect(repository.categoryById('hospital').amapKeyword, '医院');
    expect(repository.categoryById('toilet').amapKeyword, '公共厕所');
    expect(repository.categoryById('scenic').amapTypes, ['110200']);
    expect(
      repository.categoryById('scenic').searchMode,
      LifeCategorySearchMode.cityRecommended,
    );
    expect(repository.categoryById('park').amapTypes, ['110101']);
    expect(repository.categoryById('mall').amapTypes, ['060100']);
    expect(repository.categoryById('supermarket').amapTypes, ['060400']);
    expect(repository.categoryById('hotel').amapTypes, ['100100']);
    expect(repository.categoryById('transit').amapTypes, ['150500', '150700']);
    for (final categoryId in [
      'scenic',
      'park',
      'mall',
      'supermarket',
      'hotel',
      'transit',
    ]) {
      expect(
        repository.placesForCategory(categoryId),
        isNotEmpty,
        reason: '$categoryId 需要保留断网时的降级点位',
      );
    }
  });

  test('关键词搜索分类会清理输入且不限制高德类型', () {
    final category = LifeCategory.keywordSearch('  博物馆  ');

    expect(category.id, LifeCategory.keywordSearchId);
    expect(category.name, '博物馆');
    expect(category.amapKeyword, '博物馆');
    expect(category.amapTypes, isEmpty);
    expect(category.isKeywordSearch, isTrue);
    expect(category.searchMode, LifeCategorySearchMode.nearby);
    expect(MockLifeRepository().categoryById('food').isKeywordSearch, isFalse);
    expect(() => LifeCategory.keywordSearch('   '), throwsArgumentError);
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
