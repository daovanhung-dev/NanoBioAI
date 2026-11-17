# Hướng dẫn phong cách mã nguồn

## Công cụ định dạng

Dự án dùng `clang-format` để giữ phong cách mã nhất quán. Tệp `.clang-format` ở thư mục gốc dựa trên hướng dẫn phong cách Google C++ và có một số điều chỉnh riêng cho dự án.

### Cài đặt clang-format

Trước khi sử dụng, hãy bảo đảm bạn đã cài `clang-format`:

- **Windows**:
  ```powershell
  winget install LLVM
  # hoặc dùng Chocolatey
  choco install llvm
  ```

- **Linux**:
  ```bash
  sudo apt install clang-format              # Ubuntu/Debian
  sudo dnf install clang-tools-extra         # Fedora
  ```

- **macOS**:
  ```bash
  brew install clang-format
  ```

### Cách sử dụng

1. **Định dạng một tệp**:
   ```bash
   clang-format -i path/to/your/file.cpp
   ```

2. **Định dạng toàn bộ dự án**:
   ```bash
   # Chạy từ thư mục gốc của dự án
   find main -iname '*.h' -o -iname '*.cc' | xargs clang-format -i
   ```

3. **Kiểm tra định dạng mà không sửa tệp (hữu ích trong CI / pre-commit)**:
   ```bash
   clang-format --dry-run -Werror path/to/your/file.cpp
   ```

### Tích hợp IDE

- **Visual Studio Code**:
  1. Cài tiện ích C/C++.
  2. Đặt `C_Cpp.formatting` thành `clangFormat` trong phần cài đặt.
  3. Có thể bật tự định dạng khi lưu bằng `editor.formatOnSave`.

- **CLion**:
  1. Mở `Editor > Code Style > C/C++` trong phần cài đặt.
  2. Đặt `Formatter` thành `clang-format`.
  3. Chọn dùng tệp `.clang-format` của dự án.

### Quy tắc chính

- Thụt lề bằng 4 dấu cách.
- Giới hạn độ rộng dòng ở 100 ký tự.
- Dấu ngoặc nhọn theo kiểu Attach (dấu `{` nằm cùng dòng với câu lệnh điều khiển).
- Con trỏ và tham chiếu gắn với kiểu dữ liệu (căn trái).
- Các lệnh include được tự động sắp xếp.
- Các access specifier được thụt lề lùi 4 dấu cách.

## C++ Runtime và xử lý lỗi

- Mã C++ do dự án sở hữu dùng GNU C++23. Không yêu cầu các tính năng ngôn ngữ mới hơn trong `main/`.
- C++ exceptions và RTTI bị tắt. Không dùng `throw`, `try`/`catch`, `dynamic_cast` hoặc `typeid`.
- Dùng RAII cho tài nguyên thuộc quyền sở hữu, bao gồm handle ESP-IDF và C API cần hàm giải phóng tường minh. Con trỏ thô không sở hữu tài nguyên, trừ khi interface quy định khác.
- Với lỗi có thể khôi phục cần mang theo giá trị lỗi, trả về `std::expected<T, E>`. Trong đường chạy nóng, ưu tiên enum nhỏ hoặc `esp_err_t`; chuyển lỗi thành chuỗi ở ranh giới protocol hoặc UI.
- Kiểm tra `expected` trước khi giải tham chiếu. Không gọi `value()` trên kết quả chưa kiểm tra vì truy cập sai sẽ làm firmware kết thúc khi exceptions bị tắt.
- Xem việc vi phạm bất biến của lập trình viên là lỗi nghiêm trọng; dùng assertion hoặc kết thúc tường minh, không mô hình hóa chúng thành lỗi runtime có thể khôi phục.
- Đường xử lý âm thanh thời gian thực dùng queue có giới hạn và tránh cấp phát lặp lại. Khi biết trước giới hạn tối đa, ưu tiên bộ nhớ dung lượng cố định; chỉ thêm pool sau khi profiling chứng minh có cấp phát liên tục hoặc phân mảnh bộ nhớ.

### Lưu ý

1. Hãy định dạng mã trước khi commit.
2. Không tự chỉnh căn lề bằng tay sau khi chạy clang-format.
3. Để loại trừ một khối khỏi việc định dạng, bao khối đó bằng:
   ```cpp
   // clang-format off
   // mã của bạn
   // clang-format on
   ```

### Câu hỏi thường gặp

1. **Định dạng thất bại**:
   - Kiểm tra xem phiên bản clang-format có quá cũ không.
   - Bảo đảm tệp được mã hóa UTF-8.
   - Kiểm tra cú pháp của tệp `.clang-format`.

2. **Kết quả khác với mong đợi**:
   - Xác minh `.clang-format` ở thư mục gốc dự án đang được áp dụng.
   - Kiểm tra xem có tệp `.clang-format` nào ở thư mục cha được ưu tiên hơn không.

Nếu có câu hỏi hoặc đề xuất, vui lòng mở issue hoặc pull request.

