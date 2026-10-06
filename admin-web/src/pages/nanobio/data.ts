export type FeatureStatus = 'live' | 'partial' | 'soon';

export type WebsiteFeature = {
  icon: string;
  title: string;
  status: string;
  tone: FeatureStatus;
  text: string;
};

export const websiteFeatures: WebsiteFeature[] = [
  { icon: '◎', title: 'Onboarding & hồ sơ', status: 'Đang có', tone: 'live', text: 'Ghi nhận thông tin cơ bản, hồ sơ cơ thể, mục tiêu, lối sống, tình trạng tự khai và consent trước khi tạo lộ trình.' },
  { icon: '✦', title: 'Kế hoạch cá nhân hóa AI', status: 'Đang có · cần backend', tone: 'partial', text: 'AI hỗ trợ xây dựng lịch từ hồ sơ và catalog đã chuẩn bị; kết quả được kiểm tra trước khi đưa vào trải nghiệm.' },
  { icon: '▦', title: 'Lịch sinh hoạt hằng ngày', status: 'Đang có', tone: 'live', text: 'Theo dõi bữa ăn, uống nước, vận động, check-in và các nhiệm vụ sức khỏe trong cùng một timeline.' },
  { icon: '◒', title: 'Dinh dưỡng & bữa ăn', status: 'Đang có', tone: 'live', text: 'Gợi ý bữa ăn, theo dõi calories, protein, carb, fat và lịch sử bữa ăn theo hướng wellness.' },
  { icon: '↗', title: 'Chế độ luyện tập', status: 'Đang phát triển mạnh', tone: 'partial', text: 'Gym-first và tập tại nhà theo mục tiêu, kinh nghiệm, thời lượng, thiết bị và hạn chế vận động đã khai báo.' },
  { icon: '♡', title: 'Theo dõi sức khỏe', status: 'Đang có', tone: 'live', text: 'Daily check-in, nước uống, cân nặng/chỉ số cơ thể, tâm trạng, tiến độ nhiệm vụ và insight phù hợp.' },
  { icon: '◷', title: 'Nhắc nhở thông minh', status: 'Đang có', tone: 'live', text: 'Local notification cho lịch ăn, uống nước, vận động, task trong ngày và các tương tác Nabi.' },
  { icon: '◉', title: 'AI Chat / Voice', status: 'Một phần', tone: 'partial', text: 'Luồng trò chuyện và giọng nói đang được hoàn thiện; một số khả năng phụ thuộc đăng nhập, backend, quota và membership.' },
  { icon: '＋', title: 'Sleep · Stress · Community', status: 'Sắp ra mắt', tone: 'soon', text: 'Một số module hiện còn ở trạng thái placeholder hoặc đang phát triển và được tách rõ khỏi nhóm đã có.' },
];

export type WebsitePerson = {
  name: string;
  role: string;
  image: keyof typeof websiteAssets;
  story: string;
  source: string;
};

export type WebsiteGalleryItem = {
  title: string;
  image: keyof typeof websiteAssets;
};

export const websitePeople: WebsitePerson[] = [
  {
    name: 'Lưu Hải Minh', role: 'Nhà sáng chế', image: 'teamMinh',
    story: 'Đồng hành cùng dự án với niềm tin rằng sức khỏe cần một hệ sinh thái biết lắng nghe, nhắc nhở và cùng người dùng vun đắp những thói quen nhỏ mỗi ngày.',
    source: 'GitHub NanoBioAI + Nano Bio VN',
  },
  {
    name: 'Lê Quang Thành', role: 'Nhà sáng chế', image: 'teamThanh',
    story: 'Mang khát vọng đưa tri thức và công nghệ ứng dụng vào đời sống, góp phần giúp mỗi người chủ động chăm sóc sức khỏe hằng ngày.',
    source: 'GitHub NanoBioAI',
  },
  {
    name: 'Nguyễn Thị Thủy Tiên', role: 'Huấn luyện viên', image: 'teamTien',
    story: 'Đồng hành từ kinh nghiệm chia sẻ về dinh dưỡng và chăm sóc sức khỏe chủ động, giúp người dùng bớt hoang mang trước các lựa chọn mỗi ngày.',
    source: 'GitHub NanoBioAI + Nano Bio VN',
  },
];

export const websiteGallery: WebsiteGalleryItem[] = [
  { title: 'Dashboard hôm nay', image: 'galleryDashboard' },
  { title: 'Kho tính năng', image: 'galleryFeatures' },
  { title: 'Health Score', image: 'galleryScore' },
  { title: 'Trò chuyện với Nabi', image: 'galleryChat' },
  { title: 'Theo dõi nước', image: 'galleryWater' },
  { title: 'Tổng kết tuần', image: 'galleryWeekly' },
];

export const websiteFaq = [
  { q: 'NanoBio có thay thế bác sĩ không?', a: 'Không. NanoBio/Nabi là sản phẩm wellness hỗ trợ theo dõi sức khỏe và xây dựng thói quen. Ứng dụng không chẩn đoán, kê đơn hoặc thay thế tư vấn chuyên môn.' },
  { q: 'Tại sao cần nhập số điện thoại khi tải ứng dụng?', a: 'Ứng dụng được tải miễn phí. Số điện thoại dùng để ghi nhận người dùng Early Access, hỗ trợ cài đặt và đối chiếu để cấp ưu đãi VIP 1 tháng cho tài khoản tương ứng. Số điện thoại không được hiển thị công khai.' },
  { q: 'VIP 1 tháng có những quyền lợi gì?', a: 'VIP trên website tương đương quyền lợi gói Plus trong 30 ngày: AI Chat không giới hạn thay vì 3 lượt/ngày, tạo lịch trình AI không giới hạn thay vì 3 lượt/tháng, cùng quyền Plus cho các module nâng cao khi chúng khả dụng. Advanced Health Tracking và Goal Roadmap vẫn đang được hoàn thiện theo tiến độ phát hành.' },
  { q: 'VIP 1 tháng có bao gồm FamilyPlus không?', a: 'Không. Ưu đãi VIP 1 tháng ánh xạ sang gói Plus. Các quyền riêng của FamilyPlus như quản lý nhiều thành viên, lịch gia đình và theo dõi sức khỏe gia đình không nằm trong ưu đãi này.' },
  { q: 'Bản Early Access có ổn định như bản chính thức không?', a: 'Đây là bản trải nghiệm sớm nên một số tính năng có thể tiếp tục được điều chỉnh. Website luôn ghi rõ trạng thái các nhóm chức năng.' },
  { q: 'Dữ liệu đăng ký được sử dụng như thế nào?', a: 'Số điện thoại được dùng để hỗ trợ Early Access và đối chiếu ưu đãi. Nguồn chiến dịch, trang đăng ký và thông tin trình duyệt được ghi nhận để hiểu nguồn truy cập và xử lý sự cố. Chi tiết có trong chính sách quyền riêng tư.' },
  { q: 'Tôi có thể tải trên iPhone không?', a: 'Luồng Early Access trong website này tập trung vào Android APK. Phiên bản iOS sẽ phụ thuộc kênh phát hành riêng của dự án.' },
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
  galleryDashboard: 'gallery-dashboard.png',
  galleryFeatures: 'gallery-features.png',
  galleryScore: 'gallery-score.png',
  galleryChat: 'gallery-chat.png',
  galleryWater: 'gallery-water.png',
  galleryWeekly: 'gallery-weekly.png',
} as const;
