import 'package:geolocator/geolocator.dart';

/// 手机当前位置。
///
/// 这里只保留业务真正需要的经纬度和精度，避免页面层直接依赖 geolocator 的 Position 类型，
/// 后续如果替换定位 SDK，页面调用方式不需要变化。
class DeviceLocation {
  const DeviceLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
  });

  final double latitude;
  final double longitude;
  final double accuracyMeters;
}

/// 当前位置提供者。
///
/// 抽象一层是为了让正式运行使用系统定位，测试时可以注入固定坐标，
/// 这样不会在组件测试里触发真实手机权限弹窗。
abstract class CurrentLocationProvider {
  Future<DeviceLocation> currentLocation();
}

/// 定位权限或定位服务不可用异常。
///
/// UI 捕获该异常后可以回到类别页并展示“未开启定位”，而不是把平台异常直接暴露给用户。
class LocationAccessException implements Exception {
  const LocationAccessException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 基于手机系统定位的当前位置服务。
///
/// 使用高精度前台定位，是为了让周边搜索以手机真实位置为中心，
/// 不再依赖固定模拟坐标或只显示大概方位。
class DeviceLocationService implements CurrentLocationProvider {
  const DeviceLocationService();

  @override
  Future<DeviceLocation> currentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationAccessException('手机定位服务未开启');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationAccessException('未授予定位权限');
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationAccessException('定位权限已被系统永久拒绝');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 12),
      ),
    );

    return DeviceLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMeters: position.accuracy,
    );
  }
}
