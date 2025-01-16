import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_apartment_live/models/configuration.dart';
import 'package:just_apartment_live/ui/reelsplayer/reel_player.dart';
import 'package:just_apartment_live/ui/reelsplayer/reels_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_trimmer/video_trimmer.dart';
import 'package:path/path.dart';
import 'package:flutter/rendering.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';

class TrimmerView extends StatefulWidget {
  bool? isLiveVideo;
  final File file;

  TrimmerView(
    this.file, {
    super.key,
    this.isLiveVideo = false,
  });

  @override
  State<TrimmerView> createState() => _TrimmerViewState();
}

class _TrimmerViewState extends State<TrimmerView> {
  final _trimmer = Trimmer();
  final TextEditingController _descriptionController = TextEditingController();

  double _startValue = 0.0;
  double _endValue = 0.0;
  bool _isPlaying = false;
  bool _progressVisibility = false;
  bool _hasLoggedIn = false;
  int? _userID = 0;

  @override
  void initState() {
    super.initState();
    _loadVideo();
    _loadUser();
  }

  Future<void> _loadUser() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = json.decode(localStorage.getString('user') ?? '{}');
    print('User Details: $user');
    print('User id: ${user['id']}');

    // {id: 122, name: Ruth west, email: ruthwestke@gmail.com, telephone:

    if (user.isEmpty) {
      setState(() {
        _hasLoggedIn = false;
        _userID = user['id'];
      });
    } else {
      setState(() {
        _hasLoggedIn = true;
      });
    }
  }

  void _loadVideo() {
    _trimmer.loadVideo(videoFile: widget.file);
  }

  Future<File?> _captureScreenshot() async {
    final uint8List = await VideoThumbnail.thumbnailData(
      video: widget.file.path,
      imageFormat: ImageFormat.PNG,
      maxWidth: 1280,
      quality: 75,
    );

    if (uint8List != null) {
      final filePath = '${widget.file.path}_thumbnail.png';
      final file = File(filePath);
      await file.writeAsBytes(uint8List);
      return file;
    }
    return null;
  }

  //-----------------------------SAVING & COMPRESS RECORDED VIDEO-----------------------------------------------
  Future<void> saveLiveVideo(BuildContext context) async {
    setState(() {
      _progressVisibility = true;
    });

    await _trimmer.saveTrimmedVideo(
      startValue: _startValue,
      endValue: _endValue,
      onSave: (String? outputPath) async {
        if (outputPath != null) {
          // Compress and convert video to MP4 if necessary
          final compressedPath = await _compressVideo(outputPath);

          if (compressedPath == null) {
            _showErrorDialog('Failed to compress video', context);
            return;
          }

          // Capture screenshot
          final screenshotFile = await _captureScreenshot();
          if (screenshotFile == null) {
            _showErrorDialog('Failed to capture screenshot', context);
            return;
          }

          // Upload the video
          await uploadVideoLive(
            url: 'https://justhomes.co.ke/api/reels/upload-video',
            userId: _userID ?? 0,
            description: _descriptionController.text,
            videoFile: File(compressedPath),
            screenshotFile: screenshotFile,
          );

          setState(() {
            _progressVisibility = false;
          });

          const snackBar =
              SnackBar(content: Text('Live video saved successfully.'));
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        } else {
          setState(() {
            _progressVisibility = false;
          });
          _showErrorDialog('Failed to save video', context);
        }
      },
    );
  }

  // Future<String?> _compressVideo(String filePath) async {
  //   final outputFilePath = '${filePath}_compressed.mp4';
  //   final Completer<String?> completer = Completer();
  //
  //   final command = '-i "$filePath" -vcodec libx264 -crf 28 "$outputFilePath"';
  //
  //   FFmpegKit.executeAsync(command, (session) async {
  //     final returnCode = await session.getReturnCode();
  //     if (ReturnCode.isSuccess(returnCode)) {
  //       logger.i('Video compression successful');
  //       completer.complete(outputFilePath);
  //     } else {
  //       logger.e('Video compression failed with code: $returnCode');
  //       completer.complete(null);
  //     }
  //   });
  //
  //   return completer.future;
  // }

  Future<String?> _compressVideo(String filePath) async {
    try {
      // Start video compression
      final info = await VideoCompress.compressVideo(
        filePath,
        quality: VideoQuality.MediumQuality, // Adjust quality as needed
        deleteOrigin:
            false, // Set to true if you want to delete the original file
      );

      if (info != null && info.path != null) {
        logger.i('Video compression successful: ${info.path}');
        return info.path; // Path to the compressed video
      } else {
        logger.e('Video compression failed');
        return null;
      }
    } catch (e) {
      logger.e('Error during video compression: $e');
      return null;
    }
  }

  Future<void> uploadVideoLive({
    required String url,
    required int userId,
    required String description,
    required File videoFile,
    required File screenshotFile,
  }) async {
    try {
      final uri = Uri.parse('$url?user_id=$userId&description=$description');

      // Create the multipart request
      final request = http.MultipartRequest('POST', uri);

      // Attach the video file
      request.files.add(
        await http.MultipartFile.fromPath(
          'video',
          videoFile.path,
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
      logger.i('POST Request to: $uri');
      logger.i('Request fields: user_id=$userId, description=$description');
      logger.i('Video file: ${videoFile.path}');
      logger.i('Screenshot file: ${screenshotFile.path}');

      // Send the request
      final response = await request.send();

      // Read and log the response
      final responseData = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        logger.i('Upload successful: $responseData');
      } else {
        logger.e('Upload failed with status: ${response.statusCode}');
        logger.e('Response: $responseData');
      }
    } catch (e) {
      logger.e('Error during upload: $e');
    }
  }

  Future<void> _uploadLiveVideo({
    required File videoFile,
    required String description,
    required File screenshot,
    required BuildContext context,
  }) async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = json.decode(localStorage.getString('user') ?? '{}');
    final userId = user['id'] ?? _userID;

    final uri = Uri.parse("https://justhomes.co.ke/api/reels/upload-video");

    final request = http.MultipartRequest('POST', uri)
      ..fields['user_id'] = userId.toString()
      ..fields['description'] = description
      ..files.add(await http.MultipartFile.fromPath('video', videoFile.path,
          filename: basename(videoFile.path)))
      ..files.add(await http.MultipartFile.fromPath(
          'screenshot', screenshot.path,
          filename: basename(screenshot.path)));

    logger.i('Uploading live video with user_id: $userId');

    final response = await request.send();
    if (response.statusCode == 200) {
      logger.i('Live video upload successful');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const ReelsPage(),
        ),
      );
    } else {
      final responseData = await response.stream.bytesToString();
      logger.e('Live video upload failed: $responseData');
      _showErrorDialog('Failed to upload live video', context);
    }
  }

  //----------------------------------------------------------------------------

  Future<void> _saveVideo(BuildContext context) async {
    setState(() {
      _progressVisibility = true;
    });

    await _trimmer.saveTrimmedVideo(
      startValue: _startValue,
      endValue: _endValue,
      // ffmpegCommand:
      //     '-vf "fps=10,scale=480:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" -loop 0',
      // customVideoFormat: '.gif',
      onSave: (String? outputPath) async {
        if (outputPath != null) {
          final directory = dirname(outputPath);
          const fileName = 'trimmed_video.mp4';
          final newFilePath = join(directory, fileName);

          final trimmedFile = File(newFilePath);
          await File(outputPath).copy(trimmedFile.path);
          await File(outputPath).delete();

          // Call upload video function
          await _uploadVideo(trimmedFile, _descriptionController.text, context);

          setState(() {
            _progressVisibility = false;
          });

          // Show success message (optional)
          final snackBar = SnackBar(
            //   content: Text('Video Saved successfully\n${trimmedFile.path}'),
            content: Text('Video uploaded successfully'),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        } else {
          setState(() {
            _progressVisibility = false;
          });

          // Show error message
          _showErrorDialog('Failed to save video', context);
        }
      },
    );
  }

  Future<void> _uploadVideo(
      File videoFile, String description, BuildContext context) async {
    const loadingDialog = AlertDialog(
      content: Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 20),
          Text('Uploading video...'),
        ],
      ),
    );
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => loadingDialog,
    );

    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = json.decode(localStorage.getString('user') ?? '{}');

    final uri = Uri.parse('${Configuration.API_URL}reels/upload-video');
    logger.w('Uploading file: ${videoFile.path}');

    final request = http.MultipartRequest('POST', uri)
      ..fields['user_id'] = user['id'].toString()
      ..fields['description'] = description
      ..files.add(
        await http.MultipartFile.fromPath(
          'video',
          videoFile.path,
          filename: basename(videoFile.path),
        ),
      );

    // Capture the screenshot
    final screenshotFile = await _captureScreenshot();
    if (screenshotFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'screenshot',
          screenshotFile.path,
          filename: basename(screenshotFile.path),
        ),
      );
    }

    try {
      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      Navigator.of(context).pop();

      if (response.statusCode == 200) {
        // Redirect to ReelsPage
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (BuildContext context) =>
                const Reels(), // Your ReelsPage widget
          ),
        );
      } else {
        _showErrorDialog('Failed to upload video: $responseData', context);
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      _showErrorDialog('Error uploading video: $e', context);
    }
  }

  void _showErrorDialog(String message, BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Upload Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => WillPopScope(
        onWillPop: () async {
          if (Navigator.of(context).userGestureInProgress) {
            return false;
          } else {
            return true;
          }
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: const Text('Upload Reel'),
            backgroundColor: Colors.black,
          ),
          body: Center(
            child: Container(
              padding: const EdgeInsets.only(bottom: 30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Visibility(
                    visible: _progressVisibility,
                    child: const LinearProgressIndicator(
                      backgroundColor: Colors.red,
                    ),
                  ),
                  Expanded(child: VideoViewer(trimmer: _trimmer)),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TrimViewer(
                        trimmer: _trimmer,
                        viewerHeight: 50.0,
                        viewerWidth: MediaQuery.of(context).size.width,
                        durationStyle: DurationStyle.FORMAT_MM_SS,
                        maxVideoLength: const Duration(seconds: 140),
                        editorProperties: TrimEditorProperties(
                          borderPaintColor: Colors.yellow,
                          borderWidth: 4,
                          borderRadius: 5,
                          circlePaintColor: Colors.yellow.shade800,
                        ),
                        areaProperties:
                            TrimAreaProperties.edgeBlur(thumbnailQuality: 10),
                        onChangeStart: (value) => _startValue = value,
                        onChangeEnd: (value) => _endValue = value,
                        onChangePlaybackState: (value) => setState(
                          () => _isPlaying = value,
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    child: _isPlaying
                        ? const Icon(
                            Icons.pause,
                            size: 50.0,
                            color: Colors.white,
                          )
                        : const Icon(
                            Icons.play_arrow,
                            size: 50.0,
                            color: Colors.white,
                          ),
                    onPressed: () async {
                      final playbackState = await _trimmer.videoPlaybackControl(
                        startValue: _startValue,
                        endValue: _endValue,
                      );
                      setState(() => _isPlaying = playbackState);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              hintText: 'Add a description...',
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10.0,
                                horizontal: 20.0,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        CircleAvatar(
                          backgroundColor: Colors.purple,
                          child: IconButton(
                            icon: const Icon(Icons.send, color: Colors.white),
                            onPressed: _progressVisibility
                                ? null
                                : () => widget.isLiveVideo!
                                    ? saveLiveVideo(context)
                                    : _saveVideo(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
