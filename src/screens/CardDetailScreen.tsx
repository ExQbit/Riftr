import React from 'react';
import {
  View,
  StyleSheet,
  ScrollView,
  Image,
  Dimensions,
} from 'react-native';
import {
  Text,
  useTheme,
  Surface,
  Button,
  Chip,
  FAB,
  IconButton,
  Title,
  Paragraph,
} from 'react-native-paper';
import { useRoute, useNavigation, RouteProp } from '@react-navigation/native';
import { Ionicons } from '@expo/vector-icons';
import { getCardById } from '../data/mockCards';
import { useCollectionStore } from '../store';
import { COLORS } from '../constants';
import { RootStackParamList } from '../navigation';
import * as Haptics from 'expo-haptics';

type RouteProps = RouteProp<RootStackParamList, 'CardDetail'>;

const { width } = Dimensions.get('window');
const CARD_WIDTH = width - 32;
const CARD_HEIGHT = CARD_WIDTH * 1.4;

export default function CardDetailScreen() {
  const theme = useTheme();
  const navigation = useNavigation();
  const route = useRoute<RouteProps>();
  const { cardId } = route.params;
  
  const { collection, addToCollection, removeFromCollection, updateQuantity } = useCollectionStore();
  
  const card = getCardById(cardId);
  const owned = collection.get(cardId);
  const quantity = owned?.quantity || 0;

  if (!card) {
    return (
      <View style={[styles.container, { backgroundColor: theme.colors.background }]}>
        <Text>Card not found</Text>
      </View>
    );
  }

  const handleQuantityChange = (delta: number) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    const newQuantity = Math.max(0, quantity + delta);
    updateQuantity(cardId, newQuantity);
  };

  const rarityColor = COLORS[card.rarity as keyof typeof COLORS] || COLORS.common;

  return (
    <ScrollView style={[styles.container, { backgroundColor: theme.colors.background }]}>
      {/* Card Image */}
      <View style={styles.cardImageContainer}>
        <Image
          source={{ uri: card.imageUrl }}
          style={[styles.cardImage, { width: CARD_WIDTH, height: CARD_HEIGHT }]}
          resizeMode="contain"
        />
        
        {/* Rarity Badge */}
        <Chip
          style={[styles.rarityBadge, { backgroundColor: rarityColor }]}
          textStyle={{ color: '#FFFFFF', fontWeight: 'bold' }}
        >
          {card.rarity.toUpperCase()}
        </Chip>
      </View>

      {/* Card Info */}
      <Surface style={[styles.infoContainer, { backgroundColor: theme.colors.surface }]}>
        <Title style={{ color: theme.colors.onSurface }}>{card.name}</Title>
        <Text style={[styles.cardNumber, { color: theme.colors.onSurfaceVariant }]}>
          #{card.cardNumber} • {card.set}
        </Text>

        {/* Stats Row */}
        <View style={styles.statsRow}>
          <Chip icon={() => <Ionicons name="flash" size={16} color="#FFFFFF" />}
                style={[styles.statChip, { backgroundColor: theme.colors.primary }]}>
            {card.energy} Energy
          </Chip>
          
          {card.power !== undefined && (
            <Chip icon={() => <Ionicons name="shield" size={16} color="#FFFFFF" />}
                  style={[styles.statChip, { backgroundColor: '#FF6B6B' }]}>
              {card.power} Power
            </Chip>
          )}
          
          {card.health !== undefined && (
            <Chip icon={() => <Ionicons name="heart" size={16} color="#FFFFFF" />}
                  style={[styles.statChip, { backgroundColor: '#4CAF50' }]}>
              {card.health} Health
            </Chip>
          )}
        </View>

        {/* Type and Domain */}
        <View style={styles.metaRow}>
          <Text style={[styles.metaLabel, { color: theme.colors.onSurfaceVariant }]}>Type:</Text>
          <Text style={[styles.metaValue, { color: theme.colors.onSurface }]}>
            {card.type.charAt(0).toUpperCase() + card.type.slice(1)}
          </Text>
        </View>
        
        <View style={styles.metaRow}>
          <Text style={[styles.metaLabel, { color: theme.colors.onSurfaceVariant }]}>Domain:</Text>
          <Text style={[styles.metaValue, { color: theme.colors.onSurface }]}>
            {card.domain.join(', ')}
          </Text>
        </View>

        {/* Abilities */}
        {card.abilities.length > 0 && (
          <>
            <Text style={[styles.sectionTitle, { color: theme.colors.onSurface }]}>Abilities</Text>
            <View style={styles.abilitiesContainer}>
              {card.abilities.map((ability, index) => (
                <Chip key={index} style={styles.abilityChip}>
                  {ability}
                </Chip>
              ))}
            </View>
          </>
        )}

        {/* Card Text */}
        {card.text && (
          <>
            <Text style={[styles.sectionTitle, { color: theme.colors.onSurface }]}>Card Text</Text>
            <Paragraph style={{ color: theme.colors.onSurface }}>{card.text}</Paragraph>
          </>
        )}

        {/* Flavor Text */}
        {card.flavorText && (
          <>
            <Text style={[styles.sectionTitle, { color: theme.colors.onSurface }]}>Flavor Text</Text>
            <Paragraph style={[styles.flavorText, { color: theme.colors.onSurfaceVariant }]}>
              {card.flavorText}
            </Paragraph>
          </>
        )}

        {/* Artist */}
        <View style={styles.metaRow}>
          <Text style={[styles.metaLabel, { color: theme.colors.onSurfaceVariant }]}>Artist:</Text>
          <Text style={[styles.metaValue, { color: theme.colors.onSurface }]}>
            {card.artist}
          </Text>
        </View>

        {/* Collection Controls */}
        <View style={styles.collectionSection}>
          <Text style={[styles.sectionTitle, { color: theme.colors.onSurface }]}>
            My Collection
          </Text>
          
          <View style={styles.quantityControls}>
            <IconButton
              icon="minus-circle"
              size={32}
              onPress={() => handleQuantityChange(-1)}
              disabled={quantity === 0}
            />
            
            <View style={[styles.quantityDisplay, { backgroundColor: theme.colors.surfaceVariant }]}>
              <Text style={[styles.quantityText, { color: theme.colors.onSurface }]}>
                {quantity}
              </Text>
              <Text style={[styles.quantityLabel, { color: theme.colors.onSurfaceVariant }]}>
                Owned
              </Text>
            </View>
            
            <IconButton
              icon="plus-circle"
              size={32}
              onPress={() => handleQuantityChange(1)}
            />
          </View>
          
          {quantity === 0 ? (
            <Button
              mode="contained"
              onPress={() => addToCollection(cardId)}
              style={styles.addButton}
            >
              Add to Collection
            </Button>
          ) : (
            <Button
              mode="outlined"
              onPress={() => updateQuantity(cardId, 0)}
              style={styles.removeButton}
            >
              Remove from Collection
            </Button>
          )}
        </View>

        {/* Legality */}
        <View style={styles.legalitySection}>
          <Text style={[styles.sectionTitle, { color: theme.colors.onSurface }]}>Format Legality</Text>
          <View style={styles.legalityRow}>
            <Chip
              style={[
                styles.legalityChip,
                { backgroundColor: card.legality.standard ? '#4CAF50' : '#FF6B6B' },
              ]}
              textStyle={{ color: '#FFFFFF' }}
            >
              Standard: {card.legality.standard ? '✓' : '✗'}
            </Chip>
            <Chip
              style={[
                styles.legalityChip,
                { backgroundColor: card.legality.limited ? '#4CAF50' : '#FF6B6B' },
              ]}
              textStyle={{ color: '#FFFFFF' }}
            >
              Limited: {card.legality.limited ? '✓' : '✗'}
            </Chip>
          </View>
        </View>
      </Surface>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  cardImageContainer: {
    alignItems: 'center',
    padding: 16,
  },
  cardImage: {
    borderRadius: 12,
  },
  rarityBadge: {
    position: 'absolute',
    top: 24,
    right: 24,
  },
  infoContainer: {
    margin: 16,
    padding: 16,
    borderRadius: 12,
    elevation: 2,
  },
  cardNumber: {
    fontSize: 14,
    marginTop: 4,
  },
  statsRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    marginTop: 16,
  },
  statChip: {
    marginRight: 8,
    marginBottom: 8,
  },
  metaRow: {
    flexDirection: 'row',
    marginTop: 12,
  },
  metaLabel: {
    fontSize: 14,
    fontWeight: 'bold',
    marginRight: 8,
  },
  metaValue: {
    fontSize: 14,
    flex: 1,
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    marginTop: 16,
    marginBottom: 8,
  },
  abilitiesContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
  },
  abilityChip: {
    marginRight: 8,
    marginBottom: 8,
  },
  flavorText: {
    fontStyle: 'italic',
  },
  collectionSection: {
    marginTop: 24,
    paddingTop: 16,
    borderTopWidth: 1,
    borderTopColor: 'rgba(0,0,0,0.1)',
  },
  quantityControls: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    marginVertical: 16,
  },
  quantityDisplay: {
    paddingHorizontal: 24,
    paddingVertical: 12,
    borderRadius: 8,
    marginHorizontal: 16,
    alignItems: 'center',
  },
  quantityText: {
    fontSize: 24,
    fontWeight: 'bold',
  },
  quantityLabel: {
    fontSize: 12,
  },
  addButton: {
    marginTop: 8,
  },
  removeButton: {
    marginTop: 8,
  },
  legalitySection: {
    marginTop: 16,
  },
  legalityRow: {
    flexDirection: 'row',
  },
  legalityChip: {
    marginRight: 8,
  },
});
