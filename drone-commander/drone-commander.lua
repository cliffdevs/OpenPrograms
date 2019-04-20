--Follow Script Client

-- Constants
local PORT_FOLLOW = 0xbf01
local EVENT_MODEM = 'modem_message'
local MESSAGE_POSITION_UPDATE = 'POS_UPDATE'
local MESSAGE_UPDATE_NODES = 'UPDATE_NODES'
local MAX_RANGE = 100
local SLEEP_TIME = 0.1

-- Required components
local component = require('component')
local event = require('event')
local os = require('os')
local modem = component.modem
local nav = component.navigation

modem.open(PORT_FOLLOW)

--[[
    Request for a drone to link up
--]]
local function findDrone()
    print('Searching for drone...')
    modem.broadcast(PORT_FOLLOW, 'FOLLOW_REQUEST_LINK')
    local _, _, sender, _, _, _ = event.pull(EVENT_MODEM, nil, nil, PORT_FOLLOW, nil, 'FOLLOW_LINK')
    print('Drone found', sender)
    return sender
end

local drone = findDrone()

--[[
    Respond to drone heartbeat requests to stay in sync
    @sender the sender of the network message
    @port the network port
    @message the message
--]]
local function heartbeatHook(sender, port, msg)
    if sender == drone and port == PORT_FOLLOW and msg == 'HEARTBEAT_REQUEST' then
        print('Responding to heartbeat request...', drone, port)
        modem.send(sender, port, 'HEARTBEAT_RESPONSE')
    end
end

--[[
    Hook to listen and respond to networked messages. Add all event listeners in this main listener.
    @sender the sender of the network message
    @port the network port
    @message the message
--]]
local function messageListener(_, _, sender, port, _, message)
    print('Network event received...')
    heartbeatHook(sender, port, message)
end

event.listen(EVENT_MODEM, messageListener)

modem.send(drone, PORT_FOLLOW, MESSAGE_POSITION_UPDATE)
local nodes = {select(7, event.pull(EVENT_MODEM, nil, drone, PORT_FOLLOW, nil, MESSAGE_UPDATE_NODES))}

--[[
    Search for a position node to provide to the drone to follow.
--]]
local function getNode()
    print('Discovering waypoint node...')
    local tbl = nav.findWaypoints(MAX_RANGE)
    for i = 1, tbl.n do
        local label = tbl[i].label
        for i2 = 1, #nodes do
            if label == nodes[i2] then
                return label, table.unpack(tbl[i].position)
            end
        end
    end
end

while true do
    local label, x, y, z = getNode()
    print('Sending position update...', label, x, y, z)
    modem.send(drone, PORT_FOLLOW, MESSAGE_POSITION_UPDATE, label, x, y, z)
    local args = {select(6, event.pull(EVENT_MODEM, nil, drone, PORT_FOLLOW, nil))}
    if table.remove(args, 1) == MESSAGE_UPDATE_NODES then
        nodes = args
    end
    os.sleep(SLEEP_TIME)
end
