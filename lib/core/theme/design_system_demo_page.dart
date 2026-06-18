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
          title: const Text('BioAI Design System Demo'),
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
          _buildNavItem('Components', 'components'),
          _buildNavItem('Tokens', 'tokens'),
          _buildNavItem('Typography', 'typography'),
          _buildNavItem('States', 'states'),
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
        _buildSectionTitle('Primitive Components'),
        SizedBox(height: AppSpacingTokens.sectionSpacing),

        // Buttons
        _buildSubSection('Buttons', _buildButtonExamples()),

        // Cards
        _buildSubSection('Cards', _buildCardExamples()),

        // Chips
        _buildSubSection('Chips', _buildChipExamples()),

        // Inputs
        _buildSubSection('Inputs', _buildInputExamples()),

        // Badges
        _buildSubSection('Badges', _buildBadgeExamples()),

        // Section Headers
        _buildSubSection('Section Headers', _buildSectionHeaderExamples()),
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
          child: const Text('Primary'),
        ),
        AppButton(
          variant: ButtonVariant.secondary,
          onPressed: () {},
          child: const Text('Secondary'),
        ),
        AppButton(
          variant: ButtonVariant.outlined,
          onPressed: () {},
          child: const Text('Outlined'),
        ),
        AppButton(
          variant: ButtonVariant.text,
          onPressed: () {},
          child: const Text('Text'),
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
          child: const Text('Loading'),
        ),
        AppButton(
          variant: ButtonVariant.primary,
          onPressed: null,
          child: const Text('Disabled'),
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
            child: const Text('Default Card'),
          ),
        ),
        SizedBox(
          width: 200,
          child: AppCard(
            variant: CardVariant.elevated,
            child: const Text('Elevated Card'),
          ),
        ),
        SizedBox(
          width: 200,
          child: AppCard(
            variant: CardVariant.outlined,
            child: const Text('Outlined Card'),
          ),
        ),
        SizedBox(
          width: 200,
          child: AppCard(
            variant: CardVariant.defaultCard,
            onTap: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Card tapped!')));
            },
            child: const Text('Interactive Card\n(Tap me)'),
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
          label: 'Selectable',
          selected: _chipSelected,
          onTap: () {
            setState(() {
              _chipSelected = !_chipSelected;
            });
          },
        ),
        AppChip(
          variant: ChipVariant.filter,
          label: 'Filter',
          selected: false,
          onTap: () {},
        ),
        AppChip(
          variant: ChipVariant.action,
          label: 'Action',
          icon: Icons.label,
          onTap: () {},
        ),
        AppChip(
          variant: ChipVariant.action,
          label: 'With Delete',
          onTap: () {},
          onDeleted: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Chip deleted!')));
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
          label: 'Text Field',
          hint: 'Enter text here',
        ),
        SizedBox(height: AppSpacingTokens.itemSpacing),
        AppInput(variant: InputVariant.search, hint: 'Search...'),
        SizedBox(height: AppSpacingTokens.itemSpacing),
        AppInput(
          variant: InputVariant.textField,
          label: 'With Error',
          hint: 'Enter email',
          errorText: 'Invalid email format',
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
          label: 'Success',
        ),
        AppBadge(
          variant: BadgeVariant.status,
          status: BadgeStatus.warning,
          label: 'Warning',
        ),
        AppBadge(
          variant: BadgeVariant.status,
          status: BadgeStatus.error,
          label: 'Error',
        ),
        AppBadge(
          variant: BadgeVariant.status,
          status: BadgeStatus.info,
          label: 'Info',
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
        SectionHeader(title: 'Section Title'),
        SectionHeader(title: 'With Subtitle', subtitle: 'This is a subtitle'),
        SectionHeader(
          title: 'With Action',
          subtitle: 'Subtitle text here',
          actionLabel: 'View All',
          onAction: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Action pressed!')));
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
        _buildSectionTitle('Design Tokens'),
        SizedBox(height: AppSpacingTokens.sectionSpacing),

        _buildSubSection('Colors', _buildColorTokens()),
        _buildSubSection('Spacing', _buildSpacingTokens()),
        _buildSubSection('Radius', _buildRadiusTokens()),
      ],
    );
  }

  Widget _buildColorTokens() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: AppSpacingTokens.itemSpacing,
      runSpacing: AppSpacingTokens.itemSpacing,
      children: [
        _buildColorSwatch('Primary', AppColorTokens.primary),
        _buildColorSwatch('Secondary', AppColorTokens.secondary),
        _buildColorSwatch('Success', AppColorTokens.success),
        _buildColorSwatch('Warning', AppColorTokens.warning),
        _buildColorSwatch('Error', AppColorTokens.error),
        _buildColorSwatch('Info', AppColorTokens.info),
        _buildColorSwatch(
          'Surface',
          isDark ? AppColorTokens.darkSurface : AppColorTokens.surface,
        ),
        _buildColorSwatch(
          'Background',
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
        _buildSpacingExample('Page Padding', AppSpacingTokens.pagePadding),
        _buildSpacingExample(
          'Section Spacing',
          AppSpacingTokens.sectionSpacing,
        ),
        _buildSpacingExample('Card Padding', AppSpacingTokens.cardPadding),
        _buildSpacingExample('Item Spacing', AppSpacingTokens.itemSpacing),
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
        _buildRadiusExample('Button', AppRadiusTokens.button),
        _buildRadiusExample('Card', AppRadiusTokens.card),
        _buildRadiusExample('Input', AppRadiusTokens.input),
        _buildRadiusExample('Chip', AppRadiusTokens.chip),
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
        _buildSectionTitle('Typography'),
        SizedBox(height: AppSpacingTokens.sectionSpacing),

        Text(
          'Display Large',
          style: AppTextStyles.displayLarge.copyWith(color: textColor),
        ),
        SizedBox(height: AppSpacingTokens.itemSpacing),

        Text(
          'Heading 1',
          style: AppTextStyles.heading1.copyWith(color: textColor),
        ),
        SizedBox(height: AppSpacingTokens.itemSpacing),

        Text(
          'Heading 2',
          style: AppTextStyles.heading2.copyWith(color: textColor),
        ),
        SizedBox(height: AppSpacingTokens.itemSpacing),

        Text(
          'Body Large - Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
          style: AppTextStyles.bodyLarge.copyWith(color: textColor),
        ),
        SizedBox(height: AppSpacingTokens.itemSpacing),

        Text(
          'Body Medium - Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
          style: AppTextStyles.bodyMedium.copyWith(color: textColor),
        ),
        SizedBox(height: AppSpacingTokens.itemSpacing),

        Text(
          'Label Large',
          style: AppTextStyles.labelLarge.copyWith(color: textColor),
        ),
        SizedBox(height: AppSpacingTokens.itemSpacing),

        Text(
          'Caption - Small supplementary text',
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
        _buildSectionTitle('State Widgets'),
        SizedBox(height: AppSpacingTokens.sectionSpacing),

        _buildSubSection(
          'Loading State',
          SizedBox(
            height: 200,
            child: LoadingState(
              variant: LoadingVariant.spinner,
              message: 'Loading data...',
            ),
          ),
        ),

        _buildSubSection(
          'Empty State',
          SizedBox(
            height: 300,
            child: EmptyState(
              icon: Icons.inbox,
              title: 'No Items',
              description: 'You don\'t have any items yet.',
              actionLabel: 'Create Item',
              onAction: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Create action pressed!')),
                );
              },
            ),
          ),
        ),

        _buildSubSection(
          'Error State',
          SizedBox(
            height: 300,
            child: ErrorState(
              message: 'Failed to load data. Please try again.',
              onRetry: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Retrying...')));
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
