import { useColorScheme } from '@/hooks/useColorScheme';
import { StyleSheet, View, ViewProps } from 'react-native';

export function ThemedView({ style, ...props }: ViewProps) {
  const colorScheme = useColorScheme();

  return (
    <View
      style={[
        styles.container,
        { backgroundColor: colorScheme === 'dark' ? '#000' : '#fff' },
        style,
      ]}
      {...props}
    />
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
}); 