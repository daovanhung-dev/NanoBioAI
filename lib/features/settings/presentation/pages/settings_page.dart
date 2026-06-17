import 'package:flutter/material.dart';

import 'package:nano_app/core/theme/theme.dart';

import 'dev_database_viewer_page.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.pagePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildProfileCard(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildSectionTitle('Tài khoản'),
                    const SizedBox(height: AppSpacing.md),
                    _buildMenuCard(
                      children: [
                        _buildMenuItem(
                          icon: Icons.person_rounded,
                          title: 'Thông tin cá nhân',
                          subtitle:
                              'Cùng mình xem lại những điều bạn đã chia sẻ',
                        ),
                        _divider(),
                        _buildMenuItem(
                          icon: Icons.lock_rounded,
                          title: 'Bảo mật',
                          subtitle:
                              'Giữ tài khoản và thông tin của bạn an toàn',
                        ),
                        _divider(),
                        _buildMenuItem(
                          icon: Icons.notifications_rounded,
                          title: 'Thông báo',
                          subtitle: 'Chọn cách bạn muốn mình nhắc nhở',
                          trailing: Switch(
                            value: true,
                            activeThumbColor: AppColors.primary,
                            onChanged: (_) {},
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _buildSectionTitle('Ứng dụng'),
                    const SizedBox(height: AppSpacing.md),
                    _buildMenuCard(
                      children: [
                        _buildMenuItem(
                          icon: Icons.dark_mode_rounded,
                          title: 'Chế độ tối',
                          subtitle:
                              'Dịu mắt hơn khi bạn dùng ứng dụng vào buổi tối',
                          trailing: Switch(
                            value: false,
                            activeThumbColor: AppColors.primary,
                            onChanged: (_) {},
                          ),
                        ),
                        _divider(),
                        _buildMenuItem(
                          icon: Icons.language_rounded,
                          title: 'Ngôn ngữ',
                          subtitle: 'Tiếng Việt',
                        ),
                        _divider(),
                        _buildMenuItem(
                          icon: Icons.storage_rounded,
                          title: 'Dung lượng',
                          subtitle:
                              'Dọn bớt dữ liệu tạm để ứng dụng nhẹ nhàng hơn',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _buildSectionTitle('Dev'),
                    const SizedBox(height: AppSpacing.md),
                    _buildMenuCard(
                      children: [
                        _buildMenuItem(
                          icon: Icons.developer_mode_rounded,
                          title: 'Database',
                          subtitle:
                              'Xem toàn bộ bảng, cấu trúc cột và dữ liệu SQLite local',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const DevDatabaseViewerPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _buildSectionTitle('AI & Sức khỏe'),
                    const SizedBox(height: AppSpacing.md),
                    _buildMenuCard(
                      children: [
                        _buildMenuItem(
                          icon: Icons.auto_awesome_rounded,
                          title: 'Cách mình đồng hành với bạn',
                          subtitle:
                              'Điều chỉnh phong cách và mức độ hỗ trợ bạn mong muốn',
                        ),
                        _divider(),
                        _buildMenuItem(
                          icon: Icons.favorite_rounded,
                          title: 'Mục tiêu sức khỏe',
                          subtitle:
                              'Cập nhật điều bạn muốn chúng ta cùng đạt được',
                        ),
                        _divider(),
                        _buildMenuItem(
                          icon: Icons.sync_rounded,
                          title: 'Dữ liệu của bạn',
                          subtitle:
                              'Kiểm tra cách thông tin được lưu giữ và bảo vệ',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _buildDangerCard(),
                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cài đặt',
                style: AppTextStyles.heading1.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Bạn muốn mình điều chỉnh trải nghiệm thế nào?',
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        ),
        Container(
          height: 58,
          width: 58,
          decoration: AppDecoration.gradient(
            colors: const [AppColors.primary, AppColors.secondary],
            radius: AppRadius.circular,
            shadows: AppShadows.primary,
          ),
          child: const Icon(
            Icons.settings_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecoration.gradient(
        colors: const [Color(0xFF2563EB), Color(0xFF06B6D4)],
        radius: AppRadius.xxl,
        shadows: AppShadows.lg,
      ),
      child: Row(
        children: [
          Container(
            height: 72,
            width: 72,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.18),
              borderRadius: BorderRadius.circular(AppRadius.circular),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đào Văn Hùng',
                  style: AppTextStyles.heading3.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'AI Health Premium',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(.9),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.16),
                    borderRadius: BorderRadius.circular(AppRadius.circular),
                  ),
                  child: Text(
                    'Mình đang đồng hành cùng bạn',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.white70,
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w700),
    );
  }

  Widget _buildMenuCard({required List<Widget> children}) {
    return Container(
      decoration: AppDecoration.card(
        radius: AppRadius.xxl,
        shadows: AppShadows.soft,
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(
                gradient: AppGradients.primary,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.labelLarge.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
            trailing ??
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: AppColors.textHint,
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecoration.card(
        radius: AppRadius.xxl,
        shadows: AppShadows.sm,
      ),
      child: Column(
        children: [
          Container(
            height: 72,
            width: 72,
            decoration: BoxDecoration(
              color: AppColors.errorSoft,
              borderRadius: BorderRadius.circular(AppRadius.circular),
            ),
            child: const Icon(
              Icons.logout_rounded,
              color: AppColors.error,
              size: 34,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Đăng xuất',
            style: AppTextStyles.heading3.copyWith(color: AppColors.error),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Mình sẽ nhớ bạn. Bạn có thể quay lại bất cứ lúc nào.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              onPressed: () {},
              child: const Text('Tạm dừng tại đây'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return const Divider(height: 1, thickness: 1, color: AppColors.borderLight);
  }
}
