import React, { useState, useMemo } from 'react';
import {
  View,
  StyleSheet,
  FlatList,
  TouchableOpacity,
  Image,
  Dimensions,
} from 'react-native';
import {
  Text,
  useTheme,
  Searchbar,
  Chip,
  Surface,
  Badge,
  ProgressBar,
  FAB,
} from 'react-native-paper';
import { useNavigation } from '@react-navigation/native';
import { StackNavigationProp } from '@react-navigation/stack';
import { Ionicons } from '@expo/vector-icons';
import { useCollectionStore, useSettingsStore } from '../store';
import { mockCards } from '../data/mockCards';
import { Card } from '../types';
import { COLORS, FILTER_OPTIONS } from '../constants';
import { RootStackParamList } from '../navigation';
import * as Haptics from 'expo-haptics';

type NavigationProp = StackNavigationProp<RootStackParamList, 'MainTabs'>;

const { width } = Dimensions.get('window');

export default function CollectionScreen() {
  const theme = useTheme();
  const navigation = useNavigation<NavigationProp>();
  const { collection, toggleOwned, getCollectionStats } = useCollectionStore();
  const { settings } = useSettingsStore();
  const stats = useMemo(() => getCollectionStats(), [collection.size]);
  
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedRarity, setSelectedRarity] = useState('All');
  const [selectedType, setSelectedType] = useState('All');
  const [showOnlyOwned, setShowOnlyOwned] = useState(false);

  const CARD_SIZE = (width - (settings.gridColumns + 1) * 8) / settings.gridColumns;

  // Filter cards based on search and filters
  const filteredCards = useMemo(() => {
    return mockCards.filter((card) => {
      // Search filter
      if (searchQuery && !card.name.toLowerCase().includes(searchQuery.toLowerCase())) {
        return false;
      }

      // Rarity filter
      if (selectedRarity !== 'All' && card.rarity !== selectedRarity.toLowerCase()) {
        return false;
      }

      // Type filter
      if (selectedType !== 'All' && card.type !== selectedType.toLowerCase()) {
        return false;
      }

      // Owned filter
      if (showOnlyOwned && !collection.has(card.id)) {
        return false;
      }

      return true;
    });
  }, [searchQuery, selectedRarity, selectedType, showOnlyOwned, collection]);

  const handleCardPress = (card: Card) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    navigation.navigate('CardDetail', { cardId: card.id });
  };

  const handleCardLongPress = (card: Card) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    toggleOwned(card.id);
  };

  const renderCard = ({ item }: { item: Card }) => {
    const owned = collection.get(item.id);
    const quantity = owned?.quantity || 0;
    const isOwned = quantity > 0;

    return (
      <TouchableOpacity
        style={[
          styles.cardContainer,
          { width: CARD_SIZE, height: CARD_SIZE * 1.4 },
        ]}
        onPress={() => handleCardPress(item)}
        onLongPress={() => handleCardLongPress(item)}
        delayLongPress={500}
      >
        <View style={[styles.card, !isOwned && styles.unownedCard]}>
          <Image
            source={{ uri: item.imageUrl }}
            style={styles.cardImage}
            resizeMode="cover"
          />
          
          {/* Owned Indicator */}
          {isOwned && (
            <View style={[styles.ownedIndicator, { backgroundColor: theme.colors.primary }]}>
              <Ionicons name="checkmark" size={16} color="#FFFFFF" />
            </View>
          )}
          
          {/* Quantity Badge */}
          {quantity > 1 && (
            <Badge style={styles.quantityBadge}>{quantity}</Badge>
          )}
          
          {/* Rarity Indicator */}
          <View
            style={[
              styles.rarityIndicator,
              { backgroundColor: COLORS[item.rarity as keyof typeof COLORS] || COLORS.common },
            ]}
          />
        </View>
        
        <Text
          style={[styles.cardName, { color: theme.colors.onBackground }]}
          numberOfLines={1}
        >
          {item.name}
        </Text>
        <Text style={[styles.cardNumber, { color: theme.colors.onSurfaceVariant }]}>
          #{item.cardNumber}
        </Text>
      </TouchableOpacity>
    );
  };

  return (
    <View style={[styles.container, { backgroundColor: theme.colors.background }]}>
      {/* Collection Stats */}
      <Surface style={[styles.statsContainer, { backgroundColor: theme.colors.surface }]}>
        <View style={styles.statsRow}>
          <View style={styles.statItem}>
            <Text style={[styles.statLabel, { color: theme.colors.onSurfaceVariant }]}>
              Unique Cards
            </Text>
            <Text style={[styles.statValue, { color: theme.colors.primary }]}>
              {stats.uniqueCards}/50
            </Text>
          </View>
          <View style={styles.statItem}>
            <Text style={[styles.statLabel, { color: theme.colors.onSurfaceVariant }]}>
              Total Cards
            </Text>
            <Text style={[styles.statValue, { color: theme.colors.onSurface }]}>
              {stats.totalCards}
            </Text>
          </View>
        </View>
        <View style={styles.progressContainer}>
          <Text style={[styles.progressLabel, { color: theme.colors.onSurfaceVariant }]}>
            Set Completion
          </Text>
          <ProgressBar
            progress={stats.completionRate / 100}
            color={theme.colors.primary}
            style={styles.progressBar}
          />
          <Text style={[styles.progressText, { color: theme.colors.onSurface }]}>
            {stats.completionRate.toFixed(1)}%
          </Text>
        </View>
      </Surface>

      {/* Search Bar */}
      <Searchbar
        placeholder="Search cards..."
        onChangeText={setSearchQuery}
        value={searchQuery}
        style={[styles.searchBar, { backgroundColor: theme.colors.surfaceVariant }]}
      />

      {/* Filters */}
      <View style={styles.filterContainer}>
        <Chip
          selected={showOnlyOwned}
          onPress={() => setShowOnlyOwned(!showOnlyOwned)}
          style={styles.filterChip}
        >
          Owned Only
        </Chip>
        
        <Chip
          selected={selectedRarity !== 'All'}
          onPress={() => {
            // Cycle through rarities
            const rarities = FILTER_OPTIONS.rarity;
            const currentIndex = rarities.indexOf(selectedRarity);
            const nextIndex = (currentIndex + 1) % rarities.length;
            setSelectedRarity(rarities[nextIndex]);
          }}
          style={styles.filterChip}
        >
          {selectedRarity === 'All' ? 'Rarity' : selectedRarity}
        </Chip>
        
        <Chip
          selected={selectedType !== 'All'}
          onPress={() => {
            // Cycle through types
            const types = FILTER_OPTIONS.type;
            const currentIndex = types.indexOf(selectedType);
            const nextIndex = (currentIndex + 1) % types.length;
            setSelectedType(types[nextIndex]);
          }}
          style={styles.filterChip}
        >
          {selectedType === 'All' ? 'Type' : selectedType}
        </Chip>
      </View>

      {/* Cards Grid */}
      <FlatList
        data={filteredCards}
        renderItem={renderCard}
        keyExtractor={(item) => item.id}
        numColumns={settings.gridColumns}
        contentContainerStyle={styles.gridContainer}
        showsVerticalScrollIndicator={false}
        key={settings.gridColumns} // Force re-render on column change
      />

      {/* FAB for Import/Export */}
      <FAB
        icon="database-export"
        style={[styles.fab, { backgroundColor: theme.colors.primary }]}
        onPress={() => {
          // TODO: Implement import/export functionality
          console.log('Import/Export');
        }}
        color="#FFFFFF"
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  statsContainer: {
    padding: 16,
    elevation: 2,
  },
  statsRow: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    marginBottom: 12,
  },
  statItem: {
    alignItems: 'center',
  },
  statLabel: {
    fontSize: 12,
    marginBottom: 4,
  },
  statValue: {
    fontSize: 20,
    fontWeight: 'bold',
  },
  progressContainer: {
    marginTop: 8,
  },
  progressLabel: {
    fontSize: 12,
    marginBottom: 4,
  },
  progressBar: {
    height: 8,
    borderRadius: 4,
  },
  progressText: {
    fontSize: 12,
    marginTop: 4,
    textAlign: 'right',
  },
  searchBar: {
    margin: 16,
    elevation: 0,
  },
  filterContainer: {
    flexDirection: 'row',
    paddingHorizontal: 16,
    marginBottom: 16,
    flexWrap: 'wrap',
  },
  filterChip: {
    marginRight: 8,
    marginBottom: 8,
  },
  gridContainer: {
    paddingHorizontal: 4,
    paddingBottom: 80,
  },
  cardContainer: {
    margin: 4,
    alignItems: 'center',
  },
  card: {
    width: '100%',
    flex: 1,
    borderRadius: 8,
    overflow: 'hidden',
    elevation: 2,
  },
  unownedCard: {
    opacity: 0.4,
  },
  cardImage: {
    width: '100%',
    height: '100%',
  },
  ownedIndicator: {
    position: 'absolute',
    top: 4,
    right: 4,
    width: 24,
    height: 24,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  quantityBadge: {
    position: 'absolute',
    top: 4,
    left: 4,
    backgroundColor: '#FF6B6B',
  },
  rarityIndicator: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    height: 4,
  },
  cardName: {
    fontSize: 11,
    fontWeight: '500',
    marginTop: 4,
  },
  cardNumber: {
    fontSize: 10,
  },
  fab: {
    position: 'absolute',
    margin: 16,
    right: 0,
    bottom: 0,
  },
});
