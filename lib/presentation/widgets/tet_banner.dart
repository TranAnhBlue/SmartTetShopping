import 'package:flutter/material.dart';
import '../../../core/utils/location_service.dart';

class TetBanner extends StatelessWidget {
  const TetBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => LocationService().checkProximity(
        21.0285,
        105.8542,
        "Chợ Đồng Xuân",
      ),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Colors.red, Colors.orange]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              blurRadius: 12,
              color: Colors.black.withOpacity(0.2),
            )
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("🧧", style: TextStyle(fontSize: 28)),
            SizedBox(width: 10),
            Text(
              "Chúc Mừng Năm Mới 2027",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
