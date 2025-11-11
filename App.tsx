import React, { useEffect, useState } from 'react';
import { StatusBar } from 'expo-status-bar';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { Provider as PaperProvider } from 'react-native-paper';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import AsyncStorage from '@react-native-async-storage/async-storage';
import Navigation from './src/navigation';
import { useSettingsStore } from './src/store';
import { darkTheme, lightTheme } from './src/constants';

export default function App() {
  const { settings } = useSettingsStore();
  const theme = settings?.theme === 'dark' ? darkTheme : lightTheme;
  const isDark = settings?.theme === 'dark';

  useEffect(() => {
    console.log('App initialized');
  }, []);

  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <SafeAreaProvider>
        <PaperProvider theme={theme}>
          <StatusBar style={isDark ? 'light' : 'dark'} />
          <Navigation />
        </PaperProvider>
      </SafeAreaProvider>
    </GestureHandlerRootView>
  );
}
