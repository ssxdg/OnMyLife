import 'package:flutter_test/flutter_test.dart';
import 'package:on_my_life/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('用户从类别进入地图并查看点位详情', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const NearbyLifeApp());

    expect(find.text('附近生活'), findsOneWidget);
    expect(find.text('选择类别'), findsOneWidget);
    expect(find.text('美食'), findsOneWidget);
    expect(find.text('医院'), findsOneWidget);

    await tester.tap(find.text('美食'));
    await tester.pumpAndSettle();

    expect(find.text('定位授权'), findsOneWidget);
    expect(find.text('同意并使用当前位置'), findsOneWidget);

    await tester.tap(find.text('同意并使用当前位置'));
    await tester.pumpAndSettle();

    expect(find.text('附近结果'), findsOneWidget);
    expect(find.text('小巷咖啡'), findsOneWidget);
    expect(find.text('320m'), findsOneWidget);

    await tester.tap(find.text('小巷咖啡'));
    await tester.pumpAndSettle();

    expect(find.text('去这里'), findsOneWidget);
    expect(find.text('收藏'), findsOneWidget);

    await tester.tap(find.text('收藏'));
    await tester.pumpAndSettle();

    expect(find.text('已收藏'), findsOneWidget);
  });

  testWidgets('用户暂不授权定位时显示兜底提示', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const NearbyLifeApp());

    await tester.tap(find.text('美食'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('暂不授权'));
    await tester.pumpAndSettle();

    expect(find.text('未开启定位'), findsOneWidget);
    expect(find.text('需要前台定位后才能查找附近点位'), findsOneWidget);
  });
}
