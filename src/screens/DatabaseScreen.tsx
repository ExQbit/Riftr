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
  List,
  Divider,
} from 'react-native-paper';
import { useNavigation } from '@react-navigation/native';
import { StackNavigationProp } from '@react-navigation/stack';
import { Ionicons } from '@expo/vector-icons';
import { mockCards } from '../data/mockCards';
import { Card } from '../types';
import { COLORS, FILTER_OPTIONS } from '../constants';
import { RootStackParamList } from '../navigation';
import { useCollectionStore } from '../store';
import * as Haptics from 'expo-haptics';

type NavigationProp = StackNavigationProp<RootStackParamList, 'MainTabs'>;

const { width } = Dimensions.get('window');

export default function DatabaseScreen() {
  const theme = useTheme();
  const navigation = useNavigation<NavigationProp>();
  const { collection } = useCollectionStore();
  
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedRarity, setSelectedRarity] = useState('All');
  const [selectedType, setSelectedType] = useState('All');
  const [selectedDomain, setSelectedDomain] = useState('All');
  const [viewMode, setViewMode] = useState<'list' | 'grid'>('list');

  // Filter and sort cards
  const filteredCards = useMemo(() => {
    return mockCards.filter((card) => {
      if (searchQuery && !card.name.toLowerCase().includes(searchQuery.toLowerCase())) {
        return false;
      }
      if (selectedRarity !== 'All' && card.rarity !== selectedRarity.toLowerCase()) {
        return false;
      }
      if (selectedType !== 'All' && card.type !== selectedType.toLowerCase()) {
        return false;
      }
      if (selectedDomain !== 'All' && !card.domain.includes(selectedDomain as any)) {
        return false;
      }
      return true;
    }).sort((a, b) => a.name.localeCompare(b.name));
  }, [searchQuery, selectedRarity, selectedType, selectedDomain]);

  const handleCardPress = (card: Card) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    navigation.navigate('CardDetail', { cardId: card.id });
  };

  const renderListItem = ({ item }: { item: Card }) => {
    const owned = collection.get(item.id);
    const isOwned = owned && owned.quantity > 0;

    return (
      <TouchableOpacity onPress={() => handleCardPress(item)}>
        <List.Item
          title={item.name}
          description={`${item.type.charAt(0).toUpperCase() + item.type.slice(1)} • ${item.domain.join(', ')}`}
          left={() => (
            <View style={styles.listItemLeft}>
              <View
                style={[
                  styles.rarityDot,
                  { backgroundColor: COLORS[item.rarity as keyof typeof COLORS] || COLORS.common },
                ]}
              />
              <Image source={{ uri: item.imageUrl }} style={styles.listThumbnail} />
            </View>
          )}
          right={() => (
            <View style={styles.listItemRight}>
              {isOwned && (
                <Ionicons name="checkmark-circle" size={20} color={theme.colors.primary} />
              )}
              <Text style={[styles.energyCost, { color: theme.colors.primary }]}>
                {item.energy}⚡
              </Text>
            </View>
          )}
          style={{ backgroundColor: theme.colors.surface }}
          titleStyle={{ color: theme.colors.onSurface }}
          descriptionStyle={{ color: theme.colors.onSurfaceVariant }}
        />
        <Divider />
      </TouchableOpacity>
    );
  };

  const renderGridItem = ({ item }: { item: Card }) => {
    const owned = collection.get(item.id);
    const isOwned = owned && owned.quantity > 0;
    const CARD_WIDTH = (width - 32) / 3;

    return (
      <TouchableOpacity
        style={[styles.gridCard, { width: CARD_WIDTH, height: CARD_WIDTH * 1.4 }]}
        onPress={() => handleCardPress(item)}
      >
        <Image source={{ uri: item.imageUrl }} style={styles.gridImage} />
        {isOwned && (
          <View style={[styles.gridOwnedIndicator, { backgroundColor: theme.colors.primary }]}>
            <Ionicons name="checkmark" size={12} color="#FFFFFF" />
          </View>
        )}
      </TouchableOpacity>
    );
  };

  return (
    <View style={[styles.container, { backgroundColor: theme.colors.background }]}>
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
          selected={selectedRarity !== 'All'}
          onPress={() => {
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
            const types = FILTER_OPTIONS.type;
            const currentIndex = types.indexOf(selectedType);
            const nextIndex = (currentIndex + 1) % types.length;
            setSelectedType(types[nextIndex]);
          }}
          style={styles.filterChip}
        >
          {selectedType === 'All' ? 'Type' : selectedType}
        </Chip>
        
        <Chip
          selected={selectedDomain !== 'All'}
          onPress={() => {
            const domains = FILTER_OPTIONS.domain;
            const currentIndex = domains.indexOf(selectedDomain);
            const nextIndex = (currentIndex + 1) % domains.length;
            setSelectedDomain(domains[nextIndex]);
          }}
          style={styles.filterChip}
        >
          {selectedDomain === 'All' ? 'Domain' : selectedDomain}
        </Chip>

        <View style={{ flex: 1 }} />
        
        <TouchableOpacity
          onPress={() => setViewMode(viewMode === 'list' ? 'grid' : 'list')}
          style={styles.viewModeButton}
        >
          <Ionicons
            name={viewMode === 'list' ? 'grid' : 'list'}
            size={24}
            color={theme.colors.onSurface}
          />
        </TouchableOpacity>
      </View>

      {/* Results Count */}
      <Text style={[styles.resultsCount, { color: theme.colors.onSurfaceVariant }]}>
        {filteredCards.length} cards found
      </Text>

      {/* Cards List/Grid */}
      <FlatList
        data={filteredCards}
        renderItem={viewMode === 'list' ? renderListItem : renderGridItem}
        keyExtractor={(item) => item.id}
        numColumns={viewMode === 'grid' ? 3 : 1}
        key={viewMode}
        contentContainerStyle={styles.listContainer}
        showsVerticalScrollIndicator={false}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  searchBar: {
    margin: 16,
    elevation: 0,
  },
  filterContainer: {
    flexDirection: 'row',
    paddingHorizontal: 16,
    marginBottom: 8,
    alignItems: 'center',
    flexWrap: 'wrap',
  },
  filterChip: {
    marginRight: 8,
    marginBottom: 8,
  },
  viewModeButton: {
    padding: 8,
  },
  resultsCount: {
    paddingHorizontal: 16,
    paddingBottom: 8,
    fontSize: 12,
  },
  listContainer: {
    paddingBottom: 16,
  },
  listItemLeft: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  rarityDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    marginRight: 8,
  },
  listThumbnail: {
    width: 50,
    height: 70,
    borderRadius: 4,
  },
  listItemRight: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  energyCost: {
    fontSize: 16,
    fontWeight: 'bold',
    marginLeft: 12,
  },
  gridCard: {
    margin: 5,
    borderRadius: 8,
    overflow: 'hidden',
  },
  gridImage: {
    width: '100%',
    height: '100%',
  },
  gridOwnedIndicator: {
    position: 'absolute',
    top: 4,
    right: 4,
    width: 20,
    height: 20,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
  },
});
