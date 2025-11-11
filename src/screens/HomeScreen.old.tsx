import React from 'react';
import {
  View,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Dimensions,
} from 'react-native';
import {
  Text,
  Card,
  Title,
  Paragraph,
  useTheme,
  Button,
  Chip,
  Surface,
} from 'react-native-paper';
import { useNavigation } from '@react-navigation/native';
import { StackNavigationProp } from '@react-navigation/stack';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { usePackStore, useStatsStore } from '../store';
import { PACK_CONFIG, COLORS } from '../constants';
import { RootStackParamList } from '../navigation';
import * as Haptics from 'expo-haptics';

type NavigationProp = StackNavigationProp<RootStackParamList, 'MainTabs'>;

const { width } = Dimensions.get('window');
const CARD_WIDTH = (width - 48) / 2;

export default function HomeScreen() {
  const theme = useTheme();
  const navigation = useNavigation<NavigationProp>();
  const { currency, spendCurrency, canClaimDaily, claimDailyBonus, lastClaimDate } = usePackStore();
  const { stats, incrementPacksOpened } = useStatsStore();

  const handlePackPress = async (packType: keyof typeof PACK_CONFIG) => {
    const packConfig = PACK_CONFIG[packType];

    if (packConfig.cost > 0 && !spendCurrency(packConfig.cost)) {
      // Not enough currency
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Warning);
      return;
    }

    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    navigation.navigate('PackOpening', { packType });
  };

  const handleClaimDaily = () => {
    const success = claimDailyBonus();
    if (success) {
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    } else {
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Warning);
    }
  };

  const getTimeUntilNextClaim = (): string => {
    if (!lastClaimDate) return '';

    const lastClaim = new Date(lastClaimDate);
    const now = new Date();
    const nextClaim = new Date(lastClaim.getTime() + 24 * 60 * 60 * 1000);
    const msRemaining = nextClaim.getTime() - now.getTime();

    if (msRemaining <= 0) return '';

    const hours = Math.floor(msRemaining / (1000 * 60 * 60));
    const minutes = Math.floor((msRemaining % (1000 * 60 * 60)) / (1000 * 60));

    return `Available in ${hours}h ${minutes}m`;
  };

  const canClaim = canClaimDaily();

  const PackCard = ({
    packType,
    config,
  }: {
    packType: keyof typeof PACK_CONFIG;
    config: typeof PACK_CONFIG[keyof typeof PACK_CONFIG];
  }) => {
    const isAffordable = currency >= config.cost || config.cost === 0;
    const gradientColors = getPackGradient(packType);

    return (
      <TouchableOpacity
        style={styles.packCard}
        onPress={() => handlePackPress(packType)}
        disabled={!isAffordable}
      >
        <LinearGradient
          colors={gradientColors}
          style={[
            styles.packGradient,
            !isAffordable && styles.disabledPack,
          ]}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 1 }}
        >
          <View style={styles.packContent}>
            <Ionicons
              name="cube"
              size={48}
              color="#FFFFFF"
              style={styles.packIcon}
            />
            <Title style={styles.packTitle}>{config.name}</Title>
            <Paragraph style={styles.packDescription}>
              {config.cards} Cards
            </Paragraph>
            
            <View style={styles.packDetails}>
              {packType === 'starter' && (
                <Chip
                  mode="flat"
                  style={[styles.guaranteeChip, { backgroundColor: COLORS.legendary }]}
                  textStyle={{ color: '#FFFFFF' }}
                >
                  1x Champion
                </Chip>
              )}
              {packType !== 'starter' && (
                <Chip
                  mode="flat"
                  style={[styles.guaranteeChip, { backgroundColor: COLORS.rare }]}
                  textStyle={{ color: '#FFFFFF' }}
                >
                  {`${config.legendaryChance! * 100}% Legendary`}
                </Chip>
              )}
            </View>

            <Button
              mode="contained"
              style={styles.packButton}
              labelStyle={{ color: '#FFFFFF' }}
              disabled={!isAffordable}
            >
              {config.cost === 0 ? 'Open Free' : `Open - ${config.cost} 💎`}
            </Button>
          </View>
        </LinearGradient>
      </TouchableOpacity>
    );
  };

  return (
    <ScrollView style={[styles.container, { backgroundColor: theme.colors.background }]}>
      {/* Header Stats */}
      <Surface style={[styles.header, { backgroundColor: theme.colors.surface }]}>
        <View style={styles.statsRow}>
          <View style={styles.statItem}>
            <Text style={[styles.statLabel, { color: theme.colors.onSurfaceVariant }]}>
              Currency
            </Text>
            <Text style={[styles.statValue, { color: theme.colors.primary }]}>
              {currency} 💎
            </Text>
          </View>
          <View style={styles.statItem}>
            <Text style={[styles.statLabel, { color: theme.colors.onSurfaceVariant }]}>
              Packs Opened
            </Text>
            <Text style={[styles.statValue, { color: theme.colors.onSurface }]}>
              {stats.totalPacksOpened}
            </Text>
          </View>
          <View style={styles.statItem}>
            <Text style={[styles.statLabel, { color: theme.colors.onSurfaceVariant }]}>
              Collection
            </Text>
            <Text style={[styles.statValue, { color: theme.colors.onSurface }]}>
              {stats.uniqueCards}/50
            </Text>
          </View>
        </View>
      </Surface>

      {/* Daily Bonus */}
      <Card style={[styles.dailyBonus, { backgroundColor: theme.colors.primaryContainer }]}>
        <Card.Content>
          <Title style={{ color: theme.colors.onPrimaryContainer }}>
            {canClaim ? 'Daily Bonus Available!' : 'Daily Bonus Claimed'}
          </Title>
          <Paragraph style={{ color: theme.colors.onPrimaryContainer }}>
            {canClaim
              ? 'Claim your free 100 💎 and bonus pack'
              : getTimeUntilNextClaim() || 'Come back tomorrow!'}
          </Paragraph>
          <Button
            mode="contained"
            style={styles.claimButton}
            onPress={handleClaimDaily}
            disabled={!canClaim}
          >
            {canClaim ? 'Claim Now' : 'Already Claimed'}
          </Button>
        </Card.Content>
      </Card>

      {/* Pack Selection */}
      <Title style={[styles.sectionTitle, { color: theme.colors.onBackground }]}>
        Available Packs
      </Title>
      
      <View style={styles.packsGrid}>
        <PackCard packType="starter" config={PACK_CONFIG.starter} />
        <PackCard packType="foundations_booster" config={PACK_CONFIG.foundations_booster} />
      </View>
      
      <View style={styles.packsGrid}>
        <PackCard packType="expansion_booster" config={PACK_CONFIG.expansion_booster} />
        <View style={styles.packCard}>
          <Surface style={[styles.comingSoon, { backgroundColor: theme.colors.surfaceVariant }]}>
            <Ionicons name="lock-closed" size={48} color={theme.colors.onSurfaceVariant} />
            <Text style={{ color: theme.colors.onSurfaceVariant, marginTop: 8 }}>
              More Packs
            </Text>
            <Text style={{ color: theme.colors.onSurfaceVariant, fontSize: 12 }}>
              Coming Soon
            </Text>
          </Surface>
        </View>
      </View>
    </ScrollView>
  );
}

function getPackGradient(packType: keyof typeof PACK_CONFIG): string[] {
  switch (packType) {
    case 'starter':
      return [COLORS.secondary, COLORS.primary];
    case 'foundations_booster':
      return [COLORS.primary, '#0B5394'];
    case 'expansion_booster':
      return [COLORS.accent, '#4B0082'];
    default:
      return [COLORS.primary, COLORS.secondary];
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  header: {
    padding: 16,
    elevation: 2,
  },
  statsRow: {
    flexDirection: 'row',
    justifyContent: 'space-around',
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
  dailyBonus: {
    margin: 16,
    elevation: 4,
  },
  claimButton: {
    marginTop: 12,
  },
  sectionTitle: {
    fontSize: 24,
    fontWeight: 'bold',
    marginHorizontal: 16,
    marginTop: 16,
    marginBottom: 8,
  },
  packsGrid: {
    flexDirection: 'row',
    paddingHorizontal: 16,
    marginBottom: 16,
  },
  packCard: {
    width: CARD_WIDTH,
    height: CARD_WIDTH * 1.4,
    marginHorizontal: 8,
  },
  packGradient: {
    flex: 1,
    borderRadius: 12,
    padding: 16,
    justifyContent: 'space-between',
    elevation: 4,
  },
  disabledPack: {
    opacity: 0.5,
  },
  packContent: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  packIcon: {
    marginBottom: 8,
  },
  packTitle: {
    color: '#FFFFFF',
    fontSize: 18,
    textAlign: 'center',
  },
  packDescription: {
    color: '#FFFFFF',
    opacity: 0.9,
    textAlign: 'center',
  },
  packDetails: {
    marginVertical: 8,
  },
  guaranteeChip: {
    marginVertical: 4,
  },
  packButton: {
    width: '100%',
  },
  comingSoon: {
    flex: 1,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
    elevation: 2,
  },
});
