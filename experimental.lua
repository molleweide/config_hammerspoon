local logger = hs.logger.new('explore', 'debug')
local ax = require("hs._asm.axuielement")
inspect = hs.inspect.inspect

function getCurrentSelection()
   local elem=hs.uielement.focusedElement()
   local sel=nil
   if elem then
      sel=elem:selectedText()
   end
   if (not sel) or (sel == "") then
      hs.eventtap.keyStroke({"cmd"}, "c")
      hs.timer.usleep(20000)
      sel=hs.pasteboard.getContents()
   end
   return (sel or "")
end

function getForwardContents()
  hs.eventtap.keyStroke({'cmd', 'shift'}, 'down', 0)
  local contents = getCurrentSelection()
  hs.eventtap.keyStroke({}, 'left')

  logger.i(contents)
end

function getSelectedTextRange()
  -- for now force manual accessibility on
  local axApp = ax.applicationElement(hs.application.frontmostApplication())
  axApp:setAttributeValue('AXManualAccessibility', true)

  local systemElement = ax.systemWideElement()
  local currentElement = systemElement:attributeValue("AXFocusedUIElement")
  local role = currentElement:attributeValue("AXRole")

  if role == "AXTextField" or role == "AXTextArea" then
    logger.i("Currently in text field")
    logger.i(inspect(currentElement:parameterizedAttributeNames()))

    local text = currentElement:attributeValue("AXValue")
    local textLength = currentElement:attributeValue("AXNumberOfCharacters")
    local range = currentElement:attributeValue("AXSelectedTextRange")

    logger.i("range = " .. inspect(range))
    logger.i("len = " .. textLength)
    logger.i("Text is " .. text)
  else
    logger.i("Role = " .. role)
  end
end

function hasCurrentSelection()
  local currentApp = ax.applicationElement(hs.application.frontmostApplication())
  local menuBar = hs.fnutils.find(currentApp:attributeValue("AXChildren"), function(childElement)
    return childElement:attributeValue("AXRole") == "AXMenuBar"
  end)

  local menuItems = menuBar:attributeValue("AXChildren")

  local editMenu = hs.fnutils.find(menuItems, function(menuItem)
    return menuItem:attributeValue("AXTitle") == "Edit"
  end)

  local editItems = editMenu:attributeValue("AXChildren")[1]:attributeValue("AXChildren")

  local copyItem = hs.fnutils.find(editItems, function(editItem)
    return editItem:attributeValue("AXTitle") == "Copy"
  end)

  local isEnabled =  copyItem:attributeValue("AXEnabled")

  return isEnabled
end

hs.hotkey.bind(hyper, 'a', function()
  -- logger.i("Selection enabled", hasCurrentSelection())
  getSelectedTextRange()
end)

function printAXNotifications(ae, o)
  processChildren = function(child)
    failureCount = 0
    failures = ""
    for i, notification in pairs(ax.observer.notifications) do
      local status, err = pcall(function() o:addWatcher(child, notification) end)
      if not status then
        failureCount = failureCount + 1
        if i == #ax.observer.notifications then
          failures = failures .. notification
        else
          failures = failures .. notification .. ", "
        end
      end
    end
    if failureCount == 0 then
      print(string.format("All notifications available for: %s", child))
    else
      if failureCount == #ax.observer.notifications then
        print(string.format("ERROR: All notifications unavailable for: %s", child))
      else
        print(string.format("ERROR: Some notifications unavailable for: %s (%s)", child, failures))
      end
    end

    children = child:attributeValue("AXChildren")
    if children and #children > 0 then
      for _, v in pairs(children) do
        processChildren(v)
      end
    end

  end

  rootChildren = ae:attributeValue("AXChildren")
  if #rootChildren > 0 then
    print(string.format("PROCESSING: %s", app))
    print("--------------------------------------")
    for i, v in pairs(rootChildren) do
      processChildren(v)
    end
  else
    print("ERROR: There are no root children in application, so aborting.")
  end
end

-- registering all application focus events

local applicationWatchers = {}

function registerApplicationWatcher(app)
  if not app then return end
  if applicationWatchers[app:pid()] then return end

  logger.i("Registering " .. app:name() .. " with pid " .. app:pid())

  local element = ax.applicationElementForPID(app:pid())
  element:setAttributeValue('AXManualAccessibility', true)

  local observer = ax.observer.new(app:pid())
    :callback(function(...) print(hs.inspect(table.pack(...), { newline = " ", indent = "" })) end)
    :addWatcher(element, "AXFocusedUIElementChanged")

  -- printAXNotifications(element, observer)

  observer:start()

  applicationWatchers[app:pid()] = observer
end

function unregisterApplicationWatcher(app)
  logger.i("Unregistering pid " .. app:pid())

  local observer = applicationWatchers[app:pid()]

  if observer:isRunning() then observer:stop() end
  applicationWatchers[app:pid()] = nil
end

local appWatcher = hs.application.watcher.new(function(applicationName, event, hsApplication)
  if event == hs.application.watcher.terminated then
    unregisterApplicationWatcher(hsApplication)
  elseif event ~= hs.application.watcher.launched then
    registerApplicationWatcher(hsApplication)
  end
end)

-- registerApplicationWatcher(hs.application.frontmostApplication())
-- appWatcher:start()
