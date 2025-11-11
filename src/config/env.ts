/**
 * Environment Configuration
 *
 * Expo uses app.json extra config for environment variables
 * See: https://docs.expo.dev/guides/environment-variables/
 */

import Constants from 'expo-constants';

interface Config {
  riotApiKey: string;
  isDevelopment: boolean;
  apiBaseUrl: string;
}

// For development, we can hardcode the key (already exposed in chat anyway)
// For production, this should come from a secure backend
const config: Config = {
  riotApiKey: Constants.expoConfig?.extra?.RIOT_API_KEY || 'RGAPI-4789d7cf-8571-49a3-ad6f-e15a8ca647eb',
  isDevelopment: __DEV__,
  apiBaseUrl: 'https://americas.api.riotgames.com',
};

export default config;
