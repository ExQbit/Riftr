// Card Types and Interfaces
export type Rarity = 'common' | 'uncommon' | 'rare' | 'legendary';
export type CardType = 'champion' | 'unit' | 'spell' | 'relic';
export type Domain = 'Demacia' | 'Noxus' | 'Ionia' | 'Piltover & Zaun' | 'Shadow Isles' | 'Bilgewater' | 'Shurima' | 'Targon' | 'Freljord' | 'Bandle City';

// Riot API Response Types (based on official API documentation)
export interface RiftboundContentDTO {
  game: string;
  version: string;
  lastUpdated: string;
  sets: SetDTO[];
}

export interface SetDTO {
  id: string;
  name: string;
  cards: CardDTO[];
}

export interface CardDTO {
  id: string;
  collectorNumber: number;
  set: string;
  name: string;
  description: string;
  type: string;
  rarity: string;
  faction: string;
  stats: CardStatsDTO;
  keywords: string[];
  art: CardArtDTO;
  flavorText: string;
  tags: string[];
}

export interface CardStatsDTO {
  energy: number;
  might: number;
  cost: number;
  power: number;
}

export interface CardArtDTO {
  thumbnailURL: string;
  fullURL: string;
  artist: string;
}

// App Internal Card Interface
export interface Card {
  id: string;
  name: string;
  set: string;
  rarity: Rarity;
  type: CardType;
  domain: Domain[];
  energy: number;
  power?: number;
  health?: number;
  abilities: string[];
  text: string;
  flavorText?: string;
  imageUrl: string;
  imageUrlHiRes?: string;
  artist: string;
  cardNumber: string;
  legality: {
    standard: boolean;
    limited: boolean;
  };
}

export interface CollectionEntry {
  cardId: string;
  owned: boolean;
  quantity: number;
  foil: boolean;
  dateAdded: string;
  variants: ('normal' | 'foil')[];
}

export interface Deck {
  id: string;
  name: string;
  champion?: string;
  cards: DeckCard[];
  format: 'standard' | 'limited' | 'unlimited';
  dateCreated: string;
  dateModified: string;
  notes?: string;
}

export interface DeckCard {
  cardId: string;
  quantity: number;
}

export interface BoosterPack {
  packType: 'starter' | 'foundations_booster' | 'expansion_booster';
  cards: Card[];
  rarityDistribution: {
    common: number;
    uncommon: number;
    rare: number;
    legendary: number;
  };
  openedDate?: string;
}

export interface UserSettings {
  theme: 'dark' | 'light' | 'auto';
  animationsEnabled: boolean;
  soundEnabled: boolean;
  hapticEnabled: boolean;
  gridColumns: 3 | 4;
  showOwned: boolean;
  showUnowned: boolean;
}

export interface UserStats {
  totalPacksOpened: number;
  totalCards: number;
  uniqueCards: number;
  collectionValue: number;
  completionRate: number;
  favoriteCard?: string;
  lastPackOpened?: string;
}
