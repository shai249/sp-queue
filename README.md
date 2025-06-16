# S1hk0P1k0's Queue System

A comprehensive and feature-rich queue system for FiveM servers with Discord integration, priority management, and advanced player handling.

## 🎯 Key Features

### ⚙️ Advanced Queue Management

- **Priority-based queuing** - Players with higher priority points join first
- **Smart position management** - Automatic queue sorting and optimization
- **Queue time bonuses** - Players earn priority points for time spent waiting
- **Reconnect priority** - Players who disconnect get temporary priority when reconnecting
- **Anti-spam protection** - Prevents rapid connection attempts

### 🔗 Discord Integration

- **Role-based priorities** - Assign priority points based on Discord roles
- **Server membership validation** - Require Discord server membership to join
- **Avatar integration** - Display player Discord avatars in queue cards
- **Webhook notifications** - Real-time queue events sent to Discord channels

### 🎨 Present Card System

- **Beautiful queue display** - Custom present cards showing player info and queue position
- **Real-time updates** - Live queue position and wait time updates
- **Player information** - Shows avatar, name, priority points, and role status
- **Customizable templates** - Easy to modify present card appearance

### 🛡️ Player Validation

- **Identifier verification** - Ensure players have required identifiers (Steam, Discord)
- **Connection security** - Validate player credentials before queue entry
- **Timeout handling** - Automatic removal of inactive players
- **Connection state management** - Track players through connection process

### 📊 Monitoring & Statistics

- **Real-time statistics** - Track queue performance and player metrics
- **Detailed logging** - Comprehensive logging system with multiple levels
- **Health monitoring** - System status and performance tracking
- **Admin oversight** - Complete visibility into queue operations

## 🚀 Quick Setup

1. **Installation**: Place the resource in your FiveM resources folder
2. **Configuration**: Edit `config.lua` with your Discord bot token and server settings
3. **Discord Setup**: Configure your Discord bot and webhook URLs
4. **Ensure Resource**: Add `ensure sp-queue` to your server.cfg

## ⚙️ Configuration

### Discord Settings

```lua
Config.Discord = {
    enabled = true,
    guildId = 'YOUR_DISCORD_SERVER_ID',
    botToken = 'YOUR_BOT_TOKEN',
    requireServerMembership = true,
    roles = {
        ["ROLE_ID"] = { name = "VIP", points = 100 },
        -- Add more roles with their priority points
    }
}
```

### Queue Settings

```lua
Config.QueueUpdateRate = 2000  -- How often to update queue (ms)
Config.TimeoutDuration = 300000  -- Player timeout duration (ms)
Config.JoinDelay = 1000  -- Delay before processing connection (ms)
```

### Priority System

Players with the most priority points are placed first in the queue. The queue dynamically reorders as players gain points. Points can be earned through:
- Discord roles (configured per role)
- Time spent waiting in queue (players move up as they gain points)
- Reconnecting after disconnection

```lua
Config.QueueTimePoints = {
    enabled = true,
    pointsPerInterval = 1,  -- Points given per interval
    intervalSeconds = 2     -- How often to award points
}
```

## 🎮 Admin Commands

- `queue` - Show current queue status and all players
- `clearqueue` - Remove all players from queue
- `queuestats` - Display detailed queue statistics
- `reloadtemplate` - Reload the present card template
- `setpriority <player_id> <priority>` - Manually set player priority
- `kickqueue <player_id> [reason]` - Remove specific player from queue

## 📱 API Exports

### Basic Queue Information

```lua
exports['sp-queue']:getQueueCount()  -- Returns number of players in queue
exports['sp-queue']:isInQueue(source)  -- Check if player is queued
exports['sp-queue']:getQueueList()  -- Get all players in queue
```

### Advanced Functions

```lua
exports['sp-queue']:getPrioData(source)  -- Get player priority information
exports['sp-queue']:getQueueStats()  -- Get detailed queue statistics
exports['sp-queue']:addPriorityPoints(source, points)  -- Add priority points
exports['sp-queue']:removeFromQueue(source, reason)  -- Remove player from queue
```

## 🎨 Customization

### Present Card Template

Edit `presentCard.json` to customize the queue display:

- Player information layout
- Colors and styling
- Background images
- Text and messaging

### Language Support

Modify `lang.lua` to change all player-facing messages:

- Connection messages
- Error messages
- Queue status text
- Role descriptions

### Webhook Notifications

Configure Discord webhooks for different events:

- Player joins/leaves queue
- System status updates
- Admin actions
- Error notifications

## 🔧 Advanced Features

### Reconnect Priority System

Players who disconnect get temporary priority when reconnecting:

```lua
Config.ReconnectPrio = {
    enabled = true,
    timeLimit = 300,  -- 5 minutes to reconnect
    extraPoints = 50  -- Bonus priority points
}
```

### Anti-Spam Protection

Prevents rapid connection attempts:

```lua
Config.AntiSpam = {
    enabled = true,
    joinDelay = 10000  -- 10 seconds between attempts
}
```

## 🚨 Troubleshooting

### Common Issues

- **Discord integration not working**: Check bot token and permissions
- **Present cards not showing**: Verify `presentCard.json` is valid
- **Queue not processing**: Check server maxplayers setting
- **Players timing out**: Adjust timeout duration in config

---

**Built by S1hk0P1k0 - Sh1k0P1k0's Queue System Solutions**