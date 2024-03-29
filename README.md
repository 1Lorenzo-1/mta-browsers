# BetterBrowser Script for MTA:SA
`Created by 1Lorenzo + Man`

Too many browsers can eat up **memory** quickly! 

With this script;
`1` Browser is enough for everything 😉

## Exmaple usage: 
`lua code:`
```lua
-- Create a browser instance with dimensions 1920x1080
local theBrowser = exports.BetterBrowser:createBrowser(1920, 1080)

-- Load files into the browser, including HTML, CSS, and JavaScript
exports.BetterBrowser:loadBrowserFiles(theBrowser, {
    html="index.html", -- Load a single HTML file
    css={"style.css","more.css?"}, -- Load one or more CSS files
    js={"alert.js","more.css?"}    -- Load one or more JavaScript files
    -- Note: Including CSS/JS files here may impact performance; consider embedding in HTML
})

-- Add an event to know when the browser is fully loaded
-- Important: The function (exports.BetterBrowser:executeJavascript) won't work correctly until the browser has loaded.
addEventHandler("onBrowserLoad", theBrowser, function()
    iprint("The browser has been loaded!")

    -- Set the browser's z-index. Sometimes, elements that are obscured by other elements in HTML (e.g., a button behind an image) cannot be accessed. Setting the z-index higher ensures proper interaction.
     exports.BetterBrowser:setBrowserProperty(theBrowser, {
         zIndex=999,
      })
end)


-- Example event triggered when a button is clicked, changing its text to 'pressed'
addEvent("pressed_the_button", true)
addEventHandler("pressed_the_button", root, function()
    -- Execute JavaScript code in the browser to change button text when clicked
    exports.BetterBrowser:executeJavascript(theBrowser, [[
        document.getElementById("theButton").innerHTML = "pressed"
    ]])
end)

```

`html file:`
```html

<!DOCTYPE html>
<html lang="en" >
   <head>
      <meta charset="UTF-8">
      <link rel="stylesheet" href="your_css_file.css">
      <script src="your_js_file.js"></script>
   </head>
   <body>
      <a id='theButton' onclick='mta.triggerEvent("pressed_the_button")' href="#">Press me!</a>
   </body>

</html>

```
