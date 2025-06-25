import AsyncStorage from '@react-native-async-storage/async-storage';
import axios from 'axios';
import { useRouter } from 'expo-router';
import React, { useState } from 'react';
import { ActivityIndicator, Alert, Button, StyleSheet, Text, TextInput, TouchableOpacity, View } from 'react-native';

export default function LoginScreen({ onLoginSuccess }: { onLoginSuccess?: () => void }) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [isLogin, setIsLogin] = useState(true);
  const router = useRouter();

  const handleAuth = async () => {
    setLoading(true);
    try {
      if (isLogin) {
        const res = await axios.post('http://192.168.206.224:5000/api/auth/login', { email, password });
        const { token } = res.data;
        await AsyncStorage.setItem('token', token);
        setLoading(false);
        if (onLoginSuccess) onLoginSuccess();
        router.replace('/profile');
      } else {
        await axios.post('http://192.168.206.224:5000/api/auth/register', { email, password });
        setLoading(false);
        Alert.alert('Success', 'Account created! Please log in.');
        setIsLogin(true);
      }
    } catch (err: any) {
      setLoading(false);
      Alert.alert(isLogin ? 'Login Failed' : 'Sign Up Failed', err?.response?.data?.message || 'An error occurred');
    }
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>{isLogin ? 'Login' : 'Sign Up'}</Text>
      <TextInput
        style={styles.input}
        placeholder="Email"
        autoCapitalize="none"
        keyboardType="email-address"
        value={email}
        onChangeText={setEmail}
      />
      <TextInput
        style={styles.input}
        placeholder="Password"
        secureTextEntry
        value={password}
        onChangeText={setPassword}
      />
      {loading ? (
        <ActivityIndicator size="large" color="#007AFF" />
      ) : (
        <Button title={isLogin ? 'Login' : 'Sign Up'} onPress={handleAuth} />
      )}
      <TouchableOpacity onPress={() => setIsLogin(!isLogin)} style={styles.switchBtn}>
        <Text style={styles.switchText}>
          {isLogin ? "Don't have an account? Sign Up" : 'Already have an account? Login'}
        </Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 24,
    backgroundColor: '#fff',
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    marginBottom: 24,
    color: '#007AFF',
  },
  input: {
    width: '100%',
    height: 48,
    borderColor: '#ccc',
    borderWidth: 1,
    borderRadius: 8,
    paddingHorizontal: 12,
    marginBottom: 16,
    fontSize: 16,
  },
  switchBtn: {
    marginTop: 16,
  },
  switchText: {
    color: '#007AFF',
    fontSize: 16,
    textAlign: 'center',
  },
}); 