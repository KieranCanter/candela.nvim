# Candela Demo

Output candela-demo.webm

Set Shell "bash"
Set FontSize 20
Set FontFamily "JetBrainsMono Nerd Font"
Set TypingSpeed 200ms
Set PlaybackSpeed 0.7
Set Width 1920
Set Height 1080
Set Framerate 60
Set Padding 20
Set Theme "Catppuccin Mocha"

Hide
# Open the log file
Type@1ms "nvim --cmd 'set ignorecase smartcase' sample.log"
Enter
Show
Sleep 2s

# Open UI
Type " cds"
Sleep 1.5s

# Type first pattern
Type "inginx.*GET"
Escape
Sleep 0.5s

# Type second pattern
Type "opostgres"
Escape
Sleep 0.5s

# Write to save both patterns
Type ":w"
Enter
Sleep 2s

# Copy first pattern
Type "kVy"
Sleep 0.3s

# Paste below
Type "jp"
Sleep 0.5s

# Edit third pattern
Type "wwcwpost"
Escape
Sleep 0.5s

# Move to second pattern
Type "k"
Sleep 0.3s

# Edit second pattern
Type "A|cron"
Escape
Sleep 0.5s

# Write changes
Type ":w"
Enter
Sleep 2s

# Add "registered" on a new line
Type "josuccess"
Escape
Sleep 0.5s

# Write
Type ":w"
Enter
Sleep 2s

# Temp remap change_color keymap because of Alt limitations in vhs
Hide
Type@1ms ":lua vim.api.nvim_buf_set_keymap(0, 'n', 'ggc', '', { callback = function() vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<M-c>', true, false, true), 'm', false) end })"
Enter
Show
# Change color of "registered"
Type "ggc"
Sleep 0.5s
Tab
Sleep 0.5s
Ctrl+N
Sleep 0.5s
Ctrl+N
Sleep 0.5s
Ctrl+Y
Sleep 0.5s
Enter
Sleep 1s

# Open lightbox
Hide
Type@1ms ":Candela lightbox"
Show
Enter
Sleep 1s

# Switch back to left window and show UI
Ctrl+W
Type "h"
Type " cds"
Sleep 1.5s

# Toggle highlight off for pattern 3
Type "k"
Sleep 0.3s
Ctrl+H
Sleep 1s

# Toggle lightbox off for pattern 2
Type "k"
Sleep 0.3s
Ctrl+L
Sleep 1s

# Select all
Ctrl+A
Sleep 1s

# Vimmatch
Ctrl+N
Sleep 1.5s

# Cycle through matches
Type "n"
Sleep 0.5s
Type "n"
Sleep 0.5s
Type "n"
Sleep 0.5s
Type "n"
Sleep 0.5s
Type "n"
Sleep 0.5s
Type "n"
Sleep 1s

# Open UI again
Type " cds"
Sleep 1s

# Select patterns 4 & 1
Type "jj"
Sleep 0.5s
Tab
Sleep 0.5s
Tab
Sleep 1s

# Loclist
Ctrl+Q
Sleep 1.5s

# Cycle through loclist
Type@1ms ":lnext"
Enter
Sleep 0.5s
Type@1ms ":lnext"
Enter
Sleep 0.5s
Type@1ms ":lnext"
Enter
Sleep 0.5s
Type@1ms ":lnext"
Enter
Sleep 0.5s
Type@1ms ":lnext"
Enter
Sleep 0.5s
Type@1ms ":lnext"
Enter
Sleep 0.5s
Type@1ms ":lnext"
Enter
Sleep 1s

# Close loclist
Type@1ms ":lclose"
Enter
Sleep 1s

# Open UI
Type " cds"
Sleep 1.5s

# Delete a couple patterns (dd on two lines)
Type "ggVjd"
Sleep 0.5s

# Write to apply deletes
Type ":w"
Enter
Sleep 1.5s

# Close UI
Escape
Sleep 1s

# Clear all patterns
Type " cdd"
Sleep 1s

# Quit lightbox
Ctrl+W
Type "l:q"
Enter
Sleep 1s
