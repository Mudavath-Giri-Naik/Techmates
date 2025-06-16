import { CustomHeader } from '@/components/CustomHeader';
import { ThemedView } from '@/components/ThemedView';
import { SafeAreaView, StyleSheet } from 'react-native';

export default function FeedScreen() {
  return (
    <SafeAreaView style={styles.container}>
      <CustomHeader />
      <ThemedView style={styles.content}>
        {/* Feed content will go here */}
      </ThemedView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
  },
  content: {
    flex: 1,
    padding: 16,
    marginBottom: 60, // Add bottom margin to account for tab bar
  },
}); 