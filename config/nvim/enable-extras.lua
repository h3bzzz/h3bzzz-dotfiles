local extras = {
  "lang.go",
  "lang.typescript",
  "lang.python", 
  "lang.zig",
  "editor.harpoon2",
}

print("Enabling LazyVim extras...")
for _, extra in ipairs(extras) do
  print("  - " .. extra)
end
