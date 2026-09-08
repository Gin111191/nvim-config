-- Hiển thị file Markdown đã "dựng hình" ngay trong Neovim: tiêu đề có nền màu,
-- gạch đầu dòng thành ký hiệu, bảng vẽ khung, checkbox thành ô tick, khối code có
-- icon ngôn ngữ — thay vì nhìn thô các dấu #, *, |.
--
-- Vào chế độ Insert (bấm i) thì tự trả về Markdown thô để sửa, thoát ra lại dựng hình.
-- Đó chính là ý nghĩa của render_modes = { 'n', 'c', 't' } — và cũng là mặc định,
-- nên không cần khai báo.
--
-- Lệnh: :RenderMarkdown toggle | enable | disable | expand
return {
  'MeanderingProgrammer/render-markdown.nvim',
  -- Config này đã dùng nvim-web-devicons ở 4 chỗ khác (alpha, neo-tree,
  -- bufferline, telescope). Plugin tự dò icon provider: thử mini.icons trước,
  -- không có thì dùng nvim-web-devicons. Khai báo thẳng cái đang dùng để khỏi
  -- kéo thêm bộ icon thứ hai với icon khác nhau cho cùng loại file.
  dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' },
  ft = { 'markdown' }, -- chỉ nạp khi mở file .md, khớp file_types mặc định
  ---@module 'render-markdown'
  ---@type render.md.UserConfig
  opts = {},
}
