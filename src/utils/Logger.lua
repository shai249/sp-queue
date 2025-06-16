Logger = {}

-- Log levels
Logger.LEVELS = {ERROR = 1, WARN = 2, INFO = 3, DEBUG = 4}

-- Current log level (can be configured)
Logger.currentLevel = Config.Debug and Logger.LEVELS.DEBUG or Logger.LEVELS.INFO

-- Format log message with timestamp and level
local function formatMessage(level, message)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    return string.format("[%s] [%s] %s", timestamp, level, message)
end

-- Generic log function
local function log(level, levelName, color, message)
    if Logger.currentLevel >= level then
        local formattedMessage = formatMessage(levelName, message)
        print(string.format("^%s[%s Queue]^0 %s", color, Config.ServerName, formattedMessage))
    end
end

-- Error logging (red)
function Logger.error(message) log(Logger.LEVELS.ERROR, "ERROR", "1", message) end

-- Warning logging (yellow)
function Logger.warn(message) log(Logger.LEVELS.WARN, "WARN", "3", message) end

-- Info logging (green)
function Logger.info(message) log(Logger.LEVELS.INFO, "INFO", "2", message) end

-- Debug logging (blue)
function Logger.debug(message) log(Logger.LEVELS.DEBUG, "DEBUG", "4", message) end

-- Set log level
function Logger.setLevel(level) Logger.currentLevel = level end

-- Log player action
function Logger.playerAction(source, action, details)
    local playerName = GetPlayerName(source) or "Unknown"
    local message = string.format("Player %s [%d] %s", playerName, source,
                                  action)
    if details then message = message .. " - " .. details end
    Logger.info(message)
end

-- Log queue operation
function Logger.queueOperation(operation, details)
    local message = string.format("Queue %s", operation)
    if details then message = message .. " - " .. details end
    Logger.info(message)
end

-- Log system event
function Logger.system(event, details)
    local message = string.format("System %s", event)
    if details then message = message .. " - " .. details end
    Logger.info(message)
end
