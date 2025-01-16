import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:full_picker/full_picker.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:just_apartment_live/api/api.dart';
import 'package:just_apartment_live/ui/dashboard/dashboard_page.dart';
import 'package:just_apartment_live/ui/login/login.dart';
import 'package:just_apartment_live/ui/reels/trimmer_view.dart';
import 'package:just_apartment_live/ui/reelsplayer/widgets/likes_widget.dart';
import 'package:just_apartment_live/ui/reelsplayer/widgets/share_widget.dart';
import 'package:logger/logger.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:video_compress/video_compress.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

final logger = Logger();

_showSignInPrompt(BuildContext ctx) {
  showDialog(
    context: ctx,
    builder: (context) => AlertDialog(
      title: const Text('Sign In Required'),
      content: const Text('To like or share videos, you must be signed in.'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const LoginPage()));
          },
          child: const Text('Login'),
        ),
      ],
    ),
  );
}

Widget lockedInteractionPrompt(BuildContext ctx) {
  return GestureDetector(
    onTap: () => _showSignInPrompt(ctx),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          CupertinoIcons.lock,
          size: 30,
          color: Colors.red,
        ),
        const SizedBox(height: 10),
      ],
    ),
  );
}

Column likeShareCommentSave(
    var likes,
    var comments,
    var shares,
    BuildContext ctx,
    var commentList,
    String filepath,
    var videoId,
    var userId,
    var isUserLoggedIn) {
  // print("COMMENTS HEEEERE" + commentList.toString());
  return Column(
    children: [
      isUserLoggedIn
          ? LikeWidget(
              initialLikes: int.parse(likes),
              videoId: videoId,
              userId: userId,
            )
          : iconDetail(CupertinoIcons.heart, likes.toString(), () {
              print("I was commented");
              _showSignInPrompt(ctx);
            }),
      const SizedBox(height: 25),
      isUserLoggedIn
          ? iconDetail(CupertinoIcons.chat_bubble, comments.toString(), () {
              print("I was commented");
              showCommentsDialog(ctx, commentList, userId, videoId);
            })
          : iconDetail(CupertinoIcons.chat_bubble, comments.toString(), () {
              print("I was commented");
              _showSignInPrompt(ctx);
            }),
      const SizedBox(height: 25),
      isUserLoggedIn
          ? ShareWidget(
              initialShares: int.parse(shares),
              videoId: videoId,
              userId: userId,
              filepath: filepath,
            )
          : iconDetail(CupertinoIcons.arrow_turn_up_right, shares.toString(),
              () {
              print("I was commented");
              _showSignInPrompt(ctx);
            }),
      const SizedBox(height: 25),
      // const Icon(CupertinoIcons.ellipsis_vertical,
      //     size: 22, color: Colors.white),
    ],
  );
}

Widget postComment(String time, String postComment, String profileName,
    String profileImage, int likeCount) {
  return Padding(
    padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        CircleAvatar(
          maxRadius: 16,
          backgroundImage:
              NetworkImage(profileImage), // Recommended for circular images
          child: profileImage == null
              ? const Icon(Icons.person) // Fallback if no image is available
              : null,
        ),
        const SizedBox(width: 16.0),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profileName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      postComment,
                      style: const TextStyle(fontSize: 14.0),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12.0),
            Row(
              children: [
                Text(time, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 1),
                InkWell(
                  onTap: () {},
                  child: Text('$likeCount'),
                ),
                const SizedBox(width: 1),
              ],
            ),
          ],
        )
      ],
    ),
  );
}

String getAvatarUrl(Map<String, dynamic> comment) {
  const defaultAvatarUrl =
      'https://www.shutterstock.com/image-vector/default-profile-picture-avatar-photo-260nw-1681253560.jpg';
  const baseUrl = 'https://justhomes.co.ke';

  if (comment.containsKey('user')) {
    final user = comment['user'];
    if (user is Map && user.containsKey('avatar')) {
      final avatar = user['avatar'];
      if (avatar != null && avatar.isNotEmpty) {
        if (avatar.startsWith('https://')) {
          return avatar;
        } else {
          return '$baseUrl$avatar';
        }
      }
    }
  }
  return defaultAvatarUrl;
}

Future<Map<String, dynamic>> getCurrentUser() async {
  SharedPreferences localStorage = await SharedPreferences.getInstance();
  String userJson = localStorage.getString('user') ?? '{}';
  return json.decode(userJson);
}

void showCommentsDialog(BuildContext context, var comments, userId, videoid) {
  // print("COMMENTS DATA: " + comments.toString());
  TextEditingController controller = TextEditingController();

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
    ),
    builder: (BuildContext context) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize
                  .min, // Ensures dialog content adjusts to its content
              children: [
                // Display existing comments
                const Center(child: Text("Comments")),
                Expanded(
                  child: comments.isEmpty
                      ? const Center(child: Text("No comments"))
                      : ListView.builder(
                          itemCount: comments.length,
                          itemBuilder: (BuildContext context, int index) {
                            final comment = comments[index];
                            final avatarUrl = getAvatarUrl(comment);
                            return postComment(
                              timeago.format(
                                  DateTime.parse(comment['created_at'])),
                              comment['comment'] ?? "",
                              comment['user'] is Map
                                  ? comment['user']["name"]
                                  : ".",
                              avatarUrl,
                              comments.length,
                            );
                          },
                        ),
                ),
                // Input field to add new comment
                Padding(
                  padding: EdgeInsets.only(
                    top: 8.0,
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            hintText: 'Add a comment...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10.0,
                              horizontal: 16.0,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () async {
                          if (controller.text.isNotEmpty) {
                            // Handle comment submission

                            Map<String, dynamic> user = await getCurrentUser();
                            String userName = user['name'] ??
                                'Current User'; // Replace 'Current User' with the actual field name
                            String userAvatar = user['avatar'] ??
                                'https://www.shutterstock.com/image-vector/default-profile-picture-avatar-photo-260nw-1681253560.jpg';

                            comments.add({
                              'comment': controller.text,
                              'user': {
                                'name': userName,
                                'avatar': userAvatar,
                              },
                              'created_at': DateTime.now().toIso8601String(),
                            });

                            // comments.add({
                            //   'comment': controller.text,
                            //   'user':
                            //       'Current User', // Replace with actual user info
                            //   'created_at': DateTime.now().toIso8601String(),
                            // });

                            // print("THE USER ID: " + userId.toString());

                            _postCommentToServer(
                                videoid, userId, controller.text);

                            controller.clear(); // Clear input field
                            //  Navigator.pop(context); // Close the dialog
                            showCommentsDialog(context, comments, userId,
                                videoid); // Refresh the comment list
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Future<void> updateLikes(int like, int videoId, int userId) async {
  var url =
      "https://justhomes.co.ke/api/reels/update-likes?likes=$like&videoId=$videoId&user_id=$userId";
  try {
    final response = await http.post(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        // likes = int.parse(data['likes']);
        // shares = data['shares'];
        print("Likes updated successfully!");
      }
    } else {
      print("Failed to update likes: ${response.body}");
    }
  } catch (e) {
    print("Error: $e");
  }
}

Future<void> _showLoginPrompt(BuildContext context) async {
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Please log in or create an account first',
            style: TextStyle(fontSize: 15)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const LoginPage()));
            },
            child: const Text('Log in'),
          ),
        ],
      );
    },
  );
}

void showVideoOptions(BuildContext context, bool _hasLoggedIn) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Container(
        padding: const EdgeInsets.all(16),
        height: 180,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ListTile(
                leading:
                    const Icon(Icons.fiber_manual_record, color: Colors.red),
                title: const Text('Live'),
                onTap: () {
                  // Navigator.of(context).pop();
                  //
                  _hasLoggedIn
                      ? {Navigator.of(context).pop(), _recordVideo(context)}
                      : showDialog(
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
                                        builder: (context) => const LoginPage(),
                                      ),
                                    );
                                  },
                                  child: const Text('Log in'),
                                ),
                              ],
                            );
                          },
                        );
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library),
                title: const Text('Add Video'),
                onTap: () {
                  _hasLoggedIn
                      ? {
                          Navigator.of(context).pop(),
                          _pickVideoFromGallery(context, _hasLoggedIn)
                        }
                      : showDialog(
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
                                        builder: (context) => const LoginPage(),
                                      ),
                                    );
                                  },
                                  child: const Text('Log in'),
                                ),
                              ],
                            );
                          },
                        );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _pickVideoFromGallery(
    BuildContext context, bool _hasLoggedIn) async {
  final ImagePicker _picker = ImagePicker();

  final XFile? videoFile = await _picker.pickVideo(source: ImageSource.gallery);

  if (videoFile != null) {
    final file = File(videoFile.path);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TrimmerView(file),
      ),
    );
  }
}

_postCommentToServer(videoid, userId, comment) async {
  var data = {'userID': userId, 'videoID': videoid, 'comment': comment};

  var res = await CallApi().postData(data, 'reels/post-comment');

  if (res.statusCode == 200) {
    var body = json.decode(res.body);
    if (body['success']) {
      print("successsssfuul: {$videoid}");
    }
  }
}

Future<void> _recordVideo(BuildContext context) async {
  final ImagePicker _picker = ImagePicker();
  final XFile? videoFile = await _picker.pickVideo(
    source: ImageSource.camera,
    maxDuration: const Duration(minutes: 5),
  );

  if (videoFile != null) {
    final file = File(videoFile.path);
    logger.i("videoFile.path: ${videoFile.path}");
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TrimmerView(
          file,
          isLiveVideo: true,
        ),
      ),
    );
  }
}

Widget iconDetail(IconData icon, String number, VoidCallback onPressed) {
  return GestureDetector(
    onTap: onPressed, // Trigger onPressed callback when tapped
    child: Column(
      children: [
        Icon(icon, size: 33, color: Colors.white),
        Text(
          number,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: Colors.white,
          ),
        ),
      ],
    ),
  );
}

class CommentWithPublisher extends StatefulWidget {
  final String userName;
  final String imageProfile;
  final String description;
  final bool isLoggedIn;

  const CommentWithPublisher(
      {super.key,
      required this.userName,
      required this.imageProfile,
      required this.description,
      required this.isLoggedIn});

  @override
  _CommentWithPublisherState createState() => _CommentWithPublisherState();
}

class _CommentWithPublisherState extends State<CommentWithPublisher> {
  @override
  Widget build(BuildContext context) => Column(children: [
        const SizedBox(height: 30),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  CupertinoIcons.arrow_left,
                  color: Colors.white,
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const DashBoardPage()),
                  );

                  // Navigator.pushAndRemoveUntil(
                  //   context,
                  //   MaterialPageRoute(
                  //       builder: (context) =>
                  //           DashBoardPage()), // Replace NewPage with your desired page
                  //   (Route<dynamic> route) =>
                  //       false, // Remove all previous routes
                  // );
                },
              ),
              const Text(
                'Reels',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.normal,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  // IconButton(
                  //   icon: const Icon(CupertinoIcons.videocam,
                  //       color: Colors.purple, size: 36),
                  //   // onPressed: () {
                  //   onPressed: () {
                  //     showVideoOptions(context, widget.isLoggedIn);
                  //   },

                  // FullPicker(
                  //   context: context,
                  //   prefixName: 'just homes',
                  //   file: false,
                  //   voiceRecorder: false,
                  //   video: true,
                  //   videoCamera: true,
                  //   imageCamera: false,
                  //   imageCropper: false,
                  //   multiFile: false,
                  //   url: false,
                  //   onError: (final int value) {
                  //     if (kDebugMode) {
                  //       print(' ----  onError ----=$value');
                  //     }
                  //   },
                  //   onSelected: (final FullPickerOutput value) async {
                  //     if (kDebugMode) {
                  //       print(' ----  onSelected ----');
                  //     }
                  //
                  //     // Check if there are any selected videos
                  //     if (value.xFile.isNotEmpty) {
                  //       // Access the first file in the list (since it's a List<XFile?>)
                  //       XFile selectedXFile = value.xFile.firstWhere(
                  //           (xfile) => xfile != null,
                  //           orElse: () =>
                  //               null // Handle the case where the file is null
                  //           )!;
                  //
                  //       // Convert XFile to File
                  //       File videoFile = File(selectedXFile.path);
                  //
                  //       final uint8List = await VideoThumbnail.thumbnailData(
                  //         video: videoFile.path,
                  //         imageFormat: ImageFormat.PNG,
                  //         maxWidth: 1280,
                  //         quality: 75,
                  //       );
                  //
                  //       final filePath = '${videoFile.path}_thumbnail.png';
                  //       final file = File(filePath);
                  //       await file.writeAsBytes(uint8List!);
                  //
                  //       final screenshotFile = file;
                  //
                  //       // Assuming you want to take a screenshot from the video (e.g., a preview image)
                  //       // You can either manually create a screenshot or use an existing file as the screenshot
                  //       // Here, we assume `screenshotFile` is pre-defined or fetched as needed
                  //
                  //       // Now, call the `uploadVideoLive` function to upload the video and screenshot
                  //       await uploadVideoLive(
                  //         url:
                  //             'https://justhomes.co.ke/api/reels/upload-video', // Replace with the actual upload URL
                  //         userId: 123, // Replace with the actual user ID
                  //         description:
                  //             'New Video', // Replace with your description
                  //         videoFile: videoFile,
                  //         screenshotFile: screenshotFile,
                  //         context:
                  //             context, // Pass the context for showing progress
                  //       );
                  //
                  //       setState(() {});
                  //     } else {
                  //       print('No video selected');
                  //     }
                  //   },
                  // );
                  // },
                  // ),
                  // Text('New Video', style: TextStyle(color: Colors.white))
                ],
              ),
            ],
          ),
        ),
        const Spacer(),
        const Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 20.0,
            vertical: 40.0,
          ),
        ),
      ]);
}

Future<void> uploadVideoLive({
  required String url,
  required int userId,
  required String description,
  required File videoFile,
  required File screenshotFile,
  required BuildContext context, // To show progress dialog
}) async {
  try {
    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Please wait uploading..."),
            ],
          ),
        );
      },
    );

    // Compress the video
    final compressedVideo = await VideoCompress.compressVideo(
      videoFile.path,
      quality: VideoQuality.MediumQuality,
      deleteOrigin: false, // Keeps the original video
    );

    if (compressedVideo == null) {
      throw Exception("Video compression failed.");
    }

    File compressedVideoFile = File(compressedVideo.path!);

    final uri = Uri.parse('$url?user_id=$userId&description=$description');

    // Create the multipart request
    final request = http.MultipartRequest('POST', uri);

    // Attach the compressed video file
    request.files.add(
      await http.MultipartFile.fromPath(
        'video',
        compressedVideoFile.path,
        filename: 'video.mp4',
      ),
    );

    // Attach the screenshot file
    request.files.add(
      await http.MultipartFile.fromPath(
        'screenshot',
        screenshotFile.path,
        filename: 'screenshot.jpg',
      ),
    );

    // Log request details
    print('POST Request to: $uri');
    print('Request fields: user_id=$userId, description=$description');
    print('Video file: ${compressedVideoFile.path}');
    print('Screenshot file: ${screenshotFile.path}');

    // Send the request
    final response = await request.send();

    // Read and log the response
    final responseData = await response.stream.bytesToString();
    Navigator.of(context).pop(); // Close the progress dialog

    if (response.statusCode == 200) {
      // Show success message
      Fluttertoast.showToast(msg: "Upload successful!");
    } else {
      // Show error message
      Fluttertoast.showToast(msg: "Upload failed: ${response.statusCode}");
      print('Upload failed with status: ${response.statusCode}');
      print('Response: $responseData');
    }
  } catch (e) {
    Navigator.of(context).pop(); // Close the progress dialog
    Fluttertoast.showToast(msg: "Error: $e");
    print('Error during upload: $e');
  }
}
