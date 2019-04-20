--[[
    Drone Functions

    This module provides useful Drone application functionality.
--]]

local droneUtilities = {}

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

--[[
    Request for a drone to link up.
--]]
function findDrone()
    print('Searching for drone...')
    modem.broadcast(PORT_FOLLOW, 'FOLLOW_REQUEST_LINK')
    local _, _, sender, _, _, _ = event.pull(EVENT_MODEM, nil, nil, PORT_FOLLOW, nil, 'FOLLOW_LINK')
    print('Drone found', sender)
    return sender
end

--[[
    Respond to drone heartbeat requests to stay in sync
    @sender the sender of the network message
    @port the network port
    @message the message
--]]
function heartbeatHook(sender, port, msg)
    if sender == drone and port == PORT_FOLLOW and msg == 'HEARTBEAT_REQUEST' then
        print('Responding to heartbeat request...', drone, port)
        modem.send(sender, port, 'HEARTBEAT_RESPONSE')
    end
end

--[[
    Search for a position node to provide to the drone to follow.
--]]
local function getNodeFromWaypoint()
    print('Discovering waypoint node...')
    local tbl = nav.findWaypoints(MAX_RANGE)
    if tbl.n >= 1 then
        local label = tbl[1].label
        return label, table.unpack(tbl[1].position)
    end

    print('Unable to find node')
end

function follow()
    modem.open(PORT_FOLLOW)
end

return droneUtilities