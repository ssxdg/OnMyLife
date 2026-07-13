import 'package:flutter/material.dart';

/// 类别使用的地点检索策略。
///
/// 大多数生活服务强调“离我最近”，继续使用周边扩圈；城市景点强调城市代表性，
/// 必须保留高德文本搜索的综合权重顺序，不能再按距离重新排序。
enum LifeCategorySearchMode { nearby, cityRecommended }

/// 生活类别模型。
///
/// 这里同时保留业务 id、界面展示名称和高德查询关键词，是为了让 UI 不直接依赖地图服务字段。
/// 后续接入高德 POI 时，只需要替换映射来源，不需要改动首页类别组件。
class LifeCategory {
  /// 自由关键词搜索使用固定 id，避免把用户输入直接拼进业务标识。
  ///
  /// 搜索结果仍然通过现有类别查询链路加载，但固定 id 可以让降级逻辑明确区分
  /// “预设类别”和“临时关键词”，从而避免接口失败时展示不相关的模拟点位。
  static const String keywordSearchId = 'keyword-search';

  const LifeCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorValue,
    required this.amapKeyword,
    this.amapTypes = const [],
    this.searchMode = LifeCategorySearchMode.nearby,
  });

  /// 创建临时关键词搜索类别。
  ///
  /// 在模型入口统一去除首尾空格，是为了让标题、请求参数和重试操作始终使用
  /// 同一个规范化关键词；自由搜索不限定 POI 编码，交由高德按用户原词召回。
  factory LifeCategory.keywordSearch(String keyword) {
    final normalizedKeyword = keyword.trim();
    if (normalizedKeyword.isEmpty) {
      throw ArgumentError.value(keyword, 'keyword', '搜索关键词不能为空');
    }

    return LifeCategory(
      id: keywordSearchId,
      name: normalizedKeyword,
      icon: Icons.search_rounded,
      colorValue: 0xFF18A999,
      amapKeyword: normalizedKeyword,
    );
  }

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

  /// 当前类别应采用的检索策略，默认值保证原有十五个附近类别无需额外配置。
  final LifeCategorySearchMode searchMode;

  Color get color => Color(colorValue);

  /// 是否为用户临时输入的自由关键词搜索。
  bool get isKeywordSearch => id == keywordSearchId;
}
