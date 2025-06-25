import { CustomHeader } from '@/components/CustomHeader';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { useRouter } from 'expo-router';
import React, { useState } from 'react';
import { Alert, Button, Linking, SafeAreaView, ScrollView, StyleSheet, Text, TextInput, TouchableOpacity, View } from 'react-native';

const socialPlatforms = [
  { key: 'instagram', label: 'Instagram' },
  { key: 'linkedin', label: 'LinkedIn' },
  { key: 'github', label: 'GitHub' },
  { key: 'leetcode', label: 'LeetCode' },
  { key: 'twitter', label: 'Twitter' },
  { key: 'portfolio', label: 'Portfolio' },
  { key: 'facebook', label: 'Facebook' },
  { key: 'dribbble', label: 'Dribbble' },
  { key: 'behance', label: 'Behance' },
];

export default function ProfileScreen() {
  const router = useRouter();
  const [profile, setProfile] = useState<any>(null);
  const [form, setForm] = useState({
    name: '',
    yearStart: '',
    yearEnd: '',
    branch: '',
    city: '',
    bio: '',
    ...Object.fromEntries(socialPlatforms.map(p => [p.key, ''])),
  });
  const [editing, setEditing] = useState(true);

  const handleLogout = async () => {
    await AsyncStorage.removeItem('token');
    Alert.alert('Logged out', 'You have been logged out.');
    router.replace('/LoginScreen');
  };

  const handleChange = (key: string, value: string) => {
    setForm({ ...form, [key]: value });
  };

  const handleSubmit = () => {
    setProfile(form);
    setEditing(false);
  };

  if (editing) {
    return (
      <SafeAreaView style={styles.container}>
        <CustomHeader />
        <ScrollView contentContainerStyle={styles.content}>
          <Text style={styles.title}>Edit Profile</Text>
          <TextInput style={styles.input} placeholder="Name" value={form.name} onChangeText={v => handleChange('name', v)} />
          <View style={{ flexDirection: 'row', gap: 8 }}>
            <TextInput style={[styles.input, { flex: 1 }]} placeholder="Year Start" value={form.yearStart} onChangeText={v => handleChange('yearStart', v)} keyboardType="numeric" />
            <TextInput style={[styles.input, { flex: 1 }]} placeholder="Year End" value={form.yearEnd} onChangeText={v => handleChange('yearEnd', v)} keyboardType="numeric" />
          </View>
          <TextInput style={styles.input} placeholder="Branch" value={form.branch} onChangeText={v => handleChange('branch', v)} />
          <TextInput style={styles.input} placeholder="City" value={form.city} onChangeText={v => handleChange('city', v)} />
          <TextInput style={styles.input} placeholder="Bio" value={form.bio} onChangeText={v => handleChange('bio', v)} multiline />
          <Text style={styles.socialTitle}>Social Links</Text>
          {socialPlatforms.map(platform => (
            <TextInput
              key={platform.key}
              style={styles.input}
              placeholder={platform.label + ' URL'}
              value={form[platform.key]}
              onChangeText={v => handleChange(platform.key, v)}
              autoCapitalize="none"
            />
          ))}
          <Button title="Submit" onPress={handleSubmit} color="#007AFF" />
        </ScrollView>
      </SafeAreaView>
    );
  }

  // Instagram-like profile view
  return (
    <SafeAreaView style={styles.container}>
      <CustomHeader />
      <ScrollView contentContainerStyle={styles.profileContent}>
        <View style={styles.profileHeader}>
          <View style={styles.avatar} />
          <Text style={styles.profileName}>{profile.name}</Text>
          <Text style={styles.profileBio}>{profile.bio}</Text>
        </View>
        <View style={styles.profileDetails}>
          <Text style={styles.detailText}>Year of Study: {profile.yearStart} - {profile.yearEnd}</Text>
          <Text style={styles.detailText}>Branch: {profile.branch}</Text>
          <Text style={styles.detailText}>City: {profile.city}</Text>
        </View>
        <View style={styles.socialLinksContainer}>
          {socialPlatforms.map(platform => (
            profile[platform.key] ? (
              <TouchableOpacity key={platform.key} onPress={() => Linking.openURL(profile[platform.key])} style={styles.socialLink}>
                <Text style={styles.socialLinkText}>{platform.label}</Text>
              </TouchableOpacity>
            ) : null
          ))}
        </View>
        <Button title="Edit Profile" onPress={() => setEditing(true)} color="#007AFF" />
        <View style={{ marginTop: 24 }}>
          <Button title="Log Out" onPress={handleLogout} color="#FF3B30" />
        </View>
      </ScrollView>
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
    justifyContent: 'center',
    alignItems: 'center',
    padding: 16,
    marginBottom: 60,
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
  socialTitle: {
    fontSize: 18,
    fontWeight: '600',
    marginTop: 16,
    marginBottom: 8,
    color: '#007AFF',
  },
  profileContent: {
    alignItems: 'center',
    padding: 16,
    paddingBottom: 60,
  },
  profileHeader: {
    alignItems: 'center',
    marginBottom: 16,
  },
  avatar: {
    width: 90,
    height: 90,
    borderRadius: 45,
    backgroundColor: '#e0e0e0',
    marginBottom: 12,
  },
  profileName: {
    fontSize: 22,
    fontWeight: 'bold',
    color: '#222',
    marginBottom: 4,
  },
  profileBio: {
    fontSize: 16,
    color: '#444',
    marginBottom: 8,
    textAlign: 'center',
  },
  profileDetails: {
    marginBottom: 16,
    alignItems: 'center',
  },
  detailText: {
    fontSize: 16,
    color: '#555',
    marginBottom: 2,
  },
  socialLinksContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'center',
    marginBottom: 16,
    gap: 8,
  },
  socialLink: {
    backgroundColor: '#f1f1f1',
    borderRadius: 6,
    paddingHorizontal: 10,
    paddingVertical: 6,
    margin: 4,
  },
  socialLinkText: {
    color: '#007AFF',
    fontWeight: '600',
    fontSize: 15,
  },
}); 