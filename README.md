# BikeLife Queue System

A comprehensive and feature-rich queue system for FiveM servers with Discord integration, priority management, and advanced player handling.

## 🎯 Key Features

### 🏍️ Advanced Queue Management

- **Priority-based queuing** - Players with higher priority join first
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
4. **Start Resource**: Add `start bl-queue` to your server.cfg

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
exports['bl-queue']:getQueueCount()  -- Returns number of players in queue
exports['bl-queue']:isInQueue(source)  -- Check if player is queued
exports['bl-queue']:getQueueList()  -- Get all players in queue
```

### Advanced Functions

```lua
exports['bl-queue']:getPrioData(source)  -- Get player priority information
exports['bl-queue']:getQueueStats()  -- Get detailed queue statistics
exports['bl-queue']:addPriorityPoints(source, points)  -- Add priority points
exports['bl-queue']:removeFromQueue(source, reason)  -- Remove player from queue
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

### Queue Time Bonuses

Reward players for waiting in queue:

```lua
Config.QueueTimePoints = {
    enabled = true,
    pointsPerInterval = 1,  -- Points per interval
    intervalSeconds = 30    -- Award points every 30 seconds
}
```

## 🚨 Troubleshooting

### Common Issues

- **Discord integration not working**: Check bot token and permissions
- **Present cards not showing**: Verify `presentCard.json` is valid
- **Queue not processing**: Check server maxplayers setting
- **Players timing out**: Adjust timeout duration in config

### Debug Commands

Use `testmvc` console command to verify all system components are loaded correctly.

## 📈 Performance

- **Optimized queue processing** - Efficient algorithms for large queues
- **Memory management** - Automatic cleanup of disconnected players
- **Resource friendly** - Minimal impact on server performance
- **Scalable design** - Handles hundreds of concurrent queue entries

## 🔮 Future Enhancements

- Database integration for persistent statistics
- Web dashboard for queue monitoring
- Advanced priority algorithms
- Real-time position updates via events
- Player reservation system
- Multi-server queue synchronization

---

**Built for BikeLife by the BikeLife Development Team**
