import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

void main() async {
  final url = Uri.parse('https://www.hurriyet.com.tr/nobetci-eczaneler/diyarbakir/');
  final response = await http.get(url, headers: {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
  });
  
  final document = parser.parse(response.body);
  final boxes = document.querySelectorAll('.ecz-module-pharmacy-info');
  
  Map<String, List<String>> byDistrict = {};
  
  for (var box in boxes) {
    final name = box.querySelector('.ecz-module-pharmacy-name')?.text.trim() ?? '';
    final subtitle = box.querySelector('.ecz-module-pharmacy-subtitle')?.text.trim() ?? '';
    final address = box.querySelector('.ecz-module-pharmacy-location')?.text.trim() ?? '';
    
    String district = 'Diðer';
    if (subtitle.contains('/')) {
      district = subtitle.split('/')[1].trim();
    } else {
      for (var d in ['Kayapýnar', 'Baðlar', 'Sur', 'Yeniþehir', 'Bismil', 'Ergani', 'Silvan', 'Çermik', 'Çýnar']) {
        if (address.toLowerCase().contains(d.toLowerCase())) {
          district = d;
          break;
        }
      }
    }
    
    byDistrict.putIfAbsent(district, () => []).add(name);
  }
  
  byDistrict.forEach((k, v) {
    print(k + ': (' + v.length.toString() + ') -> ' + v.join(', '));
  });
}
