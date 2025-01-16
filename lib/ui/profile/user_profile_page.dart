import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:just_apartment_live/api/api.dart';
import 'package:just_apartment_live/models/configuration.dart';
import 'package:just_apartment_live/ui/loading.dart';
import 'package:just_apartment_live/ui/login/login.dart';
import 'package:just_apartment_live/ui/profile/profile_page.dart';
import 'package:just_apartment_live/ui/property/post_page.dart';
import 'package:just_apartment_live/widgets/theme_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

bool _isUploading = false;

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _initDataFetched = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _companyController = TextEditingController();
  final _facebookController = TextEditingController();
  final _twitterController = TextEditingController();
  final _tiktokController = TextEditingController();
  final _instagramController = TextEditingController();
  final _profileController = TextEditingController();

  String? _companyLogo;

  @override
  void initState() {
    super.initState();
    _getInitData();
  }

  File? _logoImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _logoImage = File(pickedFile.path);
      });
      _uploadLogo(); // Automatically upload after selection
    }
  }

  _getInitData() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = json.decode(localStorage.getString('user') ?? '{}');
    var data = {'user_id': user['id']};

    var res = await CallApi().postData(data, 'property/get-user-properties');

    if (res.statusCode == 200) {
      var body = json.decode(res.body);

      if (body['success']) {
        setState(() {
          _nameController.text = body['data']['userDetails']['name'] ?? '';
          _emailController.text = body['data']['userDetails']['email'] ?? '';
          _mobileController.text =
              body['data']['userDetails']['telephone'] ?? '';
          _companyController.text =
              body['data']['userDetails']['company_name']?.toString() ?? '';
          _facebookController.text =
              body['data']['userDetails']['facebook'] ?? '';
          _twitterController.text =
              body['data']['userDetails']['twitter'] ?? '';
          _tiktokController.text = body['data']['userDetails']['tiktok'] ?? '';
          _instagramController.text =
              body['data']['userDetails']['instagram'] ?? '';
          _profileController.text =
              body['data']['userDetails']['profile'] ?? '';

          _companyLogo = body['data']['userDetails']['company_logo'] ?? '';
          _initDataFetched = true;
        });
      }
    }
  }

  _submitForm(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    Loading().loader(context, "Processing...Please wait");

    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = json.decode(localStorage.getString('user') ?? '{}');

    var data = {
      'name': _nameController.text,
      'email': _emailController.text,
      'telephone': _mobileController.text,
      'company': _companyController.text,
      'facebook': _facebookController.text,
      'twitter': _twitterController.text,
      'tiktok': _tiktokController.text,
      'instagram': _instagramController.text,
      'profile': _profileController.text,
      'user_id': user['id'],
    };

    var res = await CallApi().postData(data, 'user/update-profile');

    var body = json.decode(res.body);

    if (res.statusCode == 200) {
      if (body['success']) {
        showDialog(
            context: context,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                title: const Text('Success'),
                content: const Text('Profile successfully updated.'),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Okay'),
                    onPressed: () {
                      Navigator.of(dialogContext).pop(); // Close the dialog
                      Navigator.of(context).pop(); // Close the profile page
                    },
                  ),
                ],
              );
            });
      }
    } else {
      Navigator.pop(context);
      print('Failed to upload images');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PostPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfilePage(),
                ),
              );
            },
          ),
        ],
        backgroundColor: HexColor('#252742'), // Set the AppBar background color
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (!_initDataFetched)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Shimmer.fromColors(
                    baseColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]! // Darker base color for dark mode
                        : Colors
                            .grey[300]!, // Lighter base color for light mode
                    highlightColor: Theme.of(context).brightness ==
                            Brightness.dark
                        ? Colors.grey[700]! // Slightly lighter for dark mode
                        : Colors.grey[
                            100]!, // Lighter highlight color for light mode
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(
                        8,
                        (index) => Container(
                          height: 40.0,
                          width: double.infinity,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors
                                  .grey[850] // Darker background for dark mode
                              : Colors.white, // White background for light mode
                          margin: const EdgeInsets.only(bottom: 16.0),
                        ),
                      ),
                    ),
                  ),
                ),
              if (_initDataFetched) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0, top: 15.0),
                  child: Center(
                    child: Text("Edit Profile",
                        style: TextStyle(
                            color: Theme.of(context)
                                .appBarTheme
                                .titleTextStyle
                                ?.color)),
                  ),
                ),
                // Form fields
                _buildTextField(_nameController, 'First & Last Name',
                    'Enter Your Name', true),
                _buildTextField(_emailController, 'Email Address',
                    'Enter Email Address', true),
                _buildTextField(_mobileController, 'Mobile Number',
                    'Enter Mobile Number', true, TextInputType.phone),
                _buildTextField(_companyController, 'Company Name (optional)',
                    'Enter Company Name', false),
                _buildUploadCompanyLogo(),
                _buildTextField(_facebookController, 'Facebook Link (optional)',
                    'Enter Facebook Link', false),
                _buildTextField(_twitterController, 'Twitter Link (optional)',
                    'Enter Twitter Link', false),
                _buildTextField(_tiktokController, 'TikTok Link (optional)',
                    'Enter TikTok Link', false),
                _buildTextField(_instagramController,
                    'Instagram Link (optional)', 'Enter Instagram Link', false),
                _buildTextField(
                    _profileController,
                    'Profile Description (optional)',
                    'Enter Profile Description',
                    false),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () => _submitForm(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.purple, // Set background color to purple
                      minimumSize: const Size(
                          double.infinity, 48), // Fit the entire width
                    ),
                    child: const Text(
                      "Update Profile",
                      style: TextStyle(
                          color: Colors.white), // Set text color to white
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadCompanyLogo() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Upload the Company Logo"),
        GestureDetector(
          onTap: _pickImage,
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                width: 100, // Set a fixed width
                height: 100, // Set a fixed height
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle,
                  image: _logoImage != null
                      ? DecorationImage(
                          image: FileImage(_logoImage!),
                          fit: BoxFit.cover,
                        )
                      : (_companyLogo != null && _companyLogo!.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(
                                  Configuration.WEB_URL + _companyLogo!),
                              fit: BoxFit.cover,
                            )
                          : null),
                ),
                child: _logoImage == null &&
                        (_companyLogo == null || _companyLogo!.isEmpty)
                    ? Icon(Icons.add_a_photo, size: 30, color: Colors.grey[700])
                    : null,
              ),
              if (_logoImage != null ||
                  (_companyLogo != null && _companyLogo!.isNotEmpty))
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: _removeImage, // Call updated remove function
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (_isUploading)
          CircularProgressIndicator(), // Display a loading indicator if uploading
      ],
    );
  }

  Future<void> _uploadLogo() async {
    if (_logoImage == null) return;

    setState(() {
      _isUploading = true;
    });

    // Retrieve user ID from SharedPreferences
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = json.decode(localStorage.getString('user') ?? '{}');
    var userId = user['id'];

    // Replace with your server's upload endpoint
    final uri = Uri.parse('${Configuration.API_URL}user/upload-company-logo');
    final request = http.MultipartRequest('POST', uri)
      ..fields['user_id'] = userId.toString() // Add user ID to request fields
      ..files.add(await http.MultipartFile.fromPath('logo', _logoImage!.path));

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "Logo uploaded successfully. Click on update profile to finish",
            ),
            duration: const Duration(
                seconds: 3), // Delay the disappearance (adjust as needed)
            action: SnackBarAction(
              label: 'X',
              textColor:
                  Colors.white, // Optional: Customize the "X" button color
              onPressed: () {
                // Dismiss the SnackBar when the user presses the "X" button
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to upload logo: $responseBody")),
        );

        print("Failed to upload logo: $responseBody");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: $e")),
      );
      print("An error occurred: $e");
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _logoImage = null; // Clear locally selected image
      _companyLogo = ''; // Clear existing uploaded image URL from network
    });
  }

  Widget _buildTextField(TextEditingController controller, String labelText,
      String hintText, bool isRequired,
      [TextInputType inputType = TextInputType.text]) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          fillColor: Theme.of(context)
              .colorScheme
              .surface, // Background color based on theme
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(
              color: isDarkMode
                  ? Colors.grey[700]!
                  : Colors.grey[300]!, // Border color based on theme
            ),
          ),
        ),
        style: TextStyle(
            color: isDarkMode
                ? Colors.white
                : Colors.black), // Text color based on theme
        validator: (value) {
          if (isRequired && (value == null || value.isEmpty)) {
            return '$labelText is required';
          }
          return null;
        },
      ),
    );
  }
}
