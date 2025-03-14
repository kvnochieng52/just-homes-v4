import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_apartment_live/api/api.dart';
import 'package:just_apartment_live/ui/property/post_property/models/submit_property.dart';
import 'package:just_apartment_live/widgets/header_main_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_apartment_live/ui/property/post_property/widgets/submit_button.dart';
import 'package:just_apartment_live/ui/property/post_property/widgets/image_preview.dart';
import 'package:just_apartment_live/ui/property/post_property/widgets/town_input.dart';
import 'package:just_apartment_live/ui/property/post_property/widgets/image_upload_input.dart';
import 'package:just_apartment_live/ui/property/post_property/widgets/title.dart';
import 'package:just_apartment_live/ui/property/post_property/widgets/regions_input.dart';

class PostPage extends StatefulWidget {
  const PostPage({super.key});

  @override
  _PostPageState createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  final _propertySubmissionService = PropertySubmissionService();

  var _userTown = '';
  var _userRegion = '';

  var _propertyID = 0;

  final _titleController = TextEditingController();

  bool _isSubRegionEnabled = false;
  bool _isLoadingSubRegions = false;

  List<AssetEntity> images = <AssetEntity>[];
  late List<File> _images;
  final picker = ImagePicker();

  bool _initDataFetched = false;
  bool _showRegionsInput = false;

  List<Map<String, dynamic>> _townsList = [];
  List<Map<String, dynamic>> _subRegionsList = [];

  var _propertyDetails;
  var _propertyFeaturesList;
  Map<String, dynamic> selectedtown = {"id": 1, "value": "Apple"};

  @override
  void initState() {
    super.initState();
    _getInitData();
    _images = [];
  }

  _getInitData() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = json.decode(localStorage.getString('user') ?? '{}');

    var data = {'user_id': user['id']};

    var res = await CallApi().postData(data, 'property/get-init-data-part-one');

    if (res.statusCode == 200) {
      var body = json.decode(res.body);

      if (body['success']) {
        final List<dynamic> townData = body['data']['townsList'];
        List<Map<String, dynamic>> towns = [];
        for (var tData in townData) {
          towns.add({
            'id': tData['id'],
            'value': tData['value'],
          });
        }

        setState(() {
          _townsList = towns;
          _initDataFetched = true;
        });
      }
    }
  }

  _getSubRegions(townID) async {
    setState(() {
      _subRegionsList = [];
      _isSubRegionEnabled = false;
      _isLoadingSubRegions = true;
    });

    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = json.decode(localStorage.getString('user') ?? '{}');

    var data = {
      'townID': townID,
      'user_id': user['id'],
      'propertyID': _propertyID
    };

    var res =
        await CallApi().postData(data, 'property/get-sub-regions-and-post');

    if (res.statusCode == 200) {
      var body = json.decode(res.body);

      print(body);

      if (body['success']) {
        final List<dynamic> subRegionsData = body['data']['subRegionsList'];

        List<Map<String, dynamic>> subRs = [];
        for (var sregionData in subRegionsData) {
          subRs.add({
            'id': sregionData['id'],
            'value': sregionData['value'],
          });
        }
        setState(() {
          _subRegionsList = subRs;
          _isSubRegionEnabled = true;
          _propertyID = body['data']['propertyID'];
          _propertyDetails = body['data']['propertyDetails'];
          _propertyFeaturesList = body['data']['propertyFeaturesList'];
        });
      }
    }

    setState(() {
      _isLoadingSubRegions = false;
    });
  }

  Future<void> pickAssets(BuildContext context) async {
    try {
      // Request permissions using photo_manager
      final PermissionState result =
          await PhotoManager.requestPermissionExtend();
      if (result.isAuth) {
        final List<AssetEntity>? result = await AssetPicker.pickAssets(
          context,
          pickerConfig: AssetPickerConfig(
            maxAssets: 40, // Allow up to 40 images
            requestType: RequestType.image,
            specialPickerType: SpecialPickerType.noPreview, // Disables camera
            selectedAssets: images, // Pass selected assets to pre-select them
          ),
        );

        if (result != null) {
          final List<File> newImages = [];
          for (var asset in result) {
            final File? file = await asset.file;
            if (file != null && !_images.any((img) => img.path == file.path)) {
              newImages.add(file);
            }
          }

          setState(() {
            _images.addAll(newImages);
            images = result; // Update the assets list
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No images selected.'),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissions are required to pick images.'),
          ),
        );
      }
    } catch (e) {
      print("Error picking assets: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred while picking images.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context)
          .scaffoldBackgroundColor, // Use theme's scaffold background color
      appBar: buildHeader(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          width: double.infinity,
          child: Card(
            elevation: 1.0,
            color: Theme.of(context).cardColor, // Use theme's card color
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  _buildTitle(context),
                  _buildPostForm(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(context) {
    return const Column(
      children: [
        Padding(
          padding: EdgeInsets.only(top: 10),
          child: Text(
            "Post A Property",
            style: TextStyle(fontSize: 20),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: 5),
          child: Text(
            "Step 1 of 3",
            style: TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildPostForm(context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          ImageUploadInput(
            pickAssets: () => pickAssets(context),
          ),
          ImagePreview(
            images: _images,
            onRemoveImage: (index) {
              setState(() {
                _images.removeAt(index);
              });
            },
          ),
          TitleInput(
            titleController: _titleController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter property title';
              }
              return null;
            },
          ),
          TownInput(
            townsList: _townsList,
            userTown: _userTown,
            isLoadingSubRegions: _isLoadingSubRegions,
            isDarkMode: Theme.of(context).brightness == Brightness.dark,
            onTownChanged: (selectedTown) {
              setState(() {
                _userTown = selectedTown?["id"].toString() ?? '';
                _showRegionsInput = true;
              });
            },
            fetchSubRegions: () => _getSubRegions(_userTown),
            initDataFetched: _initDataFetched,
          ),
          SubRegionInput(
            isSubRegionEnabled: _isSubRegionEnabled,
            subRegionsList: _subRegionsList,
            onChanged: (selectedSubRegion) {
              setState(() {
                _userRegion = selectedSubRegion?["id"].toString() ?? '';
              });
            },
            validator: (value) {
              if (value == null) {
                return 'Please select sub-region';
              }
              return null;
            },
            selectedSubRegion: _userRegion,
          ),
          NextButtonWidget(
            formKey: _formKey,
            images: _images,
            userTown: _userTown,
            userRegion: _userRegion,
            titleController: _titleController,
            propertyID: _propertyID.toString(),
            propertySubmissionService: _propertySubmissionService,
          )
        ],
      ),
    );
  }
}
