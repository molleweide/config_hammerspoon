local function jumpToSlackThread()
  hs.eventtap.keyStroke({'shift'}, 'tab', 0)
  hs.eventtap.keyStroke({'shift'}, 'tab', 0)
  hs.eventtap.keyStroke({'shift'}, 'tab', 0)
  hs.eventtap.keyStroke({'shift'}, 'tab', 0)
  hs.eventtap.keyStroke({'shift'}, 'tab', 0)
  hs.eventtap.keyStroke({'shift'}, 'tab', 0)
  hs.eventtap.keyStroke({}, 'return')
end

hs.hotkey.bind(hyper, 't', jumpToSlackThread)
