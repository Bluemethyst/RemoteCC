local rs = peripheral.find("rsBridge")
local monitor = peripheral.find("monitor")
local ws = http.websocket("ws://127.0.0.1:8000/ws")
local stored_items = {}
local start_time = os.epoch("local")
local websocket_conn = false
monitor.clear()
monitor.setCursorPos(1, 1)
monitor.setTextScale(0.5)

print("[DEBUG]: Starting script")
if ws then
    print("[DEBUG]: Websocket connected")
    local start_socket = {
        to = "remote_storage_client",
        from = "remote_storage_cc",
        data = {
            message = "Connection successful",
            name = os.getComputerLabel(),
            id = os.getComputerID()
        }
    }
    websocket_conn = true
    ws.send(textutils.serializeJSON(start_socket))
else
    print("[DEBUG]: Websocket failed to connect, disabling")
    websocket_conn = false
end

function MoveCursor()
    local _, y = monitor.getCursorPos()
    local _, h = monitor.getSize()
    if y >= h then
        monitor.scroll(1)
        monitor.setCursorPos(1, y)
    else
        monitor.setCursorPos(1, y + 1)
    end
end

function Remove(info)
    monitor.setTextColor(colors.red)
    monitor.write(info)
    print("[DEBUG]: " .. info)
    local current_time = os.epoch("local")
    if websocket_conn and (current_time - start_time) / 1000 >= 2 then
        local socket_data = {
            to = "remote_storage_client",
            from = "remote_storage_cc",
            data = {
                message = info,
                type = "remove",
                name = os.getComputerLabel(),
                id = os.getComputerID()
            }
        }
        ws.send(textutils.serializeJSON(socket_data))
    end
    monitor.setTextColor(colors.white)
end

function Add(info)
    monitor.setTextColor(colors.green)
    monitor.write(info)
    print("[DEBUG]: " .. info)
    local current_time = os.epoch("local")
    if websocket_conn and (current_time - start_time) / 1000 >= 2 then
        local socket_data = {
            to = "remote_storage_client",
            from = "remote_storage_cc",
            data = {
                message = info,
                type = "add",
                name = os.getComputerLabel(),
                id = os.getComputerID()
            }
        }
        ws.send(textutils.serializeJSON(socket_data))
    end
    monitor.setTextColor(colors.white)
end

function Craft(info)
    monitor.setTextColor(colors.yellow)
    monitor.write(info)
    print("[DEBUG]: " .. info)
    local current_time = os.epoch("local")
    if websocket_conn and (current_time - start_time) / 1000 >= 2 then
        local socket_data = {
            to = "remote_storage_client",
            from = "remote_storage_cc",
            data = {
                message = info,
                type = "craft",
                name = os.getComputerLabel(),
                id = os.getComputerID()
            }
        }
        ws.send(textutils.serializeJSON(socket_data))
    end
    monitor.setTextColor(colors.white)
end

while true do
    local items = rs.listItems()
    local current_items = {}
    for _, i in pairs(items) do
        current_items[i.name] = i
        if not stored_items[i.name] then
            local str = "+ " .. i.name .. " (Amount: " .. i.amount .. ")"
            Add(str)
            MoveCursor()
        elseif stored_items[i.name].amount < i.amount then
            local str = "+ " .. i.name .. " (Amount: " .. (i.amount - stored_items[i.name].amount) .. ")"
            Add(str)
            MoveCursor()
        end
    end

    for name, item in pairs(stored_items) do
        if not current_items[name] then
            local str = "- " .. name .. " (Amount: " .. item.amount .. ")"
            Remove(str)
            MoveCursor()
        elseif stored_items[name].amount > current_items[name].amount then
            local str = "- " .. name .. " (Amount: " .. (stored_items[name].amount - current_items[name].amount) .. ")"
            Remove(str)
            MoveCursor()
        end
    end
    local message = ws.receive()
    if message then
        local response = textutils.unserializeJSON(message)
        print("[DEBUG]: " .. response.data.message)
        if response.data.message == "craft" then
            local str = response.data.name
            Craft(str)
            MoveCursor()
        end
    end

    stored_items = current_items
    os.sleep(1)
end
