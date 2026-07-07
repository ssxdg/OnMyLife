import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../config/amap_config.dart';
import '../models/place.dart';
import '../services/amap_place_service.dart';
import '../theme/app_colors.dart';

/// 可交互高德地图。
///
/// Flutter 当前没有现成项目内地图实现；这里用 WebView 承载高德 JS API，
/// 是为了直接获得真实道路、建筑、POI 底图以及手机双指缩放能力。
class AmapWebMap extends StatefulWidget {
  const AmapWebMap({super.key, required this.center, required this.places});

  final AmapCoordinate center;
  final List<Place> places;

  @override
  State<AmapWebMap> createState() => _AmapWebMapState();
}

class _AmapWebMapState extends State<AmapWebMap> {
  late final WebViewController _controller;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.mapLand)
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {
            if (!mounted) {
              return;
            }
            setState(() => _loadError = '地图加载失败，请检查网络和高德 Web Key');
          },
        ),
      );
    _loadMap();
  }

  @override
  void didUpdateWidget(covariant AmapWebMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.center.latitude != widget.center.latitude ||
        oldWidget.center.longitude != widget.center.longitude ||
        oldWidget.places != widget.places) {
      _loadMap();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        WebViewWidget(controller: _controller),
        if (_loadError != null)
          ColoredBox(
            color: AppColors.surface.withValues(alpha: 0.92),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  _loadError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _loadMap() async {
    setState(() => _loadError = null);
    await _controller.loadHtmlString(
      _buildMapHtml(),
      baseUrl: 'https://webapi.amap.com',
    );
  }

  String _buildMapHtml() {
    final center = jsonEncode([
      widget.center.longitude,
      widget.center.latitude,
    ]);
    final places = jsonEncode(
      widget.places.map((place) {
        return {
          'name': place.name,
          'address': place.address,
          'distance': place.distanceLabel,
          'position': [place.longitude, place.latitude],
        };
      }).toList(),
    );
    final webKey = Uri.encodeComponent(amapConfig.webKey);
    final securityCode = jsonEncode(amapConfig.webSecurityCode);

    // HTML 保持在组件内生成，是为了让地图随当前坐标和点位列表同步刷新；
    // 所有动态字段都先经过 jsonEncode，避免地点名称里的特殊字符破坏脚本。
    return '''
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="initial-scale=1, maximum-scale=5, user-scalable=yes, width=device-width">
  <style>
    html, body, #container {
      width: 100%;
      height: 100%;
      margin: 0;
      padding: 0;
      overflow: hidden;
      background: #EAF3EE;
      font-family: -apple-system, BlinkMacSystemFont, "PingFang SC", "Microsoft YaHei", sans-serif;
    }
    .current-marker {
      width: 18px;
      height: 18px;
      border-radius: 50%;
      background: #18A999;
      border: 3px solid #FFFFFF;
      box-shadow: 0 0 0 10px rgba(24, 169, 153, 0.16), 0 8px 20px rgba(24, 169, 153, 0.28);
    }
    .place-marker {
      min-width: 30px;
      height: 30px;
      padding: 0 8px;
      border-radius: 15px;
      color: #FFFFFF;
      background: #FF7E67;
      border: 2px solid #FFFFFF;
      box-shadow: 0 8px 16px rgba(31, 41, 51, 0.22);
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 13px;
      font-weight: 800;
    }
    .info-window {
      min-width: 160px;
      max-width: 220px;
      padding: 10px 12px;
      color: #1F2933;
      line-height: 1.4;
    }
    .info-window strong {
      display: block;
      font-size: 14px;
      margin-bottom: 4px;
    }
    .info-window span {
      display: block;
      color: #667085;
      font-size: 12px;
    }
  </style>
  <script>
    window._AMapSecurityConfig = { securityJsCode: $securityCode };
  </script>
  <script src="https://webapi.amap.com/maps?v=2.0&key=$webKey&plugin=AMap.ToolBar,AMap.Scale"></script>
</head>
<body>
  <div id="container"></div>
  <script>
    const center = $center;
    const places = $places;

    function addMarker(map, place, index) {
      const marker = new AMap.Marker({
        position: place.position,
        anchor: 'bottom-center',
        content: '<div class="place-marker">' + (index + 1) + '</div>',
        title: place.name,
      });
      const info = new AMap.InfoWindow({
        offset: new AMap.Pixel(0, -32),
        content:
          '<div class="info-window"><strong>' + place.name + '</strong>' +
          '<span>' + place.distance + ' · ' + place.address + '</span></div>',
      });
      marker.on('click', function () {
        info.open(map, marker.getPosition());
      });
      map.add(marker);
      return marker;
    }

    function initMap() {
      const map = new AMap.Map('container', {
        center: center,
        zoom: 17,
        viewMode: '3D',
        resizeEnable: true,
        showBuildingBlock: true,
        dragEnable: true,
        zoomEnable: true,
        touchZoom: true,
        doubleClickZoom: true,
        keyboardEnable: false,
      });

      map.addControl(new AMap.ToolBar({ liteStyle: true, position: 'RT' }));
      map.addControl(new AMap.Scale());

      const markers = [
        new AMap.Marker({
          position: center,
          anchor: 'center',
          content: '<div class="current-marker"></div>',
          title: '当前位置',
          zIndex: 120,
        }),
      ];
      map.add(markers[0]);

      places.forEach(function (place, index) {
        markers.push(addMarker(map, place, index));
      });

      if (markers.length > 1) {
        map.setFitView(markers, false, [56, 44, 330, 44], 18);
      }
    }

    if (window.AMap) {
      initMap();
    }
  </script>
</body>
</html>
''';
  }
}
