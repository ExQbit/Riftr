import React, { useState, useEffect } from 'react';
import {
  View,
  StyleSheet,
  Dimensions,
  TouchableOpacity,
  Image,
  Animated,
} from 'react-native';
import {
  Text,
  useTheme,
  Button,
  Title,
  Surface,
} from 'react-native-paper';
import { useRoute, useNavigation, RouteProp } from '@react-navigation/native';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { Card, Rarity } from '../types';
import { mockCards, getCardsByRarity } from '../data/mockCards';
import { useCollectionStore, usePackStore, useStatsStore } from '../store';
import { PACK_CONFIG, COLORS } from '../constants';
import { RootStackParamList } from '../navigation';
import * as Haptics from 'expo-haptics';

type RouteProps = RouteProp<RootStackParamList, 'PackOpening'>;

const { width, height } = Dimensions.get('window');

export default function PackOpeningScreen() {
  const theme = useTheme();
  const navigation = useNavigation();
  const route = useRoute<RouteProps>();
  const { packType } = route.params;
  
  const { addToCollection } = useCollectionStore();
  const { addPackOpening } = usePackStore();
  const { incrementPacksOpened, updateStats } = useStatsStore();
  
  const [stage, setStage] = useState<'unopened' | 'opening' | 'revealed'>('unopened');
  const [pulledCards, setPulledCards] = useState<Card[]>([]);
  const [currentCardIndex, setCurrentCardIndex] = useState(0);
  const [cardAnimations] = useState(() => 
    Array(15).fill(0).map(() => new Animated.Value(0))
  );

  const packConfig = PACK_CONFIG[packType];

  useEffect(() => {
    if (stage === 'opening') {
      generatePackContents();
    }
  }, [stage]);

  const generatePackContents = () => {
    const cards: Card[] = [];
    const config = PACK_CONFIG[packType];

    if (packType === 'starter') {
      // Guaranteed distribution for starter pack
      const champions = getCardsByRarity('legendary');
      const rares = getCardsByRarity('rare');
      const uncommons = getCardsByRarity('uncommon');
      const commons = getCardsByRarity('common');

      cards.push(champions[Math.floor(Math.random() * champions.length)]);
      for (let i = 0; i < 2; i++) {
        cards.push(rares[Math.floor(Math.random() * rares.length)]);
      }
      for (let i = 0; i < 4; i++) {
        cards.push(uncommons[Math.floor(Math.random() * uncommons.length)]);
      }
      for (let i = 0; i < 5; i++) {
        cards.push(commons[Math.floor(Math.random() * commons.length)]);
      }
    } else {
      // Regular booster pack logic
      const distribution = config.distribution as any;
      
      // Check for legendary
      if (Math.random() < (config.legendaryChance || 0)) {
        const legendaries = getCardsByRarity('legendary');
        cards.push(legendaries[Math.floor(Math.random() * legendaries.length)]);
        distribution.rare -= 1; // Replace one rare with legendary
      }

      // Add cards by rarity
      Object.entries(distribution).forEach(([rarity, count]) => {
        const cardsOfRarity = getCardsByRarity(rarity);
        for (let i = 0; i < (count as number); i++) {
          cards.push(cardsOfRarity[Math.floor(Math.random() * cardsOfRarity.length)]);
        }
      });
    }

    // Shuffle cards
    for (let i = cards.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [cards[i], cards[j]] = [cards[j], cards[i]];
    }

    setPulledCards(cards.slice(0, config.cards));
    
    // Add cards to collection
    cards.forEach(card => {
      addToCollection(card.id, 1);
    });

    // Update stats
    incrementPacksOpened();
    const collectionStore = useCollectionStore.getState();
    const stats = collectionStore.getCollectionStats();
    updateStats(stats);

    // Save pack history
    addPackOpening({
      packType,
      cards,
      rarityDistribution: config.distribution || config.guaranteed as any,
    });

    // Start reveal animation
    setTimeout(() => revealCards(), 500);
  };

  const revealCards = () => {
    pulledCards.forEach((_, index) => {
      setTimeout(() => {
        Animated.spring(cardAnimations[index], {
          toValue: 1,
          tension: 50,
          friction: 7,
          useNativeDriver: true,
        }).start();
      }, index * 200);
    });

    setTimeout(() => {
      setStage('revealed');
    }, pulledCards.length * 200 + 500);
  };

  const handleOpenPack = () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Heavy);
    setStage('opening');
  };

  const handleCardTap = (index: number) => {
    if (index === currentCardIndex && index < pulledCards.length - 1) {
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
      setCurrentCardIndex(index + 1);
    }
  };

  const handleFinish = () => {
    navigation.goBack();
  };

  const getRarityGradient = (rarity: Rarity): string[] => {
    switch (rarity) {
      case 'legendary':
        return [COLORS.legendary, '#6B46C1'];
      case 'rare':
        return [COLORS.rare, '#1E3A8A'];
      case 'uncommon':
        return [COLORS.uncommon, '#15803D'];
      default:
        return [COLORS.common, '#4B5563'];
    }
  };

  if (stage === 'unopened') {
    return (
      <View style={[styles.container, { backgroundColor: theme.colors.background }]}>
        <View style={styles.packContainer}>
          <TouchableOpacity onPress={handleOpenPack} activeOpacity={0.8}>
            <Animated.View style={styles.packWrapper}>
              <LinearGradient
                colors={['#0596AA', '#C89B3C']}
                style={styles.unopenedPack}
                start={{ x: 0, y: 0 }}
                end={{ x: 1, y: 1 }}
              >
                <Ionicons name="cube" size={80} color="#FFFFFF" />
                <Title style={styles.packTitle}>{packConfig.name}</Title>
                <Text style={styles.packSubtitle}>Tap to Open</Text>
              </LinearGradient>
            </Animated.View>
          </TouchableOpacity>
        </View>
      </View>
    );
  }

  if (stage === 'opening') {
    return (
      <View style={[styles.container, { backgroundColor: theme.colors.background }]}>
        <View style={styles.cardsRevealContainer}>
          {pulledCards.map((card, index) => {
            const animatedStyle = {
              transform: [
                {
                  scale: cardAnimations[index].interpolate({
                    inputRange: [0, 1],
                    outputRange: [0, 1],
                  }),
                },
                {
                  rotate: cardAnimations[index].interpolate({
                    inputRange: [0, 1],
                    outputRange: ['180deg', '0deg'],
                  }),
                },
              ],
              opacity: cardAnimations[index],
            };

            return (
              <Animated.View
                key={index}
                style={[styles.revealingCard, animatedStyle]}
              >
                <LinearGradient
                  colors={getRarityGradient(card.rarity)}
                  style={styles.cardGradient}
                >
                  <Image source={{ uri: card.imageUrl }} style={styles.cardImage} />
                </LinearGradient>
              </Animated.View>
            );
          })}
        </View>
      </View>
    );
  }

  return (
    <View style={[styles.container, { backgroundColor: theme.colors.background }]}>
      <Title style={[styles.resultsTitle, { color: theme.colors.onBackground }]}>
        Pack Contents
      </Title>

      <View style={styles.cardsDisplayContainer}>
        {pulledCards.map((card, index) => {
          const isRevealed = index <= currentCardIndex;
          const isActive = index === currentCardIndex;

          return (
            <TouchableOpacity
              key={index}
              style={[
                styles.cardWrapper,
                isActive && styles.activeCard,
                !isRevealed && styles.hiddenCard,
              ]}
              onPress={() => handleCardTap(index)}
              disabled={!isActive || index === pulledCards.length - 1}
            >
              {isRevealed ? (
                <View style={styles.revealedCardContainer}>
                  <Image source={{ uri: card.imageUrl }} style={styles.finalCardImage} />
                  <View
                    style={[
                      styles.rarityBar,
                      { backgroundColor: COLORS[card.rarity as keyof typeof COLORS] },
                    ]}
                  />
                  <Text style={[styles.cardName, { color: theme.colors.onSurface }]}>
                    {card.name}
                  </Text>
                </View>
              ) : (
                <Surface style={styles.cardBack}>
                  <Text style={{ color: theme.colors.onSurfaceVariant }}>
                    Tap to Reveal
                  </Text>
                </Surface>
              )}
            </TouchableOpacity>
          );
        })}
      </View>

      <View style={styles.summaryContainer}>
        <Surface style={[styles.summaryCard, { backgroundColor: theme.colors.surface }]}>
          <Text style={[styles.summaryTitle, { color: theme.colors.onSurface }]}>
            Summary
          </Text>
          <View style={styles.summaryStats}>
            {Object.entries(
              pulledCards.reduce((acc, card) => {
                acc[card.rarity] = (acc[card.rarity] || 0) + 1;
                return acc;
              }, {} as Record<string, number>)
            ).map(([rarity, count]) => (
              <View key={rarity} style={styles.summaryRow}>
                <View
                  style={[
                    styles.rarityDot,
                    { backgroundColor: COLORS[rarity as keyof typeof COLORS] },
                  ]}
                />
                <Text style={{ color: theme.colors.onSurface }}>
                  {rarity.charAt(0).toUpperCase() + rarity.slice(1)}: {count}
                </Text>
              </View>
            ))}
          </View>
        </Surface>

        <Button
          mode="contained"
          onPress={handleFinish}
          style={styles.finishButton}
        >
          Add to Collection
        </Button>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  packContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  packWrapper: {
    width: 200,
    height: 280,
  },
  unopenedPack: {
    flex: 1,
    borderRadius: 16,
    alignItems: 'center',
    justifyContent: 'center',
    elevation: 8,
  },
  packTitle: {
    color: '#FFFFFF',
    marginTop: 16,
    fontSize: 20,
  },
  packSubtitle: {
    color: '#FFFFFF',
    opacity: 0.8,
    marginTop: 8,
  },
  cardsRevealContainer: {
    flex: 1,
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'center',
    alignItems: 'center',
    padding: 16,
  },
  revealingCard: {
    width: 100,
    height: 140,
    margin: 8,
  },
  cardGradient: {
    flex: 1,
    borderRadius: 8,
    padding: 2,
  },
  cardImage: {
    flex: 1,
    borderRadius: 6,
  },
  resultsTitle: {
    fontSize: 24,
    fontWeight: 'bold',
    textAlign: 'center',
    marginTop: 16,
  },
  cardsDisplayContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'center',
    padding: 16,
  },
  cardWrapper: {
    width: 100,
    height: 140,
    margin: 8,
  },
  activeCard: {
    transform: [{ scale: 1.1 }],
  },
  hiddenCard: {
    opacity: 0.6,
  },
  revealedCardContainer: {
    flex: 1,
  },
  finalCardImage: {
    width: '100%',
    height: '80%',
    borderRadius: 8,
  },
  rarityBar: {
    height: 4,
    width: '100%',
    marginTop: 4,
  },
  cardName: {
    fontSize: 10,
    textAlign: 'center',
    marginTop: 2,
  },
  cardBack: {
    flex: 1,
    borderRadius: 8,
    alignItems: 'center',
    justifyContent: 'center',
    elevation: 2,
  },
  summaryContainer: {
    padding: 16,
  },
  summaryCard: {
    padding: 16,
    borderRadius: 12,
    elevation: 2,
  },
  summaryTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 12,
  },
  summaryStats: {
    marginTop: 8,
  },
  summaryRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginVertical: 4,
  },
  rarityDot: {
    width: 12,
    height: 12,
    borderRadius: 6,
    marginRight: 8,
  },
  finishButton: {
    marginTop: 16,
  },
});
