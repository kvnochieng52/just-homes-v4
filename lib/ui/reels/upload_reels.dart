import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:just_apartment_live/models/configuration.dart';
import 'package:just_apartment_live/ui/reels/trimmer_view.dart';
import 'package:just_apartment_live/ui/reelsplayer/reels_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'reel_detail.dart';

class UserReels extends StatefulWidget {
  const UserReels({super.key});

  @override
  State<UserReels> createState() => _UserReelsState();
}

class _UserReelsState extends State<UserReels> {
  final List<File> _uploadedVideos = []; // List to store uploaded videos
  List _userReels = []; // List to hold user reels
  bool _isDeleting = false; // To track if a reel is being deleted

  @override
  void initState() {
    super.initState();
    _getUserReels(); // Fetch user reels on initialization
  }

  Future<bool> _getUserReels() async {
    try {
      SharedPreferences localStorage = await SharedPreferences.getInstance();
      var user = json.decode(localStorage.getString('user') ?? '{}');

      const uri = '${Configuration.API_URL}reels/get-user-reels';

      final response = await http.post(
        Uri.parse(uri),
        headers: {'Content-Type': 'application/json'},
        body:
            json.encode({'user_id': user['id']}), // Passing user id to the API
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        if (data['success'] == true && data['data'] != null) {
          setState(() {
            _userReels = List.from(data['data']);
          });
          return true;
        } else {
          print("Failed to fetch user reels: ${data['message']}");
          return false;
        }
      } else {
        print("Failed to fetch user reels: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error fetching user reels: $e");
      return false;
    }
  }

  void _deleteReel(String reelId) {
    // Confirmation dialog before deletion
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Reel'),
          content: const Text('Are you sure you want to delete this reel?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the confirmation dialog
                _performDeleteReel(reelId); // Delete reel
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  _performDeleteReel(String reelId) async {
    setState(() {
      _isDeleting = true; // Set deleting state to true
    });

    try {
      const uri = '${Configuration.API_URL}reels/delete-reel';
      final response = await http.post(
        Uri.parse(uri),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'reelId': reelId}), // Send the reel ID to the API
      );

      if (response.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserReels(),
          ),
        );
        //  _userReels.removeWhere((reel) => reel['id'] == reelId);

        setState(() {
          // Remove the deleted reel from the list

          _isDeleting =
              false; // Set deleting state to false after successful deletion
        });
        // Refresh the list of reels after deletion
        await _getUserReels();
      } else {
        setState(() {
          _isDeleting = false; // Set deleting state to false on failure
        });
        print("Failed to delete reel: ${response.body}");
      }
    } catch (e) {
      setState(() {
        _isDeleting = false; // Set deleting state to false if error occurs
      });
      print("Error deleting reel: $e");
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Reels',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF252742),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // Upload video card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                color: Colors.grey[200],
                child: SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.video_file),
                            label: const Text('UPLOAD VIDEO'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.purple,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              textStyle: const TextStyle(fontSize: 18),
                            ),
                            onPressed: () async {
                              final result =
                                  await FilePicker.platform.pickFiles(
                                type: FileType.video,
                                allowCompression: true,
                              );
                              if (result != null) {
                                final file = File(result.files.single.path!);
                                setState(() {
                                  _uploadedVideos.add(file);
                                });
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => TrimmerView(file),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Click on Upload video to get started',
                          style: TextStyle(fontSize: 15),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              // User reels list card
              Expanded(
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  color: Colors.grey[200],
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        if (_userReels.isEmpty)
                          const Text(
                            "No reels yet.",
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          )
                        else
                          Expanded(
                            child: ListView.builder(
                              itemCount: _userReels.length,
                              itemBuilder: (context, index) {
                                final reel = _userReels[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: Image.network(
                                            Configuration.WEB_URL +
                                                reel['screenshot'],
                                            width: 90,
                                            height: 90,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    _formatDate(
                                                        reel['created_at']),
                                                    style: const TextStyle(
                                                        fontSize: 14),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                        Icons.delete,
                                                        color: Colors.grey),
                                                    onPressed: () {
                                                      _deleteReel(reel['id']
                                                          .toString());
                                                    },
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              Row(
                                                children: [
                                                  Row(
                                                    children: [
                                                      const FaIcon(
                                                          FontAwesomeIcons
                                                              .heart,
                                                          size: 16),
                                                      const SizedBox(width: 4),
                                                      Text('${reel['likes']}'),
                                                    ],
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Row(
                                                    children: [
                                                      const FaIcon(
                                                          FontAwesomeIcons
                                                              .share,
                                                          size: 16),
                                                      const SizedBox(width: 4),
                                                      Text('${reel['shares']}'),
                                                    ],
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Row(
                                                    children: [
                                                      const Icon(Icons.comment,
                                                          size: 16),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                          '${reel['comments']?.length ?? 0}'),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Show loader while deleting
        floatingActionButton:
            _isDeleting ? const CircularProgressIndicator() : null,
      );

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final formatter =
          DateFormat('MMMM d, yyyy HH:mm'); // Use 'HH' for 24-hour format
      return formatter.format(date);
    } catch (e) {
      print("Error formatting date: $e");
      return dateStr;
    }
  }
}
