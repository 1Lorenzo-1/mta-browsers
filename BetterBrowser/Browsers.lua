--[[
 / Script created by @xMD + Man
 / Discord (1xmd)

 # 2024/02/04 
 @ better browsers. 

 https://github.com/1Lorenzo-1/mta-browsers
]]

addEvent("better-browsers:loaded", false)
addEvent("better-browsers:page-loaded", false)
addEvent("onBrowserLoad", false)

local SW, SH = guiGetScreenSize()
local dxBrowser = createBrowser
local MTAFocus = focusBrowser

local browserLoaded = false 
local Browser
local browsers = {}
local elements_resources = {} 
local toLoadBrowsers = {}

local function Constructor()
    Browser = dxBrowser(SW,SH,true,true)

    addEventHandler('onClientBrowserLoadingFailed', Browser, function()
        Constructor()
    end, false)

    addEventHandler('onClientBrowserCreated', Browser, function()
        loadBrowserURL(source, 'http://mta/BetterBrowsers')
        executeBrowserJavascript(source, [[
            document.addEventListener("DOMContentLoaded", function() {
                document.body.innerHTML = "";
                document.body.style.overflow = "hidden";   
                mta.triggerEvent("better-browsers:page-loaded")
            });      
        ]]);
        MTAFocus(Browser)
    end, false)

    addEventHandler("onClientRender", root, function()
        dxDrawImage (0,0,SW,SH, Browser,0,0,0, tocolor(255,255,255), true)
    end, false)

    addEventHandler("onClientClick", root, function(button, state)
        if state == "down" then
            injectBrowserMouseDown(Browser, button)
        else
            injectBrowserMouseUp(Browser, button)
        end 
    end, false)

    addEventHandler("onClientKey", root, function(button, pressed)
        if (not pressed) then return end -- only inject when pressed down
        if button == "mouse_wheel_down" then
            injectBrowserMouseWheel(Browser, -40, 0)
        elseif button == "mouse_wheel_up" then
            injectBrowserMouseWheel(Browser, 40, 0)
        end
    end, false)

    addEventHandler("onClientCursorMove", root, function(relativeX, relativeY, absoluteX, absoluteY)
        injectBrowserMouseMove(Browser, absoluteX, absoluteY)
    end, false)

    addEventHandler("better-browsers:loaded", Browser, function(id)
        for element, loaded in pairs(browsers) do 
            if tonumber(loaded.id) == tonumber(id) then 
                if isElement(element) then 
                    triggerEvent("onBrowserLoad", element)
                end 
                return
            end 
        end 
    end)

    addEventHandler("better-browsers:page-loaded", Browser, function()
        browserLoaded = true
    
        for id, js in pairs(toLoadBrowsers) do 
            executeBrowserJavascript(Browser, js)
        end 
        toLoadBrowsers  = {}
    end)

    addEventHandler("onClientElementDestroy", root, function()
        if getElementType(source) == "better-browser" and browsers[source] and isElement(Browser) then 
            executeBrowserJavascript(Browser, "document.getElementById('"..browsers[source].id.."').remove();")
            browsers[source] = nil
        end     
    end)
    
    addEventHandler("onClientResourceStop", root, function(res)
        if elements_resources[res] and isElement(Browser) then
            for _, element in pairs(elements_resources[res]) do 
                if browsers[element] and isElement(element) then 
                    executeBrowserJavascript(Browser, "document.getElementById('"..browsers[element].id.."').remove();")
                    browsers[element] = nil
                end
            end 
        end 
    end)
end
addEventHandler("onClientResourceStart", resourceRoot, Constructor, false)

-- Exported --
function focusBrowser(theBrowser)
    assert(isElement(theBrowser), "Bad argument 1 @ createBrowser (browser-element expected, got " .. type(theBrowser) .. ")")

    if browsers[theBrowser] then 
        executeBrowserJavascript(Browser, [[
            var iframe = document.getElementById(']].. browsers[theBrowser].id ..[[');
            if (iframe) {
                iframe.focus();
            }
        ]])
    end
end

-- Exported --
function setBrowserProperty(theBrowser, properties) 
    assert(isElement(theBrowser), "Bad argument 1 @ createBrowser (browser-element expected, got " .. type(theBrowser) .. ")")
    assert(type(properties)=="table", "Bad argument 1 @ createBrowser (table expected, got " .. type(properties) .. ")")

    if browsers[theBrowser] then 
        if properties.zIndex then 
            assert(type(properties.zIndex)=="number", "Bad argument 1 @ createBrowser (number expected, got " .. type(properties) .. ")")

            executeBrowserJavascript(Browser, [[
                var iframe = document.getElementById(']].. browsers[theBrowser].id ..[[');
                if (iframe) {
                    iframe.style.zIndex = ']]..properties.zIndex..[[';
                }
            ]])
        end 
    end 
end

-- Exported --
function createBrowser(width, height)
    assert(tonumber(width), "Bad argument 1 @ createBrowser (number expected, got " .. type(width) .. ")")
    assert(tonumber(height), "Bad argument 2 @ createBrowser (number expected, got " .. type(height) .. ")")

    local newElement = createElement("better-browser")
    
    local newId = 1
    for _, browser in pairs(browsers) do 
        if browser.id >= newId then 
            newId = browser.id + 1
        end 
    end

    browsers[newElement] = {
        id = newId,
        width = width,
        height = height,
    }


    setElementParent(newElement, getResourceDynamicElementRoot(sourceResource))

    if not elements_resources[sourceResource] then 
        elements_resources[sourceResource] = {}
    end 
    elements_resources[#elements_resources+1] = newElement
    
    return newElement
end

local function readFile(path)
    local file = fileOpen(path) 
    if not file then
        return "" 
    end
    local count = fileGetSize(file) 
    local data = fileRead(file, count) 
    fileClose(file)
    return data
end   

-- Exported --
function loadBrowserFiles(theBrowser, files)
    assert(isElement(theBrowser) , "Bad argument 1 @ loadBrowserFiles (element expected, got " .. type(theBrowser) .. ")")
    assert(type(files)=="table", "Bad argument 2 @ loadBrowserFiles (table expected, got " .. type(files) .. ")")
    
    if not browsers[theBrowser] then 
        return false, 'invalid browser / create new one'
    end 

    local browser = browsers[theBrowser]
    local id, w, h = browser.id, browser.width,  browser.height
    local toLoad = {}

    if files.css then
        for _, cssFile in pairs(files.css) do
            local cssPath = ':'..getResourceName(sourceResource)..'/'..cssFile
            toLoad["css"] = (toLoad["css"] or "") .. readFile(cssPath):gsub("['\n\r]", {["'"] = "\\'", ["\n"] = "\\n", ["\r"] = "\\r"})
        end
    end

    if files.js then
        for _, jsFile in pairs(files.js) do
            local jsPath = ':'..getResourceName(sourceResource)..'/'..jsFile
            toLoad["js"] = (toLoad["js"] or "") .. readFile(jsPath):gsub("['\n\r]", {["'"] = "\\'", ["\n"] = "\\n", ["\r"] = "\\r"})
        end
    end
    

    local htmlFile = files.html

    local thePath = getResourceName(sourceResource)..'/'..htmlFile	
    if not fileExists (':'..thePath) then 
        outputDebugString(" invalid path provided for file: "..thePath,2)
    end 

    local jsCode = [[
        var iframe = document.createElement('iframe');
        iframe.setAttribute('id', ']].. id ..[['); 
        iframe.setAttribute('src', ']]..thePath..[[');
        iframe.setAttribute('width', ']]..w..[[');
        iframe.setAttribute('height', ']]..h..[[');
        iframe.setAttribute('frameborder', '0');

        iframe.style.position = 'absolute';
        iframe.style.left = '0px';
        iframe.style.top = '0px';

        iframe.onload = function() {
            //// CSS:
            var styleTag = document.createElement('style');
            styleTag.innerHTML = ']].. (toLoad["css"] or "") ..[[';
            iframe.contentDocument.body.appendChild(styleTag);

            //// JS:
            var script = iframe.contentDocument.createElement('script');
            script.textContent = ']].. (toLoad["js"] or "") ..[[';
            iframe.contentDocument.body.appendChild(script);

            mta.triggerEvent("better-browsers:loaded", ']].. id ..[[')
        };

        document.body.appendChild(iframe);
    ]]

    if browserLoaded then 
        executeBrowserJavascript(Browser, jsCode)
    else 
        toLoadBrowsers[id] = jsCode
    end 

    toLoad = {}
    return true 
end 

-- Exported --
function executeJavascript(theBrowser, js)
    assert(isElement(theBrowser) , "Bad argument 1 @ executeJavascript (element expected, got " .. type(theBrowser) .. ")")
    assert(type(js)=="string", "Bad argument 2 @ executeJavascript (string expected, got " .. type(js) .. ")")

    if not browsers[theBrowser] then 
        return false, 'invalid browser / create new one'
    end 

    local iframeId = browsers[theBrowser].id
    if iframeId then 
        executeBrowserJavascript(Browser,[[
            var iframe = document.getElementById(']]..iframeId..[[');
            if (iframe) {
                iframe.contentWindow.eval(`]]..js..[[`);
            }
        ]])    
    end 
end 

function toggleDevTools(bool)
    assert(type(bool)=="boolean", "Bad argument 2 @ toggleDevTools (boolean expected, got " .. type(bool) .. ")")

    if not getDevelopmentMode( ) then 
        return false
    end

    return toggleBrowserDevTools(Browser, bool)
end