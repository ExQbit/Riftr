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
  Surface,
  Avatar,
  List,
  Divider,
  ProgressBar,
  Card,
  Title,
  Paragraph,
} from 'react-native-paper';
import { Ionicons } from '@expo/vector-icons';
import { useNavigation } from '@react-navigation/native';
import { StackNavigationProp } from '@react-navigation/stack';
import { RootStackParamList } from '../navigation';
import {
  useCollectionStore,
  useStatsStore,
  usePointsStore,
  useSettingsStore,
} from '../store';
import * as Haptics from 'expo-haptics';
import { COLORS } from '../constants';

type NavigationProp = StackNavigationProp<RootStackParamList, 'MainTabs'>;

export default function ProfileScreen() {
  const theme = useTheme();
  const navigation = useNavigation<NavigationProp>();
  const { getCollectionStats } = useCollectionStore();
  const { stats } = useStatsStore();
  const { points } = usePointsStore();
  const collectionStats = getCollectionStats();

  const handleSettingsPress = () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    navigation.navigate('Settings');
  };

  const achievements = [
    { id: 'first_pack', name: 'First Pack', description: 'Open your first pack', unlocked: stats.totalPacksOpened > 0, icon: 'cube' },
    { id: 'collector', name: 'Collector', description: 'Collect 25 unique cards', unlocked: collectionStats.uniqueCards >= 25, icon: 'albums' },
    { id: 'completionist', name: 'Completionist', description: 'Complete the set', unlocked: collectionStats.completionRate === 100, icon: 'trophy' },
    { id: 'point_master', name: 'Point Master', description: 'Earn 1000 points', unlocked: points.pointsEarned >= 1000, icon: 'star' },
  ];

  return (
    <ScrollView style={[styles.container, { backgroundColor: theme.colors.background }]}>
      {/* Profile Header */}
      <Surface style={[styles.headerCard, { backgroundColor: theme.colors.surface }]}>
        <View style={styles.profileHeader}>
          <Avatar.Icon size={80} icon="account" style={{ backgroundColor: theme.colors.primary }} />
          <View style={styles.profileInfo}>
            <Title style={{ color: theme.colors.onSurface }}>Sammler</Title>
            <Paragraph style={{ color: theme.colors.onSurfaceVariant }}>
              Level {Math.floor(points.totalPoints / 100) + 1}
            </Paragraph>
            <ProgressBar
              progress={(points.totalPoints % 100) / 100}
              color={theme.colors.primary}
              style={styles.levelProgress}
            />
          </View>
          <TouchableOpacity onPress={handleSettingsPress}>
            <Ionicons name="settings-outline" size={28} color={theme.colors.onSurface} />
          </TouchableOpacity>
        </View>
      </Surface>

      {/* Stats Grid */}
      <View style={styles.statsGrid}>
        <Surface style={[styles.statCard, { backgroundColor: theme.colors.primaryContainer }]}>
          <Ionicons name="albums" size={32} color={theme.colors.primary} />
          <Text style={[styles.statValue, { color: theme.colors.onPrimaryContainer }]}>
            {collectionStats.uniqueCards}/50
          </Text>
          <Text style={[styles.statLabel, { color: theme.colors.onPrimaryContainer }]}>
            Karten
          </Text>
        </Surface>

        <Surface style={[styles.statCard, { backgroundColor: theme.colors.secondaryContainer }]}>
          <Ionicons name="cube" size={32} color={theme.colors.secondary} />
          <Text style={[styles.statValue, { color: theme.colors.onSecondaryContainer }]}>
            {stats.totalPacksOpened}
          </Text>
          <Text style={[styles.statLabel, { color: theme.colors.onSecondaryContainer }]}>
            Packs
          </Text>
        </Surface>

        <Surface style={[styles.statCard, { backgroundColor: theme.colors.tertiaryContainer }]}>
          <Ionicons name="star" size={32} color={COLORS.secondary} />
          <Text style={[styles.statValue, { color: theme.colors.onTertiaryContainer }]}>
            {points.totalPoints}
          </Text>
          <Text style={[styles.statLabel, { color: theme.colors.onTertiaryContainer }]}>
            Punkte
          </Text>
        </Surface>

        <Surface style={[styles.statCard, { backgroundColor: theme.colors.surface }]}>
          <Ionicons name="flame" size={32} color={COLORS.error} />
          <Text style={[styles.statValue, { color: theme.colors.onSurface }]}>
            {points.dailyStreak}
          </Text>
          <Text style={[styles.statLabel, { color: theme.colors.onSurfaceVariant }]}>
            Streak
          </Text>
        </Surface>
      </View>

      {/* Achievements */}
      <Card style={[styles.section, { backgroundColor: theme.colors.surface }]}>
        <Card.Content>
          <Title style={{ color: theme.colors.onSurface }}>Achievements</Title>
          {achievements.map((achievement) => (
            <View key={achievement.id}>
              <List.Item
                title={achievement.name}
                description={achievement.description}
                left={() => (
                  <View
                    style={[
                      styles.achievementIcon,
                      {
                        backgroundColor: achievement.unlocked
                          ? theme.colors.primaryContainer
                          : theme.colors.surfaceVariant,
                      },
                    ]}
                  >
                    <Ionicons
                      name={achievement.icon as any}
                      size={24}
                      color={
                        achievement.unlocked
                          ? theme.colors.primary
                          : theme.colors.onSurfaceVariant
                      }
                    />
                  </View>
                )}
                right={() =>
                  achievement.unlocked ? (
                    <Ionicons name="checkmark-circle" size={24} color={COLORS.success} />
                  ) : null
                }
              />
              <Divider />
            </View>
          ))}
        </Card.Content>
      </Card>

      {/* Recent Activity */}
      <Card style={[styles.section, { backgroundColor: theme.colors.surface }]}>
        <Card.Content>
          <Title style={{ color: theme.colors.onSurface }}>Letzte Aktivitäten</Title>
          {points.transactions.slice(0, 5).map((transaction) => (
            <List.Item
              key={transaction.id}
              title={transaction.reason}
              description={new Date(transaction.date).toLocaleDateString('de-DE')}
              left={() => (
                <Ionicons
                  name={transaction.type === 'earn' ? 'add-circle' : 'remove-circle'}
                  size={24}
                  color={transaction.type === 'earn' ? COLORS.success : COLORS.error}
                />
              )}
              right={() => (
                <Text
                  style={{
                    color:
                      transaction.type === 'earn' ? COLORS.success : COLORS.error,
                    fontWeight: 'bold',
                  }}
                >
                  {transaction.type === 'earn' ? '+' : '-'}
                  {transaction.amount}
                </Text>
              )}
            />
          ))}
        </Card.Content>
      </Card>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  headerCard: {
    padding: 16,
    elevation: 2,
  },
  profileHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 16,
  },
  profileInfo: {
    flex: 1,
  },
  levelProgress: {
    marginTop: 8,
    height: 6,
    borderRadius: 3,
  },
  statsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    padding: 8,
    gap: 8,
  },
  statCard: {
    flex: 1,
    minWidth: '45%',
    padding: 16,
    borderRadius: 12,
    alignItems: 'center',
    elevation: 2,
  },
  statValue: {
    fontSize: 24,
    fontWeight: 'bold',
    marginTop: 8,
  },
  statLabel: {
    fontSize: 12,
    marginTop: 4,
  },
  section: {
    margin: 16,
    elevation: 2,
  },
  achievementIcon: {
    width: 48,
    height: 48,
    borderRadius: 24,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 8,
  },
});
