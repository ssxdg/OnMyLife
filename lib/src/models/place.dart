/// 周边点位模型。
///
/// 首版用统一模型承接模拟数据和未来高德 POI 返回值，避免 UI 关心数据来自本地还是地图服务。
/// 字段只保留地图气泡、底部列表和详情抽屉必需的信息，减少首版复杂度。
class Place {
  const Place({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
    required this.openStatus,
    this.phone,
    this.isFavorite = false,
  });

  final String id;
  final String categoryId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final int distanceMeters;
  final String openStatus;
  final String? phone;
  final bool isFavorite;

  String get distanceLabel {
    if (distanceMeters < 1000) {
      return '${distanceMeters}m';
    }

    return '${(distanceMeters / 1000).toStringAsFixed(1)}km';
  }

  Place copyWith({bool? isFavorite}) {
    return Place(
      id: id,
      categoryId: categoryId,
      name: name,
      address: address,
      latitude: latitude,
      longitude: longitude,
      distanceMeters: distanceMeters,
      openStatus: openStatus,
      phone: phone,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
