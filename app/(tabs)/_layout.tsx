import { useColorScheme } from '@/hooks/useColorScheme';
import { Ionicons } from '@expo/vector-icons';
import { Tabs } from 'expo-router';
import React from 'react';
import { Pressable } from 'react-native';

function NoFeedbackTabBarButton({
  children,
  onPress,
  onLongPress,
  accessibilityState,
  style,
  testID,
  accessibilityLabel,
  accessibilityRole,
  accessibilityHint,
}: any) {
  return (
    <Pressable
      onPress={onPress}
      onLongPress={onLongPress}
      accessibilityState={accessibilityState}
      style={style}
      testID={testID}
      accessibilityLabel={accessibilityLabel}
      accessibilityRole={accessibilityRole}
      accessibilityHint={accessibilityHint}
      android_ripple={null}
    >
      {children}
    </Pressable>
  );
}

export default function TabLayout() {
  const colorScheme = useColorScheme();

  return (
    <Tabs
      screenOptions={{
        tabBarActiveTintColor: '#007AFF',
        tabBarInactiveTintColor: '#000000',
        headerShown: false,
        tabBarShowLabel: false,
        tabBarButton: (props) => <NoFeedbackTabBarButton {...props} />,
        tabBarStyle: {
          position: 'absolute',
          bottom: 0,
          left: 0,
          right: 0,
          height: 70,
          backgroundColor: colorScheme === 'dark' ? '#000' : '#fff',
          borderTopWidth: 0.25,
          borderTopColor: colorScheme === 'dark' ? '#222' : '#E5E5EA',
          elevation: 0,
          paddingTop: 5,
          shadowOpacity: 0,
        },
        tabBarLabelStyle: {
          fontSize: 12,
          fontWeight: '600',
          marginBottom: 4,
        },
        tabBarItemStyle: {
          opacity: 1,
          backgroundColor: 'transparent',
          borderWidth: 0,
          elevation: 0,
          alignItems: 'center',
          justifyContent: 'center',
        },
      }}>
      <Tabs.Screen
        name="feed"
        options={{
          tabBarIcon: ({ color, focused }) => (
            <Ionicons 
              name={focused ? "home" : "home-outline"} 
              size={focused ? 30 : 30} 
              color={color} 
            />
          ),
        }}
      />
      <Tabs.Screen
        name="search"
        options={{
          tabBarIcon: ({ color, focused }) => (
            <Ionicons 
              name={focused ? "search" : "search-outline"} 
              size={focused ? 30 : 30} 
              color={color} 
            />
          ),
        }}
      />
      <Tabs.Screen
        name="post"
        options={{
          tabBarIcon: ({ color, focused }) => (
            <Ionicons
              name={focused ? "add-circle" : "add-circle-outline"}
              size={focused ? 30 : 30}
              color={color}
            />
          ),
          tabBarItemStyle: {
            backgroundColor: 'transparent',
          },
        }}
      />
      <Tabs.Screen
        name="resources"
        options={{
          tabBarIcon: ({ color, focused }) => (
            <Ionicons 
              name={focused ? "folder" : "folder-outline"} 
              size={focused ? 30 : 30} 
              color={color} 
            />
          ),
        }}
      />
      <Tabs.Screen
        name="work"
        options={{
          tabBarIcon: ({ color, focused }) => (
            <Ionicons
              name={focused ? "briefcase" : "briefcase-outline"}
              size={focused ? 30 : 30}
              color={color}
            />
          ),
        }}
      />
      <Tabs.Screen
        name="profile"
        options={{
          href: null,
        }}
      />
    </Tabs>
  );
}
