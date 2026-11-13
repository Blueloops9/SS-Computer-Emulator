local code = 
[[box1'0'0'100'100'hello world!
X=CursorX
Y=CursorY
change1'X'Y
goto2
]]

local yewscript = require("yewscript")

local screen = require("screen")

screen:Hook(yewscript)

yewscript:Compile(code)

function love.update()
    yewscript:Step(3)
end