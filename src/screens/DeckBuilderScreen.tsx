import React, { useState, useEffect } from 'react';
import {
  View,
  StyleSheet,
  ScrollView,
  TextInput,
} from 'react-native';
import {
  Text,
  useTheme,
  Surface,
  Button,
  Chip,
  List,
  IconButton,
  Divider,
  Title,
} from 'react-native-paper';
import { useRoute, useNavigation, RouteProp } from '@react-navigation/native';
import { useDeckStore } from '../store';
import { mockCards } from '../data/mockCards';
import { Card, DeckCard } from '../types';
import { RootStackParamList } from '../navigation';
import { COLORS } from '../constants';

type RouteProps = RouteProp<RootStackParamList, 'DeckBuilder'>;

export default function DeckBuilderScreen() {
  const theme = useTheme();
  const navigation = useNavigation();
  const route = useRoute<RouteProps>();
  const { deckId } = route.params;
  
  const { decks, createDeck, updateDeck } = useDeckStore();
  const existingDeck = deckId ? decks.find(d => d.id === deckId) : null;
  
  const [deckName, setDeckName] = useState(existingDeck?.name || '');
  const [deckCards, setDeckCards] = useState<DeckCard[]>(existingDeck?.cards || []);
  const [selectedFormat, setSelectedFormat] = useState<'standard' | 'limited' | 'unlimited'>(
    existingDeck?.format || 'standard'
  );
  const [notes, setNotes] = useState(existingDeck?.notes || '');
  const [searchQuery, setSearchQuery] = useState('');

  const totalCards = deckCards.reduce((sum, card) => sum + card.quantity, 0);
  const energyCurve = deckCards.reduce((curve, deckCard) => {
    const card = mockCards.find(c => c.id === deckCard.cardId);
    if (card) {
      curve[card.energy] = (curve[card.energy] || 0) + deckCard.quantity;
    }
    return curve;
  }, {} as Record<number, number>);

  const filteredCards = mockCards.filter(card =>
    card.name.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const addCardToDeck = (card: Card) => {
    const existingCard = deckCards.find(dc => dc.cardId === card.id);
    if (existingCard) {
      if (existingCard.quantity < 3) { // Max 3 copies per card
        setDeckCards(deckCards.map(dc =>
          dc.cardId === card.id
            ? { ...dc, quantity: dc.quantity + 1 }
            : dc
        ));
      }
    } else {
      setDeckCards([...deckCards, { cardId: card.id, quantity: 1 }]);
    }
  };

  const removeCardFromDeck = (cardId: string) => {
    const existingCard = deckCards.find(dc => dc.cardId === cardId);
    if (existingCard) {
      if (existingCard.quantity > 1) {
        setDeckCards(deckCards.map(dc =>
          dc.cardId === cardId
            ? { ...dc, quantity: dc.quantity - 1 }
            : dc
        ));
      } else {
        setDeckCards(deckCards.filter(dc => dc.cardId !== cardId));
      }
    }
  };

  const saveDeck = () => {
    if (!deckName.trim()) {
      return; // Show error
    }

    const deckData = {
      name: deckName,
      cards: deckCards,
      format: selectedFormat,
      notes,
      champion: deckCards.find(dc => {
        const card = mockCards.find(c => c.id === dc.cardId);
        return card?.type === 'champion';
      })?.cardId,
    };

    if (deckId) {
      updateDeck(deckId, deckData);
    } else {
      createDeck(deckData);
    }

    navigation.goBack();
  };

  return (
    <ScrollView style={[styles.container, { backgroundColor: theme.colors.background }]}>
      {/* Deck Name */}
      <Surface style={[styles.section, { backgroundColor: theme.colors.surface }]}>
        <TextInput
          style={[styles.nameInput, { color: theme.colors.onSurface }]}
          placeholder="Deck Name"
          placeholderTextColor={theme.colors.onSurfaceVariant}
          value={deckName}
          onChangeText={setDeckName}
        />
        
        <View style={styles.formatRow}>
          <Text style={{ color: theme.colors.onSurfaceVariant }}>Format:</Text>
          {(['standard', 'limited', 'unlimited'] as const).map(format => (
            <Chip
              key={format}
              selected={selectedFormat === format}
              onPress={() => setSelectedFormat(format)}
              style={styles.formatChip}
            >
              {format.charAt(0).toUpperCase() + format.slice(1)}
            </Chip>
          ))}
        </View>
      </Surface>

      {/* Deck Stats */}
      <Surface style={[styles.section, { backgroundColor: theme.colors.surface }]}>
        <Title style={{ color: theme.colors.onSurface }}>Deck Stats</Title>
        <View style={styles.statsRow}>
          <Chip style={styles.statChip}>
            {totalCards}/60 Cards
          </Chip>
          <Chip style={styles.statChip}>
            {deckCards.length} Unique
          </Chip>
        </View>
        
        <Text style={[styles.curveTitle, { color: theme.colors.onSurface }]}>Energy Curve</Text>
        <View style={styles.curveContainer}>
          {[0, 1, 2, 3, 4, 5, 6, 7, 8, 9].map(energy => (
            <View key={energy} style={styles.curveBar}>
              <View
                style={[
                  styles.curveBarFill,
                  {
                    backgroundColor: theme.colors.primary,
                    height: (energyCurve[energy] || 0) * 10,
                  },
                ]}
              />
              <Text style={{ color: theme.colors.onSurfaceVariant, fontSize: 10 }}>
                {energy}
              </Text>
            </View>
          ))}
        </View>
      </Surface>

      {/* Current Deck */}
      <Surface style={[styles.section, { backgroundColor: theme.colors.surface }]}>
        <Title style={{ color: theme.colors.onSurface }}>Cards in Deck</Title>
        {deckCards.length === 0 ? (
          <Text style={{ color: theme.colors.onSurfaceVariant }}>
            No cards in deck yet
          </Text>
        ) : (
          deckCards.map(deckCard => {
            const card = mockCards.find(c => c.id === deckCard.cardId);
            if (!card) return null;
            
            return (
              <View key={deckCard.cardId}>
                <List.Item
                  title={`${card.name} x${deckCard.quantity}`}
                  description={`${card.type} • ${card.energy}⚡`}
                  left={() => (
                    <View
                      style={[
                        styles.rarityIndicator,
                        { backgroundColor: COLORS[card.rarity as keyof typeof COLORS] },
                      ]}
                    />
                  )}
                  right={() => (
                    <View style={styles.cardActions}>
                      <IconButton
                        icon="minus"
                        size={20}
                        onPress={() => removeCardFromDeck(card.id)}
                      />
                      <Text style={{ color: theme.colors.onSurface }}>
                        {deckCard.quantity}
                      </Text>
                      <IconButton
                        icon="plus"
                        size={20}
                        onPress={() => addCardToDeck(card)}
                        disabled={deckCard.quantity >= 3}
                      />
                    </View>
                  )}
                />
                <Divider />
              </View>
            );
          })
        )}
      </Surface>

      {/* Card Search */}
      <Surface style={[styles.section, { backgroundColor: theme.colors.surface }]}>
        <Title style={{ color: theme.colors.onSurface }}>Add Cards</Title>
        <TextInput
          style={[styles.searchInput, { color: theme.colors.onSurface }]}
          placeholder="Search cards..."
          placeholderTextColor={theme.colors.onSurfaceVariant}
          value={searchQuery}
          onChangeText={setSearchQuery}
        />
        
        <ScrollView style={styles.searchResults}>
          {filteredCards.slice(0, 10).map(card => (
            <View key={card.id}>
              <List.Item
                title={card.name}
                description={`${card.type} • ${card.energy}⚡`}
                onPress={() => addCardToDeck(card)}
                left={() => (
                  <View
                    style={[
                      styles.rarityIndicator,
                      { backgroundColor: COLORS[card.rarity as keyof typeof COLORS] },
                    ]}
                  />
                )}
                right={() => {
                  const inDeck = deckCards.find(dc => dc.cardId === card.id);
                  return inDeck ? (
                    <Chip>{inDeck.quantity}</Chip>
                  ) : null;
                }}
              />
              <Divider />
            </View>
          ))}
        </ScrollView>
      </Surface>

      {/* Notes */}
      <Surface style={[styles.section, { backgroundColor: theme.colors.surface }]}>
        <Title style={{ color: theme.colors.onSurface }}>Notes</Title>
        <TextInput
          style={[styles.notesInput, { color: theme.colors.onSurface }]}
          placeholder="Deck notes..."
          placeholderTextColor={theme.colors.onSurfaceVariant}
          value={notes}
          onChangeText={setNotes}
          multiline
          numberOfLines={3}
        />
      </Surface>

      {/* Save Button */}
      <View style={styles.buttonContainer}>
        <Button
          mode="contained"
          onPress={saveDeck}
          disabled={!deckName.trim() || deckCards.length === 0}
        >
          {deckId ? 'Update Deck' : 'Create Deck'}
        </Button>
        <Button
          mode="outlined"
          onPress={() => navigation.goBack()}
          style={{ marginTop: 8 }}
        >
          Cancel
        </Button>
      </View>
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
  nameInput: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 12,
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(0,0,0,0.1)',
    paddingBottom: 8,
  },
  formatRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  formatChip: {
    marginLeft: 8,
  },
  statsRow: {
    flexDirection: 'row',
    marginTop: 8,
  },
  statChip: {
    marginRight: 8,
  },
  curveTitle: {
    marginTop: 16,
    marginBottom: 8,
    fontWeight: 'bold',
  },
  curveContainer: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    height: 60,
  },
  curveBar: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'flex-end',
  },
  curveBarFill: {
    width: '80%',
    marginBottom: 4,
  },
  rarityIndicator: {
    width: 8,
    height: '100%',
    marginRight: 8,
  },
  cardActions: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  searchInput: {
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(0,0,0,0.1)',
    paddingBottom: 8,
    marginBottom: 8,
  },
  searchResults: {
    maxHeight: 300,
  },
  notesInput: {
    borderWidth: 1,
    borderColor: 'rgba(0,0,0,0.1)',
    borderRadius: 8,
    padding: 8,
    marginTop: 8,
  },
  buttonContainer: {
    padding: 16,
    paddingBottom: 32,
  },
});
