import { MD3LightTheme, MD3DarkTheme } from 'react-native-paper';

// App Constants
export const APP_NAME = 'Riftbound Companion';
export const APP_VERSION = '1.0.0';

// Theme Colors based on League/Riot branding
export const COLORS = {
  // Primary Colors
  primary: '#0596AA', // Piltover Blue
  secondary: '#C89B3C', // Demacia Gold
  accent: '#6b46c1', // Viktor Purple
  
  // Rarity Colors
  common: '#808080',
  uncommon: '#32cd32',
  rare: '#4169e1',
  legendary: '#9400d3',
  
  // Domain Colors
  demacia: '#FFD700',
  noxus: '#DC143C',
  ionia: '#FF69B4',
  piltoverZaun: '#00CED1',
  shadowIsles: '#4B0082',
  bilgewater: '#FF8C00',
  shurima: '#DAA520',
  targon: '#9370DB',
  freljord: '#00BFFF',
  bandleCity: '#98FB98',
  
  // UI Colors
  background: '#0A0E1A',
  surface: '#0F1B2F',
  card: '#162136',
  text: '#FFFFFF',
  textSecondary: '#A8B1C7',
  error: '#FF6B6B',
  success: '#4CAF50',
  warning: '#FFA726',
  info: '#29B6F6',
  
  // Neutral Colors
  gray: {
    100: '#F5F5F5',
    200: '#E0E0E0',
    300: '#BDBDBD',
    400: '#9E9E9E',
    500: '#757575',
    600: '#616161',
    700: '#424242',
    800: '#303030',
    900: '#212121',
  }
};

// Light Theme
export const lightTheme = {
  ...MD3LightTheme,
  colors: {
    ...MD3LightTheme.colors,
    primary: COLORS.primary,
    secondary: COLORS.secondary,
    background: '#F5F5F5',
    surface: '#FFFFFF',
    card: '#FFFFFF',
    text: '#000000',
    textSecondary: '#666666',
  },
};

// Dark Theme (Default)
export const darkTheme = {
  ...MD3DarkTheme,
  colors: {
    ...MD3DarkTheme.colors,
    primary: COLORS.primary,
    secondary: COLORS.secondary,
    background: COLORS.background,
    surface: COLORS.surface,
    card: COLORS.card,
    text: COLORS.text,
    textSecondary: COLORS.textSecondary,
    onSurface: COLORS.text,
    onBackground: COLORS.text,
  },
};

// Layout Constants
export const LAYOUT = {
  spacing: {
    xs: 4,
    sm: 8,
    md: 16,
    lg: 24,
    xl: 32,
    xxl: 48,
  },
  borderRadius: {
    sm: 4,
    md: 8,
    lg: 12,
    xl: 16,
    card: 12,
    button: 8,
  },
  cardSize: {
    width: 100,
    height: 140,
    aspectRatio: 5 / 7,
  },
  animation: {
    fast: 200,
    medium: 300,
    slow: 500,
  },
};

// Pack Opening Constants
export const PACK_CONFIG = {
  starter: {
    name: 'Starter Pack',
    cards: 12,
    guaranteed: {
      champion: 1,
      rare: 2,
      uncommon: 4,
      common: 5,
    },
    cost: 0, // Free
  },
  foundations_booster: {
    name: 'Foundations Booster',
    cards: 10,
    distribution: {
      common: 7,
      uncommon: 2,
      rare: 1,
    },
    legendaryChance: 0.1,
    cost: 100, // Virtual currency
  },
  expansion_booster: {
    name: 'Expansion Booster',
    cards: 15,
    distribution: {
      common: 9,
      uncommon: 4,
      rare: 2,
    },
    legendaryChance: 0.15,
    cost: 150,
  },
};

// Filters and Sorting Options
export const FILTER_OPTIONS = {
  rarity: ['All', 'Common', 'Uncommon', 'Rare', 'Legendary'],
  type: ['All', 'Champion', 'Unit', 'Spell', 'Relic'],
  domain: [
    'All',
    'Demacia',
    'Noxus',
    'Ionia',
    'Piltover & Zaun',
    'Shadow Isles',
    'Bilgewater',
    'Shurima',
    'Targon',
    'Freljord',
    'Bandle City',
  ],
  owned: ['All', 'Owned', 'Not Owned'],
};

export const SORT_OPTIONS = {
  name: 'Name',
  number: 'Card Number',
  rarity: 'Rarity',
  energy: 'Energy Cost',
  dateAdded: 'Date Added',
};

// API Endpoints (for future use)
export const API = {
  baseURL: 'https://api.riftbound.gg/v1', // Placeholder
  endpoints: {
    cards: '/cards',
    sets: '/sets',
    decks: '/decks',
    news: '/news',
  },
};

// Storage Keys
export const STORAGE_KEYS = {
  collection: '@riftbound_collection',
  decks: '@riftbound_decks',
  settings: '@riftbound_settings',
  stats: '@riftbound_stats',
  packHistory: '@riftbound_pack_history',
  currency: '@riftbound_currency',
  firstLaunch: '@riftbound_first_launch',
};

// Legal Text
export const LEGAL = {
  disclaimer: 'This app is not affiliated with, endorsed, sponsored, or approved by Riot Games. Riftbound and all associated properties are trademarks or registered trademarks of Riot Games, Inc.',
  privacyUrl: 'https://yourapp.com/privacy',
  termsUrl: 'https://yourapp.com/terms',
};
