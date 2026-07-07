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
    this.amapTypes = const [],
  });

  final String id;
  final String name;
  final IconData icon;
  final int colorValue;
  final String amapKeyword;

  /// 高德 POI 分类编码。
  ///
  /// 同时传关键词和分类编码，是为了减少“类别找不到”的概率：关键词负责贴近用户表达，
  /// 分类编码负责让高德按标准 POI 类目召回结果，后续距离排序也更稳定。
  final List<String> amapTypes;

  Color get color => Color(colorValue);
}
