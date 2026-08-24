class FoodScanException implements Exception {
  final String code;
  final String userMessage;
  final Object? cause;

  const FoodScanException({
    required this.code,
    required this.userMessage,
    this.cause,
  });

  const FoodScanException.authRequired()
      : this(
          code: 'AUTH_REQUIRED',
          userMessage: 'Bạn cần đăng nhập để sử dụng quét món ăn.',
        );

  const FoodScanException.plusRequired()
      : this(
          code: 'PLUS_REQUIRED',
          userMessage: 'Quét món ăn là quyền lợi dành riêng cho gói Plus.',
        );

  const FoodScanException.notFood()
      : this(
          code: 'NOT_FOOD',
          userMessage:
              'Nabi chưa nhận thấy món ăn trong ảnh. Bạn thử chụp rõ toàn bộ phần ăn nhé.',
        );

  @override
  String toString() => 'FoodScanException($code): $userMessage';
}
