import 'package:chatapp/controlers/status_controller.dart';
import 'package:chatapp/providers/status_provider.dart';
import 'package:flutter/material.dart';
import 'package:chatapp/models/status_model.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

// ignore: must_be_immutable
class ViewStatusScreen extends StatefulWidget {
  final StatusModel status;
  bool isuserwantdelete;

  ViewStatusScreen(
      {super.key, required this.status, required this.isuserwantdelete});

  @override
  // ignore: library_private_types_in_public_api
  _ViewStatusScreenState createState() => _ViewStatusScreenState();
}

class _ViewStatusScreenState extends State<ViewStatusScreen> {
  late PageController _pageController;
  StatusController statusController = StatusController();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _deleteCurrentStatus(int index) async {
    try {
      await Provider.of<StatusProvider>(context, listen: false)
          .deleteStatusItem(index);

      setState(() {
        // Remove the image and text at the current index from the UI
        widget.status.statusImageUrls?.removeAt(index);
        widget.status.statusText?.removeAt(index);
      });
      if ((widget.status.statusImageUrls?.isEmpty ?? true) &&
          (widget.status.statusText?.isEmpty ?? true)) {
        // If all fields are empty, delete the whole status document
        await statusController.deleteStatus(widget.status.statusId);
        Logger().i(
            'Status document with ID ${widget.status.statusId} deleted successfully.');
      }

      Logger().i('Status item deleted successfully.');

      Logger().i('Status item deleted successfully.');

      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    } catch (e) {
      Logger().e('Failed to delete status item: $e');
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrls = widget.status.statusImageUrls ?? [];
    final statusTexts = widget.status.statusText ?? [];
    final hasImages = imageUrls.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (hasImages)
            // PageView for swiping through status images
            PageView.builder(
              controller: _pageController,
              itemCount: imageUrls.length,
              itemBuilder: (context, index) {
                final imageUrl = imageUrls[index];
                final text = index < statusTexts.length
                    ? statusTexts[index]
                    : 'No description'; // Fetch corresponding text

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Status image
                    Center(
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Status text
                    Positioned(
                      bottom: 70,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          text,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    if (widget.isuserwantdelete)
                      Positioned(
                        top: 130,
                        right: 20,
                        child: Material(
                          color: const Color.fromARGB(
                              0, 187, 177, 177), // Ensure no background color
                          child: InkWell(
                            borderRadius: BorderRadius.circular(
                                30), // For better tap area
                            onTap: () {
                              // Handle delete action
                              _deleteCurrentStatus(index);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 236, 235, 235)
                                    .withOpacity(0.8), // Background color
                                shape: BoxShape.circle, // Circular shape
                              ),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.red,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            )
          else
            // If no images, show a placeholder
            const Center(
              child: Text(
                'No Status Available',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          // User info at the top
          Positioned(
            top: MediaQuery.of(context).size.height *
                0.06, // Adjusted to move the user info down
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black.withOpacity(0.6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25, // Adjusted size
                    backgroundImage: NetworkImage(
                      widget.status.userProfileUrl.isNotEmpty
                          ? widget.status.userProfileUrl
                          : 'https://www.gravatar.com/avatar/00000000000000000000000000000000?d=mp',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                          height: 10,
                        ),
                        Text(
                          widget.status.username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'last status at${DateFormat(' hh:mm a').format(DateTime.parse(widget.status.timestamp.toString()))}', // Display the first text
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context); // Close the status view
                    },
                  ),
                ],
              ),
            ),
          ),
          if (hasImages)
            // Page indicator at the bottom
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: SmoothPageIndicator(
                  controller: _pageController,
                  count: imageUrls.length,
                  effect: const ScrollingDotsEffect(
                    activeDotColor: Colors.white,
                    dotColor: Colors.white54,
                    dotHeight: 8,
                    dotWidth: 8,
                    spacing: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
