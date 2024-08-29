import 'package:chatapp/screens/HomePages/add_status_page.dart';
import 'package:chatapp/screens/HomePages/view_status_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:chatapp/providers/status_provider.dart';
// Import the StatusProvider

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  // ignore: prefer_final_fields
  // ignore: prefer_final_fields
// Add this field
  @override
  void initState() {
    super.initState();

    Provider.of<StatusProvider>(context, listen: false).fetchStatuses();
    // Call the getStatus method
  }

  @override
  Widget build(BuildContext context) {
    // Access the StatusProvider
    final statusProvider = Provider.of<StatusProvider>(context);
    final String? imageUrl = statusProvider.mystatus != null
        ? (statusProvider.mystatus!.statusImageUrls?.isNotEmpty ?? false
            ? statusProvider.mystatus!.statusImageUrls?.last
            : 'https://www.gravatar.com/avatar/00000000000000000000000000000000?d=mp')
        : 'https://www.gravatar.com/avatar/00000000000000000000000000000000?d=mp';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Status"),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // My Status Section
            ListTile(
              leading: Stack(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage:
                        NetworkImage(imageUrl!, scale: 1), // Placeholder image
                  ),
                  const Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.green,
                      child: Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              title: const Text("My Status"),
              subtitle: const Text("Tap to add status update"),
              onTap: () async {
                // Check if myStatus is available
                if (statusProvider.mystatus != null) {
                  // If myStatus exists, navigate to ViewStatusScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ViewStatusScreen(
                        status: statusProvider.mystatus!,
                        isuserwantdelete: true,
                      ),
                    ),
                  );
                } else {
                  // If myStatus is not available, fetch the status
                  try {
                    await statusProvider.fetchStatuses();

                    // Check again if myStatus is available after fetching
                    if (statusProvider.mystatus != null) {
                      Navigator.push(
                        // ignore: use_build_context_synchronously
                        context,
                        MaterialPageRoute(
                          builder: (context) => ViewStatusScreen(
                            status: statusProvider.mystatus!,
                            isuserwantdelete: true,
                          ),
                        ),
                      );
                    } else {
                      // ignore: use_build_context_synchronously
                      await statusProvider.selectStatusImage(context);
                      Logger().i(statusProvider.statusImageUrl);

                      // After image is uploaded, create the status
                      if (statusProvider.statusImageUrl.isNotEmpty == true) {
                        Navigator.push(
                            // ignore: use_build_context_synchronously
                            context,
                            MaterialPageRoute(
                                builder: (context) => AddStatusTextPage(
                                    statusImageUrl:
                                        statusProvider.statusImageUrl)));
                        // await createStatus(
                        //   statusText: _statusTextController.text,
                        //   statusImageUrl: statusProvider.statusImageUrl!,
                        // );
                        Logger().i('send user to add status page');
                      } else {
                        Logger().i('emty');
                      }
                    }
                  } catch (e) {
                    Logger().f(e);
                  }
                }
              },
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "Recent updates",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            // List of statuses from contacts
            Consumer<StatusProvider>(
              builder: (context, statusProvider, child) {
                return ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: statusProvider.statuses.length,
                  itemBuilder: (context, index) {
                    final status = statusProvider.statuses[index];

                    // Safely access the image URL, defaulting to a placeholder if necessary
                    final imageUrl = (status.statusImageUrls != null &&
                            status.statusImageUrls!.isNotEmpty)
                        ? status.statusImageUrls!
                            .first // or you could use index if appropriate
                        : 'https://www.gravatar.com/avatar/00000000000000000000000000000000?d=mp';

                    return ListTile(
                      leading: CircleAvatar(
                        radius: 30,
                        backgroundImage: NetworkImage(imageUrl),
                      ),
                      title: Text(status.username),
                      subtitle: Text(
                        "Last status at ${DateFormat('hh:mm a').format(status.timestamp)}",
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ViewStatusScreen(
                              status: status,
                              isuserwantdelete: false,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Trigger image selection and status creation
          await statusProvider.selectStatusImage(context);

          // After image is uploaded, create the status
          if (statusProvider.statusImageUrl.isNotEmpty == true) {
            Navigator.push(
                // ignore: use_build_context_synchronously
                context,
                MaterialPageRoute(
                    builder: (context) => AddStatusTextPage(
                        statusImageUrl: statusProvider.statusImageUrl)));
            // await createStatus(
            //   statusText: _statusTextController.text,
            //   statusImageUrl: statusProvider.statusImageUrl!,
            // );
            Logger().i('send user to add status page');
          }
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
