Queue = {}
Queue.__index = Queue

-- Constructor
function Queue.new()
    local self = setmetatable({}, Queue)
    self.players = {}
    self.connectingPlayers = {}
    self.reconnectList = {}
    self.joinDelay = {}
    return self
end

-- Add player to queue
function Queue:addPlayer(player)
    -- Check if player is already in queue
    if self:isPlayerInQueue(player.source) then
        -- Update existing entry
        local existingPlayer = self:getPlayer(player.source)
        if existingPlayer then
            existingPlayer:setDeferrals(player.deferrals)
            existingPlayer:updateActivity()
            return false, "Player already in queue"
        end
    end

    -- Insert player based on priority
    local inserted = false
    for i = 1, #self.players do
        if self.players[i].priority < player.priority then
            table.insert(self.players, i, player)
            inserted = true
            break
        end
    end

    if not inserted then table.insert(self.players, player) end

    return true, "Player added to queue"
end

-- Remove player from queue
function Queue:removePlayer(source, reason)
    for i = #self.players, 1, -1 do
        if self.players[i].source == source then
            local player = table.remove(self.players, i)
            return player, reason or "Unknown"
        end
    end
    return nil, "Player not found"
end

-- Get player by source
function Queue:getPlayer(source)
    for _, player in ipairs(self.players) do
        if player.source == source then return player end
    end
    return nil
end

-- Check if player is in queue
function Queue:isPlayerInQueue(source) return self:getPlayer(source) ~= nil end

-- Get player position in queue
function Queue:getPlayerPosition(source)
    for i = 1, #self.players do
        if self.players[i].source == source then return i end
    end
    return 0
end

-- Get queue size
function Queue:getSize() return #self.players end

-- Get next player to connect
function Queue:getNextPlayer()
    if #self.players > 0 then return self.players[1] end
    return nil
end

-- Move player to connecting state
function Queue:moveToConnecting(source)
    local player = self:removePlayer(source, "Connecting")
    if player then
        self.connectingPlayers[source] = player
        return player
    end
    return nil
end

-- Remove from connecting state
function Queue:removeFromConnecting(source)
    if self.connectingPlayers[source] then
        self.connectingPlayers[source] = nil
        return true
    end
    return false
end

-- Get all players as table
function Queue:getAllPlayers()
    local result = {}
    for i, player in ipairs(self.players) do
        table.insert(result, {
            position = i,
            name = player.name,
            priority = player.priority,
            joinTime = player.joinTime,
            timeInQueue = player:getTimeInQueue()
        })
    end
    return result
end

-- Clean up disconnected players
function Queue:cleanup()
    local cleanedPlayers = {}
    local removedCount = 0

    for _, player in ipairs(self.players) do
        if player:isConnected() then
            table.insert(cleanedPlayers, player)
        else
            removedCount = removedCount + 1
        end
    end

    self.players = cleanedPlayers

    -- Clean up connecting players
    for source, _ in pairs(self.connectingPlayers) do
        if not GetPlayerName(source) then
            self.connectingPlayers[source] = nil
        end
    end

    return removedCount
end

-- Update queue time points for all players
function Queue:updateQueueTimePoints()
    if not Config.QueueTimePoints.enabled then return end

    local pointsAwarded = false
    for _, player in ipairs(self.players) do
        local awarded = player:calculateQueueTimePoints()
        if awarded > 0 then
            pointsAwarded = true
        end
    end

    -- Re-sort queue if any player gained points
    if pointsAwarded then
        table.sort(self.players, function(a, b) 
            return a.priority > b.priority 
        end)
    end
end

-- Check for timed out players
function Queue:checkTimeouts()
    local timedOutPlayers = {}

    for i = #self.players, 1, -1 do
        local player = self.players[i]
        if player:hasTimedOut() then
            table.insert(timedOutPlayers, table.remove(self.players, i))
        end
    end

    return timedOutPlayers
end

-- Add reconnect data
function Queue:addReconnectData(steamId, playerName)
    if Config.ReconnectPrio.enabled then
        self.reconnectList[steamId] = {
            disconnectTime = os.time(),
            playerName = playerName
        }
    end
end

-- Check and remove expired reconnect data
function Queue:checkReconnectPriority(steamId)
    if not Config.ReconnectPrio.enabled or not self.reconnectList[steamId] then
        return 0
    end

    local reconnectData = self.reconnectList[steamId]
    if os.time() - reconnectData.disconnectTime <=
        Config.ReconnectPrio.timeLimit then
        return Config.ReconnectPrio.extraPoints
    else
        self.reconnectList[steamId] = nil
        return 0
    end
end

-- Anti-spam protection
function Queue:checkAntiSpam(steamId)
    if not Config.AntiSpam.enabled then return true end

    if steamId and self.joinDelay[steamId] then
        local timeSinceLastTry = (os.time() * 1000) - self.joinDelay[steamId]
        if timeSinceLastTry < Config.AntiSpam.joinDelay then
            return false, Config.AntiSpam.joinDelay - timeSinceLastTry
        end
    end

    if steamId then self.joinDelay[steamId] = os.time() * 1000 end

    return true
end

-- Get queue statistics
function Queue:getStatistics()
    return {
        queueSize = #self.players,
        connectingCount = self:getConnectingCount(),
        totalProcessed = self:getTotalProcessed(),
        averageWaitTime = self:getAverageWaitTime()
    }
end

-- Get connecting players count
function Queue:getConnectingCount()
    local count = 0
    for _ in pairs(self.connectingPlayers) do count = count + 1 end
    return count
end

-- Calculate average wait time (placeholder implementation)
function Queue:getAverageWaitTime()
    if #self.players == 0 then return 0 end

    local totalTime = 0
    for _, player in ipairs(self.players) do
        totalTime = totalTime + player:getTimeInQueue()
    end

    return math.floor(totalTime / #self.players)
end

-- Get total processed (placeholder - would need persistent storage)
function Queue:getTotalProcessed()
    return 0 -- This would be tracked in a database in a real implementation
end
