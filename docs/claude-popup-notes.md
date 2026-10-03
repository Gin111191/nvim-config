# Claude Code trong popup tmux — ghi chú thiết kế & sự cố

Notes as of 2026-10-02. Phím tắt đầy đủ nằm trong `CHEATSHEET.md` (mục "AI — Claude in a tmux
popup" và "Reviewing what Claude changed"). File này ghi **vì sao** mọi thứ như vậy, đã thử những
gì, hỏng ở đâu, và cách kiểm tra/khắc phục khi có chuyện.

## 1. Mục tiêu đã chốt

- Claude hiện trong **khung nổi 90%** trên Neovim, **ẩn/hiện** được, Claude vẫn chạy khi ẩn.
- Bên trong khung là **terminal bình thường**: `Ctrl+b` tới đúng tmux, **cuộn kiểu vim**
  (`Ctrl+b [` → `90k`, `v`, `y`, `/`).
- Mỗi project nhiều Claude; `Space a s` liệt kê mọi Claude của project (kể cả tự chạy tay).
- `Space a t/f/v` gửi `@file#L10-20` / `@file` / đoạn chọn tới **Claude đang dùng của project
  trong window tmux đó**, không bao giờ lẫn project khác.
- Shift+←/→ chỉ nhảy giữa các window làm việc, bỏ qua window Claude.
- Xem diff những gì Claude sửa: codediff (`Space g d`).

## 2. Các mảnh ghép nằm ở đâu

| Repo | File | Vai trò |
|---|---|---|
| nvim-config | `lua/core/claude-popup.lua` | Module chính: `Space a c/s/t/f/v`, popup, danh sách, bộ chọn cuộc cũ |
| nvim-config | `lua/core/nvim-registry.lua` | Mỗi Neovim ghi `~/.cache/nvim-claude/<pid>.json` (pid + thư mục) để hook tìm thấy |
| nvim-config | `lua/core/external-change.lua` | Highlight chỗ Claude sửa, đóng buffer hook mở (`close_opened`) |
| nvim-config | `lua/plugins/codediff.lua` | codediff.nvim, `Space g d/f/h/H`, `auto_open_on_cursor` |
| tmux-config | `claude-window.sh` + `tmux.conf` | Shift+←/→ bỏ qua window `·claude:…`; trong popup thì đóng popup rồi nhảy |
| claude-config | `hooks/nvim-open.sh` | Hook Edit/Write: mở file trong Neovim của project, highlight; `done` khi Stop |
| claude-config | `settings.json` | `"tui": "default"` (renderer classic), `"disableAgentView": true` |
| zsh | `claude/CLAUDE.md` | Luật toàn cục: hiện file/diff trong Neovim thay vì chat |

Đã gỡ: `claudecode.nvim` (thay bằng module trên), `sidekick.nvim` (thử rồi bỏ).

## 3. Popup hoạt động thế nào

- Mỗi Claude sống trong **một window tmux riêng** ("stash window") trong session đang dùng, tên
  `·claude:<project>#<n>`, chạy `$SHELL -ic 'claude …; exec $SHELL -i'` → `/exit` thì rơi về
  shell ngay trong popup, gõ được `claude --resume`, `claude -c`…
- Popup = `tmux display-popup -E -w 90% -h 90%` chạy `tmux attach` vào một **session tạm**
  `claude-view-*`. Session tạm chỉ chứa đúng window Claude đó (`link-window`), nên client chính
  của bạn không bị đổi window. Các option trên session tạm:
  - `status off` (không thanh trạng thái trong popup)
  - `detach-on-destroy on` (window Claude chết → popup đóng, không nhảy sang session khác)
  - `destroy-unattached on` (đóng popup → session tạm tự xoá)
  - `@claude_origin` = session gốc (cho Shift+←/→ trong popup)
- Lệnh `tmux` bên trong popup chạy với `env -u TMUX tmux -S <socket>`: bỏ `TMUX` để tmux không
  từ chối "nested", nhưng chỉ rõ socket để vẫn nói chuyện đúng server.

Option tmux mà module dùng:

| Option | Gắn ở | Ý nghĩa |
|---|---|---|
| `@claude_project` | pane | Thư mục project của Claude đó |
| `@claude_n` | pane | Số thứ tự `#n` trong project |
| `@claude_stash` | window | Window này là window cất giữ Claude (Shift+←/→ bỏ qua) |
| `@claude_last_<hash>` | window chứa Neovim | Pane của "Claude đang dùng" cho project đó trong window này |
| `@claude_origin` | session `claude-view-*` | Session gốc khi popup mở |
| `@claude_client` | session `claude-view-*` | Client (terminal) mà popup đang vẽ lên — để mở lại popup đúng chỗ khi chuyển window |
| `@claude_float` | window làm việc | `1` khi khung nổi của window đó đang mở (xem §11) |
| `@claude_float_pane` | window làm việc | Pane Claude mà khung nổi của window đó hiện |
| `@tmux_config_dir` | global | Thư mục chứa `tmux.conf` (để tìm `claude-window.sh`) |

## 4. Module nhận diện Claude thế nào

- **Tiến trình nào là Claude**: quét `ps` một lần, lấy tiến trình có argv[0] tên `claude` và
  **không** phải `-p/--print`, `daemon`, `mcp`, `--bg-*`… Pane chứa Claude khi `pane_pid` là tổ
  tiên của tiến trình đó. (tmux đặt tên pane theo số phiên bản, vd `2.1.287`, nên không dựa vào
  tên pane được.)
- **Claude đó đang mở cuộc nào**: `~/.claude/sessions/<pid>.json` → `sessionId` (Claude Code tự
  ghi cho mọi tiến trình). Dùng để cảnh báo `⚠ same conversation as #n`.
- **Danh sách cuộc cũ** (`+ Open a past conversation…`): đọc
  `~/.claude/projects/<thư mục, ký tự không phải chữ/số → "-">/*.jsonl`. Tên = bản ghi
  `custom-title` / `ai-title` cuối cùng; bỏ các file có bản ghi `continued-in` (đã được nối sang
  mã mới) và file < 2 kB. Đọc bằng `rg` dòng-đầu `^{"type":"(ai-title|custom-title|continued-in)"`
  → ~25 ms cho 850 MB.
- **"Cuộc gần nhất"** (cho `+ Continue`): transcript có mtime mới nhất trong thư mục project.

## 5. Quyết định & lý do

1. **claudecode.nvim → sidekick → popup tmux tự viết.** claudecode chỉ một Claude/Neovim;
   sidekick một Claude/project và float của nó là tmux lồng tmux (Ctrl+b bị tmux ngoài bắt, cuộn
   lịch sử bị cắt).
2. **Popup tmux chứ không float Neovim.** Float Neovim chỉ hiện buffer Neovim; muốn hiện pane
   tmux phải lồng tmux. Popup tmux thì phím đi thẳng vào Claude, Ctrl+b đúng tmux đó.
3. **Không dùng floating pane của tmux 3.7c.** Thử trên server riêng: chiều rộng kẹt 50%, không
   có lệnh ẩn/hiện, `join-pane` trả về pane chia đôi. tmux 3.8 (chưa phát hành) có
   `break-pane -W -x 90% -y 90%` → khi lên 3.8 có thể xem lại.
4. **`"tui": "default"` (renderer classic).** Renderer fullscreen vẽ trên alternate screen nên
   tmux copy mode chỉ thấy một màn hình. Classic đổ vào scrollback → cuộn kiểu vim được.
5. **`"disableAgentView": true`.** Agents view (`←`, `claude agents`, `--bg`, `/background`,
   daemon) tự chuyển/fork cuộc hội thoại sau lưng popup (xem §6). Tắt nó → mỗi cuộc nằm đúng một
   pane tmux; tmux lo phần "sống dai". Muốn bật lại: xoá dòng đó.
6. **Bộ chọn cuộc cũ trong Neovim** thay cho `claude --resume` trong window mới: Esc không để lại
   window rỗng, cuộc đang mở thì nhảy tới thay vì mở bản thứ hai.
7. **"Claude đang dùng" nhớ theo window + project**, nên hai Neovim của hai project chung một
   window tmux vẫn gửi đúng chỗ.
8. **Claude chạy tay cạnh Neovim / trong window nhiều pane của bạn: để nguyên, chỉ nhảy tới.**
   Popup chỉ chiếu được nguyên window nên không đưa được chúng vào popup mà không di chuyển.

## 6. Sự cố đã gặp (và nguyên nhân thật)

| Hiện tượng | Nguyên nhân | Đã xử lý |
|---|---|---|
| Popup không mở | Lệnh `tmux` trong popup bỏ `TMUX` nên nối nhầm server mặc định | `-S <socket>` |
| Pane tách ra mang tên `2.1.287` | Bỏ qua bước đặt tên sau `break-pane` | Đánh dấu lại, window cũ trả về bình thường |
| Claude trong popup bị liệt kê 2 lần | Window đang chiếu popup cũng nằm trong `claude-view-*`, `list-panes -a` trả 2 lần | Bỏ bản trong `claude-view-*` |
| `Space a s` coi `claude … agents` là chat | Bộ lọc chỉ nhìn từ ngay sau `claude`, cờ chen giữa | Hết đường xảy ra vì agents view đã tắt |
| Hai Claude chung một cuộc | `claude --continue` mở đúng cuộc đang mở ở window khác | Cảnh báo ⚠; `+ Continue` nhảy tới cuộc đang mở |
| Popup ghi "em.nhumay" nhưng bên trong là cuộc khác | `←` (agents view) đổi cuộc ngay trong khung | Tắt agents view |
| Một cuộc thành nhiều bản / nhiều mã | Agents view fork (`--fork-session`), chuyển qua lại nền ↔ thường | Tắt agents view; bộ chọn ẩn mã đã `continued-in` |
| `--resume` báo "đang chạy nơi khác" | Mã cũ trong chuỗi, phần tiếp theo đang chạy nền | Như trên |
| Câu hỏi nvim lọt vào cuộc em.nhumay | Gõ nhầm khung (khung lúc đó đang hiện cuộc em.nhumay) | Tiêu đề popup + tắt agents view |
| Màn hình Claude cũ + dấu nhắc zsh bên dưới | Kill Claude ở renderer classic → chữ cũ còn trên màn hình | `clear` / `Ctrl+l` |
| `Esc` ở `claude --resume` để lại window rỗng | Window tạo trước khi chọn | Bộ chọn trong Neovim |
| (Khi thử) script chạy vào tmux thật | Gọi script ngoài tmux, thiếu `TMUX` → server mặc định | Luôn `export TMUX=<socket test>,0,0` khi thử |
| Shift+←/→ mở lại khung với pane Claude đã chết | `tmux display-message -t <pane không còn>` vẫn trả exit 0 | Kiểm tra pane bằng `list-panes -a` |
| (Khi thử) Neovim không mở được socket `--listen` | Đường dẫn socket > ~104 ký tự (giới hạn macOS) | Thử bằng socket mặc định qua file đăng ký, như script thật |

## 7. Giới hạn còn lại

- `/resume` gõ **bên trong** Claude đổi cuộc tại chỗ; module vẫn đọc lại đúng `sessionId` khi mở
  danh sách, nhưng tiêu đề window `#n` không đổi. Đổi cuộc thì nên qua `Space a s`.
- Claude chạy ngoài tmux (tab terminal thường), máy khác, hay thư mục ngoài project: không thấy.
- Ngưỡng 2 kB để ẩn "bản gần như trống" là ước lượng; cuộc thật nào biến mất khỏi danh sách thì
  hạ ngưỡng (`past()` trong `claude-popup.lua`).
- tmux server tắt / khởi động lại máy → Claude tắt (lịch sử vẫn còn, mở lại qua `Space a s`).

## 8. Lệnh chẩn đoán nhanh

```sh
# Claude nào đang chạy, cuộc nào, ở đâu (sổ đăng ký của Claude Code)
for f in ~/.claude/sessions/*.json; do p=$(jq -r .pid $f); kill -0 $p 2>/dev/null &&
  jq -r '[.pid, .sessionId[0:8], .kind, .status, (.cwd|split("/")|last), .name] | @tsv' $f; done

# Window/pane Claude và nhãn module gắn
tmux list-panes -a -F '#{pane_id} #{session_name}:#{window_index} #{window_name} proj=#{@claude_project} n=#{@claude_n} stash=#{@claude_stash}'

# "Claude đang dùng" ghi trên từng window
for w in $(tmux list-windows -a -F '#{window_id}'); do tmux show-options -w -t $w | grep claude_last; done

# Cuộc hội thoại đã lưu của một project (mới nhất trước)
ls -lt ~/.claude/projects/-Users-gin-Everything-in-Gin-Business-em-nhumay/*.jsonl | head

# Cuộc A đã được nối sang mã nào
jq -r 'select(.type=="continued-in") | .continuedInSessionId' <file>.jsonl

# Neovim nào hook sẽ tìm thấy
cat ~/.cache/nvim-claude/*.json
```

## 9. Cách thử an toàn (không đụng tmux thật)

- Server riêng: `tmux -L <tên> -f /dev/null new -d -s work -x 200 -y 50 -c <dir> "nvim --listen <sock>"`.
- Mọi lệnh gọi script/tmux từ shell ngoài: `export TMUX="$(tmux -L <tên> display -p '#{socket_path}'),0,0"`.
- Client giả cho popup: `(sleep 600 | script -q /dev/null sh -c "stty rows 50 cols 200; tmux -L <tên> attach") &`.
- Claude giả: `ln -s /bin/cat <dir>/bin/claude` (symlink — bản **copy** của binary hệ thống bị macOS
  SIGKILL, exit 137). Lưu ý `zsh -ic` đọc `.zshrc` nên có thể vẫn gọi Claude thật.
- Thư mục cấu hình Claude giả: `CLAUDE_CONFIG_DIR=<dir>/cfg` cho sessions/projects giả.
- Điều khiển Neovim: `nvim --server <sock> --remote-expr "luaeval('...')"`; thay `vim.ui.select`
  bằng hàm in danh sách rồi `cb(nil)` để thử chỉ đọc.

## 10. Quay lại cách cũ

- Bật lại agents view: xoá `"disableAgentView": true` trong `~/.claude/settings.json`.
- Về claudecode.nvim: trong nvim-config `git revert` các commit từ `879d9ec` tới `05fe770` (hoặc
  checkout `f7d5847`), rồi `:Lazy restore` + `:Lazy clean`.

## 11. Khung nổi riêng cho từng window (kế hoạch 2026-10-03 — đã làm, đã thử)

**Yêu cầu**
1. Mỗi window tmux có khung nổi (popup Claude) **của riêng nó**: mở hay đóng, hiện Claude nào.
2. Shift+←/→ chuyển window; khung của window mới mở/đóng **đúng trạng thái đã ghi của window đó**
   — không để khung của A nổi trên B, không lẫn Claude giữa các window.
3. Shift+↑ = mở khung của window hiện tại. Shift+↓ = đóng khung (Claude vẫn chạy).

**Cách làm**
- popup tmux gắn theo *client* (terminal đang xem), không theo window → mỗi window tự **ghi trạng
  thái** bằng option tmux:
  - `@claude_float` = `1` khi khung của window đó đang mở (không có = đóng)
  - `@claude_float_pane` = pane Claude mà khung của window đó hiện
- `claude-window.sh` (tmux-config) thêm hai lệnh `open` / `close` bên cạnh `prev` / `next`:
  - `open`: window có `@claude_float_pane` còn sống → mở popup của nó, ghi `@claude_float 1`.
    Chưa có → nhờ Neovim trong window đó (RPC tới socket của nó) làm như `Space a c`.
    Không có Neovim → báo trên thanh trạng thái.
  - `close`: đóng popup, xoá `@claude_float` của window.
  - `prev` / `next`: đang trong popup thì đóng popup **nhưng giữ** trạng thái; chuyển window (bỏ
    qua `·claude:…`); window mới có `@claude_float 1` và pane còn sống → mở lại popup của nó.
- `tmux.conf`: `Shift+↑` → `open` (mọi nơi; Neovim mất phím cuộn-lên-một-trang mặc định).
  `Shift+↓` → `close` khi đang trong popup, ngoài popup thì chuyển phím cho ứng dụng.
  `Prefix + d` trong popup → `close` (ghi đóng); ngoài popup vẫn là detach như cũ.
- `claude-popup.lua`: mỗi lần tự mở popup thì ghi `@claude_float 1` + `@claude_float_pane` lên
  window chứa Neovim, và ghi client ngoài (`@claude_client`) lên session tạm để script biết mở lại
  popup trên client nào khi chuyển window từ trong popup.
- Claude trong khung thoát hẳn (window chết) → pane không còn → window đó coi như "đóng".

**Kiểm thử** (tmux server riêng nạp đúng `tmux.conf` thật, 2 window làm việc + 2 Claude giả) —
tất cả **đạt**:

| # | Thao tác | Kết quả |
|---|---|---|
| 1 | A: Shift+↑ | Khung mở, hiện Claude A |
| 2 | Trong khung: Shift+→ | Sang B; khung đóng (B đang đóng); A vẫn ghi "mở" |
| 3 | B: Shift+← | Về A; khung tự mở lại đúng Claude A |
| 4 | Trong khung: Shift+↓ | Khung đóng; A ghi "đóng" |
| 5 | Shift+→ rồi Shift+← | Về A; khung **không** tự mở |
| 6–8 | Mở khung ở B, chuyển qua lại A ↔ B | Mỗi window đúng trạng thái của nó, B luôn hiện Claude B |
| 9–10 | Claude của A chết | Khung đóng ngay; lần sau ghé A, A tự về "đóng" |
| 11 | Shift+↑ ở window không có Claude, không có Neovim | Chỉ báo, không mở gì |
| — | Shift+↑ ở window có Neovim nhưng chưa ghi Claude | Neovim của window đó được gọi `toggle()` (= `Space a c`) |
| — | `Space a c` | Ghi `@claude_float=1`, `@claude_float_pane`; session popup có `@claude_client`, `@claude_origin` |
