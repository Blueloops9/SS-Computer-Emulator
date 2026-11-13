local screen = {}


screen.Instructions, screen.Keywords = {}, {}

screen.Mouse = {0, 0}

screen.Objects = {}

screen.ScreenSize = {300, 225}
screen.RealScreenSize = {300, 225}
screen.ScaleMonitor = true

screen.Colors = require("colors")

screen.UseRobloxAssets = true

local https = require("https")

function screen.setColor(color)
    return love.graphics.setColor(love.math.colorFromBytes(color))
end

screen.ImagesLoading = {}
screen.Images = {}

local cookies

function screen.getCookies()
    File = io.open("cookies.txt", "r")

    if File then
        cookies = File:read("*a")
        File:close()
    else
        error("Cookies.txt is not found, please one!")
    end
end


function screen.getImage(imageId)
    if screen.Images[imageId] then return screen.Images[imageId] end

    local path = "assets/"..imageId..".png"

    screen.ImagesLoading[imageId] = true
    if love.filesystem.getInfo(path) then
        screen.Images[imageId] = love.graphics.newImage(path)
        screen.ImagesLoading[imageId] = false
    elseif screen.UseRobloxAssets then
        local link = "https://assetdelivery.roblox.com/v1/asset/?id="..imageId

        local co = coroutine.create(function()
            if not cookies then screen.getCookies() end
            
            local status, data, headers = https.request(link, {headers={
                Cookie = cookies
            }})

            if status == 200 then

                local encoding = headers["content-encoding"]
                local decodedData
                if encoding == "gzip" or encoding == " gzip" then
                    decodedData = love.data.decompress("string", "gzip", data)
                else
                    decodedData = data
                end
                
                local File = io.open(path, "wb")

                if File then
                    File:write(decodedData)
                    File:close()
                end

                screen.Images[imageId] = love.graphics.newImage(path)
                screen.ImagesLoading[imageId] = false
            else
                print(status, data)
            end
        end)

        coroutine.resume(co)
    end
end

function screen.Instructions.box() return function(id, posX, posY, sizeX, sizeY, text, backcolor, color)
    screen.Objects[id] = {
        posX or 0, posY or 0, sizeX or 50, sizeY or 50, text, backcolor or 1, color or 1003
    }
    screen.Objects[id].type = "box"
end end

function screen.Instructions.imgbox() return function(id, posX, posY, sizeX, sizeY, imageid, backcolor, color)
    screen.Objects[id] = {
        posX or 0, posY or 0, sizeX or 50, sizeY or 50, imageid, backcolor or 1, color or 1
    }
    screen.Objects[id].type = "imgbox"
end end

function screen.Instructions.change() return function(id, posX, posY, sizeX, sizeY, value, backcolor, color)
    local object = screen.Objects[id]
    if object then
        local type = screen.Objects[id].type
        screen.Objects[id] = {
            posX or object[1],
            posY or object[2],
            sizeX or object[3],
            sizeY or object[4],
            value or object[5],
            backcolor or object[6],
            color or object[7]
        }

        screen.Objects[id].type = type
    end
end end

function screen.Instructions.delete() return function(id)
    screen.Objects[id] = nil
end end

function screen.Instructions.cursor() return function(id)
    error("The 'cursor' instruction is not implemented, dm blueloops9 if you know how it was implemented")
end end

function screen.Keywords.CursorX()
    return screen.Mouse[1]
end

function screen.Keywords.CursorY()
    return screen.Mouse[2]
end

function screen.Keywords.Touch2D(id)
    local o, touching = screen.Objects[id], {}

    for index, v in pairs(screen.Objects) do
        if o ~= v then
            if
                o[1] <= v[1]+v[3] and
                o[1] >= v[1] and
                o[2] <= v[2]+v[4] and
                o[2] >= v[2] then
                
                table.insert(touching, index)
            end
        end
    end

    return touching
end


function screen:Hook(yewscript)
    for i, v in pairs(screen.Instructions) do yewscript.Instructions[i] = v end
    for i, v in pairs(screen.Keywords) do yewscript.Keywords[i] = v end
end

function love.mousemoved(x, y)
    local size = screen.RealScreenSize

    local screenSize = screen.ScaleMonitor and screen.ScreenSize or size

    screen.Mouse = {x/size[1]*screenSize[1], y/size[2]*screenSize[2]}
end

local font = love.graphics.newFont(12, "normal", 2)


function love.draw()
    local sizeX, sizeY = love.graphics.getDimensions()

    screen.RealScreenSize = {sizeX, sizeY}
    if screen.ScaleMonitor then
        love.graphics.scale(sizeX/screen.ScreenSize[1], sizeY/screen.ScreenSize[2])
    end

    local sorting = {}

    for i, v in pairs(screen.Objects) do
        table.insert(sorting, {i, v})
    end

    table.sort(sorting, function(a, b)return a[1] < b[1] end)

    for _, object in pairs(sorting) do
        local object = object[2]

        screen.setColor(screen.Colors[object[6]])

        love.graphics.rectangle("fill", object[1], object[2], object[3], object[4])

        screen.setColor(screen.Colors[object[7]])
        if object.type == "box" then
            local textwidth, textheight = font:getWidth(object[5]), font:getHeight()

            love.graphics.print(
                object[5],
                font,
                object[1]+object[3]/2-textwidth/2,
                object[2]+object[4]/2-textheight/2
            )
        elseif object.type == "imgbox" then
            if not screen.ImagesLoading[object[5]] then
                screen.getImage(object[5])

                local image = screen.Images[object[5]]
                if image then
                    local w, h = image:getDimensions()
                    love.graphics.draw(image, object[1],object[2], 0, object[3]/w, object[4]/h)
                end
            end
        end
    end
end

return screen