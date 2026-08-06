# UI Interaction Event Matrix

| Event | Semantic class | Visual | Haptic | Sound | Duration | Reduced behavior |
| --- | --- | --- | --- | --- | --- | --- |
| button.pointerDown | Visual | scale 0.975 + shadow/highlight tween | None | None | 90 ms | No scale |
| button.primaryAccepted | Action | return spring + icon shift | Light | Optional soft tap | 140–180 ms | Opacity only |
| selection.changed | Selection | indicator/check morph | Selection | Optional tick | 140–180 ms | Color/check instant |
| form.validationError | Error | border + supporting size/fade + small shake | Optional warning | None | 180–240 ms | No shake |
| repository.commitSuccess | Success | check/progress/status morph | Medium/success | Soft success | 240–520 ms | Static check |
| repository.commitError | Error | error state reveal | Warning/light | Soft error | 180–240 ms | Static error |
| voice.listeningStarted | Voice | orb listen state | Light | Start cue | 180 ms | Color/static icon |
| voice.listeningStopped | Voice | orb settle | Selection | Stop cue | 140 ms | Static |
| ai.answerInserted | AI | message size+fade | None | Answer-ready cue | 240 ms | Opacity 80 ms |
| plan.persistedAndScheduled | Milestone | Nabi + success aura | Success | Plan-ready chime | 520 ms | Static success |
| timeline.completed | Progress | circle→check + line fill | Medium | Soft success optional | 320–450 ms | Immediate state |
| timeline.skipped | Neutral | neutral status morph | Light | None | 180–240 ms | Immediate state |
| payment.requestSubmitted | Pending | pending state only | Light | None | 240 ms | Static pending |
| payment.approvedTrusted | Success | access unlocked transition | Success | Success cue | 320–520 ms | Static unlocked |
| admin.rowUpdated | Operational | row highlight fade | None/light | None | 220 ms | Static highlight |
| critical.alert | Critical | clear icon/border/message | Warning | Soft alert with cooldown | 180 ms | Static critical |

## Rule

Event ID phải đến từ UI state/action result. Không phát feedback trong repository/datasource; không phát success khi chỉ bắt đầu request.
