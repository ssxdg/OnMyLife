import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/mock_life_repository.dart';
import '../models/life_category.dart';
import '../models/place.dart';
import '../services/favorite_storage.dart';
import '../services/navigation_url_builder.dart';
import '../theme/app_colors.dart';

class NearbyLifeApp extends StatelessWidget {
  const NearbyLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Material 3 提供更接近原生移动端的控件状态，主题色锁定为 A 风格的薄荷绿。
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '附近生活',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.surface,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.mint,
          primary: AppColors.mint,
          secondary: AppColors.coral,
          surface: AppColors.surface,
        ),
        fontFamilyFallback: const ['PingFang SC', 'Microsoft YaHei', 'sans'],
      ),
      home: const LifeHomeScreen(),
    );
  }
}

class LifeHomeScreen extends StatefulWidget {
  const LifeHomeScreen({super.key});

  @override
  State<LifeHomeScreen> createState() => _LifeHomeScreenState();
}

class _LifeHomeScreenState extends State<LifeHomeScreen> {
  // 仓库放在页面状态内，确保收藏切换可以在当前运行周期保留，同时不引入账号和持久化复杂度。
  MockLifeRepository _repository = MockLifeRepository();
  FavoriteStorage? _favoriteStorage;

  LifeCategory? _selectedCategory;
  bool _hasLocationConsent = false;
  bool _locationDenied = false;

  @override
  void initState() {
    super.initState();
    _restoreFavorites();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = _selectedCategory;

    return Scaffold(
      body: SafeArea(
        child: selectedCategory == null
            ? _CategoryHome(
                categories: _repository.categories,
                showLocationFallback: _locationDenied,
                onCategorySelected: _handleCategorySelected,
              )
            : _MapResultsScreen(
                category: selectedCategory,
                places: _repository.placesForCategory(selectedCategory.id),
                repository: _repository,
                favoriteStorage: _favoriteStorage,
                onBack: () => setState(() => _selectedCategory = null),
                onChanged: () => setState(() {}),
              ),
      ),
    );
  }

  void _handleCategorySelected(LifeCategory category) {
    if (_hasLocationConsent) {
      setState(() => _selectedCategory = category);
      return;
    }

    _showLocationConsent(category);
  }

  Future<void> _restoreFavorites() async {
    final preferences = await SharedPreferences.getInstance();
    final storage = FavoriteStorage(preferences);
    if (!mounted) {
      return;
    }

    setState(() {
      _favoriteStorage = storage;
      _repository = MockLifeRepository(
        favoritePlaceIds: storage.loadFavoritePlaceIds(),
      );
    });
  }

  void _showLocationConsent(LifeCategory category) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '定位授权',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '仅使用前台定位为你查找附近点位，不保存轨迹，也不会默认上传精准坐标。',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _hasLocationConsent = true;
                    _locationDenied = false;
                    _selectedCategory = category;
                  });
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: AppColors.mint,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('同意并使用当前位置'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() => _locationDenied = true);
                },
                child: const Text('暂不授权'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryHome extends StatelessWidget {
  const _CategoryHome({
    required this.categories,
    required this.showLocationFallback,
    required this.onCategorySelected,
  });

  final List<LifeCategory> categories;
  final bool showLocationFallback;
  final ValueChanged<LifeCategory> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.softMint,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.near_me_rounded,
                        color: AppColors.mint,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '附近生活',
                            style: TextStyle(
                              color: AppColors.ink,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '选择类别，快速找到身边可用地点',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  '选择类别',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (showLocationFallback) ...[
                  const SizedBox(height: 12),
                  const _LocationFallbackNotice(),
                ],
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate((context, index) {
              final category = categories[index];
              return _CategoryTile(
                category: category,
                onTap: () => onCategorySelected(category),
              );
            }, childCount: categories.length),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.48,
            ),
          ),
        ),
      ],
    );
  }
}

class _LocationFallbackNotice extends StatelessWidget {
  const _LocationFallbackNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.softCoral,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.coral.withValues(alpha: 0.22)),
      ),
      child: const Row(
        children: [
          Icon(Icons.location_off_rounded, color: AppColors.coral, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '未开启定位',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '需要前台定位后才能查找附近点位',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.onTap});

  final LifeCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(8),
      elevation: 1,
      shadowColor: AppColors.mint.withValues(alpha: 0.10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.line),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(category.icon, color: category.color, size: 22),
              ),
              Text(
                category.name,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapResultsScreen extends StatelessWidget {
  const _MapResultsScreen({
    required this.category,
    required this.places,
    required this.repository,
    required this.favoriteStorage,
    required this.onBack,
    required this.onChanged,
  });

  final LifeCategory category;
  final List<Place> places;
  final MockLifeRepository repository;
  final FavoriteStorage? favoriteStorage;
  final VoidCallback onBack;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: '返回',
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '已按“${category.amapKeyword}”准备高德 POI 查询',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              _MockMap(category: category, places: places),
              Align(
                alignment: Alignment.bottomCenter,
                child: _ResultsSheet(
                  places: places,
                  onPlaceTap: (place) => _showPlaceDetail(context, place),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showPlaceDetail(BuildContext context, Place place) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final latest = repository.placeById(place.id);

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          latest.name,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(
                        latest.distanceLabel,
                        style: const TextStyle(
                          color: AppColors.coral,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    latest.address,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${latest.openStatus}${latest.phone == null ? '' : ' · ${latest.phone}'}',
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            repository.toggleFavorite(latest.id);
                            favoriteStorage?.saveFavoritePlaceIds(
                              repository.favoritePlaceIds,
                            );
                            setSheetState(() {});
                            onChanged();
                          },
                          icon: Icon(
                            latest.isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                          ),
                          label: Text(latest.isFavorite ? '已收藏' : '收藏'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: latest.isFavorite
                                ? AppColors.coral
                                : AppColors.ink,
                            side: const BorderSide(color: AppColors.line),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _openNavigation(context, latest),
                          icon: const Icon(Icons.navigation_rounded),
                          label: const Text('去这里'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.coral,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openNavigation(BuildContext context, Place place) async {
    final amapUri = buildAmapNavigationUri(
      name: place.name,
      latitude: place.latitude,
      longitude: place.longitude,
    );
    final fallbackUri = buildWebMapFallbackUri(
      name: place.name,
      latitude: place.latitude,
      longitude: place.longitude,
    );

    final opened = await launchUrl(amapUri);
    if (!opened) {
      await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
    }

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已为你打开导航：${place.name}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _MockMap extends StatelessWidget {
  const _MockMap({required this.category, required this.places});

  final LifeCategory category;
  final List<Place> places;

  @override
  Widget build(BuildContext context) {
    // 这里用 Flutter 原生布局模拟地图，是为了先完成可测试的点位体验；
    // 等高德 Key 配好后，可以把该组件替换为真实高德 Map Widget。
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(color: AppColors.mapLand),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _MapPainter())),
          const Positioned(
            top: 148,
            left: 0,
            right: 0,
            child: Center(child: _LocationPulse()),
          ),
          ...List.generate(places.length, (index) {
            final offsets = [
              const Offset(82, 96),
              const Offset(232, 132),
              const Offset(148, 214),
            ];
            final offset = offsets[index % offsets.length];

            return Positioned(
              left: offset.dx,
              top: offset.dy,
              child: _MapBubble(index: index + 1, color: category.color),
            );
          }),
        ],
      ),
    );
  }
}

class _MapBubble extends StatelessWidget {
  const _MapBubble({required this.index, required this.color});

  final int index;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.24),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        '$index',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _LocationPulse extends StatelessWidget {
  const _LocationPulse();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.mint.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(29),
      ),
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: AppColors.mint,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: Colors.white, width: 3),
        ),
      ),
    );
  }
}

class _ResultsSheet extends StatelessWidget {
  const _ResultsSheet({required this.places, required this.onPlaceTap});

  final List<Place> places;
  final ValueChanged<Place> onPlaceTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 285),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A1F2933),
            blurRadius: 22,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '附近结果',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '${places.length} 个地点',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              itemBuilder: (context, index) {
                final place = places[index];
                return _PlaceRow(place: place, onTap: () => onPlaceTap(place));
              },
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, color: AppColors.line),
              itemCount: places.length,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceRow extends StatelessWidget {
  const _PlaceRow({required this.place, required this.onTap});

  final Place place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.zero,
        title: Text(
          place.name,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          '${place.openStatus} · ${place.address}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        trailing: Text(
          place.distanceLabel,
          style: const TextStyle(
            color: AppColors.coral,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = AppColors.mapRoad
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final thinRoadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.72)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(-20, size.height * 0.26),
      Offset(size.width + 30, size.height * 0.18),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.18, -20),
      Offset(size.width * 0.64, size.height * 0.72),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.06, size.height * 0.52),
      Offset(size.width * 0.92, size.height * 0.40),
      thinRoadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.74, 0),
      Offset(size.width * 0.88, size.height * 0.62),
      thinRoadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
