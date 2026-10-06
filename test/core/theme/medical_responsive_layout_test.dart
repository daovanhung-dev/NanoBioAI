import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/theme/theme.dart';

void main() {
  testWidgets('medical page shell adapts to narrow widths and larger text', (
    tester,
  ) async {
    const widths = <double>[320, 360, 412, 600, 840];
    const textScales = <double>[1, 1.3, 1.6];
    final themes = <ThemeData>[AppTheme.lightTheme, AppTheme.darkTheme];

    for (final theme in themes) {
      for (final width in widths) {
        for (final scale in textScales) {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(width, 900);
          await tester.pumpWidget(
            MaterialApp(
              theme: theme,
              home: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 900),
                  textScaler: TextScaler.linear(scale),
                ),
                child: MedicalScrollPage(
                  title: 'Tổng quan sức khỏe hôm nay',
                  subtitle:
                      'Theo dõi các thay đổi gần đây và chọn bước tiếp theo phù hợp với bạn.',
                  icon: Icons.favorite_outline_rounded,
                  children: [
                    const MedicalSurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Mục tiêu đang theo dõi'),
                          SizedBox(height: AppSpacing.sm),
                          Text(
                            'Thông tin được trình bày theo cách dễ đọc và vẫn có thể cuộn trên màn hình nhỏ.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(
                      onPressed: () {},
                      child: const Text('Xem kế hoạch sức khỏe'),
                    ),
                  ],
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(
            tester.takeException(),
            isNull,
            reason:
                'width=$width, textScale=$scale, brightness=${theme.brightness}',
          );
          expect(find.text('Tổng quan sức khỏe hôm nay'), findsOneWidget);
          expect(find.text('Xem kế hoạch sức khỏe'), findsOneWidget);
        }
      }
    }

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
