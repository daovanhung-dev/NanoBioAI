export type FeatureStatus = 'live' | 'partial' | 'soon';

export type WebsiteFeature = {
  icon: string;
  title: string;
  status: string;
  tone: FeatureStatus;
  text: string;
};

export const websiteFeatures: WebsiteFeature[] = [
  { icon: '◎', title: 'Hồ sơ & mục tiêu', status: 'Đang có', tone: 'live', text: 'Thông tin và thói quen trong hồ sơ cá nhân.' },
  { icon: '✦', title: 'Gợi ý từ AI', status: 'Một phần · cần kết nối', tone: 'partial', text: 'Lịch trình gợi ý theo hồ sơ cá nhân.' },
  { icon: '▦', title: 'Lịch hằng ngày', status: 'Đang có', tone: 'live', text: 'Bữa ăn, nước uống, vận động và việc cần làm.' },
  { icon: '◒', title: 'Bữa ăn & dinh dưỡng', status: 'Đang có', tone: 'live', text: 'Ghi nhận bữa ăn và dinh dưỡng.' },
  { icon: '↗', title: 'Luyện tập', status: 'Đang hoàn thiện', tone: 'partial', text: 'Bài tập tại nhà và phòng gym.' },
  { icon: '♡', title: 'Theo dõi sức khỏe', status: 'Đang có', tone: 'live', text: 'Check-in, chỉ số cơ thể, tâm trạng và tiến trình.' },
  { icon: '◷', title: 'Nhắc nhở', status: 'Đang có', tone: 'live', text: 'Nhắc giờ ăn, uống nước và vận động.' },
  { icon: '◉', title: 'Trò chuyện với Nabi', status: 'Một phần', tone: 'partial', text: 'Trò chuyện và giọng nói đang hoàn thiện.' },
  { icon: '＋', title: 'Giấc ngủ · Căng thẳng · Cộng đồng', status: 'Sắp ra mắt', tone: 'soon', text: 'Các tính năng đang được chuẩn bị.' },
];

export type WebsitePerson = {
  group: 'project' | 'reference';
  name: string;
  role: string;
  image?: keyof typeof websiteAssets;
  initials: string;
  story: string;
  sourceLabel: string;
  sourceUrl: string;
};

export type WebsiteGalleryItem = {
  title: string;
  image: keyof typeof websiteAssets;
};

export const websitePeople: WebsitePerson[] = [
  {
    group: 'project', name: 'Lưu Hải Minh', role: 'Nhà sáng chế', image: 'teamMinh', initials: 'LM',
    story: 'Theo đuổi việc đưa công nghệ vào ứng dụng thực tiễn và chăm sóc sức khỏe chủ động.',
    sourceLabel: 'Hồ sơ dự án NanoBio', sourceUrl: 'https://github.com/daovanhung-dev/NanoBioAI/blob/main/lib/app_versions/v1/features/onboarding/presentation/widgets/consent_step.dart',
  },
  {
    group: 'project', name: 'Lê Quang Thành', role: 'Nhà sáng chế', image: 'teamThanh', initials: 'LT',
    story: 'Mang khát vọng đưa tri thức và công nghệ ứng dụng vào đời sống, góp phần giúp mỗi người chủ động chăm sóc sức khỏe hằng ngày.',
    sourceLabel: 'Hồ sơ dự án NanoBio', sourceUrl: 'https://github.com/daovanhung-dev/NanoBioAI/blob/main/lib/app_versions/v1/features/onboarding/presentation/widgets/consent_step.dart',
  },
  {
    group: 'project', name: 'Thủy Tiên', role: 'Huấn luyện viên', image: 'teamTien', initials: 'TT',
    story: 'Chia sẻ kiến thức dinh dưỡng và lối sống chủ động theo cách gần gũi với đời sống hằng ngày.',
    sourceLabel: 'Hồ sơ dự án NanoBio', sourceUrl: 'https://github.com/daovanhung-dev/NanoBioAI/blob/main/lib/app_versions/v1/features/onboarding/presentation/widgets/consent_step.dart',
  },
  {
    group: 'reference', name: 'GS.VS Phạm Văn Thức', role: 'Dị ứng – Miễn dịch học', initials: 'PT',
    story: 'Nano Bio VN giới thiệu ông trong Ban Khoa học với chuyên môn Dị ứng – Miễn dịch học.',
    sourceLabel: 'Ban Khoa học Nano Bio VN', sourceUrl: 'https://nanobiovn.com/',
  },
  {
    group: 'reference', name: 'PGS.TS, TTƯT Nguyễn Quang Duật', role: 'Tiêu hóa – Gan mật', initials: 'QD',
    story: 'Nano Bio VN giới thiệu ông trong Ban Khoa học với chuyên môn Tiêu hóa – Gan mật.',
    sourceLabel: 'Ban Khoa học Nano Bio VN', sourceUrl: 'https://nanobiovn.com/',
  },
];

export const websiteGallery: WebsiteGalleryItem[] = [
  { title: 'Dashboard hôm nay', image: 'galleryToday' },
  { title: 'Tiện ích sức khỏe', image: 'galleryWellnessTools' },
  { title: 'Ngày của tôi', image: 'galleryMyDay' },
  { title: 'Thực đơn', image: 'galleryMeals' },
  { title: 'Sức khỏe của bạn', image: 'galleryHealthOverview' },
  { title: 'Uống nước hôm nay', image: 'galleryWaterToday' },
];

export const websiteFaq = [
  { q: 'NanoBio có thay thế bác sĩ không?', a: 'Không. NanoBio hỗ trợ theo dõi thói quen, không chẩn đoán hay thay thế tư vấn y khoa.' },
  { q: 'Vì sao cần số điện thoại?', a: 'Để nhận link tải và đối chiếu ưu đãi. Xem cách dùng dữ liệu trong chính sách quyền riêng tư.' },
  { q: 'Ưu đãi Plus 30 ngày gồm gì?', a: 'AI Chat và tạo lịch AI không giới hạn. Ưu đãi không gồm FamilyPlus; một số tính năng đang hoàn thiện.' },
  { q: 'NanoBio có trên iPhone không?', a: 'Early Access hiện dành cho Android.' },
];

export const websiteAssets = {
  logo: 'logo.jpg',
  nabiWave: 'nabi-wave.png',
  nabiThink: 'nabi-think.png',
  nabiPlan: 'nabi-plan.png',
  fitnessAtlas: 'fitness-atlas.png',
  nabiStreak: 'nabi-streak.png',
  teamMinh: 'team-minh.jpg',
  teamThanh: 'team-thanh.jpg',
  teamTien: 'team-tien.jpg',
  galleryToday: 'gallery-today.jpg',
  galleryWellnessTools: 'gallery-wellness-tools.jpg',
  galleryMyDay: 'gallery-my-day.jpg',
  galleryMeals: 'gallery-meals.jpg',
  galleryHealthOverview: 'gallery-health-overview.jpg',
  galleryWaterToday: 'gallery-water-today.jpg',
} as const;
