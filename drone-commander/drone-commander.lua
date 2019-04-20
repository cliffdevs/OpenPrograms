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
local droneUtilities = require('lib.drone-functions')

modem.open(PORT_FOLLOW)

local drone = droneUtilities.findDrone()

--[[
    Hook to listen and respond to networked messages. Add all event listeners in this main listener.
    @sender the sender of the network message
    @port the network port
    @message the message
--]]
local function messageListener(_, _, sender, port, _, message)
    print('Network event received...')
    droneUtilities.heartbeatHook(sender, port, message)
end

event.listen(EVENT_MODEM, messageListener)

modem.send(drone, PORT_FOLLOW, MESSAGE_POSITION_UPDATE)
local nodes = {select(7, event.pull(EVENT_MODEM, nil, drone, PORT_FOLLOW, nil, MESSAGE_UPDATE_NODES))}


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
