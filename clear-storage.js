// Clear AsyncStorage script
const AsyncStorage = require('@react-native-async-storage/async-storage').default;

async function clearStorage() {
  try {
    await AsyncStorage.clear();
    console.log('Storage cleared successfully!');
  } catch (e) {
    console.error('Failed to clear storage:', e);
  }
}

clearStorage();
