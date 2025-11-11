import React, { useState, useEffect } from 'react';
import {
  View,
  StyleSheet,
  TouchableOpacity,
  Alert,
} from 'react-native';
import {
  Text,
  useTheme,
  Button,
  ActivityIndicator,
} from 'react-native-paper';
import { Ionicons } from '@expo/vector-icons';
import { useNavigation } from '@react-navigation/native';
import { StackNavigationProp } from '@react-navigation/stack';
import { RootStackParamList } from '../navigation';
import { useCollectionStore } from '../store';
import * as Haptics from 'expo-haptics';

type NavigationProp = StackNavigationProp<RootStackParamList, 'CardScanner'>;

export default function CardScannerScreen() {
  const theme = useTheme();
  const navigation = useNavigation<NavigationProp>();
  const { addToCollection } = useCollectionStore();
  const [hasPermission, setHasPermission] = useState<boolean | null>(null);
  const [scanning, setScanning] = useState(false);

  useEffect(() => {
    // Request camera permission
    (async () => {
      // TODO: Add expo-camera dependency
      // For now, we'll simulate permission
      setHasPermission(true);
    })();
  }, []);

  const handleScan = async () => {
    setScanning(true);
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);

    // Simulate scanning delay
    setTimeout(() => {
      setScanning(false);
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);

      Alert.alert(
        'Karte erkannt!',
        'Viktor, Machine Herald wurde zu deiner Sammlung hinzugefügt.',
        [
          {
            text: 'Zur Sammlung',
            onPress: () => {
              addToCollection('RB-001');
              navigation.goBack();
            },
          },
          { text: 'Weiter scannen', style: 'cancel' },
        ]
      );
    }, 2000);
  };

  if (hasPermission === null) {
    return (
      <View style={[styles.container, { backgroundColor: theme.colors.background }]}>
        <ActivityIndicator size="large" />
      </View>
    );
  }

  if (hasPermission === false) {
    return (
      <View style={[styles.container, { backgroundColor: theme.colors.background }]}>
        <Ionicons name="camera-off" size={64} color={theme.colors.onSurfaceVariant} />
        <Text style={[styles.errorText, { color: theme.colors.onSurface }]}>
          Keine Kamera-Berechtigung
        </Text>
        <Button mode="contained" onPress={() => navigation.goBack()}>
          Zurück
        </Button>
      </View>
    );
  }

  return (
    <View style={[styles.container, { backgroundColor: theme.colors.background }]}>
      {/* Camera Preview Placeholder */}
      <View style={[styles.cameraPreview, { backgroundColor: theme.colors.surfaceVariant }]}>
        <View style={styles.scanFrame}>
          <View style={[styles.corner, styles.topLeft, { borderColor: theme.colors.primary }]} />
          <View style={[styles.corner, styles.topRight, { borderColor: theme.colors.primary }]} />
          <View style={[styles.corner, styles.bottomLeft, { borderColor: theme.colors.primary }]} />
          <View style={[styles.corner, styles.bottomRight, { borderColor: theme.colors.primary }]} />
        </View>

        {scanning && (
          <View style={styles.scanningOverlay}>
            <ActivityIndicator size="large" color={theme.colors.primary} />
            <Text style={[styles.scanningText, { color: theme.colors.onSurface }]}>
              Scanne Karte...
            </Text>
          </View>
        )}
      </View>

      {/* Instructions */}
      <View style={styles.instructions}>
        <Text style={[styles.instructionText, { color: theme.colors.onBackground }]}>
          Platziere die Karte im Rahmen
        </Text>
        <Text style={[styles.instructionSubtext, { color: theme.colors.onSurfaceVariant }]}>
          Der Scanner erkennt automatisch Riftbound TCG Karten
        </Text>
      </View>

      {/* Scan Button */}
      <View style={styles.controls}>
        <TouchableOpacity
          style={[styles.scanButton, { backgroundColor: theme.colors.primary }]}
          onPress={handleScan}
          disabled={scanning}
        >
          <Ionicons name="scan" size={32} color="#FFFFFF" />
        </TouchableOpacity>

        <Button
          mode="text"
          onPress={() => navigation.goBack()}
          style={styles.cancelButton}
        >
          Abbrechen
        </Button>
      </View>

      {/* Feature Info */}
      <View style={[styles.featureInfo, { backgroundColor: theme.colors.surface }]}>
        <Ionicons name="information-circle" size={24} color={theme.colors.primary} />
        <Text style={[styles.featureText, { color: theme.colors.onSurface }]}>
          Der Scanner nutzt KI-basierte Bilderkennung, um Karten automatisch zu identifizieren
        </Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  cameraPreview: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  scanFrame: {
    width: 250,
    height: 350,
    position: 'relative',
  },
  corner: {
    position: 'absolute',
    width: 40,
    height: 40,
    borderWidth: 4,
  },
  topLeft: {
    top: 0,
    left: 0,
    borderRightWidth: 0,
    borderBottomWidth: 0,
  },
  topRight: {
    top: 0,
    right: 0,
    borderLeftWidth: 0,
    borderBottomWidth: 0,
  },
  bottomLeft: {
    bottom: 0,
    left: 0,
    borderRightWidth: 0,
    borderTopWidth: 0,
  },
  bottomRight: {
    bottom: 0,
    right: 0,
    borderLeftWidth: 0,
    borderTopWidth: 0,
  },
  scanningOverlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(0, 0, 0, 0.7)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  scanningText: {
    marginTop: 16,
    fontSize: 18,
    fontWeight: 'bold',
  },
  instructions: {
    padding: 24,
    alignItems: 'center',
  },
  instructionText: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 8,
  },
  instructionSubtext: {
    fontSize: 14,
    textAlign: 'center',
  },
  controls: {
    alignItems: 'center',
    paddingBottom: 24,
  },
  scanButton: {
    width: 80,
    height: 80,
    borderRadius: 40,
    justifyContent: 'center',
    alignItems: 'center',
    elevation: 4,
    marginBottom: 16,
  },
  cancelButton: {
    marginTop: 8,
  },
  errorText: {
    fontSize: 18,
    marginVertical: 16,
  },
  featureInfo: {
    flexDirection: 'row',
    padding: 16,
    alignItems: 'center',
    gap: 12,
    elevation: 2,
  },
  featureText: {
    flex: 1,
    fontSize: 12,
  },
});
