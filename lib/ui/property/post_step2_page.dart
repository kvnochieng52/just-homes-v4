import 'dart:convert';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:just_apartment_live/api/api.dart';
import 'package:just_apartment_live/ui/property/post_step3_page.dart';
import 'package:just_apartment_live/ui/property/price_input_formatter.dart';
import 'package:just_apartment_live/widgets/header_main_widget.dart';
import 'package:just_apartment_live/widgets/theme_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class PostStep2Page extends StatefulWidget {
  // PostStep2Page({Key? key, required this.title}) : super(key: key);

  var propertyID;
  PostStep2Page({super.key, required this.propertyID});

  // final String title;

  @override
  _PostStep2PageState createState() => _PostStep2PageState();
}

class _PostStep2PageState extends State<PostStep2Page> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _amountController = TextEditingController();
  final _parkingSpacesController = TextEditingController();
  final _sqmController = TextEditingController();

  final jobRoleCtrl = TextEditingController();

  List<Map<String, dynamic>> _propertTypesList = [];
  var _propertyType = '';

  List<Map<String, dynamic>> _propertConditionsList = [];
  var _propertyCondition = '';

  List<Map<String, dynamic>> _furnishedList = [];
  var _propertyFurnished = '';

  List<Map<String, dynamic>> _leaseTypesList = [];
  var _leaseType = '';

  List<Map<String, dynamic>> _landTypesList = [];
  var _landType = '';

  List<Map<String, dynamic>> _landMeasurementsList = [];
  var _landMeasurement = '';

  var _bedrooms = '';

  bool _initDataFetched = false;

  var propertyTypeSelectedIndex;
  var propertyConditionSelectedIndex;
  var propertyFurnishedSelectedIndex;
  var propertyLeaseTypeSelectedIndex;
  var landTypeSelectedIndex;
  var landMeasurementIndex;
  var propertyDetails;

  String _selectedAuction = '0';
  String _selectedOffPlan = '0';

  final _landMeasurementNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getInitData();
  }

  _getInitData() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = json.decode(localStorage.getString('user') ?? '{}');

    var data = {
      'user_id': user['id'],
      'propertyID': widget.propertyID,
    };

    var res = await CallApi().postData(data, 'property/get-init-data-part-one');
    // print(body['data']['PropertyTypesList']);

    if (res.statusCode == 200) {
      var body = json.decode(res.body);

      //  print(body['data']['propertyDetails']);

      if (body['success']) {
        final List<dynamic> propertyTypesData =
            body['data']['PropertyTypesList'];
        List<Map<String, dynamic>> props = [];
        propertyTypesData.asMap().forEach((index, pData) {
          print("PDATA-------------> $pData");

          print("PDATA------66666-------> ${body['data']['propertyDetails']}");

          if (body['data']['propertyDetails'] != null &&
              body['data']['propertyDetails'].isNotEmpty &&
              pData['id'] == body['data']['propertyDetails'][0]['type_id']) {
            setState(() {
              propertyTypeSelectedIndex = index;
            });
          } else {
            propertyTypeSelectedIndex = pData['id'];
          }


          props.add({
            'id': pData['id'],
            'value': pData['value'],
          });
        });

        final List<dynamic> propertyConditionsData =
            body['data']['propertyConditionsList'];
        List<Map<String, dynamic>> pcon = [];
        propertyConditionsData.asMap().forEach((index, pdData) {


          if (body['data']['propertyDetails'].isNotEmpty && pdData['id'] == body['data']['propertyDetails'][0]['condition_id']) {
            setState(() {
              propertyConditionSelectedIndex = index;
            });
          }else{
            propertyConditionSelectedIndex = pdData['id'];
          }


          pcon.add({
            'index': index,
            'id': pdData['id'],
            'value': pdData['value'],
          });
        });

        final List<dynamic> furnishedData = body['data']['furnishedList'];
        List<Map<String, dynamic>> furnArray = [];
        furnishedData.asMap().forEach((index, fdData) {
          if (body['data']['propertyDetails'].isNotEmpty && fdData['id'] == body['data']['propertyDetails'][0]['furnish_id']) {
            setState(() {
              propertyFurnishedSelectedIndex = index;
            });
          }else{
            propertyFurnishedSelectedIndex = fdData['id'];
          }

          furnArray.add({
            'index': index,
            'id': fdData['id'],
            'value': fdData['value'],
          });
        });

        final List<dynamic> leaseData = body['data']['leaseTypesList'];
        List<Map<String, dynamic>> leaseArray = [];
        leaseData.asMap().forEach((index, laData) {
          if (body['data']['propertyDetails'].isNotEmpty && laData['id'] == body['data']['propertyDetails'][0]['lease_type_id']) {
            setState(() {
              propertyLeaseTypeSelectedIndex = index;
            });
          }else{
            propertyLeaseTypeSelectedIndex =  laData['id'];

          }


          leaseArray.add({
            'index': index,
            'id': laData['id'],
            'value': laData['value'],
          });
        });

        final List<dynamic> landTypesData = body['data']['landTypes'];
        List<Map<String, dynamic>> landTypesArray = [];
        landTypesData.asMap().forEach((index, laData) {
          if (body['data']['propertyDetails'].isNotEmpty && laData['id'] == body['data']['propertyDetails'][0]['land_type_id']) {
            setState(() {
              landTypeSelectedIndex = index;
            });
          }else{
            landTypeSelectedIndex = laData['id'];

          }

          landTypesArray.add({
            'index': index,
            'id': laData['id'],
            'value': laData['value'],
          });
        });

        final List<dynamic> landMeasurementsData =
            body['data']['landMeasurements'];
        List<Map<String, dynamic>> landMeasurementsArray = [];
        landMeasurementsData.asMap().forEach((index, laData) {
          if (body['data']['propertyDetails'].isNotEmpty && laData['id'] == body['data']['propertyDetails'][0]['land_measurement_id']) {
            setState(() {
              landTypeSelectedIndex = index;
            });
          }else{
            landTypeSelectedIndex = laData['id'];

          }

          landMeasurementsArray.add({
            'index': index,
            'id': laData['id'],
            'value': laData['value'],
          });
        });

        setState(() {
          _propertTypesList = props;
          _propertConditionsList = pcon;
          _furnishedList = furnArray;
          _leaseTypesList = leaseArray;
          _landTypesList = landTypesArray;
          _landMeasurementsList = landMeasurementsArray;
          _initDataFetched = true;
          propertyDetails = body['data']['propertyDetails'];


          if (body['data']['propertyDetails'].isNotEmpty) {
            _descriptionController.text =
                body['data']['propertyDetails']['property_description'] ?? "";
            _addressController.text = body['data']['propertyDetails']['address'] ?? "";
            _amountController.text =
            body['data']['propertyDetails']['amount'] != null
                ? body['data']['propertyDetails']['amount'].toString()
                : "";
            _sqmController.text =
            body['data']['propertyDetails']['measurements'] != null
                ? body['data']['propertyDetails']['measurements'].toString()
                : "";
            _parkingSpacesController.text =
            body['data']['propertyDetails']['parking_spaces'] != null
                ? body['data']['propertyDetails']['parking_spaces'].toString()
                : "";
            _propertyType =
                body['data']['propertyDetails']['type_id']?.toString() ?? "";
            _propertyCondition =
                body['data']['propertyDetails']['condition_id']?.toString() ?? "";
            _propertyFurnished =
                body['data']['propertyDetails']['furnish_id']?.toString() ?? "";
            _leaseType =
                body['data']['propertyDetails']['lease_type_id']?.toString() ?? "";
            _bedrooms = body['data']['propertyDetails']['bedrooms'] != null
                ? body['data']['propertyDetails']['bedrooms'].toString()
                : "";
            _parkingSpacesController.text =
            body['data']['propertyDetails']['parking_spaces'] != null
                ? body['data']['propertyDetails']['parking_spaces'].toString()
                : "";
          } else {
            // Handle the case where 'propertyDetails' is empty
            // Optionally, you can set default values or handle as per your logic.
            _descriptionController.text = "";
            _addressController.text = "";
            _amountController.text = "";
            _sqmController.text = "";
            _parkingSpacesController.text = "";
            _propertyType = "";
            _propertyCondition = "";
            _propertyFurnished = "";
            _leaseType = "";
            _bedrooms = "";
            _parkingSpacesController.text = "";
          }
        });


        }
    }
  }

  _submitProperty(context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostStep3Page(
          propertyID: widget.propertyID.toString(),
        ),
      ),
    );

    //Loading().loader(context, "Processing...Please wait");
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = json.decode(localStorage.getString('user') ?? '{}');

    String cleanedAmount =
        _amountController.text.replaceAll(RegExp(r'[^\d]'), '');

    var data = {
      'step': '2',
      'propertyID': widget.propertyID,
      'userID': user['id'].toString(),
      'propertyType': _propertyType,
      'propertyCondition': _propertyCondition,
      'furnished': _propertyFurnished,
      'leaseType': _leaseType,
      'bedrooms': _bedrooms,
      'description': _descriptionController.text,
      'address': _addressController.text,
      'amount': cleanedAmount,
      'parking': _parkingSpacesController.text,
      'measurement': _sqmController.text,
      'auction': _selectedAuction,
      'offplan': _selectedOffPlan,
      'landType': _landType,
      'landMeasurementID': _landMeasurement,
      'landMeasurementName': _landMeasurementNameController.text
    };

    var res = await CallApi().postData(data, 'property/post');

    var body = json.decode(res.body);

    print(body);

    if (res.statusCode == 200) {
      var body = json.decode(res.body);
      if (body['success']) {
        //Navigator.pop(context);
      }
    } else {
      //  Navigator.pop(context);
      //print('Failed to upload images');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      drawer: buildDrawer(context),
      backgroundColor: isDarkMode
          ? Colors.grey[900]
          : Colors.grey.shade100, // Dynamic background color
      appBar: buildHeader(context),
      body: _bodyBuild(context),
    );
  }

  Widget _bodyBuild(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(3.0),
        child: SizedBox(
          width: double.infinity,
          child: Card(
            elevation: 1.0,
            child: Padding(
              padding: const EdgeInsets.all(3.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitle(context),
                  const SizedBox(
                      height:
                          20), // Add some space between the title and the form
                  _initDataFetched
                      ? _buildPostForm(context)
                      : const Center(
                          child: Text(
                            "Loading...Please Wait",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min, // Minimize the height of the column
        children: [
          Padding(
            padding: EdgeInsets.only(top: 10),
          ),
          Text(
            "Post Property",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center, // Center-align the text
          ),
          Padding(
            padding: EdgeInsets.only(top: 5),
          ),
          Text(
            "Step 2 of 3",
            style: TextStyle(fontSize: 13, color: Colors.grey),
            textAlign: TextAlign.center, // Center-align the text
          ),
        ],
      ),
    );
  }

  Widget _buildPostForm(context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: 10.0,
                bottom: 10.0,
                left: 5,
                right: 5,
              ),
              child: DropdownSearch<Map<String, dynamic>>(
                items: _propertTypesList,
                dropdownDecoratorProps: DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    labelText: "Property Type",
                    hintText: "Select Property Type",
                    labelStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70 // Label color in dark mode
                          : Colors.black54, // Label color in light mode
                    ),
                    hintStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white54 // Hint text color in dark mode
                          : Colors.black38, // Hint text color in light mode
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors
                            .grey[850] // Dropdown background color in dark mode
                        : Colors
                            .white, // Dropdown background color in light mode
                  ),
                ),
                selectedItem: propertyTypeSelectedIndex != null &&
                        propertyTypeSelectedIndex != ""
                    ? _propertTypesList[propertyTypeSelectedIndex]
                    : null,
                dropdownBuilder: (context, selectedItem) {
                  // Safeguard against null selectedItem
                  final displayText = selectedItem != null
                      ? selectedItem["value"]
                      : "Select Property Type";
                  return Text(
                    displayText,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white // Text color in dark mode
                          : Colors.black, // Text color in light mode
                    ),
                  );
                },
                itemAsString: (Map<String, dynamic> subregion) =>
                    subregion["value"],
                onChanged: (Map<String, dynamic>? onchangeData) {
                  setState(() {
                    _propertyType = onchangeData?["id"].toString() ?? '';
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please Select Property Type';
                  }
                  return null;
                },
                compareFn: (item, selectedItem) =>
                    item["id"] == selectedItem["id"],
              ),
            ),
            Visibility(
              visible: _propertyType == '7',
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 10.0,
                  bottom: 10.0,
                  left: 5,
                  right: 5,
                ),
                child: DropdownSearch<Map<String, dynamic>>(
                  items: _landTypesList,
                  dropdownDecoratorProps: DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: "Land Type",
                      hintText: "Select Land Type",
                      labelStyle: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70 // Label color in dark mode
                            : Colors.black54, // Label color in light mode
                      ),
                      hintStyle: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white54 // Hint text color in dark mode
                            : Colors.black38, // Hint text color in light mode
                      ),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[
                              850] // Dropdown background color in dark mode
                          : Colors
                              .white, // Dropdown background color in light mode
                    ),
                  ),
                  selectedItem: landTypeSelectedIndex != null &&
                          landTypeSelectedIndex != ""
                      ? _landTypesList[landTypeSelectedIndex]
                      : null,
                  dropdownBuilder: (context, selectedItem) {
                    // Safeguard against null selectedItem
                    final displayText = selectedItem != null
                        ? selectedItem["value"]
                        : "Select Land Type";
                    return Text(
                      displayText,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white // Text color in dark mode
                            : Colors.black, // Text color in light mode
                      ),
                    );
                  },
                  itemAsString: (Map<String, dynamic> subregion) =>
                      subregion["value"],
                  onChanged: (Map<String, dynamic>? onchangeData) {
                    setState(() {
                      _landType = onchangeData?["id"].toString() ?? '';
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please Select Land Type';
                    }
                    return null;
                  },
                  compareFn: (item, selectedItem) =>
                      item["id"] == selectedItem["id"],
                ),
              ),
            ),
            Visibility(
              visible: _propertyType == '7',
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 10.0,
                  bottom: 10.0,
                  left: 5,
                  right: 5,
                ),
                child: DropdownSearch<Map<String, dynamic>>(
                  items: _landMeasurementsList,
                  dropdownDecoratorProps: DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: "Land Measurement in Acres(optional)",
                      hintText: "Select Land Measurement",
                      labelStyle: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70 // Label color in dark mode
                            : Colors.black54, // Label color in light mode
                      ),
                      hintStyle: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white54 // Hint text color in dark mode
                            : Colors.black38, // Hint text color in light mode
                      ),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[
                              850] // Dropdown background color in dark mode
                          : Colors
                              .white, // Dropdown background color in light mode
                    ),
                  ),
                  selectedItem:
                      landMeasurementIndex != null && landMeasurementIndex != ""
                          ? _landMeasurementsList[landMeasurementIndex]
                          : null,
                  dropdownBuilder: (context, selectedItem) {
                    // Safeguard against null selectedItem
                    final displayText = selectedItem != null
                        ? selectedItem["value"]
                        : "Select Land Measurement";
                    return Text(
                      displayText,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white // Text color in dark mode
                            : Colors.black, // Text color in light mode
                      ),
                    );
                  },
                  itemAsString: (Map<String, dynamic> subregion) =>
                      subregion["value"],
                  onChanged: (Map<String, dynamic>? onchangeData) {
                    setState(() {
                      _landMeasurement = onchangeData?["id"].toString() ?? '';
                    });
                  },
                  // validator: (value) {
                  //   if (value == null) {
                  //     return 'Please Select Land Type';
                  //   }
                  //   return null;
                  // },
                  compareFn: (item, selectedItem) =>
                      item["id"] == selectedItem["id"],
                ),
              ),
            ),
            if (_landMeasurement == '10')
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: TextFormField(
                  controller: _landMeasurementNameController,
                  decoration: InputDecoration(
                    labelText: 'Enter Land Measurement(Acre)',
                    hintText: 'Enter Land Measurement',
                    labelStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70 // Label text color in dark mode
                          : Colors.black54, // Label text color in light mode
                    ),
                    hintStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white54 // Hint text color in dark mode
                          : Colors.black38, // Hint text color in light mode
                    ),
                    filled: true, // Enable filling
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800] // Background color in dark mode
                        : Colors.white, // Background color in light mode
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white38 // Border color in dark mode
                            : Colors.black54, // Border color in light mode
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white // Focused border color in dark mode
                            : Colors.blue, // Focused border color in light mode
                      ),
                    ),
                  ),
                  // validator: (value) {
                  //   if (value == null || value.isEmpty) {
                  //     return 'Please enter property title';
                  //   }
                  //   return null;
                  // },
                ),
              ),
            Visibility(
              visible: _propertyType != '7',
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 10.0,
                  bottom: 10.0,
                  left: 5,
                  right: 5,
                ),
                child: DropdownSearch<Map<String, dynamic>>(
                  items: _propertConditionsList,
                  dropdownDecoratorProps: DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: "Property Condition",
                      hintText: "Select Property Condition",
                      labelStyle: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70 // Label text in dark mode
                            : Colors.black54, // Label text in light mode
                      ),
                      hintStyle: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white54 // Hint text in dark mode
                            : Colors.black38, // Hint text in light mode
                      ),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[850] // Background color in dark mode
                          : Colors.white, // Background color in light mode
                    ),
                  ),
                  selectedItem: propertyConditionSelectedIndex != null &&
                          propertyConditionSelectedIndex != ""
                      ? _propertConditionsList[propertyConditionSelectedIndex]
                      : null,
                  dropdownBuilder: (context, selectedItem) {
                    final displayText = selectedItem != null
                        ? selectedItem["value"]
                        : "Select Property Condition";
                    return Text(
                      displayText,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white // Text color in dark mode
                            : Colors.black, // Text color in light mode
                      ),
                    );
                  },
                  itemAsString: (Map<String, dynamic> subregion) =>
                      subregion["value"],
                  onChanged: (Map<String, dynamic>? onchangeData) {
                    setState(() {
                      _propertyCondition = onchangeData?["id"].toString() ?? '';
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please Select Property Condition';
                    }
                    return null;
                  },
                  compareFn: (item, selectedItem) =>
                      item["id"] == selectedItem["id"],
                ),
              ),
            ),
            Visibility(
              visible: _propertyType != '7',
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 10.0,
                  bottom: 10.0,
                  left: 5,
                  right: 5,
                ),
                child: DropdownSearch<Map<String, dynamic>>(
                  items: _furnishedList,
                  dropdownDecoratorProps: DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: "Furnished",
                      hintText: "Select Furnished Status",
                      labelStyle: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70 // Label text in dark mode
                            : Colors.black54, // Label text in light mode
                      ),
                      hintStyle: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white54 // Hint text in dark mode
                            : Colors.black38, // Hint text in light mode
                      ),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[850] // Background color in dark mode
                          : Colors.white, // Background color in light mode
                    ),
                  ),
                  selectedItem: propertyFurnishedSelectedIndex != null &&
                          propertyFurnishedSelectedIndex != ""
                      ? _furnishedList[propertyFurnishedSelectedIndex]
                      : null,
                  dropdownBuilder: (context, selectedItem) {
                    final displayText = selectedItem != null
                        ? selectedItem["value"]
                        : "Select Furnished Status";
                    return Text(
                      displayText,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white // Text color in dark mode
                            : Colors.black, // Text color in light mode
                      ),
                    );
                  },
                  itemAsString: (Map<String, dynamic> furnishedItem) =>
                      furnishedItem["value"],
                  onChanged: (Map<String, dynamic>? onchangeData) {
                    setState(() {
                      _propertyFurnished = onchangeData?["id"].toString() ?? '';
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please Select Furnished Status';
                    }
                    return null;
                  },
                  compareFn: (item, selectedItem) =>
                      item["id"] == selectedItem["id"],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                top: 10.0,
                bottom: 10,
                left: 5,
                right: 5,
              ),
              child: DropdownSearch<Map<String, dynamic>>(
                items: _leaseTypesList,
                dropdownDecoratorProps: DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    labelText: "Listing Type",
                    hintText: "Select Lease Type",
                    labelStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70 // Label text color in dark mode
                          : Colors.black54, // Label text color in light mode
                    ),
                    hintStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white54 // Hint text color in dark mode
                          : Colors.black38, // Hint text color in light mode
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[850] // Background color in dark mode
                        : Colors.white, // Background color in light mode
                  ),
                ),
                selectedItem: propertyLeaseTypeSelectedIndex != null &&
                        propertyLeaseTypeSelectedIndex != ""
                    ? _leaseTypesList[propertyLeaseTypeSelectedIndex]
                    : null,
                dropdownBuilder: (context, selectedItem) {
                  // Safeguard against null selectedItem
                  final displayText = selectedItem != null
                      ? selectedItem["value"]
                      : "Select Lease Type";
                  return Text(
                    displayText,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white // Text color in dark mode
                          : Colors.black, // Text color in light mode
                    ),
                  );
                },
                itemAsString: (Map<String, dynamic> sData) => sData["value"],
                onChanged: (Map<String, dynamic>? onchangeData) {
                  setState(() {
                    _leaseType = onchangeData?["id"].toString() ?? '';
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please Select Lease Type';
                  }
                  return null;
                },
                compareFn: (item, selectedItem) =>
                    item["id"] == selectedItem["id"],
              ),
            ),
            if (_leaseType == '2')
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Is this Property on Auction?',
                      style: TextStyle(fontSize: 16.0),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('No'),
                            value: '0',
                            groupValue: _selectedAuction,
                            onChanged: (String? value) {
                              setState(() {
                                _selectedAuction = value!;
                                // If auction is 'No', reset offplan selection
                                if (_selectedAuction == '0') {
                                  _selectedOffPlan = '0'; // Set offplan to 'No'
                                }
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Yes'),
                            value: '1',
                            groupValue: _selectedAuction,
                            onChanged: (String? value) {
                              setState(() {
                                _selectedAuction = value!;
                                // If auction is 'Yes', set offplan to 'No'
                                if (_selectedAuction == '1') {
                                  _selectedOffPlan = '0'; // Set offplan to 'No'
                                }
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    if (_propertyType != '7')
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Is this an Offplan Property?',
                            style: TextStyle(fontSize: 16.0),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<String>(
                                  title: const Text('No'),
                                  value: '0',
                                  groupValue: _selectedOffPlan,
                                  onChanged: (String? value) {
                                    setState(() {
                                      _selectedOffPlan = value!;
                                      // If offplan is 'No', reset auction selection
                                      if (_selectedOffPlan == '0') {
                                        _selectedAuction =
                                            '0'; // Set auction to 'No'
                                      }
                                    });
                                  },
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<String>(
                                  title: const Text('Yes'),
                                  value: '1',
                                  groupValue: _selectedOffPlan,
                                  onChanged: (String? value) {
                                    setState(() {
                                      _selectedOffPlan = value!;
                                      // If offplan is 'Yes', set auction to 'No'
                                      if (_selectedOffPlan == '1') {
                                        _selectedAuction =
                                            '0'; // Set auction to 'No'
                                      }
                                    });
                                  },
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            Visibility(
              visible: _propertyType != '7',
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 10.0,
                  bottom: 10.0,
                  left: 5,
                  right: 5,
                ),
                child: DropdownSearch<String>(
                  popupProps: PopupProps.menu(
                    showSelectedItems: true,
                    showSearchBox: false, // Disable the search box
                    isFilterOnline: true,
                    itemBuilder: (context, item, isSelected) {
                      final isDisabled = item.startsWith('I');
                      return ListTile(
                        title: Text(
                          item,
                          style: TextStyle(
                            color: isDisabled
                                ? Colors.grey
                                : Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white // Text color in dark mode
                                    : Colors.black, // Text color in light mode
                          ),
                        ),
                        enabled: !isDisabled,
                        selected: isSelected,
                      );
                    },
                  ),
                  items: const [
                    "1",
                    "2",
                    "3",
                    "4",
                    "5",
                    "6",
                    "7",
                    "8",
                    "9",
                    "10",
                    "11",
                    "12",
                  ],
                  dropdownDecoratorProps: DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: "Bedrooms",
                      hintText: "Select Bedroom",
                      labelStyle: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70 // Label text color in dark mode
                            : Colors.black54, // Label text color in light mode
                      ),
                      hintStyle: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white54 // Hint text color in dark mode
                            : Colors.black38, // Hint text color in light mode
                      ),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[850] // Background color in dark mode
                          : Colors.white, // Background color in light mode
                    ),
                  ),
                  selectedItem: _bedrooms,
                  dropdownBuilder: (context, selectedItem) {
                    final displayText = selectedItem ?? "Select Bedroom";
                    return Text(
                      displayText,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white // Text color in dark mode
                            : Colors.black, // Text color in light mode
                      ),
                    );
                  },
                  onChanged: (String? data) {
                    setState(() {
                      _bedrooms = data ?? '';
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please Select Bedroom';
                    }
                    return null;
                  },
                  compareFn: (item, selectedItem) => item == selectedItem,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                bottom: 10.0,
                left: 5,
                right: 5,
              ),
              child: Container(
                decoration: ThemeHelper().inputBoxDecorationShaddow(),
                child: TextFormField(
                  maxLines: 5,
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter Description',
                    labelStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70 // Label text color in dark mode
                          : Colors.black54, // Label text color in light mode
                    ),
                    hintStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white54 // Hint text color in dark mode
                          : Colors.black38, // Hint text color in light mode
                    ),
                    filled: true, // Enable filling
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800] // Background color in dark mode
                        : Colors.white, // Background color in light mode
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white38 // Border color in dark mode
                            : Colors.black54, // Border color in light mode
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white // Focused border color in dark mode
                            : Colors.blue, // Focused border color in light mode
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Enter property Description';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _descriptionController.text = value!;
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                bottom: 10.0,
                left: 5,
                right: 5,
              ),
              child: Container(
                decoration: ThemeHelper().inputBoxDecorationShaddow(),
                child: TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    hintText: 'Enter Address',
                    labelStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70 // Label text color in dark mode
                          : Colors.black54, // Label text color in light mode
                    ),
                    hintStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white54 // Hint text color in dark mode
                          : Colors.black38, // Hint text color in light mode
                    ),
                    filled: true, // Enable filling
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800] // Background color in dark mode
                        : Colors.white, // Background color in light mode
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white38 // Border color in dark mode
                            : Colors.black54, // Border color in light mode
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white // Focused border color in dark mode
                            : Colors.blue, // Focused border color in light mode
                      ),
                    ),
                  ),
                  // Uncomment if you want to enable validation
                  // validator: (value) {
                  //   if (value!.isEmpty) {
                  //     return 'Enter property Address';
                  //   }
                  //   return null;
                  // },
                  onSaved: (value) {
                    _addressController.text = value!;
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                bottom: 10.0,
                left: 5,
                right: 5,
              ),
              child: Container(
                child: TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Price',
                    hintText: 'Enter price',
                    labelStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70 // Label color in dark mode
                          : Colors.black54, // Label color in light mode
                    ),
                    hintStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white54 // Hint color in dark mode
                          : Colors.black38, // Hint color in light mode
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white38 // Border color in dark mode
                            : Colors.black54, // Border color in light mode
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white // Focused border color in dark mode
                            : Colors.blue, // Focused border color in light mode
                      ),
                    ),
                    filled: true, // Ensure filled is set to true
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800] // Background color in dark mode
                        : Colors.white, // Background color in light mode
                  ),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Enter property Price';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _amountController.text = value!;
                  },
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    PriceInputFormatter(),
                  ],
                ),
              ),
            ),
            if (_propertyType != '7')
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        bottom: 10.0,
                        left: 5,
                        right: 5,
                      ),
                      child: Container(
                        decoration: ThemeHelper()
                            .inputBoxDecorationShaddow(), // This can remain as is
                        child: TextFormField(
                          controller: _parkingSpacesController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Parking Spaces (Optional)',
                            hintText: 'Enter Parking Spaces',
                            labelStyle: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white70 // Label color in dark mode
                                  : Colors.black54, // Label color in light mode
                            ),
                            hintStyle: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white54 // Hint color in dark mode
                                  : Colors.black38, // Hint color in light mode
                            ),
                            filled: true, // Ensure filled is set to true
                            fillColor: Theme.of(context).brightness ==
                                    Brightness.dark
                                ? Colors
                                    .grey[800] // Background color in dark mode
                                : Colors
                                    .white, // Background color in light mode
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors
                                        .white38 // Border color in dark mode
                                    : Colors
                                        .black54, // Border color in light mode
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors
                                        .white // Focused border color in dark mode
                                    : Colors
                                        .blue, // Focused border color in light mode
                              ),
                            ),
                          ),
                          onSaved: (value) {
                            _parkingSpacesController.text = value!;
                          },
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        bottom: 10.0,
                        left: 5,
                        right: 5,
                      ),
                      child: Container(
                        decoration: ThemeHelper()
                            .inputBoxDecorationShaddow(), // Keep the shadow decoration
                        child: TextFormField(
                          controller: _sqmController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Square metres (sqm) (optional)',
                            hintText: 'Specify the Property Measurements.',
                            labelStyle: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white70 // Label color in dark mode
                                  : Colors.black54, // Label color in light mode
                            ),
                            hintStyle: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white54 // Hint color in dark mode
                                  : Colors.black38, // Hint color in light mode
                            ),
                            filled: true, // Ensure filled is set to true
                            fillColor: Theme.of(context).brightness ==
                                    Brightness.dark
                                ? Colors
                                    .grey[800] // Background color in dark mode
                                : Colors
                                    .white, // Background color in light mode
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors
                                        .white38 // Border color in dark mode
                                    : Colors
                                        .black54, // Border color in light mode
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors
                                        .white // Focused border color in dark mode
                                    : Colors
                                        .blue, // Focused border color in light mode
                              ),
                            ),
                          ),
                          onSaved: (value) {
                            _sqmController.text = value!;
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            Row(children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5.0, vertical: 10.0),
                  child: ElevatedButton(
                    onPressed: () => _submitProperty(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple, // Button background color
                      padding: const EdgeInsets.symmetric(
                          vertical: 16.0), // Vertical padding
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            8.0), // Optional: rounded corners
                      ),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 18, // Increased font size
                        color: Colors.white,
                        fontWeight:
                            FontWeight.bold, // Optional: makes the text bold
                      ),
                    ),
                  ),
                ),
              )
            ]),
          ],
        ),
      ),
    );
  }
}
