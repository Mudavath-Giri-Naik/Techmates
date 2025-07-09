import AsyncStorage from '@react-native-async-storage/async-storage';
import { useRouter } from 'expo-router';
import React, { useState } from 'react';
import { Alert, Button, KeyboardAvoidingView, Platform, SafeAreaView, ScrollView, StyleSheet, Text, TextInput, TouchableOpacity, View } from 'react-native';

type ProfileForm = {
  name: string;
  yearStart: string;
  yearEnd: string;
  branch: string;
  city: string;
};

export default function ProfileScreen() {
  const router = useRouter();
  const [profile, setProfile] = useState<ProfileForm | null>(null);
  const [form, setForm] = useState<ProfileForm>({
    name: '',
    yearStart: '',
    yearEnd: '',
    branch: '',
    city: '',
  });
  const [editing, setEditing] = useState(true);

  const handleLogout = async () => {
    await AsyncStorage.removeItem('token');
    Alert.alert('Logged out', 'You have been logged out.');
    router.replace('/LoginScreen');
  };

  const handleChange = (key: keyof ProfileForm, value: string) => {
    setForm({ ...form, [key]: value });
  };

  const handleSubmit = () => {
    setProfile(form);
    setEditing(false);
  };

  if (editing) {
    return (
      <SafeAreaView style={styles.container}>
        <KeyboardAvoidingView
          style={{ flex: 1 }}
          behavior={Platform.OS === 'ios' ? 'padding' : undefined}
          keyboardVerticalOffset={80}
        >
          <ScrollView contentContainerStyle={styles.content} style={{ flex: 1, width: '100%' }}>
            <Text style={styles.title}>Edit Profile</Text>
            <TextInput style={styles.input} placeholder="Name" value={form.name} onChangeText={v => handleChange('name', v)} />
            <View style={{ flexDirection: 'row', gap: 8 }}>
              <TextInput style={[styles.input, { flex: 1 }]} placeholder="Year Start" value={form.yearStart} onChangeText={v => handleChange('yearStart', v)} keyboardType="numeric" />
              <TextInput style={[styles.input, { flex: 1 }]} placeholder="Year End" value={form.yearEnd} onChangeText={v => handleChange('yearEnd', v)} keyboardType="numeric" />
            </View>
            <TextInput style={styles.input} placeholder="Branch" value={form.branch} onChangeText={v => handleChange('branch', v)} />
            <TextInput style={styles.input} placeholder="City" value={form.city} onChangeText={v => handleChange('city', v)} />
            <View style={{ marginTop: 16, marginBottom: 32 }}>
              <Button title="Submit" onPress={handleSubmit} color="#007AFF" />
            </View>
            {/* Logout button in edit mode */}
            <View style={{ padding: 16 }}>
              <TouchableOpacity style={styles.logoutButton} onPress={handleLogout}>
                <Text style={styles.logoutButtonText}>Logout</Text>
              </TouchableOpacity>
            </View>
          </ScrollView>
        </KeyboardAvoidingView>
      </SafeAreaView>
    );
  }

  if (!profile) return null;
  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.profileInfoContainer}>
        <Text style={styles.profileTitle}>Profile</Text>
        <Text style={styles.profileLabel}>Name:</Text>
        <Text style={styles.profileValue}>{profile.name}</Text>
        <Text style={styles.profileLabel}>Year Start:</Text>
        <Text style={styles.profileValue}>{profile.yearStart}</Text>
        <Text style={styles.profileLabel}>Year End:</Text>
        <Text style={styles.profileValue}>{profile.yearEnd}</Text>
        <Text style={styles.profileLabel}>Branch:</Text>
        <Text style={styles.profileValue}>{profile.branch}</Text>
        <Text style={styles.profileLabel}>City:</Text>
        <Text style={styles.profileValue}>{profile.city}</Text>
      </View>
      <View style={{ padding: 16 }}>
        <TouchableOpacity style={styles.logoutButton} onPress={handleLogout}>
          <Text style={styles.logoutButtonText}>Logout</Text>
        </TouchableOpacity>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
  },
  content: {
    flexGrow: 1,
    padding: 16,
    marginBottom: 60,
    paddingBottom: 32,
    width: '100%',
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#007AFF',
    marginBottom: 16,
  },
  input: {
    width: '100%',
    height: 44,
    borderColor: '#ccc',
    borderWidth: 1,
    borderRadius: 8,
    paddingHorizontal: 12,
    marginBottom: 12,
    fontSize: 16,
    backgroundColor: '#f9f9f9',
  },
  profileInfoContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 24,
  },
  profileTitle: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#007AFF',
    marginBottom: 24,
  },
  profileLabel: {
    fontSize: 18,
    fontWeight: '600',
    color: '#222',
    marginTop: 8,
  },
  profileValue: {
    fontSize: 18,
    color: '#555',
    marginBottom: 4,
  },
  logoutButton: {
    backgroundColor: '#ff3b30',
    borderRadius: 8,
    paddingVertical: 12,
    alignItems: 'center',
    marginTop: 16,
  },
  logoutButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: 'bold',
  },
}); 