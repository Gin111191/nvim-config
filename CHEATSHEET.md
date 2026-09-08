# Cheatsheet

Leader = **`Space`**. `Space + e` nghĩa là bấm `Space` rồi bấm `e`.

> **Quên phím?** Bấm `Space` rồi **đợi 300ms** — `which-key` hiện bảng gợi ý mọi phím tiếp theo.
> Hoặc `Space + s + k` để tìm kiếm trong toàn bộ phím tắt.

---

## Ba khái niệm cần nắm trước

```
  BUFFER   =  nội dung một file, đang nằm trong bộ nhớ   →  tờ giấy
  WINDOW   =  một ô để NHÌN VÀO buffer                    →  khung cửa sổ
  TAB      =  một cách sắp xếp các window                 →  cách bày các khung
```

Mở 10 file = **10 buffer**, nhưng màn hình chỉ hiện 1. Chín cái kia vẫn còn trong bộ nhớ.
`:q` đóng **window**, không vứt buffer. Muốn vứt hẳn buffer phải `Space + x`.

Dải tab trên cùng (`bufferline`) tồn tại để **hiện ra** danh sách buffer mà Vim vốn giấu.

---

## File & tìm kiếm — Telescope

| Phím | Việc |
|---|---|
| **`Space + s + f`** | **Tìm file** theo tên |
| **`Space + s + g`** | **Tìm chữ** trong toàn bộ dự án (grep) |
| `Space + s + w` | Tìm từ đang đứng dưới con trỏ |
| `Space + Space` | Danh sách buffer đang mở |
| `Space + s + .` | File mở gần đây |
| `Space + s + d` | Danh sách lỗi/cảnh báo |
| `Space + s + h` | Tra tài liệu Neovim |
| `Space + s + k` | **Tìm trong danh sách phím tắt** |
| `Space + s + r` | Mở lại lần tìm trước |
| `Space + s + s` | Danh sách mọi lệnh Telescope |

Trong cửa sổ Telescope: `Ctrl+n`/`Ctrl+p` lên xuống, `Enter` mở, `Ctrl+v` mở sang split dọc, `Esc` thoát.

## Cây thư mục — Neo-tree

| Phím | Việc |
|---|---|
| **`Space + e`** | Bật/tắt cây thư mục |
| `\` | Mở cây và nhảy tới file đang mở |
| `Space + n + g + s` | Cửa sổ nổi xem trạng thái git |

Khi đang ở trong cây:

| Phím | Việc |
|---|---|
| `a` / `A` | Thêm file / thêm thư mục |
| `d` `r` `c` `m` | Xoá / đổi tên / copy / di chuyển |
| `y` `x` `p` | Copy / cắt / dán |
| `S` / `s` | Mở sang split ngang / dọc |
| `t` | Mở sang tab mới |
| `w` | Chọn cửa sổ nào để mở vào |
| `P` | Xem trước, không rời cây |
| `H` | Hiện/ẩn file ẩn |
| `/` | Lọc nhanh theo tên |
| `z` | Đóng hết nhánh |
| `?` | Xem toàn bộ phím của neo-tree |

---

## Buffer, cửa sổ, tab

| Phím | Việc |
|---|---|
| **`Tab`** / **`Shift+Tab`** | Buffer sau / trước |
| **`Space + x`** | **Đóng hẳn buffer** |
| `Space + b` | Buffer trống mới |
| `Space + v` | Chia cửa sổ **dọc** |
| `Space + h` | Chia cửa sổ **ngang** |
| `Ctrl + h/j/k/l` | Nhảy giữa các cửa sổ — **và cả pane tmux** |
| Phím mũi tên | Đổi kích thước cửa sổ |
| `Space + s + e` | Cân đều kích thước các cửa sổ |
| `Space + x + s` | Đóng cửa sổ hiện tại |
| `Space + t + o` / `t + x` | Mở / đóng tab |
| `Space + t + n` / `t + p` | Tab sau / trước |

> `Ctrl+h/j/k/l` là phím **dùng chung với tmux** nhờ `vim-tmux-navigator`. Đang ở cửa sổ nvim
> ngoài cùng bên trái mà bấm `Ctrl+h` thì nhảy thẳng sang pane tmux bên cạnh.

---

## Lập trình — LSP

Chỉ hoạt động khi mở file có language server (Mason đã cài sẵn cho lua, ts/js, json, css, html, python, sql, yaml, docker, terraform, tailwind).

| Phím | Việc |
|---|---|
| **`K`** | **Xem mô tả** hàm/biến dưới con trỏ |
| **`gd`** | **Nhảy tới định nghĩa** (`Ctrl+o` để quay lại) |
| `gr` | Xem mọi nơi đang dùng nó |
| `gI` | Nhảy tới phần cài đặt (implementation) |
| `gD` | Nhảy tới khai báo |
| `Space + D` | Nhảy tới định nghĩa kiểu dữ liệu |
| **`Space + c + a`** | **Sửa lỗi tự động** (code action) |
| **`Space + r + n`** | **Đổi tên** biến/hàm ở mọi nơi |
| `Space + d + s` | Danh sách ký hiệu trong file |
| `Space + w + s` | Tìm ký hiệu trong cả dự án |
| `[d` / `]d` | Lỗi trước / sau |
| `Space + d` | Xem chi tiết lỗi tại con trỏ |
| `Space + q` | Mở danh sách toàn bộ lỗi |

## Gợi ý khi gõ

| Phím | Việc |
|---|---|
| `Ctrl + n` / `Ctrl + p` | Xuống / lên trong danh sách gợi ý |
| `Enter` | Chọn |
| `Ctrl + Space` | Gọi gợi ý thủ công |
| `Tab` | Nhảy tới ô tiếp theo trong snippet |
| `Ctrl + e` | Đóng bảng gợi ý |

## Git

| Phím / lệnh | Việc |
|---|---|
| `:Git` | Bảng trạng thái git |
| `:Git commit` / `:Git push` | Commit / push |
| `:Gdiffsplit` | So sánh với bản đã commit |
| `Space + n + g + s` | Trạng thái git dạng cửa sổ nổi |

Cột trái tự hiện dấu: `+` thêm, `~` sửa, `_` xoá.

---

## Sửa văn bản

| Phím | Việc |
|---|---|
| `Ctrl + s` | Lưu |
| `Space + s + n` | Lưu **không** chạy format tự động |
| `Ctrl + q` | Thoát |
| `gcc` | Comment dòng hiện tại |
| `gc` (visual) | Comment vùng chọn |
| `Ctrl+d` / `Ctrl+u` | Cuộn nửa trang, **tự căn giữa** |
| `n` / `N` | Tìm tiếp, **tự căn giữa** |
| `x` | Xoá 1 ký tự, **không ghi đè clipboard** |
| `<` `>` (visual) | Thụt lề, **giữ nguyên vùng chọn** |
| `p` (visual) | Dán **không mất nội dung đã copy** |
| `Space + l + w` | Bật/tắt xuống dòng tự động |

## Giao diện

| Phím | Việc |
|---|---|
| `Space + b + g` | Bật/tắt nền trong suốt |
| `Space + t + t` | Xem Neovim đang đọc theme từ đâu |

---

## Màu — đồng bộ với WezTerm

Bảng màu Neovim lấy **nguyên 16 màu Dusk-Navy** từ `wezterm.lua`:

| Thành phần | Màu | Nguồn |
|---|---|---|
| Nền | `#1d2837` | `background` |
| Chữ | `#EDEEF7` | `foreground` |
| Chú thích | `#93a1b3` | `BRIGHT_BLACK.dark` |
| Chuỗi | `#8fbfa9` | `brights[2]` |
| Tên hàm | `#7d9bd4` | `brights[4]` |
| Từ khoá | `#a99ad4` | `brights[5]` |
| Vùng bôi đen | `#3d4a6b` | `selection_bg` |

Nền để **trong suốt** cho gradient của WezTerm hiện xuyên qua.

Đổi màu: sửa `DUSK_NAVY` trong `lua/plugins/colortheme.lua` cho khớp `CUSTOM_SCHEMES` trong `wezterm.lua`.

---

## Lệnh bảo trì

| Lệnh | Việc |
|---|---|
| `:Lazy` | Bảng quản lý plugin |
| `:Lazy update` | Cập nhật plugin (nhớ commit lại `lazy-lock.json`) |
| `:Mason` | Bảng quản lý LSP / formatter / linter |
| `:TSUpdate` | Cập nhật parser treesitter |
| **`:checkhealth`** | **Soi xem còn thiếu gì** — chạy khi có gì đó không hoạt động |
| `:LspInfo` | Xem LSP nào đang chạy cho file hiện tại |
| `:messages` | Xem lại các thông báo đã trôi qua |

---

## Khi hỏng

| Triệu chứng | Nguyên nhân thường gặp |
|---|---|
| `module 'nvim-treesitter.configs' not found` | Thiếu `branch = 'master'` trong `lua/plugins/treesitter.lua`. Nhánh mặc định của nvim-treesitter đã chuyển sang `main` — bản viết lại bỏ module này |
| LSP JavaScript không cài được | Chưa có `node` / `npm` |
| Parser treesitter không biên dịch | Chưa có `gcc` |
| `Too many rounds of missing plugins` | Một plugin build lỗi lặp vô hạn. Xem `:Lazy` để biết cái nào |
| Icon hiện ô vuông | Terminal chưa dùng Nerd Font |
| Màu trông sai | Terminal chưa bật true color |
