import React, { useEffect, useState } from 'react';
import {
  View,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Dimensions,
  Image,
  Animated,
} from 'react-native';
import {
  Text,
  useTheme,
  Surface,
  Title,
  Paragraph,
  Card,
  ProgressBar,
  Chip,
  FAB,
} from 'react-native-paper';
import { useNavigation } from '@react-navigation/native';
import { StackNavigationProp } from '@react-navigation/stack';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { RootStackParamList } from '../navigation';
import {
  useCollectionStore,
  useStatsStore,
  usePointsStore,
  usePackStore,
  useFeaturedCardsStore,
} from '../store';
import { mockCards } from '../data/mockCards';
import { Card as CardType, FeaturedCard } from '../types';
import { COLORS } from '../constants';
import * as Haptics from 'expo-haptics';

type NavigationProp = StackNavigationProp<RootStackParamList, 'MainTabs'>;

const { width } = Dimensions.get('window');
const CARD_WIDTH = width - 32;

export default function HomeScreen() {
  const theme = useTheme();
  const navigation = useNavigation<NavigationProp>();

  const { getCollectionStats } = useCollectionStore();
  const { stats } = useStatsStore();
  const { points } = usePointsStore();
  const { currency } = usePackStore();
  const { currentFeaturedCard, setFeaturedCards, updateCurrentFeaturedCard } =
    useFeaturedCardsStore();

  const collectionStats = getCollectionStats();
  const [fadeAnim] = useState(new Animated.Value(0));

  // Initialize featured cards on mount
  useEffect(() => {
    initializeFeaturedCards();
    updateCurrentFeaturedCard();

    Animated.timing(fadeAnim, {
      toValue: 1,
      duration: 800,
      useNativeDriver: true,
    }).start();
  }, []);

  const initializeFeaturedCards = () => {
    // Sample featured cards with mechanics and lore
    const featured: FeaturedCard[] = [
      {
        cardId: 'RB-001',
        title: 'Mechanik: Hexcore',
        description:
          'Hexcore-Karten erhalten zusätzliche Effekte basierend auf deiner aktuellen Energie. Je mehr Energie du hast, desto stärker werden diese Karten!',
        type: 'mechanic',
        startDate: new Date().toISOString(),
        endDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
      },
      {
        cardId: 'RB-004',
        title: 'Die Geschichte von Jinx',
        description:
          'Jinx war einst als Powder bekannt, bis eine Tragödie ihr Leben für immer veränderte. Ihre chaotische Energie spiegelt sich in ihren explosiven Karten wider.',
        type: 'lore',
        startDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
        endDate: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000).toISOString(),
      },
    ];

    setFeaturedCards(featured);
  };

  const handleCardPress = (cardId: string) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    navigation.navigate('CardDetail', { cardId });
  };

  const handleOpenPacks = () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    // Navigate to pack opening (keep old HomeScreen for this)
    navigation.navigate('PackOpening', { packType: 'foundations_booster' });
  };

  const handleScanCard = () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    navigation.navigate('CardScanner');
  };

  const getFeaturedCardData = (): CardType | null => {
    if (!currentFeaturedCard) return null;
    return mockCards.find((card) => card.id === currentFeaturedCard.cardId) || null;
  };

  const featuredCard = getFeaturedCardData();

  return (
    <View style={[styles.container, { backgroundColor: theme.colors.background }]}>
      <ScrollView showsVerticalScrollIndicator={false}>
        {/* Header with Greeting */}
        <Animated.View style={[styles.header, { opacity: fadeAnim }]}>
          <View>
            <Title style={[styles.greeting, { color: theme.colors.onBackground }]}>
              Willkommen zurück!
            </Title>
            <Paragraph style={{ color: theme.colors.onSurfaceVariant }}>
              Deine Riftbound Sammlung
            </Paragraph>
          </View>
          <View style={styles.currencyBadge}>
            <Ionicons name="diamond" size={20} color={COLORS.secondary} />
            <Text style={[styles.currencyText, { color: theme.colors.onBackground }]}>
              {currency}
            </Text>
          </View>
        </Animated.View>

        {/* Collection Progress Card */}
        <Animated.View style={{ opacity: fadeAnim }}>
          <Card style={[styles.progressCard, { backgroundColor: theme.colors.surface }]}>
            <LinearGradient
              colors={[theme.colors.primary + '20', theme.colors.surface]}
              style={styles.progressGradient}
            >
              <Card.Content>
                <View style={styles.progressHeader}>
                  <View>
                    <Title style={{ color: theme.colors.onSurface }}>Deine Sammlung</Title>
                    <Paragraph style={{ color: theme.colors.onSurfaceVariant }}>
                      {collectionStats.uniqueCards} von 50 Karten
                    </Paragraph>
                  </View>
                  <View style={styles.completionBadge}>
                    <Text style={[styles.completionText, { color: theme.colors.primary }]}>
                      {collectionStats.completionRate.toFixed(0)}%
                    </Text>
                  </View>
                </View>

                <ProgressBar
                  progress={collectionStats.completionRate / 100}
                  color={theme.colors.primary}
                  style={styles.progressBar}
                />

                <View style={styles.statsRow}>
                  <View style={styles.statItem}>
                    <Ionicons name="albums" size={24} color={theme.colors.primary} />
                    <Text style={[styles.statValue, { color: theme.colors.onSurface }]}>
                      {collectionStats.totalCards}
                    </Text>
                    <Text style={[styles.statLabel, { color: theme.colors.onSurfaceVariant }]}>
                      Gesamt
                    </Text>
                  </View>

                  <View style={styles.statItem}>
                    <Ionicons name="cube" size={24} color={theme.colors.secondary} />
                    <Text style={[styles.statValue, { color: theme.colors.onSurface }]}>
                      {stats.totalPacksOpened}
                    </Text>
                    <Text style={[styles.statLabel, { color: theme.colors.onSurfaceVariant }]}>
                      Packs
                    </Text>
                  </View>

                  <View style={styles.statItem}>
                    <Ionicons name="star" size={24} color={COLORS.secondary} />
                    <Text style={[styles.statValue, { color: theme.colors.onSurface }]}>
                      {points.totalPoints}
                    </Text>
                    <Text style={[styles.statLabel, { color: theme.colors.onSurfaceVariant }]}>
                      Punkte
                    </Text>
                  </View>
                </View>
              </Card.Content>
            </LinearGradient>
          </Card>
        </Animated.View>

        {/* Featured Card Showcase */}
        {featuredCard && currentFeaturedCard && (
          <Animated.View style={{ opacity: fadeAnim }}>
            <Card style={[styles.featuredCard, { backgroundColor: theme.colors.surface }]}>
              <Card.Content>
                <View style={styles.featuredHeader}>
                  <Chip
                    icon={
                      currentFeaturedCard.type === 'mechanic'
                        ? 'cog'
                        : currentFeaturedCard.type === 'lore'
                        ? 'book'
                        : 'star'
                    }
                    style={{ backgroundColor: theme.colors.primaryContainer }}
                  >
                    {currentFeaturedCard.type === 'mechanic'
                      ? 'Mechanik'
                      : currentFeaturedCard.type === 'lore'
                      ? 'Lore'
                      : 'Spotlight'}
                  </Chip>
                  <Text style={[styles.featuredDate, { color: theme.colors.onSurfaceVariant }]}>
                    Heute
                  </Text>
                </View>

                <TouchableOpacity
                  onPress={() => handleCardPress(featuredCard.id)}
                  activeOpacity={0.8}
                >
                  <LinearGradient
                    colors={[COLORS.primary + '30', COLORS.accent + '30']}
                    style={styles.featuredCardDisplay}
                    start={{ x: 0, y: 0 }}
                    end={{ x: 1, y: 1 }}
                  >
                    <Image
                      source={{ uri: featuredCard.imageUrl }}
                      style={styles.featuredCardImage}
                      resizeMode="contain"
                    />
                  </LinearGradient>

                  <View style={styles.featuredContent}>
                    <Title style={{ color: theme.colors.onSurface, marginBottom: 8 }}>
                      {currentFeaturedCard.title}
                    </Title>
                    <Paragraph style={{ color: theme.colors.onSurfaceVariant }}>
                      {currentFeaturedCard.description}
                    </Paragraph>

                    <View style={styles.featuredCardInfo}>
                      <Text style={[styles.cardName, { color: theme.colors.primary }]}>
                        {featuredCard.name}
                      </Text>
                      <Chip
                        style={{
                          backgroundColor: COLORS[featuredCard.rarity as keyof typeof COLORS],
                        }}
                        textStyle={{ color: '#FFFFFF' }}
                      >
                        {featuredCard.rarity.toUpperCase()}
                      </Chip>
                    </View>
                  </View>
                </TouchableOpacity>
              </Card.Content>
            </Card>
          </Animated.View>
        )}

        {/* Quick Actions */}
        <Animated.View style={{ opacity: fadeAnim }}>
          <Title style={[styles.sectionTitle, { color: theme.colors.onBackground }]}>
            Schnellzugriff
          </Title>

          <View style={styles.quickActions}>
            <TouchableOpacity
              style={[styles.actionCard, { backgroundColor: theme.colors.primaryContainer }]}
              onPress={handleOpenPacks}
            >
              <LinearGradient
                colors={[COLORS.primary, COLORS.primary + '80']}
                style={styles.actionGradient}
              >
                <Ionicons name="cube" size={32} color="#FFFFFF" />
                <Text style={styles.actionText}>Packs öffnen</Text>
              </LinearGradient>
            </TouchableOpacity>

            <TouchableOpacity
              style={[styles.actionCard, { backgroundColor: theme.colors.secondaryContainer }]}
              onPress={() => navigation.navigate('Collection' as any)}
            >
              <LinearGradient
                colors={[COLORS.secondary, COLORS.secondary + '80']}
                style={styles.actionGradient}
              >
                <Ionicons name="albums" size={32} color="#FFFFFF" />
                <Text style={styles.actionText}>Sammlung</Text>
              </LinearGradient>
            </TouchableOpacity>

            <TouchableOpacity
              style={[styles.actionCard, { backgroundColor: theme.colors.tertiaryContainer }]}
              onPress={() => navigation.navigate('Decks' as any)}
            >
              <LinearGradient
                colors={[COLORS.accent, COLORS.accent + '80']}
                style={styles.actionGradient}
              >
                <Ionicons name="layers" size={32} color="#FFFFFF" />
                <Text style={styles.actionText}>Decks</Text>
              </LinearGradient>
            </TouchableOpacity>

            <TouchableOpacity
              style={[styles.actionCard, { backgroundColor: theme.colors.surface }]}
              onPress={handleScanCard}
            >
              <LinearGradient
                colors={[theme.colors.surface, theme.colors.surfaceVariant]}
                style={styles.actionGradient}
              >
                <Ionicons name="scan" size={32} color={theme.colors.primary} />
                <Text style={[styles.actionText, { color: theme.colors.onSurface }]}>
                  Scannen
                </Text>
              </LinearGradient>
            </TouchableOpacity>
          </View>
        </Animated.View>

        {/* Daily Streak */}
        {points.dailyStreak > 0 && (
          <Animated.View style={{ opacity: fadeAnim }}>
            <Card style={[styles.streakCard, { backgroundColor: theme.colors.errorContainer }]}>
              <Card.Content style={styles.streakContent}>
                <Ionicons name="flame" size={40} color={COLORS.error} />
                <View style={styles.streakInfo}>
                  <Title style={{ color: theme.colors.onErrorContainer }}>
                    {points.dailyStreak} Tage Streak!
                  </Title>
                  <Paragraph style={{ color: theme.colors.onErrorContainer }}>
                    Mach weiter so und sammle täglich Punkte
                  </Paragraph>
                </View>
              </Card.Content>
            </Card>
          </Animated.View>
        )}
      </ScrollView>

      {/* Floating Scan Button */}
      <FAB
        icon="scan"
        style={[styles.fab, { backgroundColor: theme.colors.primary }]}
        onPress={handleScanCard}
        color="#FFFFFF"
        label="Scannen"
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 16,
    paddingTop: 24,
  },
  greeting: {
    fontSize: 28,
    fontWeight: 'bold',
  },
  currencyBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 20,
    backgroundColor: COLORS.secondary + '20',
  },
  currencyText: {
    fontSize: 16,
    fontWeight: 'bold',
  },
  progressCard: {
    marginHorizontal: 16,
    marginBottom: 16,
    elevation: 4,
    borderRadius: 16,
    overflow: 'hidden',
  },
  progressGradient: {
    padding: 16,
  },
  progressHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  completionBadge: {
    width: 60,
    height: 60,
    borderRadius: 30,
    backgroundColor: COLORS.primary + '20',
    justifyContent: 'center',
    alignItems: 'center',
  },
  completionText: {
    fontSize: 18,
    fontWeight: 'bold',
  },
  progressBar: {
    height: 8,
    borderRadius: 4,
    marginBottom: 16,
  },
  statsRow: {
    flexDirection: 'row',
    justifyContent: 'space-around',
  },
  statItem: {
    alignItems: 'center',
    gap: 4,
  },
  statValue: {
    fontSize: 20,
    fontWeight: 'bold',
  },
  statLabel: {
    fontSize: 12,
  },
  featuredCard: {
    marginHorizontal: 16,
    marginBottom: 16,
    elevation: 4,
    borderRadius: 16,
  },
  featuredHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  featuredDate: {
    fontSize: 12,
  },
  featuredCardDisplay: {
    height: 200,
    borderRadius: 12,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 16,
  },
  featuredCardImage: {
    width: '60%',
    height: '90%',
  },
  featuredContent: {
    marginTop: 8,
  },
  featuredCardInfo: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: 12,
  },
  cardName: {
    fontSize: 16,
    fontWeight: 'bold',
  },
  sectionTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    marginHorizontal: 16,
    marginBottom: 12,
  },
  quickActions: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    paddingHorizontal: 8,
    gap: 8,
    marginBottom: 16,
  },
  actionCard: {
    width: (width - 40) / 2,
    height: 120,
    borderRadius: 12,
    overflow: 'hidden',
    elevation: 2,
  },
  actionGradient: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    gap: 8,
  },
  actionText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: 'bold',
  },
  streakCard: {
    marginHorizontal: 16,
    marginBottom: 24,
    elevation: 2,
    borderRadius: 12,
  },
  streakContent: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 16,
  },
  streakInfo: {
    flex: 1,
  },
  fab: {
    position: 'absolute',
    margin: 16,
    right: 0,
    bottom: 0,
    elevation: 8,
  },
});
