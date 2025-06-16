import { Ionicons } from '@expo/vector-icons';
import { StyleProp, TextStyle } from 'react-native';

type IconSymbolProps = {
  name: string;
  size?: number;
  color?: string;
  weight?: 'regular' | 'medium' | 'bold';
  style?: StyleProp<TextStyle>;
};

export function IconSymbol({ name, size = 24, color = '#000', style }: IconSymbolProps) {
  // Convert SF Symbol names to Ionicons names
  const getIoniconName = (sfName: string): keyof typeof Ionicons.glyphMap => {
    const nameMap: { [key: string]: keyof typeof Ionicons.glyphMap } = {
      'newspaper': 'newspaper-outline',
      'newspaper.fill': 'newspaper',
      'magnifyingglass': 'search-outline',
      'magnifyingglass.circle.fill': 'search',
      'folder': 'folder-outline',
      'folder.fill': 'folder',
      'person': 'person-outline',
      'person.fill': 'person',
    };
    return nameMap[sfName] || 'help-outline';
  };

  return (
    <Ionicons
      name={getIoniconName(name)}
      size={size}
      color={color}
      style={style}
    />
  );
} 