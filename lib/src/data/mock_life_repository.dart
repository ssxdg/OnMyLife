import 'package:flutter/material.dart';

import '../models/life_category.dart';
import '../models/place.dart';

/// 首版模拟仓库。
///
/// 选择模拟仓库是因为高德 Key、原生定位权限和 Android/iOS 配置需要用户本地提供；
/// 先用稳定的本地数据打通类别、地图气泡、列表、详情和收藏流程，后续再替换为真实服务。
class MockLifeRepository {
  MockLifeRepository({Set<String> favoritePlaceIds = const {}})
    : _places = _seedPlaces
          .map(
            (place) =>
                place.copyWith(isFavorite: favoritePlaceIds.contains(place.id)),
          )
          .toList();

  static const List<LifeCategory> _categories = [
    LifeCategory(
      id: 'food',
      name: '美食',
      icon: Icons.restaurant_rounded,
      colorValue: 0xFFFF7E67,
      amapKeyword: '美食',
      amapTypes: ['050000'],
    ),
    LifeCategory(
      id: 'hospital',
      name: '医院',
      icon: Icons.local_hospital_rounded,
      colorValue: 0xFF4ECDC4,
      amapKeyword: '医院',
      amapTypes: ['090000'],
    ),
    LifeCategory(
      id: 'pharmacy',
      name: '药店',
      icon: Icons.medication_rounded,
      colorValue: 0xFF6BCB77,
      amapKeyword: '药店',
      amapTypes: ['090601'],
    ),
    LifeCategory(
      id: 'pet',
      name: '宠物',
      icon: Icons.pets_rounded,
      colorValue: 0xFFFFB84D,
      amapKeyword: '宠物服务',
      amapTypes: ['071500'],
    ),
    LifeCategory(
      id: 'toilet',
      name: '厕所',
      icon: Icons.wc_rounded,
      colorValue: 0xFF45B7D1,
      amapKeyword: '公共厕所',
      amapTypes: ['200300'],
    ),
    LifeCategory(
      id: 'parking',
      name: '停车场',
      icon: Icons.local_parking_rounded,
      colorValue: 0xFF7C83FD,
      amapKeyword: '停车场',
      amapTypes: ['150900'],
    ),
    LifeCategory(
      id: 'gas',
      name: '加油站',
      icon: Icons.local_gas_station_rounded,
      colorValue: 0xFFFF9671,
      amapKeyword: '加油站',
      amapTypes: ['010100'],
    ),
    LifeCategory(
      id: 'charging',
      name: '充电桩',
      icon: Icons.ev_station_rounded,
      colorValue: 0xFF2EC4B6,
      amapKeyword: '充电站',
      amapTypes: ['011100'],
    ),
    LifeCategory(
      id: 'bank',
      name: '银行',
      icon: Icons.account_balance_rounded,
      colorValue: 0xFF5C7AEA,
      amapKeyword: '银行',
      amapTypes: ['160300'],
    ),
    LifeCategory(
      id: 'store',
      name: '便利店',
      icon: Icons.storefront_rounded,
      colorValue: 0xFFFFB703,
      amapKeyword: '便利店',
      amapTypes: ['060200'],
    ),
    // 新增类别使用高德精确中类或小类编码，避免“景点”和“公园”等相近入口
    // 召回大量重复结果；关键词则保留用户熟悉的中文表达，兼顾搜索召回率。
    LifeCategory(
      id: 'scenic',
      name: '景点',
      icon: Icons.landscape_rounded,
      colorValue: 0xFF2A9D8F,
      amapKeyword: '景点',
      amapTypes: ['110200'],
    ),
    LifeCategory(
      id: 'park',
      name: '公园',
      icon: Icons.park_rounded,
      colorValue: 0xFF70A288,
      amapKeyword: '公园',
      amapTypes: ['110101'],
    ),
    LifeCategory(
      id: 'mall',
      name: '商场',
      icon: Icons.shopping_bag_rounded,
      colorValue: 0xFFE76F51,
      amapKeyword: '商场',
      amapTypes: ['060100'],
    ),
    LifeCategory(
      id: 'supermarket',
      name: '超市',
      icon: Icons.local_grocery_store_rounded,
      colorValue: 0xFFF4A261,
      amapKeyword: '超市',
      amapTypes: ['060400'],
    ),
    LifeCategory(
      id: 'hotel',
      name: '酒店',
      icon: Icons.hotel_rounded,
      colorValue: 0xFF8E7DBE,
      amapKeyword: '酒店',
      amapTypes: ['100100'],
    ),
    LifeCategory(
      id: 'transit',
      name: '公交地铁',
      icon: Icons.directions_transit_rounded,
      colorValue: 0xFF457B9D,
      amapKeyword: '公交地铁',
      amapTypes: ['150500', '150700'],
    ),
  ];

  static const List<Place> _seedPlaces = [
    Place(
      id: 'food-coffee',
      categoryId: 'food',
      name: '小巷咖啡',
      address: '梧桐路 18 号',
      latitude: 31.2309,
      longitude: 121.4741,
      distanceMeters: 320,
      openStatus: '营业中',
      phone: '021-6000 1001',
    ),
    Place(
      id: 'food-noodle',
      categoryId: 'food',
      name: '青禾面馆',
      address: '人民路 66 号',
      latitude: 31.2317,
      longitude: 121.4729,
      distanceMeters: 680,
      openStatus: '营业中',
      phone: '021-6000 1002',
    ),
    Place(
      id: 'food-bakery',
      categoryId: 'food',
      name: '晨光烘焙',
      address: '东湖路 9 号',
      latitude: 31.2298,
      longitude: 121.4752,
      distanceMeters: 980,
      openStatus: '即将打烊',
      phone: '021-6000 1003',
    ),
    Place(
      id: 'hospital-central',
      categoryId: 'hospital',
      name: '中心医院',
      address: '健康路 20 号',
      latitude: 31.2324,
      longitude: 121.4761,
      distanceMeters: 540,
      openStatus: '急诊开放',
      phone: '021-6000 2001',
    ),
    Place(
      id: 'hospital-community',
      categoryId: 'hospital',
      name: '社区卫生服务中心',
      address: '民生路 38 号',
      latitude: 31.2288,
      longitude: 121.4717,
      distanceMeters: 860,
      openStatus: '营业中',
      phone: '021-6000 2002',
    ),
    Place(
      id: 'pet-care',
      categoryId: 'pet',
      name: '安安宠物诊所',
      address: '花园路 12 号',
      latitude: 31.2321,
      longitude: 121.4733,
      distanceMeters: 410,
      openStatus: '营业中',
      phone: '021-6000 3001',
    ),
    Place(
      id: 'toilet-park',
      categoryId: 'toilet',
      name: '城市公园公共厕所',
      address: '城市公园东门',
      latitude: 31.2294,
      longitude: 121.4736,
      distanceMeters: 260,
      openStatus: '开放中',
    ),
    Place(
      id: 'parking-mall',
      categoryId: 'parking',
      name: '生活广场停车场',
      address: '生活广场 B2',
      latitude: 31.2301,
      longitude: 121.4719,
      distanceMeters: 520,
      openStatus: '有空位',
    ),
    Place(
      id: 'charging-east',
      categoryId: 'charging',
      name: '东湖快充站',
      address: '东湖路 88 号',
      latitude: 31.2311,
      longitude: 121.4767,
      distanceMeters: 760,
      openStatus: '可用',
    ),
    Place(
      id: 'store-family',
      categoryId: 'store',
      name: '邻里便利店',
      address: '梧桐路 3 号',
      latitude: 31.2302,
      longitude: 121.4747,
      distanceMeters: 180,
      openStatus: '24 小时',
    ),
    // 每个新增固定类别保留一个本地点位，是为了在高德配置缺失或网络不可用时
    // 仍能完整展示地图、列表和详情流程；自由关键词搜索不会使用这些兜底数据。
    Place(
      id: 'scenic-viewpoint',
      categoryId: 'scenic',
      name: '城市观景台',
      address: '滨河路 16 号',
      latitude: 31.2328,
      longitude: 121.4758,
      distanceMeters: 920,
      openStatus: '开放中',
    ),
    Place(
      id: 'park-central',
      categoryId: 'park',
      name: '中央公园',
      address: '花园路 1 号',
      latitude: 31.2293,
      longitude: 121.4738,
      distanceMeters: 280,
      openStatus: '开放中',
    ),
    Place(
      id: 'mall-life-plaza',
      categoryId: 'mall',
      name: '生活广场',
      address: '人民路 88 号',
      latitude: 31.2300,
      longitude: 121.4718,
      distanceMeters: 510,
      openStatus: '营业中',
    ),
    Place(
      id: 'supermarket-neighborhood',
      categoryId: 'supermarket',
      name: '邻里超市',
      address: '民生路 25 号',
      latitude: 31.2299,
      longitude: 121.4749,
      distanceMeters: 230,
      openStatus: '营业中',
    ),
    Place(
      id: 'hotel-lakeside',
      categoryId: 'hotel',
      name: '湖畔酒店',
      address: '东湖路 56 号',
      latitude: 31.2315,
      longitude: 121.4763,
      distanceMeters: 690,
      openStatus: '可预订',
      phone: '021-6000 5001',
    ),
    Place(
      id: 'transit-people-square',
      categoryId: 'transit',
      name: '人民广场地铁站',
      address: '人民广场东侧',
      latitude: 31.2307,
      longitude: 121.4728,
      distanceMeters: 440,
      openStatus: '运营中',
    ),
  ];

  final List<Place> _places;

  List<LifeCategory> get categories => _categories;

  LifeCategory categoryById(String id) {
    return _categories.firstWhere((category) => category.id == id);
  }

  List<Place> placesForCategory(String categoryId) {
    final places =
        _places.where((place) => place.categoryId == categoryId).toList()
          ..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

    return places;
  }

  Place placeById(String id) {
    return _places.firstWhere((place) => place.id == id);
  }

  Set<String> get favoritePlaceIds {
    return _places
        .where((place) => place.isFavorite)
        .map((place) => place.id)
        .toSet();
  }

  void toggleFavorite(String placeId) {
    final index = _places.indexWhere((place) => place.id == placeId);
    if (index == -1) {
      return;
    }

    final current = _places[index];
    _places[index] = current.copyWith(isFavorite: !current.isFavorite);
  }
}
