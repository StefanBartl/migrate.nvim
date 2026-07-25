std = "luajit"
cache = true

globals = {
  "vim",
}

-- stylua (.stylua.toml, column_width = 100) already owns line-length/formatting;
-- don't duplicate that concern here.
max_line_length = false

exclude_files = {
  ".luarocks/",
}
