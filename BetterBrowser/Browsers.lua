--[[
 / Script created by @xMD + Man
 / Discord (1xmd)

 # 2024/02/04 
 @ better browsers. 

 https://github.com/1Lorenzo-1/mta-browsers
]]

addEvent("better-browsers:loaded", true)
addEvent("better-browsers:page-loaded", true)
addEvent("onBrowserLoad", true)


local browserLoaded = false 
local screen = Vector2(guiGetScreenSize())
local Browser
local browsersCounts = 0
local browsers = {}
local elements_resources = {} 
local dxBrowser = createBrowser
local MTAFocus = focusBrowser
local toLoadBrowsers = {}

function Constructor()
    Browser = dxBrowser(screen.x,screen.y,true,true)

    addEventHandler('onClientBrowserLoadingFailed', Browser, function()
        Constructor()
    end)

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
    end)

    addEventHandler("onClientRender",root,function()
        dxDrawImage ( 0,0,screen.x,screen.y, Browser,0,0,0, tocolor(255,255,255), true)
    end)

    addEventHandler("onClientClick", root,function(button, state)
        if state == "down" then
            injectBrowserMouseDown(Browser, button)
        else
            injectBrowserMouseUp(Browser, button)
        end 
    end)

    addEventHandler("onClientKey", root, function(button)
        if button == "mouse_wheel_down" then
            injectBrowserMouseWheel(Browser, -40, 0)
        elseif button == "mouse_wheel_up" then
            injectBrowserMouseWheel(Browser, 40, 0)
        end
    end)

    addEventHandler("onClientCursorMove", root,function (relativeX, relativeY, absoluteX, absoluteY)
        injectBrowserMouseMove(Browser, absoluteX, absoluteY)
    end)

    addEventHandler("better-browsers:loaded", root,function (id)
        for element, loaded in pairs(browsers) do 
            if tonumber(loaded.id) == tonumber(id) then 
                if isElement(element) then 
                    triggerEvent("onBrowserLoad", element)
                end 
                break
            end 
        end 
    end)

    addEventHandler("better-browsers:page-loaded", root,function ()
        browserLoaded = true
    
        for id, js in pairs(toLoadBrowsers) do 
            executeBrowserJavascript(Browser, js)
    
            for element, loaded in pairs(browsers) do 
                if tonumber(loaded.id) == tonumber(id) then 
                    if isElement(element) then 
                        triggerEvent("onBrowserLoad", element)
                    end 
                    break
                end 
            end 
        end 
        toLoadBrowsers  = {}
    end)
end

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

function setBrowserProperty(theBrowser, propertys) 
    assert(isElement(theBrowser), "Bad argument 1 @ createBrowser (browser-element expected, got " .. type(theBrowser) .. ")")
    assert(type(propertys)=="table", "Bad argument 1 @ createBrowser (table expected, got " .. type(propertys) .. ")")

    if browsers[theBrowser] then 
        if propertys and propertys.zIndex then 
            assert(type(propertys.zIndex)=="number", "Bad argument 1 @ createBrowser (number expected, got " .. type(propertys) .. ")")

            executeBrowserJavascript(Browser, [[
                var iframe = document.getElementById(']].. browsers[theBrowser].id ..[[');
                if (iframe) {
                    iframe.style.zIndex = ']]..propertys.zIndex..[[';
                }
            ]])
        end 
    end 
end

function readFile(path)
    local file = fileOpen(path) 
    if not file then
        return "" 
    end
    local count = fileGetSize(file) 
    local data = fileRead(file, count) 
    fileClose(file)
    return data
end

function createBrowser(width, height)
    assert(tonumber(width), "Bad argument 1 @ createBrowser (number expected, got " .. type(width) .. ")")
    assert(tonumber(height), "Bad argument 2 @ createBrowser (number expected, got " .. type(height) .. ")")

    local newElement = createElement("better-browser")
    browsersCounts = browsersCounts + 1

    browsers[newElement] = {
        id = browsersCounts,
        width = width,
        height = height,
    }


    setElementParent(newElement,getResourceDynamicElementRoot(sourceResource) )

    if not elements_resources[sourceResource] then 
        elements_resources[sourceResource] = {}
    end 
    table.insert(elements_resources[sourceResource], newElement)
    
    return newElement
end     

function loadBrowserFiles(theBrowser, files)
    assert(isElement(theBrowser) , "Bad argument 1 @ loadBrowserFiles (element expected, got " .. type(theBrowser) .. ")")
    
    if not browsers[theBrowser] then 
        return false, 'invalid browser / create new one'
    end 

    local browser = browsers[theBrowser]
    local id, w, h = browser.id, browser.width,  browser.height
    local toLoad = {}

    if files.css then
        for _, cssFile in ipairs(files.css) do
            local cssPath = ':'..getResourceName(sourceResource)..'/'..cssFile
            toLoad["css"] = (toLoad["css"] or "") .. readFile(cssPath):gsub("['\n\r]", {["'"] = "\\'", ["\n"] = "\\n", ["\r"] = "\\r"})
        end
    end

    if files.js then
        for _, jsFile in ipairs(files.js) do
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

function executeJavascript(theBrowser, js)
    assert(isElement(theBrowser) , "Bad argument 1 @ executeJavascript (element expected, got " .. type(theBrowser) .. ")")
    assert(type(js)=="string", "Bad argument 2 @ executeJavascript (string expected, got " .. type(js) .. ")")

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

addEventHandler("onClientElementDestroy", getRootElement(), function ()
	if getElementType(source) == "better-browser" and browsers[source] and isElement(Browser) then 
        executeBrowserJavascript(Browser, "document.getElementById('"..browsers[source].id.."').remove();")
        browsers[source] = nil
    end     
end)

addEventHandler("onClientResourceStop", root, function(res)
    if elements_resources[res] and isElement(Browser) then
        for _, element in ipairs(elements_resources[res]) do 
            if browsers[element] and isElement(element) then 
                executeBrowserJavascript(Browser, "document.getElementById('"..browsers[element].id.."').remove();")
                browsers[element] = nil
            end   
        end 
    end 
end)



addEventHandler("onClientResourceStart", resourceRoot, Constructor)