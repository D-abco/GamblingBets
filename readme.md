# What is GamblingBets?

GamblingBets is a Balatro mod that adds a casino-style betting system to the shop. You can wager your money on predicting what poker hand you'll play in the next round, with payouts based on hand difficulty and betting odds.

## How It Works

### Betting System

- **Shop Integration**: Betting controls are built into the shop interface
- **Hand Selection**: Choose from 3 randomly generated poker hands each shop visit
- **Bet Amount**: Wager $5 minimum up to all your money
- **Payout Odds**: Dynamic odds from 1:1 to 3.5:1 based on difficulty

### How payout works

Payout is determined by your earnings + your base bet
Your earnings are determined by the following formula:

```earnings = (bet/ratio) + bet```

What this would look like if you were to bet $20 on Two Pair

```earnings = (20/2.5) + 20```
```earnings = 28```
In the case of a decimal, which we would get above integers are rounded *UP*


### Available Hands & Payouts

| Hand Type | Payout Ratio | Max Payout | Winning Conditions |
|-----------|--------------|------------|-------------------|
| Two Pair | 2.5:1 | $25 | Two Pair, Full House, Four of a Kind |
| Three of a Kind | 2:1 | $25 | Three of a Kind, Full House, Four of a Kind |
| Straight | 1.8:1 | $50 | Straight, Straight Flush, Royal Flush |
| Flush | 1.5:1 | $50 | Flush, Flush House, Straight Flush, Royal Flush, Flush Five |
| Full House | 1.3:1 | $50 | Full House, Flush House |
| Four of a Kind | 1.1:1 | $100 | Four of a Kind |
| Straight Flush | 1:1 | $100 | Straight Flush, Royal Flush |

## Installation Guide

### Prerequisites

- **Balatro** (Steam version recommended)
- **Steamodded** mod framework ([Download here](https://github.com/Steamodded/smods))
- **Lovely** mod loader (comes with Steamodded)

### Installation Steps

1. **Install Steamodded** (if not already installed)
   - Download the latest Steamodded release
   - Follow Steamodded's installation instructions for your platform

2. **Locate Your Mods Folder:**
   ```
   Windows: %APPDATA%/Balatro/Mods/
   Mac: ~/Library/Application Support/Balatro/Mods/
   Linux: ~/.local/share/Balatro/Mods/
   ```

3. **Install GamblingBets**
   - Download the GamblingBets folder
   - Place the entire folder in your Mods directory
   - Your folder structure should look like:
     ```
     Balatro/Mods/GamblingBets/
     ├── core.lua
     └── manifest.json
     ```

4. **Launch the Game**
   - Start Balatro
   - Look for "GamblingBets" in the mods list (accessible from main menu)
   - The mod should load automatically

### Verification

- Enter the shop and look for betting controls
- You should see hand selection, betting amount controls, and "Place Bet" button

## Known Issues to Watch For

- **Performance**: Check for lag when entering shop with many other mods
- **Hand Recognition**: Verify all poker hand types are detected correctly
- **Save Corruption**: Test save/load extensively to prevent save issues
- **Negative Money**: If you preset a large bet (without placing it), spend money, then click place bet you will go negative and successfully place the bet

## Reporting Issues

When testing, please report:

- **Exact steps** to reproduce any bugs
- **Expected vs actual behavior**
- **Other mods** installed
- **Game version** and platform
- **Screenshots/videos** if applicable

## CREDITS

### Code Attribution

- **UI Framework & Shop Integration**: Adapted from [Hellyom's Roulette Mod](https://github.com/Hellyom/HellyomBalatroMods/tree/main/Roulette)

### Dependencies
- **Steamodded**: Mod framework by [Steamodded Team](https://github.com/Steamodded/smods)
- **Lovely**: Mod loader included with Steamodded

### Special Thanks
- **Hellyom**: For the excellent UI foundation and Balatro modding examples
- **Steamodded Community**: For the modding framework and documentation

### License Information
This mod references MIT-licensed code from the Hellyom Balatro Mods repository. The GamblingBets-specific logic and betting system are original implementations.

**Original Roulette Mod License**: MIT  
**GamblingBets Modifications**: MIT (maintaining compatibility)


## Happy testing! 🎰