import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { createStackNavigator } from '@react-navigation/stack';
import { Ionicons } from '@expo/vector-icons';
import { useTheme } from 'react-native-paper';

// Import screens
import NewHomeScreen from '../screens/NewHomeScreen';
import HomeScreen from '../screens/HomeScreen';
import CollectionScreen from '../screens/CollectionScreen';
import DatabaseScreen from '../screens/DatabaseScreen';
import DecksScreen from '../screens/DecksScreen';
import ProfileScreen from '../screens/ProfileScreen';
import SettingsScreen from '../screens/SettingsScreen';
import CardDetailScreen from '../screens/CardDetailScreen';
import PackOpeningScreen from '../screens/PackOpeningScreen';
import DeckBuilderScreen from '../screens/DeckBuilderScreen';
import CardScannerScreen from '../screens/CardScannerScreen';
import ApiTestScreen from '../screens/ApiTestScreen';

// Type definitions for navigation
export type RootTabParamList = {
  Home: undefined;
  Collection: undefined;
  Decks: undefined;
  Profile: undefined;
};

export type RootStackParamList = {
  MainTabs: undefined;
  CardDetail: { cardId: string };
  PackOpening: { packType: 'starter' | 'foundations_booster' | 'expansion_booster' };
  DeckBuilder: { deckId?: string };
  CardScanner: undefined;
  Settings: undefined;
  Database: undefined;
  PackSelection: undefined;
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
            case 'Decks':
              iconName = focused ? 'layers' : 'layers-outline';
              break;
            case 'Profile':
              iconName = focused ? 'person' : 'person-outline';
              break;
          }

          return <Ionicons name={iconName} size={size} color={color} />;
        },
        tabBarActiveTintColor: theme.colors.primary,
        tabBarInactiveTintColor: theme.colors.onSurfaceVariant,
        tabBarStyle: {
          backgroundColor: theme.colors.surface,
          borderTopColor: theme.colors.surfaceVariant,
          borderTopWidth: 1,
          height: 60,
          paddingBottom: 8,
          paddingTop: 8,
        },
        tabBarLabelStyle: {
          fontSize: 12,
          fontWeight: '600',
        },
        headerStyle: {
          backgroundColor: theme.colors.surface,
          elevation: 0,
        },
        headerTintColor: theme.colors.onSurface,
        headerTitleStyle: {
          fontWeight: 'bold',
        },
      })}
    >
      <Tab.Screen
        name="Home"
        component={NewHomeScreen}
        options={{
          title: 'Home',
          headerTitle: 'Riftbound',
        }}
      />
      <Tab.Screen
        name="Collection"
        component={CollectionScreen}
        options={{
          title: 'Sammlung',
          headerTitle: 'Meine Sammlung',
        }}
      />
      <Tab.Screen
        name="Decks"
        component={DecksScreen}
        options={{
          title: 'Decks',
          headerTitle: 'Meine Decks',
        }}
      />
      <Tab.Screen
        name="Profile"
        component={ProfileScreen}
        options={{
          title: 'Profil',
          headerTitle: 'Mein Profil',
        }}
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
          options={{
            title: 'Kartendetails',
            headerBackTitle: 'Zurück',
          }}
        />
        <Stack.Screen
          name="PackOpening"
          component={PackOpeningScreen}
          options={{
            title: 'Pack öffnen',
            headerBackTitle: 'Zurück',
          }}
        />
        <Stack.Screen
          name="DeckBuilder"
          component={DeckBuilderScreen}
          options={{
            title: 'Deck Builder',
            headerBackTitle: 'Zurück',
          }}
        />
        <Stack.Screen
          name="CardScanner"
          component={CardScannerScreen}
          options={{
            title: 'Karte scannen',
            headerBackTitle: 'Zurück',
          }}
        />
        <Stack.Screen
          name="Settings"
          component={SettingsScreen}
          options={{
            title: 'Einstellungen',
            headerBackTitle: 'Zurück',
          }}
        />
        <Stack.Screen
          name="Database"
          component={DatabaseScreen}
          options={{
            title: 'Kartendatenbank',
            headerBackTitle: 'Zurück',
          }}
        />
        <Stack.Screen
          name="PackSelection"
          component={HomeScreen}
          options={{
            title: 'Packs öffnen',
            headerBackTitle: 'Zurück',
          }}
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
