import React from 'react';
import {
  View,
  StyleSheet,
  ScrollView,
  Alert,
} from 'react-native';
import {
  Text,
  useTheme,
  Surface,
  List,
  Switch,
  Button,
  Divider,
  Title,
  Paragraph,
} from 'react-native-paper';
import { Ionicons } from '@expo/vector-icons';
import { useNavigation, NavigationProp } from '@react-navigation/native';
import {
  useSettingsStore,
  useCollectionStore,
  usePackStore,
  useDeckStore,
  useStatsStore,
} from '../store';
import { LEGAL, APP_VERSION } from '../constants';
import { RootStackParamList } from '../navigation';
import * as Haptics from 'expo-haptics';

export default function SettingsScreen() {
  const theme = useTheme();
  const navigation = useNavigation<NavigationProp<RootStackParamList>>();
  const { settings, updateSettings, resetSettings } = useSettingsStore();
  const { clearCollection, exportCollection } = useCollectionStore();
  const { clearHistory } = usePackStore();
  const stats = useStatsStore((state) => state.stats);

  const handleExportCollection = () => {
    const data = exportCollection();
    // In production, would share this via Share API
    console.log('Collection exported:', data);
    Alert.alert('Export', 'Collection data logged to console (In production: Share via system)');
  };

  const handleImportCollection = () => {
    // In production, would use Document Picker
    Alert.alert('Import', 'Import feature coming soon!');
  };

  const handleClearData = () => {
    Alert.alert(
      'Clear All Data',
      'This will delete your entire collection, decks, and statistics. This action cannot be undone.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Clear',
          style: 'destructive',
          onPress: () => {
            Haptics.notificationAsync(Haptics.NotificationFeedbackType.Warning);
            clearCollection();
            clearHistory();
            useDeckStore.getState().decks.forEach(deck => 
              useDeckStore.getState().deleteDeck(deck.id)
            );
            useStatsStore.getState().updateStats({
              totalPacksOpened: 0,
              totalCards: 0,
              uniqueCards: 0,
              collectionValue: 0,
              completionRate: 0,
            });
            Alert.alert('Success', 'All data has been cleared');
          },
        },
      ]
    );
  };

  return (
    <ScrollView style={[styles.container, { backgroundColor: theme.colors.background }]}>
      {/* Display Settings */}
      <Surface style={[styles.section, { backgroundColor: theme.colors.surface }]}>
        <Title style={{ color: theme.colors.onSurface }}>Display</Title>
        
        <List.Item
          title="Dark Mode"
          description="Use dark theme"
          left={() => <List.Icon icon="theme-light-dark" />}
          right={() => (
            <Switch
              value={settings.theme === 'dark'}
              onValueChange={(value) => 
                updateSettings({ theme: value ? 'dark' : 'light' })
              }
            />
          )}
        />
        
        <Divider />
        
        <List.Item
          title="Grid Columns"
          description={`Show ${settings.gridColumns} cards per row`}
          left={() => <List.Icon icon="view-grid" />}
          right={() => (
            <View style={styles.gridSelector}>
              {([3, 4] as const).map(cols => (
                <Button
                  key={cols}
                  mode={settings.gridColumns === cols ? 'contained' : 'outlined'}
                  onPress={() => updateSettings({ gridColumns: cols })}
                  compact
                  style={{ marginLeft: 8 }}
                >
                  {cols}
                </Button>
              ))}
            </View>
          )}
        />
      </Surface>

      {/* Interaction Settings */}
      <Surface style={[styles.section, { backgroundColor: theme.colors.surface }]}>
        <Title style={{ color: theme.colors.onSurface }}>Interaction</Title>
        
        <List.Item
          title="Animations"
          description="Enable animations"
          left={() => <List.Icon icon="animation" />}
          right={() => (
            <Switch
              value={settings.animationsEnabled}
              onValueChange={(value) => 
                updateSettings({ animationsEnabled: value })
              }
            />
          )}
        />
        
        <Divider />
        
        <List.Item
          title="Sound Effects"
          description="Play sound effects"
          left={() => <List.Icon icon="volume-high" />}
          right={() => (
            <Switch
              value={settings.soundEnabled}
              onValueChange={(value) => 
                updateSettings({ soundEnabled: value })
              }
            />
          )}
        />
        
        <Divider />
        
        <List.Item
          title="Haptic Feedback"
          description="Vibration feedback"
          left={() => <List.Icon icon="vibrate" />}
          right={() => (
            <Switch
              value={settings.hapticEnabled}
              onValueChange={(value) => {
                updateSettings({ hapticEnabled: value });
                if (value) {
                  Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
                }
              }}
            />
          )}
        />
      </Surface>

      {/* Data Management */}
      <Surface style={[styles.section, { backgroundColor: theme.colors.surface }]}>
        <Title style={{ color: theme.colors.onSurface }}>Data Management</Title>
        
        <Button
          mode="contained"
          onPress={handleExportCollection}
          style={styles.button}
          icon="export"
        >
          Export Collection
        </Button>
        
        <Button
          mode="contained"
          onPress={handleImportCollection}
          style={styles.button}
          icon="import"
        >
          Import Collection
        </Button>
        
        <Button
          mode="outlined"
          onPress={handleClearData}
          style={[styles.button, styles.dangerButton]}
          textColor="#FF6B6B"
          icon="delete-forever"
        >
          Clear All Data
        </Button>
      </Surface>

      {/* Statistics */}
      <Surface style={[styles.section, { backgroundColor: theme.colors.surface }]}>
        <Title style={{ color: theme.colors.onSurface }}>Statistics</Title>
        
        <View style={styles.statsGrid}>
          <View style={styles.statItem}>
            <Text style={[styles.statValue, { color: theme.colors.primary }]}>
              {stats.totalPacksOpened}
            </Text>
            <Text style={[styles.statLabel, { color: theme.colors.onSurfaceVariant }]}>
              Packs Opened
            </Text>
          </View>
          
          <View style={styles.statItem}>
            <Text style={[styles.statValue, { color: theme.colors.primary }]}>
              {stats.uniqueCards}
            </Text>
            <Text style={[styles.statLabel, { color: theme.colors.onSurfaceVariant }]}>
              Unique Cards
            </Text>
          </View>
          
          <View style={styles.statItem}>
            <Text style={[styles.statValue, { color: theme.colors.primary }]}>
              {stats.totalCards}
            </Text>
            <Text style={[styles.statLabel, { color: theme.colors.onSurfaceVariant }]}>
              Total Cards
            </Text>
          </View>
          
          <View style={styles.statItem}>
            <Text style={[styles.statValue, { color: theme.colors.primary }]}>
              {stats.completionRate.toFixed(1)}%
            </Text>
            <Text style={[styles.statLabel, { color: theme.colors.onSurfaceVariant }]}>
              Completion
            </Text>
          </View>
        </View>
      </Surface>

      {/* Developer Options */}
      <Surface style={[styles.section, { backgroundColor: theme.colors.errorContainer }]}>
        <Title style={{ color: theme.colors.onErrorContainer }}>Developer</Title>

        <Button
          mode="contained"
          onPress={() => navigation.navigate('ApiTest')}
          style={styles.button}
          icon="code-tags"
        >
          Test Riot API Connection
        </Button>
      </Surface>

      {/* About */}
      <Surface style={[styles.section, { backgroundColor: theme.colors.surface }]}>
        <Title style={{ color: theme.colors.onSurface }}>About</Title>

        <List.Item
          title="Riftr"
          description={`Version ${APP_VERSION}`}
          left={() => <List.Icon icon="information" />}
        />
        
        <Divider />
        
        <List.Item
          title="Privacy Policy"
          description="View privacy policy"
          left={() => <List.Icon icon="shield-account" />}
          right={() => <List.Icon icon="chevron-right" />}
          onPress={() => {
            // Open privacy policy URL
            Alert.alert('Privacy Policy', LEGAL.privacyUrl);
          }}
        />
        
        <Divider />
        
        <List.Item
          title="Terms of Service"
          description="View terms"
          left={() => <List.Icon icon="file-document" />}
          right={() => <List.Icon icon="chevron-right" />}
          onPress={() => {
            // Open terms URL
            Alert.alert('Terms of Service', LEGAL.termsUrl);
          }}
        />
        
        <Divider />
        
        <View style={styles.disclaimer}>
          <Paragraph style={[styles.disclaimerText, { color: theme.colors.onSurfaceVariant }]}>
            {LEGAL.disclaimer}
          </Paragraph>
        </View>
      </Surface>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  section: {
    margin: 16,
    padding: 16,
    borderRadius: 12,
    elevation: 2,
  },
  gridSelector: {
    flexDirection: 'row',
  },
  button: {
    marginVertical: 8,
  },
  dangerButton: {
    borderColor: '#FF6B6B',
  },
  statsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    marginTop: 8,
  },
  statItem: {
    width: '50%',
    alignItems: 'center',
    marginVertical: 12,
  },
  statValue: {
    fontSize: 24,
    fontWeight: 'bold',
  },
  statLabel: {
    fontSize: 12,
    marginTop: 4,
  },
  disclaimer: {
    marginTop: 16,
  },
  disclaimerText: {
    fontSize: 12,
    lineHeight: 18,
  },
});
