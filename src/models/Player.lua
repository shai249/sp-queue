Player = {}
Player.__index = Player

-- Constructor
function Player.new(source, name, priority)
    local self = setmetatable({}, Player)
    self.source = source
    self.name = name
    self.priority = priority or Config.DefaultInfo.defaultPriority
    self.joinTime = os.time()
    self.lastUpdate = os.time()
    self.queueTimePoints = 0
    self.deferrals = nil
    self.isDirect = false
    self.reconnectData = nil
    return self
end

-- Update last activity timestamp
function Player:updateActivity() self.lastUpdate = os.time() end

-- Check if player has timed out
function Player:hasTimedOut()
    local currentTime = os.time()
    return currentTime - self.lastUpdate > (Config.TimeoutDuration / 1000)
end

-- Get time spent in queue
function Player:getTimeInQueue() return os.time() - self.joinTime end

-- Calculate queue time bonus points
function Player:calculateQueueTimePoints()
    if not Config.QueueTimePoints.enabled then return 0 end

    local timeInQueue = self:getTimeInQueue()
    local expectedPoints = math.floor(timeInQueue /
                                          Config.QueueTimePoints.intervalSeconds) *
                               Config.QueueTimePoints.pointsPerInterval

    local pointsToAward = expectedPoints - self.queueTimePoints
    if pointsToAward > 0 then
        self.queueTimePoints = expectedPoints
        self.priority = self.priority + pointsToAward
        return pointsToAward
    end

    return 0
end

-- Get player identifiers
function Player:getIdentifiers() return GetPlayerIdentifiers(self.source) end

-- Get specific identifier by type
function Player:getIdentifier(type)
    local identifiers = self:getIdentifiers()
    for _, id in ipairs(identifiers) do
        if string.find(id, type .. ":") then
            return string.gsub(id, type .. ":", "")
        end
    end
    return nil
end

-- Get Steam ID
function Player:getSteamId() return self:getIdentifier("steam") end

-- Get Discord ID
function Player:getDiscordId() return self:getIdentifier("discord") end

-- Set deferrals object
function Player:setDeferrals(deferrals) self.deferrals = deferrals end

-- Check if player is still connected
function Player:isConnected() return GetPlayerName(self.source) ~= nil end

-- Convert to table for serialization
function Player:toTable()
    return {
        source = self.source,
        name = self.name,
        priority = self.priority,
        joinTime = self.joinTime,
        lastUpdate = self.lastUpdate,
        queueTimePoints = self.queueTimePoints,
        isDirect = self.isDirect
    }
end
