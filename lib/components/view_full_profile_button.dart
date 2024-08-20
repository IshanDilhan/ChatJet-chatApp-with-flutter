import 'package:flutter/material.dart';

class ViewMoreButton extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onPressed;

  const ViewMoreButton({
    super.key,
    required this.isExpanded,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(20),
          backgroundColor: const Color(0xFFF5F6F9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: onPressed,
        child: Row(
          children: [
            const Icon(
              Icons.view_kanban_rounded,
              color: Color(0xFF2661FA),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                isExpanded ? 'View Less' : 'View Full ',
                style: const TextStyle(
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Transform.rotate(
              angle: isExpanded
                  ? -3.14 / 2
                  : 3.14 / 2, // Rotate 90 degrees if not expanded
              child: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.black,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
