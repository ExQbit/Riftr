import React from 'react';
import {
  View,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
} from 'react-native';
import {
  Text,
  useTheme,
  Card,
  Title,
  Paragraph,
  FAB,
  IconButton,
  Chip,
  Surface,
} from 'react-native-paper';
import { useNavigation } from '@react-navigation/native';
import { StackNavigationProp } from '@react-navigation/stack';
import { Ionicons } from '@expo/vector-icons';
import { useDeckStore, useCollectionStore } from '../store';
import { RootStackParamList } from '../navigation';
import { COLORS } from '../constants';
import * as Haptics from 'expo-haptics';

type NavigationProp = StackNavigationProp<RootStackParamList, 'MainTabs'>;

export default function DecksScreen() {
  const theme = useTheme();
  const navigation = useNavigation<NavigationProp>();
  const { decks, deleteDeck, duplicateDeck } = useDeckStore();
  const { collection } = useCollectionStore();

  const handleCreateDeck = () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    navigation.navigate('DeckBuilder', {});
  };

  const handleEditDeck = (deckId: string) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    navigation.navigate('DeckBuilder', { deckId });
  };

  const handleDeleteDeck = (deckId: string) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    deleteDeck(deckId);
  };

  const handleDuplicateDeck = (deckId: string) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    duplicateDeck(deckId);
  };

  const calculateDeckStats = (deck: typeof decks[0]) => {
    const totalCards = deck.cards.reduce((sum, card) => sum + card.quantity, 0);
    const uniqueCards = deck.cards.length;
    const ownedCards = deck.cards.filter(card => collection.has(card.cardId)).length;
    const completion = uniqueCards > 0 ? (ownedCards / uniqueCards) * 100 : 0;

    return { totalCards, uniqueCards, ownedCards, completion };
  };

  return (
    <View style={[styles.container, { backgroundColor: theme.colors.background }]}>
      <ScrollView contentContainerStyle={styles.scrollContent}>
        {decks.length === 0 ? (
          <Surface style={[styles.emptyState, { backgroundColor: theme.colors.surface }]}>
            <Ionicons name="layers-outline" size={64} color={theme.colors.onSurfaceVariant} />
            <Title style={{ color: theme.colors.onSurface, marginTop: 16 }}>
              No Decks Yet
            </Title>
            <Paragraph style={{ color: theme.colors.onSurfaceVariant, textAlign: 'center' }}>
              Create your first deck to start building your perfect strategy
            </Paragraph>
          </Surface>
        ) : (
          decks.map((deck) => {
            const stats = calculateDeckStats(deck);
            return (
              <Card
                key={deck.id}
                style={[styles.deckCard, { backgroundColor: theme.colors.surface }]}
                onPress={() => handleEditDeck(deck.id)}
              >
                <Card.Content>
                  <View style={styles.deckHeader}>
                    <View style={styles.deckInfo}>
                      <Title style={{ color: theme.colors.onSurface }}>{deck.name}</Title>
                      {deck.champion && (
                        <Text style={{ color: theme.colors.primary }}>
                          Champion: {deck.champion}
                        </Text>
                      )}
                    </View>
                    <View style={styles.deckActions}>
                      <IconButton
                        icon="content-duplicate"
                        size={20}
                        onPress={() => handleDuplicateDeck(deck.id)}
                      />
                      <IconButton
                        icon="delete"
                        size={20}
                        onPress={() => handleDeleteDeck(deck.id)}
                      />
                    </View>
                  </View>

                  <View style={styles.statsContainer}>
                    <Chip style={styles.statChip}>
                      {stats.totalCards} Cards
                    </Chip>
                    <Chip style={styles.statChip}>
                      {stats.uniqueCards} Unique
                    </Chip>
                    <Chip
                      style={[
                        styles.statChip,
                        { backgroundColor: stats.completion === 100 ? '#4CAF50' : undefined },
                      ]}
                      textStyle={{ color: stats.completion === 100 ? '#FFFFFF' : undefined }}
                    >
                      {stats.completion.toFixed(0)}% Owned
                    </Chip>
                  </View>

                  <View style={styles.formatContainer}>
                    <Text style={[styles.formatLabel, { color: theme.colors.onSurfaceVariant }]}>
                      Format: {deck.format}
                    </Text>
                    <Text style={[styles.dateLabel, { color: theme.colors.onSurfaceVariant }]}>
                      Modified: {new Date(deck.dateModified).toLocaleDateString()}
                    </Text>
                  </View>

                  {deck.notes && (
                    <Paragraph
                      style={[styles.notes, { color: theme.colors.onSurfaceVariant }]}
                      numberOfLines={2}
                    >
                      {deck.notes}
                    </Paragraph>
                  )}
                </Card.Content>
              </Card>
            );
          })
        )}
      </ScrollView>

      <FAB
        icon="plus"
        style={[styles.fab, { backgroundColor: theme.colors.primary }]}
        onPress={handleCreateDeck}
        color="#FFFFFF"
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  scrollContent: {
    padding: 16,
    paddingBottom: 80,
  },
  emptyState: {
    padding: 48,
    borderRadius: 12,
    alignItems: 'center',
    elevation: 2,
  },
  deckCard: {
    marginBottom: 16,
    borderRadius: 12,
    elevation: 2,
  },
  deckHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
  },
  deckInfo: {
    flex: 1,
  },
  deckActions: {
    flexDirection: 'row',
  },
  statsContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    marginTop: 12,
  },
  statChip: {
    marginRight: 8,
    marginBottom: 8,
  },
  formatContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: 8,
  },
  formatLabel: {
    fontSize: 12,
  },
  dateLabel: {
    fontSize: 12,
  },
  notes: {
    marginTop: 8,
    fontSize: 14,
    fontStyle: 'italic',
  },
  fab: {
    position: 'absolute',
    margin: 16,
    right: 0,
    bottom: 0,
  },
});
