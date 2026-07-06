import 'package:flutter/material.dart';

import 'src/app/nearby_life_app.dart';

export 'src/app/nearby_life_app.dart';

void main() {
  // 入口只负责启动应用，把页面、数据和主题逻辑放到 src 下，后续接入高德 SDK 时不会污染启动文件。
  runApp(const NearbyLifeApp());
}
