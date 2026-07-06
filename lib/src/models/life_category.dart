import 'package:flutter/material.dart';

/// 生活类别模型。
///
/// 这里同时保留业务 id、界面展示名称和高德查询关键词，是为了让 UI 不直接依赖地图服务字段。
/// 后续接入高德 POI 时，只需要替换映射来源，不需要改动首页类别组件。
class LifeCategory {
  const LifeCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorValue,
    required this.amapKeyword,
  });

  final String id;
  final String name;
  final IconData icon;
  final int colorValue;
  final String amapKeyword;

  Color get color => Color(colorValue);
}
