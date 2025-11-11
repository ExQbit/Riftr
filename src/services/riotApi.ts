/**
 * Riot Games Riftbound API Service
 *
 * Official API Documentation: https://developer.riotgames.com/docs/riftbound
 *
 * IMPORTANT: This API key is for DEVELOPMENT ONLY
 * Rate Limits: 20 requests/second, 100 requests/2 minutes
 */

import { Card } from '../types';
import config from '../config/env';

// API Configuration
const RIOT_API_KEY = config.riotApiKey;
const BASE_URL = config.apiBaseUrl;
const RIFTBOUND_VERSION = 'v1';

// Common API endpoints (to be updated when official docs are available)
const ENDPOINTS = {
  // Data Dragon style endpoints (common for Riot games)
  cards: `/riftbound-content/${RIFTBOUND_VERSION}/cards`,
  sets: `/riftbound-content/${RIFTBOUND_VERSION}/sets`,

  // Alternative possible endpoints
  allCards: `/riftbound/${RIFTBOUND_VERSION}/cards`,
  cardById: (id: string) => `/riftbound/${RIFTBOUND_VERSION}/cards/${id}`,
};

interface RiotApiResponse<T> {
  data: T;
  status: number;
}

interface RiotCardData {
  id: string;
  name: string;
  set: string;
  rarity: string;
  type: string;
  energy: number;
  power?: number;
  health?: number;
  text: string;
  flavorText?: string;
  imageUrl?: string;
  artist?: string;
  cardNumber?: string;
  // Add more fields as we discover the actual API response structure
}

/**
 * Fetches all Riftbound cards from the Riot API
 */
export async function fetchAllCards(): Promise<Card[]> {
  try {
    console.log('Fetching cards from Riot API...');

    const response = await fetch(`${BASE_URL}${ENDPOINTS.cards}`, {
      method: 'GET',
      headers: {
        'X-Riot-Token': RIOT_API_KEY,
        'Accept': 'application/json',
      },
    });

    if (!response.ok) {
      throw new Error(`Riot API Error: ${response.status} - ${response.statusText}`);
    }

    const data = await response.json();
    console.log('Riot API Response:', data);

    // Transform Riot API response to our Card interface
    return transformRiotCards(data);
  } catch (error) {
    console.error('Failed to fetch cards from Riot API:', error);
    throw error;
  }
}

/**
 * Fetches a specific card by ID
 */
export async function fetchCardById(cardId: string): Promise<Card | null> {
  try {
    const response = await fetch(`${BASE_URL}${ENDPOINTS.cardById(cardId)}`, {
      method: 'GET',
      headers: {
        'X-Riot-Token': RIOT_API_KEY,
        'Accept': 'application/json',
      },
    });

    if (!response.ok) {
      if (response.status === 404) return null;
      throw new Error(`Riot API Error: ${response.status}`);
    }

    const data = await response.json();
    return transformRiotCard(data);
  } catch (error) {
    console.error(`Failed to fetch card ${cardId}:`, error);
    return null;
  }
}

/**
 * Transforms Riot API card data to our internal Card interface
 * This will need to be adjusted once we see the actual API response structure
 */
function transformRiotCards(apiData: any): Card[] {
  // Handle different possible response structures
  const cards = apiData.cards || apiData.data || apiData;

  if (!Array.isArray(cards)) {
    console.warn('Unexpected API response structure:', apiData);
    return [];
  }

  return cards.map(transformRiotCard).filter(Boolean) as Card[];
}

function transformRiotCard(apiCard: any): Card {
  // Map Riot API fields to our Card interface
  // This is a best-guess mapping and will need adjustment
  return {
    id: apiCard.id || apiCard.cardId,
    name: apiCard.name,
    set: apiCard.set || 'Origins',
    rarity: normalizeRarity(apiCard.rarity),
    type: normalizeType(apiCard.type || apiCard.cardType),
    domain: apiCard.domain || apiCard.regions || ['Neutral'],
    energy: apiCard.energy || apiCard.cost || 0,
    power: apiCard.power || apiCard.attack,
    health: apiCard.health,
    abilities: apiCard.abilities || apiCard.keywords || [],
    text: apiCard.text || apiCard.description || '',
    flavorText: apiCard.flavorText || apiCard.flavor,
    imageUrl: apiCard.imageUrl || apiCard.image || `https://via.placeholder.com/300x420?text=${encodeURIComponent(apiCard.name)}`,
    artist: apiCard.artist || 'Unknown Artist',
    cardNumber: apiCard.cardNumber || apiCard.number || apiCard.id,
    legality: {
      standard: apiCard.legality?.standard ?? true,
      limited: apiCard.legality?.limited ?? true,
    },
  };
}

/**
 * Normalize rarity values to our expected format
 */
function normalizeRarity(rarity: string): 'common' | 'uncommon' | 'rare' | 'legendary' {
  const normalized = rarity?.toLowerCase();
  if (['common', 'uncommon', 'rare', 'legendary'].includes(normalized)) {
    return normalized as any;
  }
  return 'common'; // Default fallback
}

/**
 * Normalize type values to our expected format
 */
function normalizeType(type: string): 'champion' | 'unit' | 'spell' | 'relic' {
  const normalized = type?.toLowerCase();
  if (['champion', 'unit', 'spell', 'relic'].includes(normalized)) {
    return normalized as any;
  }
  return 'unit'; // Default fallback
}

/**
 * Test API connection and log response structure
 * Call this during development to understand the API response format
 */
export async function testApiConnection(): Promise<void> {
  console.log('=== Testing Riot API Connection ===');
  console.log('API Key:', RIOT_API_KEY.substring(0, 10) + '...');
  console.log('Base URL:', BASE_URL);

  try {
    // Try different possible endpoints
    const endpoints = [
      ENDPOINTS.cards,
      ENDPOINTS.allCards,
      `/riftbound-data-dragon/${RIFTBOUND_VERSION}/cards`,
      `/riftbound/${RIFTBOUND_VERSION}/cards/all`,
    ];

    for (const endpoint of endpoints) {
      console.log(`\nTrying endpoint: ${BASE_URL}${endpoint}`);

      try {
        const response = await fetch(`${BASE_URL}${endpoint}`, {
          method: 'GET',
          headers: {
            'X-Riot-Token': RIOT_API_KEY,
            'Accept': 'application/json',
          },
        });

        console.log('Status:', response.status, response.statusText);

        if (response.ok) {
          const data = await response.json();
          console.log('SUCCESS! Response structure:', JSON.stringify(data, null, 2).substring(0, 500));
          return;
        }
      } catch (err) {
        console.log('Error:', err);
      }
    }

    console.log('\n❌ No working endpoint found. Check Riot Developer Portal for correct endpoints.');
  } catch (error) {
    console.error('API Test Failed:', error);
  }
}

/**
 * Rate limiter to respect Riot API limits
 * 20 requests/second, 100 requests/2 minutes
 */
class RateLimiter {
  private requests: number[] = [];
  private readonly shortLimit = 20; // per second
  private readonly longLimit = 100; // per 2 minutes

  async waitForSlot(): Promise<void> {
    const now = Date.now();

    // Remove old requests
    this.requests = this.requests.filter(time => now - time < 120000);

    // Check limits
    const recentRequests = this.requests.filter(time => now - time < 1000);

    if (recentRequests.length >= this.shortLimit || this.requests.length >= this.longLimit) {
      const waitTime = recentRequests.length >= this.shortLimit ? 1000 : 5000;
      console.log(`Rate limit reached, waiting ${waitTime}ms...`);
      await new Promise(resolve => setTimeout(resolve, waitTime));
    }

    this.requests.push(now);
  }
}

export const rateLimiter = new RateLimiter();
