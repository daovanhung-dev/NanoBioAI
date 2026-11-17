# Kiểm toán kênh đầu vào AudioCodec

Ngày kiểm toán: 2026-09-29. Mốc mã nguồn trước khi sửa: `cf2024f`. Danh sách theo từng bo giữ nguyên kết quả kiểm toán trước khi sửa; các điều chỉnh trong đợt này được nêu dưới đây.

## Điều chỉnh trong đợt này

Áp dụng chiến lược mặc định một micro cho các đường dẫn sau, đồng thời giữ hỗ trợ đầu vào nhiều micro của AFE:

| Bo mạch | Trước đây | Mặc định sau sửa | Giao diện thử nghiệm cho nhà phát triển |
|---|---|---|---|
| Box Lite | MMR / MM | MR / M | `BoxAudioCodecLite` có thêm tham số cuối `microphone_channels=1`; truyền tường minh `2` để thử MMR / MM, giữ nguyên logic bật/tắt kênh tham chiếu. |
| ESP32-S31-Korvo-1 | MM | M | `AUDIO_INPUT_CHANNELS` ở cấp bo mặc định là `1`; đặt thành `2` vẫn có thể thử MM. Bo không có tham chiếu nên không được khai báo MMR. |
| T-CameraPlus-S3 V1.0/V1.1 | Thu đơn kênh nhưng khai báo MR | M | Tắt khai báo tham chiếu sai để khớp dữ liệu RX. V1.2 vốn đã dùng M. |

Các đường dẫn M / MR còn lại được giữ nguyên. Hai bo LILYGO có nguồn tham chiếu cần xác minh vẫn cần kiểm tra phần cứng. Thay đổi này không thay thế việc xác minh trên thiết bị thật và cũng không có nghĩa nguyên nhân gốc lỗi Box Lite đã được xác nhận.

Xem [Thiết kế âm thanh](../main/audio/README.md#board-input-layouts) để biết giao diện phát triển và yêu cầu xác minh.

## Phạm vi và kết luận kiểm toán trước khi sửa

Đã kiểm tra `main/audio/`, toàn bộ codec theo bo, tham số constructor của `GetAudioCodec()`, lớp dẫn xuất tùy chỉnh và mọi phép gán `input_channels_` / `input_reference_`. Phạm vi gồm 150 thư mục bo có `config.json`, cộng thêm hai thư mục mã nguồn `kevin/sp-v3-dev` và `lilygo/t-display-p4`, tổng cộng 152 thư mục. Một thư mục có thể chứa nhiều cấu hình hoặc phiên bản phần cứng; bảng này không xem số thư mục là số lượng firmware phát hành.

Định dạng mô tả ngữ nghĩa dữ liệu mà codec khai báo với audio engine; chip tài nguyên hạn chế có thể dùng LiteAudioEngine và không thực sự tạo AFE. Không được đánh đồng số slot I2S, số đầu vào vật lý của ADC và số micro ở tầng trên. Khai báo `MR` cũng không chứng minh dây nối, dạng sóng hay thời điểm của tín hiệu tham chiếu đã được xác minh trên thiết bị thật.

- `M`: một micro, không có tham chiếu. Có thể đánh thức và hội thoại bình thường; không cung cấp tín hiệu tham chiếu cần cho AEC trên thiết bị.
- `MR`: một micro và một kênh tham chiếu âm thanh phát.
- `MM`: hai micro, không có tham chiếu.
- `MMR`: hai micro và một kênh tham chiếu âm thanh phát.

**Không thể đổi tất cả bo sang MR. Chiến lược một micro phù hợp là: dùng MR khi có tín hiệu tham chiếu hợp lệ, nếu không thì dùng M.** Phần lớn triển khai hiện có đã tuân theo chiến lược số kênh này; chỉ Box Lite và ESP32-S31-Korvo-1 được cấu hình rõ ràng làm đầu vào hai micro.

## Cấu hình hai micro trong kiểm toán trước khi sửa

| Bo mạch | Triển khai | Định dạng hiện tại | Nếu quyết định thống nhất thành một micro |
|---|---|---|---|
| ESP32-S3-Box-Lite | BoxAudioCodecLite | MMR khi bật xử lý âm thanh, nếu không thì MM | `input_channels_ = input_reference_ ? 2 : 1`; EnableInput/Read hiện được điều chỉnh theo để thu và sắp xếp dữ liệu một micro. Cần xác minh trên thiết bị thật việc thu một kênh, tín hiệu tham chiếu phần mềm và hội thoại. |
| ESP32-S31-Korvo-1 | Es8389AudioCodec | MM | Hiện `AUDIO_INPUT_CHANNELS=2` và `input_reference_=false`; theo chiến lược một micro phải dùng M, không gán micro thứ hai thành R. Chỉ sửa cấu hình đầu vào của bo này; không nên sửa lớp ES8389 dùng chung hoặc cấu hình đầu ra stereo. |

Căn cứ mã nguồn: [Box Lite](../main/boards/espressif/esp32-s3-box-lite/box_audio_codec_lite.cc), [cấu hình S31 Korvo](../main/boards/espressif/esp32-s31-korvo-1/config.h), [ES8389](../main/audio/codecs/es8389_audio_codec.cc). Hiện cả hai bản ALIENTEK Box2 WiFi / 4G đều dùng đầu vào một micro mặc định của constructor ES8389, không phải đầu vào hai micro.

## Các ngoại lệ liên quan đến kênh tham chiếu trong kiểm toán trước khi sửa

### LILYGO T-CameraPlus-S3 V1.0/V1.1: định dạng chắc chắn không khớp

`config.h` đặt `AUDIO_INPUT_REFERENCE=true`, nên codec khai báo MR hai kênh; tuy nhiên `CreateVoiceHardware()` cấu hình RX của micro thành `I2S_SLOT_MODE_MONO`. `Read()` đọc trực tiếp mẫu đơn kênh, không chèn tín hiệu tham chiếu phát; `Write()` cũng không tạo đường hồi tiếp phần mềm. Vì vậy, các mẫu micro liên tiếp bị tầng trên diễn giải theo cặp M/R, khiến thời lượng đọc không khớp thời lượng frame ở tầng trên.

Nên ưu tiên đối chiếu đường dẫn này với đầu vào một micro thực tế và đổi thành M, thay vì tiếp tục thống nhất thành MR. V1.2 dùng PDM đơn kênh và khai báo M nên không gặp trường hợp khai báo không khớp này. Đây là phát hiện riêng từ mã nguồn, không thể xem là nguyên nhân gốc của lỗi Box Lite.

Căn cứ: [cấu hình](../main/boards/lilygo/t-cameraplus-s3/config.h), [codec](../main/boards/lilygo/t-cameraplus-s3/tcamerapluss3_audio_codec.cc).

### LILYGO T-Circle-S3 / T-Display-S3-Pro-MVSrLora: cần xác minh nguồn tham chiếu trên phần cứng

Cả hai khai báo MR và đọc trực tiếp dữ liệu I2S RX stereo từ micro, không chèn tham chiếu phát bằng phần mềm. Mã nguồn xác nhận bố cục hai kênh nhưng không chứng minh slot thứ hai được nối với tín hiệu hồi tiếp âm thanh phát; cần kiểm tra sơ đồ mạch hoặc bản ghi âm. Không thể chỉ dựa vào `input_reference=true` để kết luận tham chiếu AEC có hiệu lực, cũng không được sửa slot/pin trước khi xác minh phần cứng.

Căn cứ: [T-Circle](../main/boards/lilygo/t-circle-s3/tcircles3_audio_codec.cc), [T-Display](../main/boards/lilygo/t-display-s3-pro-mvsrlora/tdisplays3promvsrlora_audio_codec.cc). Trong bảng theo bo, ký hiệu † cho biết có trường hợp không khớp nêu trên hoặc nguồn tham chiếu cần xác minh.

### Có macro tham chiếu nhưng codec thực tế vẫn là M

Ví dụ, thư mục M5Stack Atom EchoS3R và AtomS3R Echo Base định nghĩa `AUDIO_INPUT_REFERENCE=true`, nhưng lại tạo instance `Es8311AudioCodec`, lớp này không nhận tham số đó. Lớp luôn đặt `input_reference_=false` và `input_channels_=1`. Sửa macro không tự tạo ra đường hồi tiếp. Kiểm toán dựa trên tham số constructor thực tế và phần triển khai codec.

### Xác minh riêng tham chiếu phần mềm và phần cứng

Box Lite và AIVOX3 tạo tham chiếu bằng buffer phần mềm giữa Read/Write; các triển khai như BoxAudioCodec đọc tham chiếu từ kênh ADC/I2S được chọn. Thống nhất định dạng thành MR chỉ thống nhất bố cục, không đồng nhất thời điểm xử lý hay hiệu quả khử vọng của hai cách.

Buffer tham chiếu dùng chung và vị trí đọc/ghi của Box Lite chưa được bảo vệ đồng bộ; lỗi thu vẫn trả về thành công. Đây là các vấn đề riêng cần xác minh và sửa, không thể thay thế bằng việc chuyển sang một micro.

## Xác minh phần cứng tiếp theo

1. Box Lite: so sánh mặc định một micro MR/M với hai micro MMR/MM được chọn tường minh; kiểm tra đánh thức, hội thoại, thu lại sau khi phát, ngắt quãng và kết nối lại, cùng AEC trên thiết bị bật/tắt. Cấu hình một micro không thay thế việc kiểm tra thời điểm tham chiếu phần mềm và đồng bộ.
2. T-CameraPlus-S3: xác minh thu đơn kênh và khai báo M trên V1.0/V1.1, đồng thời kiểm tra hồi quy V1.2.
3. S31 Korvo-1: xác minh thu M mặc định và phát stereo; hiện chưa có bằng chứng tái hiện lỗi gốc của bo này, nên không thể tuyên bố đã sửa lỗi đó.
4. Xác minh nguồn tham chiếu của hai bo LILYGO. Nếu bo không có tham chiếu mà cần bổ sung MR, phải thực sự cung cấp và đồng bộ dữ liệu tham chiếu, không chỉ sửa số kênh hoặc chuỗi định dạng.

Phân tích trước đó về đường đầu ra nội bộ ESP-SR vẫn là giả thuyết cần xác minh, không phải căn cứ để kết luận lỗi đã được sửa. Đợt này không có xác minh trên phần cứng thật.

## Hồ sơ xác minh trong đợt này

- Kiểm thử trên máy chủ: `python3 -m unittest discover -s scripts/tests -v`, 81 mục đạt.
- Kiểm tra định dạng: 4 tệp C/C++ được sửa vượt qua kiểm tra clang-format theo cấu hình kho; kiểm tra khoảng trắng của diff giữ nguyên CRLF vốn có ở Box Lite.
- Box Lite / T-CameraPlus-S3 V1.0/V1.1: gọi `scripts/build.py` theo quy định; ESP-IDF 6.1 bị chặn ở bước cấu hình dependency do không tồn tại `ESP_VIDEO_USE_CUSTOMIZED_ESP_H264_VERSION`. Thử lại Box Lite bằng phiên bản 6.0.2 được hỗ trợ cũng bị chặn ở bước kiểm tra cấu hình (`Missing required kconfig option after retry`). Hai bo này chưa build firmware thành công.
- ESP32-S31-Korvo-1: ESP-IDF `v6.1-beta1-701-g812f3e98ca5`; build theo quy trình và ghép firmware thành công. Thư mục build cục bộ hiện tương ứng với bo này.
- Không thử nghiệm phần cứng thật; đường thử nghiệm hai micro chưa được xác minh trên thiết bị.

## Danh sách kiểm toán trước khi sửa theo từng bo

Nhiều codec đại diện cho tùy chọn biên dịch, phiên bản phần cứng hoặc lựa chọn lúc chạy. Bảng ghi riêng từng định dạng để tránh gộp các đường dẫn khác nhau trong cùng thư mục thành một kết luận.

| Thư mục bo | codec → định dạng được khai báo |
|---|---|
| [alientek/atk-dnesp32s3](../main/boards/alientek/atk-dnesp32s3/) | `Es8388AudioCodec` → M |
| [alientek/atk-dnesp32s3-box](../main/boards/alientek/atk-dnesp32s3-box/) | `ATK_NoAudioCodecDuplex` → M<br>`Es8311AudioCodec` → M |
| [alientek/atk-dnesp32s3-box0](../main/boards/alientek/atk-dnesp32s3-box0/) | `Es8311AudioCodec` → M |
| [alientek/atk-dnesp32s3-box2-4g](../main/boards/alientek/atk-dnesp32s3-box2-4g/) | `Es8389AudioCodec` → M |
| [alientek/atk-dnesp32s3-box2-wifi](../main/boards/alientek/atk-dnesp32s3-box2-wifi/) | `Es8389AudioCodec` → M |
| [alientek/atk-dnesp32s3-box3](../main/boards/alientek/atk-dnesp32s3-box3/) | `BoxAudioCodec` → MR |
| [alientek/atk-dnesp32s3m-4g](../main/boards/alientek/atk-dnesp32s3m-4g/) | `Es8388AudioCodec` → M |
| [alientek/atk-dnesp32s3m-wifi](../main/boards/alientek/atk-dnesp32s3m-wifi/) | `Es8388AudioCodec` → M |
| [bread-compact-esp32](../main/boards/bread-compact-esp32/) | `NoAudioCodecDuplex` → M<br>`NoAudioCodecSimplex` → M |
| [bread-compact-esp32-lcd](../main/boards/bread-compact-esp32-lcd/) | `NoAudioCodecDuplex` → M<br>`NoAudioCodecSimplex` → M |
| [bread-compact-ml307](../main/boards/bread-compact-ml307/) | `NoAudioCodecDuplex` → M<br>`NoAudioCodecSimplex` → M |
| [bread-compact-nt26](../main/boards/bread-compact-nt26/) | `NoAudioCodecDuplex` → M<br>`NoAudioCodecSimplex` → M |
| [bread-compact-wifi](../main/boards/bread-compact-wifi/) | `NoAudioCodecDuplex` → M<br>`NoAudioCodecSimplex` → M |
| [bread-compact-wifi-lcd](../main/boards/bread-compact-wifi-lcd/) | `NoAudioCodecDuplex` → M<br>`NoAudioCodecSimplex` → M |
| [bread-compact-wifi-s3cam](../main/boards/bread-compact-wifi-s3cam/) | `NoAudioCodecDuplex` → M<br>`NoAudioCodecSimplex` → M |
| [dfrobot/df-k10](../main/boards/dfrobot/df-k10/) | `K10AudioCodec` → MR |
| [dfrobot/df-s3-ai-cam](../main/boards/dfrobot/df-s3-ai-cam/) | `NoAudioCodecSimplexPdm` → M |
| [doit-s3-aibox](../main/boards/doit-s3-aibox/) | `NoAudioCodecSimplexPdm` → M |
| [du-chatx](../main/boards/du-chatx/) | `NoAudioCodecSimplex` → M |
| [electron-bot](../main/boards/electron-bot/) | `NoAudioCodecSimplex` → M |
| [espressif/esp-hi](../main/boards/espressif/esp-hi/) | `AdcPdmAudioCodec` → M |
| [espressif/esp-sensairshuttle](../main/boards/espressif/esp-sensairshuttle/) | `AdcPdmAudioCodec` → M |
| [espressif/esp-sparkbot](../main/boards/espressif/esp-sparkbot/) | `SparkBotEs8311AudioCodec` → M |
| [espressif/esp-spot](../main/boards/espressif/esp-spot/) | `Es8311AudioCodec` → M |
| [espressif/esp-vocat](../main/boards/espressif/esp-vocat/) | `BoxAudioCodec` → MR |
| [espressif/esp32-p4-function-ev-board](../main/boards/espressif/esp32-p4-function-ev-board/) | `Es8311AudioCodec` → M |
| [espressif/esp32-s3-box](../main/boards/espressif/esp32-s3-box/) | `BoxAudioCodec` → MR |
| [espressif/esp32-s3-box-3](../main/boards/espressif/esp32-s3-box-3/) | `BoxAudioCodec` → MR |
| [espressif/esp32-s3-box-lite](../main/boards/espressif/esp32-s3-box-lite/) | `BoxAudioCodecLite` → MMR / MM（tùy công tắc xử lý âm thanh） |
| [espressif/esp32-s3-korvo-2-v3.0](../main/boards/espressif/esp32-s3-korvo-2-v3.0/) | `BoxAudioCodec` → MR |
| [espressif/esp32-s3-korvo-2-v3.0-rndis](../main/boards/espressif/esp32-s3-korvo-2-v3.0-rndis/) | `BoxAudioCodec` → MR |
| [espressif/esp32-s3-lcd-ev-board](../main/boards/espressif/esp32-s3-lcd-ev-board/) | `BoxAudioCodec` → MR |
| [espressif/esp32-s3-lcd-ev-board-2](../main/boards/espressif/esp32-s3-lcd-ev-board-2/) | `BoxAudioCodec` → MR |
| [espressif/esp32-s31-function-coreboard-1](../main/boards/espressif/esp32-s31-function-coreboard-1/) | `Es8311AudioCodec` → M |
| [espressif/esp32-s31-korvo-1](../main/boards/espressif/esp32-s31-korvo-1/) | `Es8389AudioCodec` → MM |
| [folotoy/ai-passport](../main/boards/folotoy/ai-passport/) | `Es8311AudioCodec` → M |
| [freenove-esp32s3-display-2.8-lcd](../main/boards/freenove-esp32s3-display-2.8-lcd/) | `Es8311AudioCodec` → M |
| [genjutech-s3-1.54tft](../main/boards/genjutech-s3-1.54tft/) | `SparkBotEs8311AudioCodec` → M |
| [hu-087](../main/boards/hu-087/) | `NoAudioCodecSimplex` → M |
| [jiuchuan-s3](../main/boards/jiuchuan-s3/) | `Es8311AudioCodec` → M |
| [kevin/box-2](../main/boards/kevin/box-2/) | `BoxAudioCodec` → MR |
| [kevin/c3](../main/boards/kevin/c3/) | `Es8311AudioCodec` → M |
| [kevin/sp-v3-dev](../main/boards/kevin/sp-v3-dev/) | `NoAudioCodecSimplex` → M |
| [kevin/sp-v4-dev](../main/boards/kevin/sp-v4-dev/) | `Es8311AudioCodec` → M |
| [kevin/yuying-313lcd](../main/boards/kevin/yuying-313lcd/) | `Es8311AudioCodec` → M |
| [labplus/ledong-v2](../main/boards/labplus/ledong-v2/) | `Es8388AudioCodec` → M |
| [labplus/mpython-v3](../main/boards/labplus/mpython-v3/) | `Es8388AudioCodec` → M |
| [lcdwiki-es3c35p](../main/boards/lcdwiki-es3c35p/) | `Es8311AudioCodec` → M |
| [lceda-course-examples/eda-robot-pro](../main/boards/lceda-course-examples/eda-robot-pro/) | `NoAudioCodecSimplex` → M |
| [lceda-course-examples/eda-super-bear](../main/boards/lceda-course-examples/eda-super-bear/) | `NoAudioCodecSimplex` → M |
| [lceda-course-examples/eda-tv-pro](../main/boards/lceda-course-examples/eda-tv-pro/) | `NoAudioCodecDuplex` → M<br>`NoAudioCodecSimplex` → M |
| [lckfb/szpi-esp32c3](../main/boards/lckfb/szpi-esp32c3/) | `Es8311AudioCodec` → M |
| [lckfb/szpi-esp32s3](../main/boards/lckfb/szpi-esp32s3/) | `CustomAudioCodec` → MR |
| [lilygo/t-cameraplus-s3](../main/boards/lilygo/t-cameraplus-s3/) | `Tcamerapluss3AudioCodec` → MR†（V1.0/V1.1）/ M（V1.2） |
| [lilygo/t-circle-s3](../main/boards/lilygo/t-circle-s3/) | `Tcircles3AudioCodec` → MR† |
| [lilygo/t-display-p4](../main/boards/lilygo/t-display-p4/) | `Es8311AudioCodec` → M |
| [lilygo/t-display-s3-pro-mvsrlora](../main/boards/lilygo/t-display-s3-pro-mvsrlora/) | `Tdisplays3promvsrloraAudioCodec` → MR† |
| [m5stack/atom-echos3r](../main/boards/m5stack/atom-echos3r/) | `Es8311AudioCodec` → M |
| [m5stack/atommatrix-echo-base](../main/boards/m5stack/atommatrix-echo-base/) | `Es8311AudioCodec` → M |
| [m5stack/atoms3-echo-base](../main/boards/m5stack/atoms3-echo-base/) | `Es8311AudioCodec` → M |
| [m5stack/atoms3r-cam-m12-echo-base](../main/boards/m5stack/atoms3r-cam-m12-echo-base/) | `Es8311AudioCodec` → M |
| [m5stack/atoms3r-echo-base](../main/boards/m5stack/atoms3r-echo-base/) | `Es8311AudioCodec` → M |
| [m5stack/atoms3r-echo-pyramid](../main/boards/m5stack/atoms3r-echo-pyramid/) | `PyramidAudioCodec` → MR |
| [m5stack/cardputer-adv](../main/boards/m5stack/cardputer-adv/) | `CardputerAdvEs8311` → M |
| [m5stack/core-s3](../main/boards/m5stack/core-s3/) | `CoreS3AudioCodec` → M |
| [m5stack/corep4](../main/boards/m5stack/corep4/) | `BoxAudioCodec` → MR |
| [m5stack/stick-s3](../main/boards/m5stack/stick-s3/) | `Sticks3AudioCodec` → M |
| [m5stack/stopwatch](../main/boards/m5stack/stopwatch/) | `Es8311AudioCodec` → M |
| [m5stack/tab5](../main/boards/m5stack/tab5/) | `Tab5AudioCodec` → MR |
| [magiclick/2p4](../main/boards/magiclick/2p4/) | `Es8311AudioCodec` → M |
| [magiclick/2p5](../main/boards/magiclick/2p5/) | `Es8311AudioCodec` → M |
| [magiclick/c3](../main/boards/magiclick/c3/) | `Es8311AudioCodec` → M |
| [magiclick/c3-v2](../main/boards/magiclick/c3-v2/) | `Es8311AudioCodec` → M |
| [maza-ai/esp32-s3](../main/boards/maza-ai/esp32-s3/) | `Es8311AudioCodec` → M |
| [maza-ai/esp32-s31](../main/boards/maza-ai/esp32-s31/) | `Es8311AudioCodec` → M |
| [minsi-k08-dual](../main/boards/minsi-k08-dual/) | `NoAudioCodecSimplex` → M |
| [mixgo-nova](../main/boards/mixgo-nova/) | `Es8374AudioCodec` → M |
| [movecall/cuican-esp32s3](../main/boards/movecall/cuican-esp32s3/) | `Es8311AudioCodec` → M |
| [movecall/moji-esp32s3](../main/boards/movecall/moji-esp32s3/) | `Es8311AudioCodec` → M |
| [movecall/moji2-esp32c5](../main/boards/movecall/moji2-esp32c5/) | `Es8311AudioCodec` → M |
| [nologo/xingzhi-abs-2.0](../main/boards/nologo/xingzhi-abs-2.0/) | `Es8311AudioCodec` → M |
| [nologo/xingzhi-cube-0.85tft-ml307](../main/boards/nologo/xingzhi-cube-0.85tft-ml307/) | `NoAudioCodecSimplex` → M |
| [nologo/xingzhi-cube-0.85tft-wifi](../main/boards/nologo/xingzhi-cube-0.85tft-wifi/) | `NoAudioCodecSimplex` → M |
| [nologo/xingzhi-cube-0.96oled-ml307](../main/boards/nologo/xingzhi-cube-0.96oled-ml307/) | `NoAudioCodecSimplex` → M |
| [nologo/xingzhi-cube-0.96oled-wifi](../main/boards/nologo/xingzhi-cube-0.96oled-wifi/) | `NoAudioCodecSimplex` → M |
| [nologo/xingzhi-cube-1.54tft-ml307](../main/boards/nologo/xingzhi-cube-1.54tft-ml307/) | `NoAudioCodecSimplex` → M |
| [nologo/xingzhi-cube-1.54tft-wifi](../main/boards/nologo/xingzhi-cube-1.54tft-wifi/) | `NoAudioCodecSimplex` → M |
| [nologo/xingzhi-metal-1.54-wifi](../main/boards/nologo/xingzhi-metal-1.54-wifi/) | `Es8311AudioCodec` → M |
| [nulllab-ai-vox-v3](../main/boards/nulllab-ai-vox-v3/) | `AIVOX3AudioCodec` → MR / M（tùy công tắc AEC trên thiết bị） |
| [otto-robot](../main/boards/otto-robot/) | `NoAudioCodecDuplex` → M<br>`NoAudioCodecSimplex` → M |
| [quandong-s3-dev](../main/boards/quandong-s3-dev/) | `Es8311AudioCodec` → M |
| [rymcu/bigsmart](../main/boards/rymcu/bigsmart/) | `CustomAudioCodec` → MR |
| [sensecap-watcher](../main/boards/sensecap-watcher/) | `SensecapAudioCodec` → M |
| [spotpear/sp-esp32-s3-1.28-box](../main/boards/spotpear/sp-esp32-s3-1.28-box/) | `Es8311AudioCodec` → M |
| [spotpear/sp-esp32-s3-1.54-muma](../main/boards/spotpear/sp-esp32-s3-1.54-muma/) | `Es8311AudioCodec` → M |
| [surfer-c3-1.14tft](../main/boards/surfer-c3-1.14tft/) | `Es8311AudioCodec` → M |
| [taiji-pi-s3](../main/boards/taiji-pi-s3/) | `NoAudioCodecSimplex` → M<br>`NoAudioCodecSimplexPdm` → M |
| [waveshare/esp32-c5-touch-lcd-1.69](../main/boards/waveshare/esp32-c5-touch-lcd-1.69/) | `Es8311AudioCodec` → M |
| [waveshare/esp32-c6-epaper-1.54](../main/boards/waveshare/esp32-c6-epaper-1.54/) | `Es8311AudioCodec` → M |
| [waveshare/esp32-c6-lcd-0.85](../main/boards/waveshare/esp32-c6-lcd-0.85/) | `BoxAudioCodec` → MR |
| [waveshare/esp32-c6-lcd-1.69](../main/boards/waveshare/esp32-c6-lcd-1.69/) | `Es8311AudioCodec` → M |
| [waveshare/esp32-c6-touch-amoled-1.32](../main/boards/waveshare/esp32-c6-touch-amoled-1.32/) | `Es8311AudioCodec` → M |
| [waveshare/esp32-c6-touch-amoled-1.43](../main/boards/waveshare/esp32-c6-touch-amoled-1.43/) | `BoxAudioCodec` → M |
| [waveshare/esp32-c6-touch-amoled-1.8](../main/boards/waveshare/esp32-c6-touch-amoled-1.8/) | `Es8311AudioCodec` → M |
| [waveshare/esp32-c6-touch-amoled-2.06](../main/boards/waveshare/esp32-c6-touch-amoled-2.06/) | `BoxAudioCodec` → M |
| [waveshare/esp32-c6-touch-amoled-2.16](../main/boards/waveshare/esp32-c6-touch-amoled-2.16/) | `BoxAudioCodec` → M |
| [waveshare/esp32-c6-touch-lcd-1.54](../main/boards/waveshare/esp32-c6-touch-lcd-1.54/) | `BoxAudioCodec` → MR |
| [waveshare/esp32-c6-touch-lcd-1.83](../main/boards/waveshare/esp32-c6-touch-lcd-1.83/) | `BoxAudioCodec` → MR |
| [waveshare/esp32-p4-nano](../main/boards/waveshare/esp32-p4-nano/) | `Es8311AudioCodec` → M |
| [waveshare/esp32-p4-wifi6-touch-lcd](../main/boards/waveshare/esp32-p4-wifi6-touch-lcd/) | `BoxAudioCodec` → MR |
| [waveshare/esp32-p4-wifi6-touch-lcd-3.5](../main/boards/waveshare/esp32-p4-wifi6-touch-lcd-3.5/) | `Es8311AudioCodec` → M |
| [waveshare/esp32-s3-audio-board](../main/boards/waveshare/esp32-s3-audio-board/) | `BoxAudioCodec` → MR |
| [waveshare/esp32-s3-cam](../main/boards/waveshare/esp32-s3-cam/) | `BoxAudioCodec` → MR |
| [waveshare/esp32-s3-epaper-1.54](../main/boards/waveshare/esp32-s3-epaper-1.54/) | `Es8311AudioCodec` → M |
| [waveshare/esp32-s3-epaper-3.97](../main/boards/waveshare/esp32-s3-epaper-3.97/) | `Es8311AudioCodec` → M |
| [waveshare/esp32-s3-lcd-0.85](../main/boards/waveshare/esp32-s3-lcd-0.85/) | `BoxAudioCodec` → MR |
| [waveshare/esp32-s3-rgb-matrix](../main/boards/waveshare/esp32-s3-rgb-matrix/) | `BoxAudioCodec` → MR |
| [waveshare/esp32-s3-rlcd-4.2](../main/boards/waveshare/esp32-s3-rlcd-4.2/) | `BoxAudioCodec` → MR |
| [waveshare/esp32-s3-touch-amoled-1.32](../main/boards/waveshare/esp32-s3-touch-amoled-1.32/) | `Es8311AudioCodec` → M |
| [waveshare/esp32-s3-touch-amoled-1.43c](../main/boards/waveshare/esp32-s3-touch-amoled-1.43c/) | `BoxAudioCodec` → MR |
| [waveshare/esp32-s3-touch-amoled-1.75](../main/boards/waveshare/esp32-s3-touch-amoled-1.75/) | `BoxAudioCodec` → MR |
| [waveshare/esp32-s3-touch-amoled-1.8](../main/boards/waveshare/esp32-s3-touch-amoled-1.8/) | `Es8311AudioCodec` → M |
| [waveshare/esp32-s3-touch-amoled-1.8-v2](../main/boards/waveshare/esp32-s3-touch-amoled-1.8-v2/) | `Es8311AudioCodec` → M |
| [waveshare/esp32-s3-touch-amoled-2.06](../main/boards/waveshare/esp32-s3-touch-amoled-2.06/) | `BoxAudioCodec` → MR |
| [waveshare/esp32-s3-touch-amoled-2.16](../main/boards/waveshare/esp32-s3-touch-amoled-2.16/) | `BoxAudioCodec` → MR |
| [waveshare/esp32-s3-touch-lcd-1.46](../main/boards/waveshare/esp32-s3-touch-lcd-1.46/) | `NoAudioCodecSimplex` → M |
| [waveshare/esp32-s3-touch-lcd-1.54](../main/boards/waveshare/esp32-s3-touch-lcd-1.54/) | `BoxAudioCodec` → MR |
| [waveshare/esp32-s3-touch-lcd-1.83](../main/boards/waveshare/esp32-s3-touch-lcd-1.83/) | `BoxAudioCodec` → MR |
| [waveshare/esp32-s3-touch-lcd-1.85](../main/boards/waveshare/esp32-s3-touch-lcd-1.85/) | `NoAudioCodecSimplex` → M |
| [waveshare/esp32-s3-touch-lcd-1.85b](../main/boards/waveshare/esp32-s3-touch-lcd-1.85b/) | `BoxAudioCodec` → MR |
| [waveshare/esp32-s3-touch-lcd-1.85c](../main/boards/waveshare/esp32-s3-touch-lcd-1.85c/) | `BoxAudioCodec` → MR<br>`NoAudioCodecSimplex` → M |
| [waveshare/esp32-s3-touch-lcd-3.49](../main/boards/waveshare/esp32-s3-touch-lcd-3.49/) | `BoxAudioCodec` → MR |
| [waveshare/esp32-s3-touch-lcd-3.49-v2](../main/boards/waveshare/esp32-s3-touch-lcd-3.49-v2/) | `BoxAudioCodec` → MR |
| [waveshare/esp32-s3-touch-lcd-3.5](../main/boards/waveshare/esp32-s3-touch-lcd-3.5/) | `Es8311AudioCodec` → M |
| [waveshare/esp32-s3-touch-lcd-3.5b](../main/boards/waveshare/esp32-s3-touch-lcd-3.5b/) | `Es8311AudioCodec` → M |
| [waveshare/esp32-s3-touch-lcd-4.3c](../main/boards/waveshare/esp32-s3-touch-lcd-4.3c/) | `BoxAudioCodec` → MR |
| [waveshare/esp32-s3-touch-lcd-4b](../main/boards/waveshare/esp32-s3-touch-lcd-4b/) | `BoxAudioCodec` → MR |
| [waveshare/esp32-s3-touch-lcd-7c](../main/boards/waveshare/esp32-s3-touch-lcd-7c/) | `WaveshareAudioCodec` → MR |
| [waveshare/esp32-touch-lcd-3.5](../main/boards/waveshare/esp32-touch-lcd-3.5/) | `Es8311AudioCodec` → M |
| [wdmomo/esp32-cgc](../main/boards/wdmomo/esp32-cgc/) | `NoAudioCodecDuplex` → M<br>`NoAudioCodecSimplex` → M |
| [wdmomo/esp32-cgc-144](../main/boards/wdmomo/esp32-cgc-144/) | `NoAudioCodecSimplex` → M |
| [wk-esp32s3-dev](../main/boards/wk-esp32s3-dev/) | `NoAudioCodecDuplex` → M<br>`NoAudioCodecSimplex` → M |
| [xmini/c3](../main/boards/xmini/c3/) | `Es8311AudioCodec` → M |
| [xmini/c3-4g](../main/boards/xmini/c3-4g/) | `Es8311AudioCodec` → M |
| [xmini/c3-v3](../main/boards/xmini/c3-v3/) | `Es8311AudioCodec` → M |
| [xorigin/aipi-lite](../main/boards/xorigin/aipi-lite/) | `Es8311AudioCodec` → M |
| [yunliao-s3](../main/boards/yunliao-s3/) | `Es8388AudioCodec` → MR |
| [zectrix/zectrix-s3-epaper-4.2](../main/boards/zectrix/zectrix-s3-epaper-4.2/) | `Es8311AudioCodec` → M |
| [zhengchen/1.54tft-ml307](../main/boards/zhengchen/1.54tft-ml307/) | `NoAudioCodecSimplex` → M |
| [zhengchen/1.54tft-wifi](../main/boards/zhengchen/1.54tft-wifi/) | `NoAudioCodecSimplex` → M |
| [zhengchen/cam](../main/boards/zhengchen/cam/) | `CustomAudioCodec` → MR |
| [zhengchen/cam-ml307](../main/boards/zhengchen/cam-ml307/) | `CustomAudioCodec` → MR |
