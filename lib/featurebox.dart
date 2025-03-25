import 'package:flutter/material.dart';

class Featurebox extends StatelessWidget {
  final Color color;
  final String title;
  final String description;
  const Featurebox({super.key, required this.color, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal : 30,  
        vertical : 10,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.all(Radius.circular(15)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 12.0, left: 12.0, right: 20.0, bottom: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: "SpaceMono",
              ),
            ),
            const SizedBox(height: 3),
            Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: "SpaceMono",
              ),
            ),  
          ],
        ),
      ),
    );
  }
}