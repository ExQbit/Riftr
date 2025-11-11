# Riftr

**Riftr** is a mobile companion app for Riftbound TCG players, providing comprehensive collection management and deck building tools.

## Features

### Collection Management
- Track owned cards with quantity tracking and completion stats
- Smart card detection with automatic collection updates
- Visual indicators for card rarity and ownership status

### Virtual Pack Opening
- Simulate the pack opening experience with authentic animations
- Haptic feedback for realistic card reveals
- Visual effects for rare card pulls

### Deck Builder
- Create and manage multiple decks
- Mana curve visualization and format validation
- Real-time deck statistics and legality checking
- Export/import deck lists

### Card Database
- Browse all Riftbound cards with advanced filters
- Search by name, type, rarity, domain, and energy cost
- Detailed card view with abilities, legality, artwork, and flavor text

### Daily Rewards
- Daily login bonus system
- Earn virtual currency for opening packs
- Streak tracking and reward progression

## Technical Stack

- **Framework**: React Native with Expo SDK 54
- **Language**: TypeScript
- **State Management**: Zustand with AsyncStorage persistence
- **UI Library**: React Native Paper (Material Design)
- **Navigation**: React Navigation (Stack + Bottom Tabs)
- **API Integration**: Riot Games Developer API

## API Usage

This app uses the Riftbound API to fetch official card data, images, and set information. The app implements:
- Proper rate limiting and request throttling
- Response caching to minimize API calls
- Efficient data synchronization

## Development

```bash
# Install dependencies
npm install

# Start development server
npx expo start

# Run on iOS
npx expo start --ios

# Run on Android
npx expo start --android

# Run on web
npx expo start --web
```

## Compliance

This project is built in compliance with Riot Games API policies:
- Non-commercial personal project
- Proper attribution of Riot Games assets
- Implements required rate limiting
- Caches responses appropriately

## License

MIT License

---

*Riftr is not affiliated with or endorsed by Riot Games.*
