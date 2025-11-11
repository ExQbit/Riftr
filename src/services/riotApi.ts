/**
 * Riot Games Riftbound API Service
 *
 * Official API Documentation: https://developer.riotgames.com/apis#riftbound-content-v1
 * Endpoint: GET /riftbound/content/v1/contents
 *
 * IMPORTANT: This API key is for DEVELOPMENT ONLY
 * Rate Limits: 20 requests/second, 100 requests/2 minutes
 */

import { Card, RiftboundContentDTO, CardDTO } from '../types';
import config from '../config/env';

// API Configuration
const RIOT_API_KEY = config.riotApiKey;
const BASE_URL = config.apiBaseUrl;

// Official API Endpoints (verified from Riot API documentation)
const ENDPOINTS = {
  content: '/riftbound/content/v1/contents', // Main endpoint - returns all cards and sets
};

/**
 * Fetches all Riftbound content (cards and sets) from the Riot API
 * @param locale Optional locale code (default: 'en'). Only 'en' available during beta.
 */
export async function fetchAllCards(locale: string = 'en'): Promise<Card[]> {
  try {
    console.log('Fetching Riftbound content from Riot API...');

    const url = `${BASE_URL}${ENDPOINTS.content}?locale=${locale}`;
    console.log('Request URL:', url);

    const response = await fetch(url, {
      method: 'GET',
      headers: {
        'X-Riot-Token': RIOT_API_KEY,
        'Accept': 'application/json',
      },
    });

    console.log('API Response Status:', response.status, response.statusText);

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Riot API Error: ${response.status} - ${response.statusText}\n${errorText}`);
    }

    const data: RiftboundContentDTO = await response.json();
    console.log('Riot API Response:', {
      game: data.game,
      version: data.version,
      lastUpdated: data.lastUpdated,
      setsCount: data.sets?.length || 0,
      totalCards: data.sets?.reduce((sum, set) => sum + (set.cards?.length || 0), 0) || 0,
    });

    // Transform Riot API response to our Card interface
    return transformRiotContent(data);
  } catch (error) {
    console.error('Failed to fetch cards from Riot API:', error);
    throw error;
  }
}

/**
 * Fetches a specific card by ID from cached content
 * Note: Riot API doesn't have a single-card endpoint, so we fetch all and filter
 */
export async function fetchCardById(cardId: string): Promise<Card | null> {
  try {
    const allCards = await fetchAllCards();
    return allCards.find(card => card.id === cardId) || null;
  } catch (error) {
    console.error(`Failed to fetch card ${cardId}:`, error);
    return null;
  }
}

/**
 * Transforms Riot API content response to our internal Card interface
 * Based on official API documentation: RiftboundContentDTO structure
 */
function transformRiotContent(content: RiftboundContentDTO): Card[] {
  const allCards: Card[] = [];

  // Iterate through all sets and their cards
  for (const set of content.sets) {
    for (const card of set.cards) {
      allCards.push(transformRiotCard(card, set.name));
    }
  }

  console.log(`Transformed ${allCards.length} cards from ${content.sets.length} sets`);
  return allCards;
}

/**
 * Transforms a single Riot API card (CardDTO) to our internal Card interface
 */
function transformRiotCard(apiCard: CardDTO, setName: string): Card {
  return {
    id: apiCard.id,
    name: apiCard.name,
    set: setName,
    rarity: normalizeRarity(apiCard.rarity),
    type: normalizeType(apiCard.type),
    domain: [apiCard.faction as any] || ['Neutral'], // Map faction to domain
    energy: apiCard.stats.energy,
    power: apiCard.stats.power || undefined,
    health: apiCard.stats.might || undefined, // 'might' might be health
    abilities: apiCard.keywords || [],
    text: apiCard.description || '',
    flavorText: apiCard.flavorText || undefined,
    imageUrl: apiCard.art.thumbnailURL,
    imageUrlHiRes: apiCard.art.fullURL,
    artist: apiCard.art.artist,
    cardNumber: apiCard.collectorNumber.toString(),
    legality: {
      standard: true, // Default - can be updated based on tags if needed
      limited: true,
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
 * Tests the official Riot Riftbound Content API endpoint
 */
export async function testApiConnection(): Promise<void> {
  console.log('=== Testing Riot Riftbound Content API ===');
  console.log('API Key:', RIOT_API_KEY ? RIOT_API_KEY.substring(0, 10) + '...' : 'NOT SET');
  console.log('Base URL:', BASE_URL);
  console.log('Endpoint:', ENDPOINTS.content);

  try {
    const url = `${BASE_URL}${ENDPOINTS.content}?locale=en`;
    console.log('\nFull URL:', url);

    const response = await fetch(url, {
      method: 'GET',
      headers: {
        'X-Riot-Token': RIOT_API_KEY,
        'Accept': 'application/json',
      },
    });

    console.log('\nResponse Status:', response.status, response.statusText);
    console.log('Response Headers:', {
      'content-type': response.headers.get('content-type'),
      'x-app-rate-limit': response.headers.get('x-app-rate-limit'),
      'x-app-rate-limit-count': response.headers.get('x-app-rate-limit-count'),
    });

    if (response.ok) {
      const data: RiftboundContentDTO = await response.json();
      console.log('\n✅ SUCCESS! API is working!');
      console.log('Content Summary:', {
        game: data.game,
        version: data.version,
        lastUpdated: data.lastUpdated,
        sets: data.sets?.length || 0,
        totalCards: data.sets?.reduce((sum, set) => sum + set.cards.length, 0) || 0,
      });

      if (data.sets && data.sets.length > 0) {
        console.log('\nFirst Set Sample:', {
          id: data.sets[0].id,
          name: data.sets[0].name,
          cardsCount: data.sets[0].cards.length,
        });

        if (data.sets[0].cards.length > 0) {
          console.log('\nFirst Card Sample:', JSON.stringify(data.sets[0].cards[0], null, 2).substring(0, 500));
        }
      }
    } else {
      const errorText = await response.text();
      console.error('\n❌ API Request Failed');
      console.error('Error Response:', errorText);

      if (response.status === 403) {
        console.error('\n⚠️  403 Forbidden - Your API key might not have access yet.');
        console.error('Make sure you completed the Riot Developer Portal registration.');
      } else if (response.status === 401) {
        console.error('\n⚠️  401 Unauthorized - Check your API key.');
      }
    }
  } catch (error) {
    console.error('\n❌ API Test Failed:', error);
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
