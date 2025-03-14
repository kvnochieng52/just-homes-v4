import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:just_apartment_live/ui/login/login.dart';
import 'package:just_apartment_live/ui/reels/trimmer_view.dart';
import 'package:just_apartment_live/ui/reelsplayer/widgets/mainwidget.dart';
import 'package:just_apartment_live/ui/reelsplayer/widgets/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class Reels extends StatefulWidget {
  const Reels({super.key});

  @override
  _ReelsState createState() => _ReelsState();
}

class _ReelsState extends State<Reels> {
  final videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(
      'https://flipfit-cdn.akamaized.net/flip_hls/661f570aab9d840019942b80-473e0b/video_h1.m3u8'));

  bool isUserLoggedIn = false;
  final List<File> _uploadedVideos = [];
  var userID = 0;

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
    loadVideoClip();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive, overlays: []);
  }

  Future<void> _checkUserStatus() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    String? userData = localStorage.getString('user');

    setState(() {
      if (userData != null && userData.isNotEmpty) {
        isUserLoggedIn = true;
        Map<String, dynamic> jsonMap = jsonDecode(userData);
        logger.i("JSON MAP $jsonMap");
        userID = jsonMap['id'] ?? 0;
      } else {
        isUserLoggedIn = false;
        userID = 0; // Default value if user data is not available
      }
    });
  }

  Future<List<dynamic>> _fetchVideos() async {
    var request = http.Request(
        'POST', Uri.parse('https://justhomes.co.ke/api/reels/get-videos'));
    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      String responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody);
      if (data['success'] == true && data['data'] != null) {
        return List<dynamic>.from(data['data'].map((video) {
          return {
            "video": 'https://justhomes.co.ke/${video['video_path'] ?? ""}',
            "username": video["user"]["name"] ?? "",
            "profile":
                '${video["user"]["avatar"] ?? "https://www.shutterstock.com/image-vector/avatar-gender-neutral-silhouette-vector-600nw-2470054311.jpg"}',
            "description": video["description"] ?? "",
            "likes": (video["likes"] ?? 0).toString(),
            "shares": (video["shares"] ?? 0).toString(),
            "comments": (video["comments"]),
            "id": (video["id"])
          };
        }));
      }
    } else {
      throw Exception('Failed to load videos');
    }
    return [];
  }

  Future<String> _getCachedVideo(String videoUrl) async {
    final cacheManager = DefaultCacheManager();
    final fileInfo = await cacheManager.getFileFromCache(videoUrl);

    if (fileInfo != null) {
      return fileInfo.file.path;
    } else {
      final downloadedFile = await cacheManager.downloadFile(videoUrl);
      return downloadedFile.file.path;
    }
  }

  _uploadVideo() async {
    if (isUserLoggedIn) {
      final result = await FilePicker.platform.pickFiles(
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
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text(
              'Please log in or create an account first',
              style: TextStyle(fontSize: 15),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoginPage(),
                    ),
                  );
                },
                child: const Text('Log in'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<List<dynamic>>(
        future: _fetchVideos(),
        builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child:
                  Image.asset('images/animated_logo.gif'), // Show animated logo
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            List<dynamic> videoUrls = snapshot.data!;
            return PreloadPageView.builder(
              scrollDirection: Axis.vertical,
              preloadPagesCount: 5,
              controller:
                  PreloadPageController(keepPage: false, initialPage: 0),
              itemCount: videoUrls.length,
              itemBuilder: (BuildContext context, int index) {
                String videoUrl = videoUrls[index]['video'];
                String username = videoUrls[index]['username'];
                String profile = videoUrls[index]['profile'];
                String description = videoUrls[index]['description'];
                String likes = videoUrls[index]['likes'];
                String shares = videoUrls[index]['shares'];
                var videoID = videoUrls[index]['id'];
                var comments = videoUrls[index]['comments'];

                return FutureBuilder<String>(
                  future: _getCachedVideo(videoUrl),
                  builder: (context, videoSnapshot) {
                    if (videoSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Center(
                        child: Image.asset(
                            'images/animated_logo.gif'), // Show animated logo
                      );
                    }

                    if (videoSnapshot.hasError) {
                      return Center(
                          child: Text(
                              'Error caching video: ${videoSnapshot.error}'));
                    }

                    if (videoSnapshot.hasData) {
                      String cachedVideoPath = videoSnapshot.data!;

                      // return Stack(children: [
                      //   // Full-screen black background
                      //   Positioned.fill(
                      //     child: Container(color: Colors.black),
                      //   ),
                      //   // Video player filling the screen
                      //   Positioned.fill(
                      //     child: AspectRatio(
                      //       aspectRatio: 16 / 8,
                      //       child: Videoplayer(url: cachedVideoPath),
                      //     ),
                      //   ),
                      //   // Overlay for comments and user info
                      //   CommentWithPublisher(
                      //     userName: username,
                      //     imageProfile: profile,
                      //     description: description,
                      //     isLoggedIn: isUserLoggedIn,
                      //   ),
                      //
                      //   Positioned(
                      //     bottom: 50,
                      //     right: 10,
                      //     width: 50,
                      //     height: 250,
                      //     child: likeShareCommentSave(
                      //         likes,
                      //         comments.length,
                      //         shares,
                      //         context,
                      //         comments,
                      //         cachedVideoPath,
                      //         videoID,
                      //         userID,
                      //         isUserLoggedIn),
                      //   ),
                      //   // Username and profile photo at the bottom
                      //   Positioned(
                      //     bottom: 20, // Adjust as needed
                      //     left: 10, // Adjust as needed
                      //     right:
                      //         10, // Optional: To center the content horizontally
                      //     child: Row(
                      //       children: [
                      //         // Profile Photo
                      //         CircleAvatar(
                      //           radius: 20, // Adjust the size as needed
                      //           backgroundImage: NetworkImage(
                      //               profile), // Or AssetImage if using a local image
                      //         ),
                      //         SizedBox(
                      //             width:
                      //                 10), // Space between photo and username
                      //         // Username
                      //         Text(
                      //           username,
                      //           style: TextStyle(
                      //             color: Colors
                      //                 .white, // Ensure visibility over the video
                      //             fontSize: 16, // Adjust font size
                      //             fontWeight: FontWeight.bold,
                      //           ),
                      //         ),
                      //       ],
                      //     ),
                      //   ),
                      // ]);

                      return Stack(
                        children: [
                          // Full-screen black background
                          Positioned.fill(
                            child: Container(color: Colors.black),
                          ),
                          // Video player filling the screen
                          Positioned.fill(
                            child: AspectRatio(
                              aspectRatio: 16 / 8,
                              child: Videoplayer(url: cachedVideoPath),
                            ),
                          ),
                          // Overlay for comments and user info
                          CommentWithPublisher(
                            userName: username,
                            imageProfile: profile,
                            description: description,
                            isLoggedIn: isUserLoggedIn,
                          ),
                          // Like, Share, Comment, Save

                          Positioned(
                            bottom: 150,
                            right: 10,
                            width: 50,
                            height: 250,
                            child: likeShareCommentSave(
                              likes,
                              comments.length,
                              shares,
                              context,
                              comments,
                              cachedVideoPath,
                              videoID,
                              userID,
                              isUserLoggedIn,
                            ),
                          ),

                          Positioned(
                            bottom: 85,
                            right: 20,
                            child: GestureDetector(
                              onTap: _uploadVideo,
                              child: Container(
                                width: 56, // Button width (size of the circle)
                                height:
                                    56, // Button height (size of the circle)
                                decoration: BoxDecoration(
                                  color:
                                      Colors.purple, // Button background color
                                  shape: BoxShape.circle, // Makes it round
                                ),
                                child: Icon(
                                  FontAwesomeIcons.plus,
                                  color: Colors.white,
                                  size: 30, // Icon size
                                ),
                              ),
                            ),
                          ),
                          // Username, Profile Photo, and Description at the bottom
                          Positioned(
                            bottom: 20, // Adjust as needed
                            left: 10, // Adjust as needed
                            right:
                                10, // Optional: To center the content horizontally
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Profile Photo
                                CircleAvatar(
                                  radius: 20, // Adjust the size as needed
                                  backgroundImage: NetworkImage(
                                      profile), // Or AssetImage for local images
                                ),
                                SizedBox(
                                    width: 10), // Space between photo and text
                                // Username and Description
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Username
                                      Text(
                                        username,
                                        style: TextStyle(
                                          color:
                                              Colors.white, // Ensure visibility
                                          fontSize: 16, // Adjust font size
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(
                                          height:
                                              5), // Space between username and description
                                      // Description
                                      Text(
                                        description,
                                        style: TextStyle(
                                          color: Colors
                                              .white70, // Slightly dimmer for distinction
                                          fontSize: 14, // Adjust font size
                                        ),
                                        maxLines: 2, // Limit to 2 lines
                                        overflow: TextOverflow
                                            .ellipsis, // Add ellipsis for long text
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }
                    return const Center(child: Text('Failed to load video.'));
                  },
                );
              },
            );
          }
          return const Center(child: Text('No videos available'));
        },
      ),
    );
  }

  void _onShareFileFromCache(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Get the cache directory path
    final cacheDir = await getTemporaryDirectory();

    // Correctly instantiate the File class with a valid file path
    final cacheFile = File('${cacheDir.path}/flutter_logo.png');

    // If the file doesn't exist in cache, load it from assets and save it to cache
    if (!await cacheFile.exists()) {
      final data = await rootBundle.load('assets/flutter_logo.png');
      final buffer = data.buffer;
      await cacheFile.writeAsBytes(
        buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
    }

    // Share the file from the cache
    final shareResult = await Share.shareXFiles(
      [
        XFile(cacheFile.path, mimeType: 'image/png'),
      ],
      sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
    );

    scaffoldMessenger.showSnackBar(getResultSnackBar(shareResult));
  }

  SnackBar getResultSnackBar(ShareResult result) {
    return SnackBar(content: Text('Share result: ${result.status}'));
  }

  void loadVideoClip() async {
    await videoPlayerController.initialize();
    videoPlayerController.play();
  }

  @override
  void dispose() {
    videoPlayerController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    super.dispose();
  }
}
