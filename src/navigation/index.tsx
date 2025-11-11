import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { createStackNavigator } from '@react-navigation/stack';
import { Ionicons } from '@expo/vector-icons';
import { useTheme } from 'react-native-paper';

// Import screens (will be created next)
import HomeScreen from '../screens/HomeScreen';
import CollectionScreen from '../screens/CollectionScreen';
import DatabaseScreen from '../screens/DatabaseScreen';
import DecksScreen from '../screens/DecksScreen';
import SettingsScreen from '../screens/SettingsScreen';
import CardDetailScreen from '../screens/CardDetailScreen';
import PackOpeningScreen from '../screens/PackOpeningScreen';
import DeckBuilderScreen from '../screens/DeckBuilderScreen';
import ApiTestScreen from '../screens/ApiTestScreen';

// Type definitions for navigation
export type RootTabParamList = {
  Home: undefined;
  Collection: undefined;
  Database: undefined;
  Decks: undefined;
  Settings: undefined;
};

export type RootStackParamList = {
  MainTabs: undefined;
  CardDetail: { cardId: string };
  PackOpening: { packType: 'starter' | 'foundations_booster' | 'expansion_booster' };
  DeckBuilder: { deckId?: string };
  ApiTest: undefined;
};

const Tab = createBottomTabNavigator<RootTabParamList>();
const Stack = createStackNavigator<RootStackParamList>();

// Tab Navigator
function TabNavigator() {
  const theme = useTheme();

  return (
    <Tab.Navigator
      screenOptions={({ route }) => ({
        tabBarIcon: ({ focused, color, size }) => {
          let iconName: keyof typeof Ionicons.glyphMap = 'home';

          switch (route.name) {
            case 'Home':
              iconName = focused ? 'home' : 'home-outline';
              break;
            case 'Collection':
              iconName = focused ? 'albums' : 'albums-outline';
              break;
            case 'Database':
              iconName = focused ? 'search' : 'search-outline';
              break;
            case 'Decks':
              iconName = focused ? 'layers' : 'layers-outline';
              break;
            case 'Settings':
              iconName = focused ? 'settings' : 'settings-outline';
              break;
          }

          return <Ionicons name={iconName} size={size} color={color} />;
        },
        tabBarActiveTintColor: theme.colors.primary,
        tabBarInactiveTintColor: theme.colors.onSurface,
        tabBarStyle: {
          backgroundColor: theme.colors.surface,
          borderTopColor: theme.colors.surfaceVariant,
          borderTopWidth: 1,
        },
        headerStyle: {
          backgroundColor: theme.colors.surface,
        },
        headerTintColor: theme.colors.onSurface,
        headerTitleStyle: {
          fontWeight: 'bold',
        },
      })}
    >
      <Tab.Screen 
        name="Home" 
        component={HomeScreen} 
        options={{ title: 'Booster Packs' }}
      />
      <Tab.Screen 
        name="Collection" 
        component={CollectionScreen}
        options={{ title: 'My Collection' }}
      />
      <Tab.Screen 
        name="Database" 
        component={DatabaseScreen}
        options={{ title: 'Card Database' }}
      />
      <Tab.Screen 
        name="Decks" 
        component={DecksScreen}
        options={{ title: 'My Decks' }}
      />
      <Tab.Screen 
        name="Settings" 
        component={SettingsScreen}
        options={{ title: 'Settings' }}
      />
    </Tab.Navigator>
  );
}

// Main Navigation Container
export default function Navigation() {
  const theme = useTheme();

  return (
    <NavigationContainer>
      <Stack.Navigator
        screenOptions={{
          headerStyle: {
            backgroundColor: theme.colors.surface,
          },
          headerTintColor: theme.colors.onSurface,
          headerTitleStyle: {
            fontWeight: 'bold',
          },
        }}
      >
        <Stack.Screen
          name="MainTabs"
          component={TabNavigator}
          options={{ headerShown: false }}
        />
        <Stack.Screen
          name="CardDetail"
          component={CardDetailScreen}
          options={{ title: 'Card Details' }}
        />
        <Stack.Screen
          name="PackOpening"
          component={PackOpeningScreen}
          options={{ title: 'Opening Pack' }}
        />
        <Stack.Screen
          name="DeckBuilder"
          component={DeckBuilderScreen}
          options={{ title: 'Deck Builder' }}
        />
        <Stack.Screen
          name="ApiTest"
          component={ApiTestScreen}
          options={{ title: 'API Test (Dev Only)' }}
        />
      </Stack.Navigator>
    </NavigationContainer>
  );
}
