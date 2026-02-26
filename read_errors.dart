import 'dart:io';
import 'dart:convert';

void main() {
  final file = File('analyzer_output.json');
  final jsonStr = file.readAsStringSync(encoding: utf8);
  final data = jsonDecode(jsonStr);
  final diagnostics = data['diagnostics'] as List;
  for (var d in diagnostics) {
    var loc = d['location'];
    if (loc['file'].toString().contains('home_screen_tab')) {
      print('${d['severity']}: line ${loc['range']['start']['line']} - ${d['problemMessage']}');
    }
  }
}
