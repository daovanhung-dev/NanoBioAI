import 'package:flutter/material.dart';
import 'design_system.dart';

/// Design System Demo Page
///
/// This page demonstrates all primitive components and tokens from the
/// BioAI design system. Use this as a visual reference and testing ground
/// for the new design system.
///
/// **To view this page:**
/// Add a route in app_router.dart and navigate to it, or replace your
/// home page temporarily with this widget.
///
/// **Features:**
/// - All primitive components with variants
/// - Token examples (colors, spacing, typography)
/// - Light/Dark mode toggle
/// - Interactive examples
class DesignSystemDemoPage extends StatefulWidget {
  const DesignSystemDemoPage({super.key});

  @override
  State<DesignSystemDemoPage> createState() => _DesignSystemDemoPageState();
}

class _DesignSystemDemoPageState extends State<DesignSystemDemoPage> {
  bool _isDarkMode = false;
  bool _buttonLoading = false;
  bool _chipSelected = false;
  String _selectedView = 'components';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _isDarkMode ? _buildDarkTheme() : _buildLightTheme(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Bản xem trước hệ thống thiết kế BioAI'),
          actions: [
            IconButton(
              icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: () {
                setState(() {
                  _isDarkMode = !_isDarkMode;
                });
              },
            ),
          ],
        ),
        body: Row(
          children: [
            // Sidebar Navigation
            _buildSidebar(),
            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(AppSpacingTokens.pagePadding),
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 200,
      color: Theme.of(context).brightness == Brightness.dark
          ? AppColorTokens.darkSurface
          : AppColorTokens.surface,
      child: ListView(
        children: [
          _buildNavItem('Thành phần', 'components'),
          _buildNavItem('Mã thiết kế', 'tokens'),
          _buildNavItem('Kiểu chữ', 'typography'),
          _buildNavItem('Trạng thái', 'states'),
        ],
      ),
    );
  }

  Widget _buildNavItem(String title, String view) {
    final isSelected = _selectedView == view;
    return ListTile(
      title: Text(title),
      selected: isSelected,
      selectedColor: AppColorTokens.primary,
      onTap: () {
        setState(() {
          _selectedView = view;
        });
      },
    );
  }

  Widget _buildContent() {
    switch (_selectedView) {
      case 'components':
        return _buildComponentsSection();
      case 'tokens':
        return _buildTokensSection();
      case 'typography':
        return _buildTypographySection();
      case 'states':
        return _buildStatesSection();
      default:
        return _buildComponentsSection();
    }
  }

  // ============================================================================
  // COMPONENTS SECTION
  // ============================================================================

  Widget _buildComponentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Thành phần giao diện cơ bản'),
        SizedBox(height: AppSpacingTokens.sectionSpacing),

        // Buttons
        _buildSubSection('Nút bấm', _buildButtonExamples()),

        // Cards
        _buildSubSection('Thẻ nội dung', _buildCardExamples()),

        // Chips
        _buildSubSection('Nhãn chọn', _buildChipExamples()),

        // Inputs
        _buildSubSection('Trường nhập liệu', _buildInputExamples()),

        // Badges
        _buildSubSection('Huy hiệu', _buildBadgeExamples()),

        // Section Headers
        _buildSubSection('Tiêu đề khu vực', _buildSectionHeaderExamples()),
      ],
    );
  }

  Widget _buildButtonExamples() {
    return Wrap(
      spacing: AppSpacingTokens.itemSpacing,
      runSpacing: AppSpacingTokens.itemSpacing,
      children: [
        AppButton(
          variant: ButtonVariant.primary,
          onPressed: () {},
          child: const Text('Chính'),
        ),
        AppButton(
          variant: ButtonVariant.secondary,
          onPressed: () {},
          child: const Text('Phụ'),
        ),
        AppButton(
          variant: ButtonVariant.outlined,
          onPressed: () {},
          child: const Text('Viền'),
        ),
        AppButton(
          variant: ButtonVariant.text,
          onPressed: () {},
          child: const Text('Văn bản'),
        ),
        AppButton(
          variant: ButtonVariant.icon,
          onPressed: () {},
          icon: Icons.favorite,
        ),
        AppButton(
          variant: ButtonVariant.primary,
          onPressed: () {
            setState(() {
              _buttonLoading = true;
            });
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                setState(() {
                  _buttonLoading = false;
                });
              }
            });
          },
          loading: _buttonLoading,
          child: const Text('Đang tải'),
        ),
        AppButton(
          variant: ButtonVariant.primary,
          onPressed: null,
          child: const Text('Vô hiệu hóa'),
        ),
      ],
    );
  }

  Widget _buildCardExamples() {
    return Wrap(
      spacing: AppSpacingTokens.itemSpacing,
      runSpacing: AppSpacingTokens.itemSpacing,
      children: [
        SizedBox(
          width: 200,
          child: AppCard(
            variant: CardVariant.defaultCard,
            child: const Text('Thẻ mặc định'),
          ),
        ),
        SizedBox(
          width: 200,
          child: AppCard(
            variant: CardVariant.elevated,
            child: const Text('Thẻ nâng cao'),
          ),
        ),
        SizedBox(
          width: 200,
          child: AppCard(
            variant: CardVariant.outlined,
            child: const Text('Thẻ có viền'),
          ),
        ),
        SizedBox(
          width: 200,
          child: AppCard(
            variant: CardVariant.defaultCard,
            onTap: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Đã chạm vào thẻ!')));
            },
            child: const Text('Thẻ có tương tác\n(Chạm để thử)'),
          ),
        ),
      ],
    );
  }

  Widget _buildChipExamples() {
    return Wrap(
      spacing: AppSpacingTokens.itemSpacing,
      runSpacing: AppSpacingTokens.itemSpacing,
      children: [
        AppChip(
          variant: ChipVariant.selectable,
          label: 'Có thể chọn',
          selected: _chipSelected,
          onTap: () {
            setState(() {
              _chipSelected = !_chipSelected;
            });
          },
        ),
        AppChip(
          variant: ChipVariant.filter,
          label: 'Lọc',
          selected: false,
          onTap: () {},
        ),
        AppChip(
          variant: ChipVariant.action,
          label: 'Thao tác',
          icon: Icons.label,
          onTap: () {},
        ),
        AppChip(
          variant: ChipVariant.action,
          label: 'Có thể xóa',
          onTap: () {},
          onDeleted: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Đã xóa nhãn!')));
          },
        ),
      ],
    );
  }

  Widget _buildInputExamples() {
    return Column(
      children: [
        AppInput(
          variant: InputVariant.textField,
          label: 'Ô nhập văn bản',
          hint: 'Nhập nội dung tại đây',
        ),
        SizedBox(height: AppSpacingTokens.itemSpacing),
        AppInput(variant: InputVariant.search, hint: 'Tìm kiếm...'),
        SizedBox(height: AppSpacingTokens.itemSpacing),
        AppInput(
          variant: InputVariant.textField,
          label: 'Có lỗi',
          hint: 'Nhập email',
          errorText: 'Email không đúng định dạng',
        ),
      ],
    );
  }

  Widget _buildBadgeExamples() {
    return Wrap(
      spacing: AppSpacingTokens.itemSpacing,
      runSpacing: AppSpacingTokens.itemSpacing,
      children: [
        AppBadge(
          variant: BadgeVariant.status,
          status: BadgeStatus.success,
          label: 'Thành công',
        ),
        AppBadge(
          variant: BadgeVariant.status,
          status: BadgeStatus.warning,
          label: 'Cảnh báo',
        ),
        AppBadge(
          variant: BadgeVariant.status,
          status: BadgeStatus.error,
          label: 'Lỗi',
        ),
        AppBadge(
          variant: BadgeVariant.status,
          status: BadgeStatus.info,
          label: 'Thông tin',
        ),
        AppBadge(variant: BadgeVariant.count, count: 5),
        AppBadge(variant: BadgeVariant.count, count: 99),
        AppBadge(variant: BadgeVariant.count, count: 100),
        AppBadge(variant: BadgeVariant.dot, status: BadgeStatus.error),
      ],
    );
  }

  Widget _buildSectionHeaderExamples() {
    return Column(
      children: [
        SectionHeader(title: 'Tiêu đề khu vực'),
        SectionHeader(title: 'Có phụ đề', subtitle: 'Đây là phần mô tả phụ'),
        SectionHeader(
          title: 'Có thao tác',
          subtitle: 'Nội dung mô tả phụ',
          actionLabel: 'Xem tất cả',
          onAction: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Đã thực hiện thao tác!')));
          },
        ),
      ],
    );
  }

  // ============================================================================
  // TOKENS SECTION
  // ============================================================================

  Widget _buildTokensSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Mã thiết kế'),
        SizedBox(height: AppSpacingTokens.sectionSpacing),

        _buildSubSection('Màu sắc', _buildColorTokens()),
        _buildSubSection('Khoảng cách', _buildSpacingTokens()),
        _buildSubSection('Bo góc', _buildRadiusTokens()),
      ],
    );
  }

  Widget _buildColorTokens() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: AppSpacingTokens.itemSpacing,
      runSpacing: AppSpacingTokens.itemSpacing,
      children: [
        _buildColorSwatch('Chính', AppColorTokens.primary),
        _buildColorSwatch('Phụ', AppColorTokens.secondary),
        _buildColorSwatch('Thành công', AppColorTokens.success),
        _buildColorSwatch('Cảnh báo', AppColorTokens.warning),
        _buildColorSwatch('Lỗi', AppColorTokens.error),
        _buildColorSwatch('Thông tin', AppColorTokens.info),
        _buildColorSwatch(
          'Bề mặt',
          isDark ? AppColorTokens.darkSurface : AppColorTokens.surface,
        ),
        _buildColorSwatch(
          'Nền',
          isDark ? AppColorTokens.darkBackground : AppColorTokens.background,
        ),
      ],
    );
  }

  Widget _buildColorSwatch(String label, Color color) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadiusTokens.card),
            border: Border.all(color: AppColorTokens.border),
          ),
        ),
        SizedBox(height: AppSpacingTokens.itemSpacing / 2),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }

  Widget _buildSpacingTokens() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSpacingExample('Lề trang', AppSpacingTokens.pagePadding),
        _buildSpacingExample(
          'Khoảng cách khu vực',
          AppSpacingTokens.sectionSpacing,
        ),
        _buildSpacingExample('Lề trong thẻ', AppSpacingTokens.cardPadding),
        _buildSpacingExample('Khoảng cách mục', AppSpacingTokens.itemSpacing),
      ],
    );
  }

  Widget _buildSpacingExample(String label, double spacing) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacingTokens.itemSpacing),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(label, style: AppTextStyles.labelLarge),
          ),
          Container(width: spacing, height: 20, color: AppColorTokens.primary),
          SizedBox(width: AppSpacingTokens.itemSpacing),
          Text('${spacing}px', style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _buildRadiusTokens() {
    return Wrap(
      spacing: AppSpacingTokens.itemSpacing,
      runSpacing: AppSpacingTokens.itemSpacing,
      children: [
        _buildRadiusExample('Nút bấm', AppRadiusTokens.button),
        _buildRadiusExample('Thẻ nội dung', AppRadiusTokens.card),
        _buildRadiusExample('Trường nhập', AppRadiusTokens.input),
        _buildRadiusExample('Nhãn chọn', AppRadiusTokens.chip),
      ],
    );
  }

  Widget _buildRadiusExample(String label, double radius) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColorTokens.primary,
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
        SizedBox(height: AppSpacingTokens.itemSpacing / 2),
        Text(
          '$label\n${radius}px',
          style: AppTextStyles.caption,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ============================================================================
  // TYPOGRAPHY SECTION
  // ============================================================================

  Widget _buildTypographySection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? AppColorTokens.darkTextPrimary
        : AppColorTokens.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Kiểu chữ'),
        SizedBox(height: AppSpacingTokens.sectionSpacing),

        Text(
          'Hiển thị lớn',
          style: AppTextStyles.displayLarge.copyWith(color: textColor),
        ),
        SizedBox(height: AppSpacingTokens.itemSpacing),

        Text(
          'Tiêu đề 1',
          style: AppTextStyles.heading1.copyWith(color: textColor),
        ),
        SizedBox(height: AppSpacingTokens.itemSpacing),

        Text(
          'Tiêu đề 2',
          style: AppTextStyles.heading2.copyWith(color: textColor),
        ),
        SizedBox(height: AppSpacingTokens.itemSpacing),

        Text(
          'Nội dung lớn – ví dụ văn bản để xem trước kiểu chữ.',
          style: AppTextStyles.bodyLarge.copyWith(color: textColor),
        ),
        SizedBox(height: AppSpacingTokens.itemSpacing),

        Text(
          'Nội dung vừa – ví dụ văn bản để xem trước kiểu chữ.',
          style: AppTextStyles.bodyMedium.copyWith(color: textColor),
        ),
        SizedBox(height: AppSpacingTokens.itemSpacing),

        Text(
          'Nhãn lớn',
          style: AppTextStyles.labelLarge.copyWith(color: textColor),
        ),
        SizedBox(height: AppSpacingTokens.itemSpacing),

        Text(
          'Chú thích – văn bản bổ trợ nhỏ',
          style: AppTextStyles.caption.copyWith(color: textColor),
        ),
      ],
    );
  }

  // ============================================================================
  // STATES SECTION
  // ============================================================================

  Widget _buildStatesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Thành phần trạng thái'),
        SizedBox(height: AppSpacingTokens.sectionSpacing),

        _buildSubSection(
          'Trạng thái đang tải',
          SizedBox(
            height: 200,
            child: LoadingState(
              variant: LoadingVariant.spinner,
              message: 'Đang tải dữ liệu...',
            ),
          ),
        ),

        _buildSubSection(
          'Trạng thái trống',
          SizedBox(
            height: 300,
            child: EmptyState(
              icon: Icons.inbox,
              title: 'Chưa có mục nào',
              description: 'Bạn chưa có mục nào ở đây.',
              actionLabel: 'Tạo mục mới',
              onAction: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã chọn tạo mục mới!')),
                );
              },
            ),
          ),
        ),

        _buildSubSection(
          'Trạng thái lỗi',
          SizedBox(
            height: 300,
            child: ErrorState(
              message: 'Không tải được dữ liệu. Bạn thử lại nhé.',
              onRetry: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Đang thử lại...')));
              },
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // HELPER WIDGETS
  // ============================================================================

  Widget _buildSectionTitle(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: AppTextStyles.heading1.copyWith(
        color: isDark
            ? AppColorTokens.darkTextPrimary
            : AppColorTokens.textPrimary,
      ),
    );
  }

  Widget _buildSubSection(String title, Widget content) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.heading2.copyWith(
            color: isDark
                ? AppColorTokens.darkTextPrimary
                : AppColorTokens.textPrimary,
          ),
        ),
        SizedBox(height: AppSpacingTokens.itemSpacing),
        content,
        SizedBox(height: AppSpacingTokens.sectionSpacing),
      ],
    );
  }

  // ============================================================================
  // THEME DATA
  // ============================================================================

  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColorTokens.background,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColorTokens.surface,
        foregroundColor: AppColorTokens.textPrimary,
        elevation: 0,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColorTokens.darkBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColorTokens.darkSurface,
        foregroundColor: AppColorTokens.darkTextPrimary,
        elevation: 0,
      ),
    );
  }
}
