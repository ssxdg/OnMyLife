# 附近生活 App 开发清单

## 已确认事项

- [x] 确认项目方向：附近生活点位查询 App。
- [x] 确认首版平台：Flutter 双端原生 App。
- [x] 确认服务区域：中国大陆。
- [x] 确认地图方案：高德地图。
- [x] 确认视觉风格：A 清爽生活服务风格。
- [x] 配置高德 Web端 Key、安全密钥和 Web服务 Key 的本地读取入口。
- [x] 保存计划文档到 `docs/nearby-life-app-plan.md`。
- [x] 保存开发清单到 `docs/nearby-life-app-checklist.md`。
- [x] 保存 A 风格设计图到 `docs/design/style-a-clean-life.png`。

## 开发事项

- [x] 使用终端创建 Flutter 项目结构。
- [x] 搭建基础页面：首页类别页、地图页、详情抽屉。
- [x] 接入定位权限流程：首版已完成前台定位授权说明、同意流程和拒绝兜底提示。
- [ ] 接入高德地图展示：当前已配置 Web端/Web服务 Key；如接入 Android/iOS 原生高德地图 SDK，还需要新增对应平台 Key 后替换当前模拟地图组件。
- [x] 配置高德 Web服务 Key：已通过 `env/amap.local.json` 和 `--dart-define-from-file` 接入，真实文件不提交。
- [x] 实现类别到 POI 搜索参数的映射。
- [x] 实现地图气泡点位展示：当前使用模拟地图气泡，后续可替换为高德 Marker。
- [x] 实现底部结果列表。
- [x] 实现点位详情与导航跳转：已支持高德 App Scheme 和 Web 地图兜底链接。
- [x] 实现本地收藏：已使用 `shared_preferences` 保存收藏点位 id。
- [x] 添加隐私授权与定位失败兜底状态。
- [ ] 运行并验证 Android 首版可用流程：当前环境缺少 Android SDK/设备，暂未完成真机或 APK 验证。

## 验证记录

- [x] `flutter test`：通过。
- [x] `flutter analyze`：通过。
- [ ] Android 真机或模拟器验证：`flutter doctor -v` 显示 Android SDK 缺少 `cmdline-tools`，且 Google Maven 检查超时，待环境补齐后执行。

## 执行约束

- 每完成一个阶段，更新本清单对应状态。
- 不实现账号、社区纠错、后台持续定位、支付和 AI 推荐。
- 开发初期使用模拟 POI 数据，避免高德 Key 阻塞 UI 与流程验证。
- 后续接入高德 SDK 时，Key 不写入业务代码。
