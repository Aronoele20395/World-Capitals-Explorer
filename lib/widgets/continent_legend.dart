import 'package:flutter/material.dart';

class ContinentLegend extends StatelessWidget {
  const ContinentLegend({super.key});

  static const Map<String, Color> continentColors = {
    'Europe':        Color(0xFF4FC3F7),
    'Asia':          Color(0xFFFFB74D),
    'Africa':        Color(0xFFA5D6A7),
    'North America': Color(0xFFCE93D8),
    'South America': Color(0xFFF48FB1),
    'Oceania':       Color(0xFF80DEEA),
    'Antarctica':    Color(0xFFB0BEC5),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12)
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: continentColors.entries.map((entry) {
          return Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: entry.value, shape: BoxShape.circle),),
              const SizedBox(width: 8,),
              Text(entry.key, style: const TextStyle(color: Colors.white70, fontSize: 11),)
            ],
          ),);
        }).toList(),
      ),
    );
  }
}
