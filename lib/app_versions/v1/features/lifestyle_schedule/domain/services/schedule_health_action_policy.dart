import '../entities/lifestyle_schedule_item_entity.dart';
import '../entities/manual_health_task_draft.dart';
import '../entities/schedule_health_action_type.dart';

class ScheduleHealthActionPolicy {
  const ScheduleHealthActionPolicy._();

  static ScheduleHealthActionType forItem(LifestyleScheduleItemEntity item) {
    if (item.sourceType == LifestyleScheduleSourceTypes.manualHealthTask) {
      final metadata = ManualHealthTaskMetadata.tryParse(item.sourceId);
      return metadata?.actionType ?? ScheduleHealthActionType.quickComplete;
    }

    if (item.sourceType == LifestyleScheduleSourceTypes.mealPlan ||
        item.sourceType == LifestyleScheduleSourceTypes.exerciseTask) {
      return ScheduleHealthActionType.photoProof;
    }

    return switch (item.category) {
      LifestyleScheduleCategories.water => ScheduleHealthActionType.hydration,
      LifestyleScheduleCategories.mind || LifestyleScheduleCategories.brain =>
        ScheduleHealthActionType.quickComplete,
      LifestyleScheduleCategories.sleep =>
        ScheduleHealthActionType.quickComplete,
      LifestyleScheduleCategories.metric =>
        ScheduleHealthActionType.weightCheckIn,
      LifestyleScheduleCategories.routine || LifestyleScheduleCategories.body =>
        ScheduleHealthActionType.quickComplete,
      _ => ScheduleHealthActionType.photoProof,
    };
  }

  static bool requiresInput(ScheduleHealthActionType action) => switch (action) {
    ScheduleHealthActionType.hydration ||
    ScheduleHealthActionType.moodStress ||
    ScheduleHealthActionType.sleepCheckIn ||
    ScheduleHealthActionType.weightCheckIn => true,
    _ => false,
  };

  static int rewardPreviewPoints(ScheduleHealthActionType action) => switch (action) {
    ScheduleHealthActionType.photoProof => 10,
    ScheduleHealthActionType.hydration => 4,
    ScheduleHealthActionType.moodStress => 5,
    ScheduleHealthActionType.sleepCheckIn => 6,
    ScheduleHealthActionType.weightCheckIn => 4,
    ScheduleHealthActionType.quickComplete => 5,
  };

  static String encouragement(ScheduleHealthActionType action) => switch (action) {
    ScheduleHealthActionType.hydration =>
      'Ghi nhận lượng nước vừa uống để Nabi theo dõi nhịp chăm sóc hôm nay.',
    ScheduleHealthActionType.moodStress =>
      'Một check-in ngắn giúp bạn nhìn rõ cảm xúc mà không phán xét bản thân.',
    ScheduleHealthActionType.sleepCheckIn =>
      'Ghi lại thời lượng ngủ để quan sát nhịp nghỉ ngơi theo thời gian.',
    ScheduleHealthActionType.weightCheckIn =>
      'Chỉ ghi nhận số đo khi bạn chủ động muốn theo dõi.',
    ScheduleHealthActionType.quickComplete =>
      'Xác nhận nhanh khi bạn đã thực hiện mốc chăm sóc này.',
    ScheduleHealthActionType.photoProof =>
      'Chụp ảnh minh chứng trong cửa sổ hoàn thành để hệ thống xác nhận.',
  };
}
