import { useColorScheme } from '@/hooks/useColorScheme';
import { Ionicons } from '@expo/vector-icons';
import React, { useState } from 'react';
import { StyleSheet, TouchableOpacity, View } from 'react-native';
import { ThemedText } from './ThemedText';

export function CustomHeader() {
  const colorScheme = useColorScheme();
  const isDark = colorScheme === 'dark';
  const [selectedIcon, setSelectedIcon] = useState<string | null>(null);

  const getIconColor = (iconName: string) => {
    if (selectedIcon === iconName) {
      return '#007AFF';
    }
    return '#000';
  };

  return (
    <View style={[
      styles.header,
      { backgroundColor: isDark ? '#000' : '#fff' }
    ]}>
      <View style={styles.logoContainer}>
        <ThemedText style={styles.logoText}>
          <ThemedText style={[styles.logoText, { color: '#007AFF' }]}>Tech</ThemedText>mates
        </ThemedText>
      </View>
      <View style={styles.actionsContainer}>
        <TouchableOpacity 
          style={styles.iconButton}
          onPress={() => setSelectedIcon(selectedIcon === 'add' ? null : 'add')}
        >
          <Ionicons 
            name="add-circle-outline" 
            size={24} 
            color={getIconColor('add')} 
          />
        </TouchableOpacity>
        <TouchableOpacity 
          style={styles.iconButton}
          onPress={() => setSelectedIcon(selectedIcon === 'chat' ? null : 'chat')}
        >
          <Ionicons 
            name="chatbubble-outline" 
            size={24} 
            color={getIconColor('chat')} 
          />
        </TouchableOpacity>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  header: {
    height: 80,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingTop: 40,
  },
  logoContainer: {
    flex: 1,
  },
  logoText: {
    fontSize: 24,
    fontWeight: 'bold',
  },
  actionsContainer: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  iconButton: {
    marginLeft: 16,
  },
}); 