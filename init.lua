hs.loadSpoon("SpoonInstall")

require "common"
require "config-watch"
require "window-management"
require "key-bindings"
require "mute-on-sleep"
require "audio-switcher"
require "favorites"
require "quick-switch"
require "slack"
require "pairing-mode"
require "experimental"

vim = hs.loadSpoon('VimMode')

vim:disableForApp('Code')
vim:disableForApp('zoom.us')
vim:disableForApp('iTerm')
vim:disableForApp('iTerm2')

vim:enableKeySequence('j', 'k')
