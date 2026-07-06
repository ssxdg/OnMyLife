# 附近生活 App 计划文档

## 项目定位

附近生活 App 是一个面向中国大陆用户的原生移动应用。用户打开 App 后先选择生活类别，例如美食、医院、宠物、厕所、停车场、加油站、充电桩等。选择类别后，App 获取用户前台定位，并以用户当前位置为中心，在地图上展示附近对应类别的点位。

首版目标是完成可运行 MVP：让用户能快速从类别进入地图、看到周边点位、查看点位详情，并跳转到外部地图导航。

## 已确认方案

- 首版平台：Flutter 双端原生 App。
- 服务区域：中国大陆。
- 地图方案：高德地图。
- 视觉风格：A 清爽生活服务风格。
- 设计基准图：`docs/design/style-a-clean-life.png`。
- 首版数据：开发阶段先使用模拟 POI 数据，后续接入高德 POI 查询接口。

## 首版功能范围

### 类别首页

- 展示常用生活类别。
- 默认类别包括：美食、医院、药店、宠物、厕所、停车场、加油站、充电桩、银行、便利店。
- 用户点击类别后进入地图页。

### 地图页

- 使用当前位置作为地图中心点。
- 按用户选择的类别展示附近点位。
- 点位以小气泡形式显示在地图上。
- 地图底部展示附近结果列表。
- 点击气泡或列表项后打开点位详情抽屉。

### 点位详情

- 展示点位名称、地址、距离、营业状态、电话等信息。
- 提供收藏按钮。
- 提供“去这里”按钮，后续用于跳转高德地图导航。

### 定位与隐私

- 默认只申请前台定位。
- 用户同意隐私提示后再请求定位权限。
- 不保存用户轨迹。
- 不默认上传用户精准坐标到自有服务。
- 定位失败时展示手动重试与默认城市兜底状态。

## 暂不实现范围

- 不做账号体系。
- 不做社区纠错。
- 不做后台持续定位。
- 不做支付或商家入驻。
- 不做 AI 推荐。
- 不做自建 POI 数据库。

## 技术实现思路

### 客户端

- 使用 Flutter 创建 Android 和 iOS 双端工程。
- 使用页面状态管理首页类别、当前定位、当前类别、点位列表、选中点位、收藏状态。
- 开发初期使用模拟 POI 数据完成 UI 与交互闭环。
- 高德地图 Key 不硬编码在业务逻辑中，后续通过本地配置或原生平台配置接入。

### 当前实现状态

- 已创建 Flutter Android/iOS 项目结构。
- 已完成类别首页、模拟地图页、地图气泡、底部结果列表和详情抽屉。
- 已完成前台定位授权说明、拒绝授权兜底提示和模拟定位流程。
- 已完成本地收藏，收藏点位 id 保存在设备本地。
- 已完成“去这里”导航入口，优先尝试调起高德地图，失败后使用 Web 地图兜底。
- 暂未接入真实高德地图 SDK，原因是需要高德 Key 和原生平台配置。
- 已配置高德 Web端 Key、安全密钥和 Web服务 Key 的本地读取入口，真实值保存在 `env/amap.local.json`，不会提交到 Git。
- 当前截图中的 Key 可用于 Web端/ Web服务场景；如果后续接入高德 Android/iOS 原生地图 SDK，还需要在高德控制台新增 Android/iOS 平台 Key。

### 新增依赖

- `shared_preferences`：用于保存本地收藏点位 id。首版只保存少量字符串，不需要引入数据库。
- `url_launcher`：用于调起高德地图 Scheme 或浏览器兜底链接，实现“去这里”导航入口。

### 本地打包参数

- 调试 APK 打包命令：`powershell -ExecutionPolicy Bypass -File scripts/build-debug-apk.ps1`
- 等价 Flutter 命令：`C:\tools\flutter\bin\flutter.bat build apk --debug --dart-define-from-file=env/amap.local.json`
- 当前 Android 环境仍需要补齐 NDK 和 cmdline-tools 后才能完成 APK 构建。

### 地图与 POI

- 地图页先实现可替换的地图区域组件。
- 模拟点位阶段使用本地坐标偏移展示气泡。
- 接入高德后，将业务类别映射为高德 POI 类型或关键词。
- 后续可通过后端代理隐藏 Web 服务 Key、做限流和缓存。

### 数据结构

```dart
class LifeCategory {
  final String id;
  final String name;
  final String icon;
  final int colorValue;
}

class Place {
  final String id;
  final String categoryId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final int distanceMeters;
  final String? phone;
  final String openStatus;
  final bool isFavorite;
}
```

## 视觉规范

- 背景：白色为主。
- 主色：薄荷绿，用于主按钮、定位点、选中状态。
- 强调色：珊瑚色，用于重要类别、选中气泡或导航行动按钮。
- 圆角：8px 为主，避免过度圆角。
- 阴影：轻阴影，保持生活服务产品的清爽感。
- 信息密度：移动端优先，类别和列表要容易扫读。

## 验证标准

- App 可以启动到类别首页。
- 点击类别可以进入地图页。
- 地图页可以展示当前类别的模拟点位气泡。
- 底部列表与点位数据一致。
- 点击点位可以打开详情抽屉。
- 收藏状态可以在当前运行周期内切换。
- 定位权限未接入真实 SDK 前，必须有明确的模拟定位或待授权状态。
