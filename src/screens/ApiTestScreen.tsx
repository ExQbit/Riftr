/**
 * API Test Screen
 *
 * Use this screen to test the Riot API connection and discover the correct endpoints.
 * Add this to your navigation temporarily for testing.
 */

import React, { useState } from 'react';
import { View, StyleSheet, ScrollView } from 'react-native';
import { Text, Button, Card, Title, Paragraph, useTheme, ActivityIndicator } from 'react-native-paper';
import { testApiConnection, fetchAllCards } from '../services/riotApi';

export default function ApiTestScreen() {
  const theme = useTheme();
  const [testing, setTesting] = useState(false);
  const [result, setResult] = useState<string>('');

  const handleTestConnection = async () => {
    setTesting(true);
    setResult('Testing API connection...\nCheck console for details.\n\n');

    try {
      await testApiConnection();
      setResult(prev => prev + '\n✅ Test complete! Check console for full output.');
    } catch (error) {
      setResult(prev => prev + `\n❌ Error: ${error}`);
    } finally {
      setTesting(false);
    }
  };

  const handleFetchCards = async () => {
    setTesting(true);
    setResult('Fetching cards from Riot API...\n\n');

    try {
      const cards = await fetchAllCards();
      setResult(prev => prev + `\n✅ Success! Fetched ${cards.length} cards.\n\n${JSON.stringify(cards[0], null, 2)}`);
    } catch (error: any) {
      setResult(prev => prev + `\n❌ Error: ${error.message}\n\nCheck console for details.`);
    } finally {
      setTesting(false);
    }
  };

  return (
    <ScrollView style={[styles.container, { backgroundColor: theme.colors.background }]}>
      <Card style={[styles.card, { backgroundColor: theme.colors.surface }]}>
        <Card.Content>
          <Title style={{ color: theme.colors.onSurface }}>Riot API Test</Title>
          <Paragraph style={{ color: theme.colors.onSurfaceVariant }}>
            Use these buttons to test the Riot API connection and discover the correct endpoints.
          </Paragraph>

          <View style={styles.buttonContainer}>
            <Button
              mode="contained"
              onPress={handleTestConnection}
              disabled={testing}
              style={styles.button}
            >
              Test API Connection
            </Button>

            <Button
              mode="contained"
              onPress={handleFetchCards}
              disabled={testing}
              style={styles.button}
            >
              Fetch All Cards
            </Button>
          </View>

          {testing && (
            <View style={styles.loadingContainer}>
              <ActivityIndicator size="large" color={theme.colors.primary} />
              <Text style={{ color: theme.colors.onSurface, marginTop: 8 }}>
                Testing...
              </Text>
            </View>
          )}
        </Card.Content>
      </Card>

      {result && (
        <Card style={[styles.card, { backgroundColor: theme.colors.surfaceVariant }]}>
          <Card.Content>
            <Title style={{ color: theme.colors.onSurface }}>Result</Title>
            <Text
              style={{
                color: theme.colors.onSurfaceVariant,
                fontFamily: 'monospace',
                fontSize: 12,
              }}
            >
              {result}
            </Text>
          </Card.Content>
        </Card>
      )}

      <Card style={[styles.card, { backgroundColor: theme.colors.errorContainer }]}>
        <Card.Content>
          <Title style={{ color: theme.colors.onErrorContainer }}>⚠️ Important</Title>
          <Paragraph style={{ color: theme.colors.onErrorContainer }}>
            This screen is for development only. The API endpoints are currently unknown and need
            to be discovered through testing.
            {'\n\n'}
            Check the Expo console and your browser's Network tab for full API responses.
          </Paragraph>
        </Card.Content>
      </Card>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  card: {
    margin: 16,
    elevation: 4,
  },
  buttonContainer: {
    marginTop: 16,
    gap: 12,
  },
  button: {
    marginVertical: 4,
  },
  loadingContainer: {
    alignItems: 'center',
    marginTop: 20,
  },
});
