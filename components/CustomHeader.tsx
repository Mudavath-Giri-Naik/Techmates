import { useColorScheme } from '@/hooks/useColorScheme';
import { Ionicons } from '@expo/vector-icons';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { useRouter } from 'expo-router';
import React, { useState } from 'react';
import { StyleSheet, TouchableOpacity, View } from 'react-native';
import { ThemedText } from './ThemedText';

export function CustomHeader() {
  const colorScheme = useColorScheme();
  const isDark = colorScheme === 'dark';
  const [selectedIcon, setSelectedIcon] = useState<string | null>(null);
  const router = useRouter();

  const handleProfilePress = async () => {
    const token = await AsyncStorage.getItem('token');
    if (token) {
      router.replace('/profile');
    } else {
      router.push('/LoginScreen');
    }
  };

  return (
    <View style={[
      styles.header,
      { backgroundColor: isDark ? '#000' : '#fff' }
    ]}>
      <TouchableOpacity style={styles.profileIconButton} onPress={handleProfilePress}>
        <Ionicons name="person-outline" size={28} color={selectedIcon === 'profile' ? '#007AFF' : '#000'} />
      </TouchableOpacity>
      <View style={styles.logoContainer}>
        <ThemedText style={styles.logoText}>
          <ThemedText style={[styles.logoText, { color: '#007AFF' }]}>Tech</ThemedText>mates
        </ThemedText>
      </View>
      <View style={styles.actionsContainer}>
        <TouchableOpacity 
          style={styles.iconButton}
          onPress={() => setSelectedIcon(selectedIcon === 'chat' ? null : 'chat')}
        >
          <Ionicons 
            name="chatbubble-outline" 
            size={28} 
            color={selectedIcon === 'chat' ? '#007AFF' : '#000'} 
          />
        </TouchableOpacity>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  header: {
    height: 100,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingTop: 40,
  },
  profileIconButton: {
    marginRight: 8,
  },
  logoContainer: {
    flex: 1,
    alignItems: 'center',
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