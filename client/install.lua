-- Define the WebSocket server URL
local serverUrl = "ws://localhost:8080"

-- Create a WebSocket connection
local ws, err = http.websocket(serverUrl)

-- Check if the connection was successful
if not ws then
    print("Failed to connect to WebSocket server: " .. err)
    return
end

-- Function to handle incoming messages
local function handleMessage(message)
    print("Received message: " .. message)
end

-- Register the message handler
ws.onMessage(handleMessage)

-- Send a message to the server
ws.send("Hello from ComputerCraft!")

-- Wait for messages and handle them
while true do
    ws.pullEvent("websocket_message")
end
