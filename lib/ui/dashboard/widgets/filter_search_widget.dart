import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:just_apartment_live/api/api.dart';
import 'dropdown_style_helper.dart';

class FilterSearchWidget extends StatefulWidget {
  final List<dynamic> properties;
  final Function(String, String, String, String, String, String)
      onLocationSelected;

  const FilterSearchWidget(
      {super.key, required this.properties, required this.onLocationSelected});

  @override
  _FilterSearchWidgetState createState() => _FilterSearchWidgetState();
}

class _FilterSearchWidgetState extends State<FilterSearchWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final int _selectedValue = 1;
  String? _selectedItem;

  List<Map<String, dynamic>> _townList = [];
  List<Map<String, dynamic>> _regionList = [];
  List<Map<String, dynamic>> _subRegionsData = [];
  List<Map<String, dynamic>> _propertyTypeList = [];
  List<Map<String, dynamic>> _leaseTypeList = [];

  final List<Map<String, dynamic>> _auctionList = [
    {"id": 0, "value": "Auction"},
    {"id": 0, "value": "No"},
    {"id": 1, "value": "Yes"}
  ];

  final List<Map<String, dynamic>> _offPlanList = [
    {"id": 0, "value": "OffPlan"},
    {"id": 0, "value": "No"},
    {"id": 1, "value": "Yes"}
  ];

  var _town = '';
  var _subRegion = '';
  var _propertyType = '';
  var _leaseType = '';
  var _onAuction = '';
  final _offPlan = '';
  bool _showRegionList = false;

  bool isFavorite = false; // Add a boolean to track favorite state

  _getInitData() async {
    var data = {};

    var res = await CallApi().postData(data, 'property/get-init-data-part-one');

    if (res.statusCode == 200) {
      var body = json.decode(res.body);

      if (body['success']) {
        final List<dynamic> townListData = body['data']['townsList'];
        final List<dynamic> regionData = body['data']['subRegions'];
        final List<dynamic> propertyTypeData =
            body['data']['PropertyTypesList'];
        final List<dynamic> leaseTypeData = body['data']['leaseTypesList'];

        List<Map<String, dynamic>> townsArray = [];
        List<Map<String, dynamic>> subRegionsArray = [];
        List<Map<String, dynamic>> propertyTypeArray = [];
        List<Map<String, dynamic>> leaseTypeArray = [];

        for (var tData in townListData) {
          townsArray.add({
            'id': tData['id'],
            'value': tData['value'],
          });
        }

        for (var rData in regionData) {
          subRegionsArray.add({
            'id': rData['id'],
            'value': rData['value'],
            'town_id': rData['town_id'],
          });
        }

        for (var pData in propertyTypeData) {
          propertyTypeArray.add({
            'id': pData['id'],
            'value': pData['value'],
          });
        }

        for (var lData in leaseTypeData) {
          leaseTypeArray.add({
            'id': lData['id'],
            'value': lData['value'],
          });
        }
        if (mounted) {
          setState(() {
            _townList = townsArray;
            _subRegionsData = subRegionsArray;
            _propertyTypeList = propertyTypeArray;
            _leaseTypeList = leaseTypeArray;
          });
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _getInitData();
  }

  @override
  Widget build(BuildContext context) {
    return searchCard(context);
  }

  Widget searchCard(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: SizedBox(
                height: 35,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      buildLocationDropdown(context),

                      if (_showRegionList) buildSubLocationDropdown(context),
                      buildPropertyTypeDropdown(context),
                      buildLeaseTypeDropdown(context),
                      buildOnAuctionDropdown(context),
                      buildOffPlanDropdown(context),
                      // IconButton(
                      //   icon: Icon(
                      //     isFavorite ? Icons.favorite : Icons.favorite_border,
                      //     color: isFavorite ? Colors.red : Colors.grey,
                      //   ),
                      //   onPressed: () {
                      //     setState(() {
                      //       isFavorite = !isFavorite;
                      //     });
                      //   },
                      // ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget buildLocationDropdown(BuildContext context) {
    // Detect if the theme is dark
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 150.0,
        ),
        child: DropdownSearch<Map<String, dynamic>>(
          popupProps: PopupProps.modalBottomSheet(
            showSelectedItems: true,
            showSearchBox: true, // Ensure search box is enabled
            searchFieldProps: TextFieldProps(
              decoration:
                  DropdownStyleHelper.dropdownSearchDecoration(isDarkMode)
                      .copyWith(
                hintText: 'Search here', // Provide hint text
                hintStyle: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              style: TextStyle(
                color: isDarkMode
                    ? Colors.white
                    : Colors.grey.shade700, // Adjust search input text color
              ),
            ),
            modalBottomSheetProps: ModalBottomSheetProps(
              backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
            ),
            itemBuilder: (context, item, isSelected) {
              return DropdownStyleHelper.popupItemBuilder(
                  context, item, isSelected, isDarkMode);
            },
            fit: FlexFit.loose, // Ensure the dropdown expands as needed
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height *
                    0.7), // Limit popup height if necessary
          ),
          items: _townList,
          dropdownDecoratorProps: DropDownDecoratorProps(
            dropdownSearchDecoration:
                DropdownStyleHelper.dropdownDecoration(isDarkMode),
          ),
          selectedItem:
              null, // Set to null to avoid selecting the first item by default
          dropdownBuilder: (context, selectedItem) {
            return DropdownStyleHelper.dropdownBuilder(
                context, selectedItem, "Location", isDarkMode);
          },
          onChanged: (Map<String, dynamic>? selectedTown) {
            setState(() {
              _town = selectedTown?["id"].toString() ?? '';
              _regionList = _subRegionsData
                  .where((region) => region['town_id'] == selectedTown?['id'])
                  .toList();
              _subRegion = ''; // Clear subregion selection when town changes
              widget.onLocationSelected(_town, _subRegion, _propertyType,
                  _leaseType, _onAuction, _offPlan);

              _showRegionList = true;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Please Select the County';
            }
            return null;
          },
          compareFn: (item, selectedItem) => item["id"] == selectedItem["id"],
        ),
      ),
    );
  }

  Widget buildSubLocationDropdown(BuildContext context) {
    // Detect if the theme is dark
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 150.0,
        ),
        child: DropdownSearch<Map<String, dynamic>>(
          popupProps: PopupProps.modalBottomSheet(
            showSelectedItems: true,
            showSearchBox: true, // Enable the search box
            searchFieldProps: TextFieldProps(
              decoration:
                  DropdownStyleHelper.dropdownSearchDecoration(isDarkMode)
                      .copyWith(
                hintText: 'Search here', // Provide hint text for sublocation
                hintStyle: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              style: TextStyle(
                color: isDarkMode
                    ? Colors.white
                    : Colors.grey.shade700, // Adjust search input text color
              ),
            ),
            modalBottomSheetProps: ModalBottomSheetProps(
              backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
            ),
            itemBuilder: (context, item, isSelected) {
              return DropdownStyleHelper.popupItemBuilder(
                  context, item, isSelected, isDarkMode);
            },
          ),
          items: _regionList,
          dropdownDecoratorProps: DropDownDecoratorProps(
            dropdownSearchDecoration:
                DropdownStyleHelper.dropdownDecoration(isDarkMode),
          ),
          selectedItem: _regionList.isNotEmpty
              ? _regionList.firstWhere(
                  (region) => region["id"].toString() == _subRegion,
                  orElse: () => _regionList.first, // Provide a fallback item
                )
              : null,
          dropdownBuilder: (context, selectedItem) {
            final displayText =
                selectedItem != null ? selectedItem["value"] : "Region";
            return DropdownStyleHelper.dropdownBuilder(
                context, selectedItem, displayText, isDarkMode);
          },
          onChanged: (Map<String, dynamic>? selectedRegion) {
            setState(() {
              _subRegion = selectedRegion?["id"].toString() ?? '';
              widget.onLocationSelected(_town, _subRegion, _propertyType,
                  _leaseType, _onAuction, _offPlan);
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Please Select the Region';
            }
            return null;
          },
          compareFn: (item, selectedItem) => item["id"] == selectedItem["id"],
        ),
      ),
    );
  }

  Widget buildPropertyTypeDropdown(BuildContext context) {
    // Detect if the theme is dark
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 150.0,
        ),
        child: DropdownSearch<Map<String, dynamic>>(
          popupProps: PopupProps.menu(
            showSelectedItems: true,
            showSearchBox: true, // Enable the search box
            searchFieldProps: TextFieldProps(
              decoration:
                  DropdownStyleHelper.dropdownSearchDecoration(isDarkMode)
                      .copyWith(
                hintText:
                    'Search Property Type', // Provide hint text for property type
                hintStyle: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              style: TextStyle(
                color: isDarkMode
                    ? Colors.white
                    : Colors.grey.shade700, // Adjust search input text color
              ),
            ),
            itemBuilder: (context, item, isSelected) {
              return DropdownStyleHelper.popupItemBuilder(
                  context, item, isSelected, isDarkMode);
            },
          ),
          items: _propertyTypeList,
          dropdownDecoratorProps: DropDownDecoratorProps(
            dropdownSearchDecoration:
                DropdownStyleHelper.dropdownDecoration(isDarkMode),
          ),
          selectedItem: _propertyTypeList.isNotEmpty
              ? _propertyTypeList.firstWhere(
                  (propertyType) =>
                      propertyType["id"].toString() == _propertyType,
                  orElse: () =>
                      _propertyTypeList.first, // Provide a fallback item
                )
              : null,
          dropdownBuilder: (context, selectedItem) {
            final displayText =
                selectedItem != null ? selectedItem["value"] : "Property Type";
            return DropdownStyleHelper.dropdownBuilder(
                context, selectedItem, displayText, isDarkMode);
          },
          onChanged: (Map<String, dynamic>? selectedPropertyType) {
            setState(() {
              _propertyType = selectedPropertyType?["id"].toString() ?? '';
              widget.onLocationSelected(_town, _subRegion, _propertyType,
                  _leaseType, _onAuction, _offPlan);
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Please Select the Property Type';
            }
            return null;
          },
          compareFn: (item, selectedItem) => item["id"] == selectedItem["id"],
        ),
      ),
    );
  }

  Widget buildLeaseTypeDropdown(BuildContext context) {
    // Detect if the theme is dark
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 150.0,
        ),
        child: DropdownSearch<Map<String, dynamic>>(
          popupProps: PopupProps.menu(
            showSelectedItems: true,
            showSearchBox: true, // Enable the search box
            searchFieldProps: TextFieldProps(
              decoration:
                  DropdownStyleHelper.dropdownSearchDecoration(isDarkMode)
                      .copyWith(
                hintText:
                    'Search Lease Type', // Specific hint text for lease type
                hintStyle: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              style: TextStyle(
                color: isDarkMode
                    ? Colors.white
                    : Colors.grey.shade700, // Adjust search input text color
              ),
            ),
            itemBuilder: (context, item, isSelected) {
              return DropdownStyleHelper.popupItemBuilder(
                  context, item, isSelected, isDarkMode);
            },
          ),
          items: _leaseTypeList,
          dropdownDecoratorProps: DropDownDecoratorProps(
            dropdownSearchDecoration:
                DropdownStyleHelper.dropdownDecoration(isDarkMode),
          ),
          selectedItem: _leaseTypeList.isNotEmpty
              ? _leaseTypeList.firstWhere(
                  (leaseType) => leaseType["id"].toString() == _leaseType,
                  orElse: () => _leaseTypeList.first, // Provide a fallback item
                )
              : null,
          dropdownBuilder: (context, selectedItem) {
            final displayText =
                selectedItem != null ? selectedItem["value"] : "Lease Type";
            return DropdownStyleHelper.dropdownBuilder(
                context, selectedItem, displayText, isDarkMode);
          },
          onChanged: (Map<String, dynamic>? selectedLeaseType) {
            setState(() {
              _leaseType = selectedLeaseType?["id"].toString() ?? '';
              widget.onLocationSelected(_town, _subRegion, _propertyType,
                  _leaseType, _onAuction, _offPlan);
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Please Select the Lease Type';
            }
            return null;
          },
          compareFn: (item, selectedItem) => item["id"] == selectedItem["id"],
        ),
      ),
    );
  }

  Widget buildOnAuctionDropdown(BuildContext context) {
    // Detect if the theme is dark
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 150.0,
        ),
        child: DropdownSearch<Map<String, dynamic>>(
          popupProps: PopupProps.menu(
            showSelectedItems: true,
            showSearchBox: false, // Search box is disabled here
            itemBuilder: (context, item, isSelected) {
              return DropdownStyleHelper.popupItemBuilder(
                  context, item, isSelected, isDarkMode);
            },
          ),
          items: _auctionList,
          dropdownDecoratorProps: DropDownDecoratorProps(
            dropdownSearchDecoration:
                DropdownStyleHelper.dropdownDecoration(isDarkMode),
          ),
          selectedItem: _auctionList.isNotEmpty
              ? _auctionList.firstWhere(
                  (auctionType) => auctionType["id"].toString() == _onAuction,
                  orElse: () => _auctionList.first, // Provide a fallback item
                )
              : null,
          dropdownBuilder: (context, selectedItem) {
            final displayText =
                selectedItem != null ? selectedItem["value"] : "On Auction";
            return DropdownStyleHelper.dropdownBuilder(
                context, selectedItem, displayText, isDarkMode);
          },
          onChanged: (Map<String, dynamic>? selectedAuction) {
            setState(() {
              _onAuction = selectedAuction?["id"].toString() ?? '';
              widget.onLocationSelected(_town, _subRegion, _propertyType,
                  _leaseType, _onAuction, _offPlan);
            });
          },
          validator: (value) {
            if (value == null) {
              // Optionally return a validation error here
            }
            return null;
          },
          compareFn: (item, selectedItem) => item["id"] == selectedItem["id"],
        ),
      ),
    );
  }

  Widget buildOffPlanDropdown(BuildContext context) {
    // Detect if the theme is dark
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 150.0,
        ),
        child: DropdownSearch<Map<String, dynamic>>(
          popupProps: PopupProps.menu(
            showSelectedItems: true,
            showSearchBox: false, // Search box is disabled here
            itemBuilder: (context, item, isSelected) {
              return DropdownStyleHelper.popupItemBuilder(
                  context, item, isSelected, isDarkMode);
            },
          ),
          items: _offPlanList,
          dropdownDecoratorProps: DropDownDecoratorProps(
            dropdownSearchDecoration:
                DropdownStyleHelper.dropdownDecoration(isDarkMode),
          ),
          selectedItem: _offPlanList.isNotEmpty
              ? _offPlanList.firstWhere(
                  (offPlanType) => offPlanType["id"].toString() == _onAuction,
                  orElse: () => _offPlanList.first, // Provide a fallback item
                )
              : null,
          dropdownBuilder: (context, selectedItem) {
            final displayText =
                selectedItem != null ? selectedItem["value"] : "OffPlan";
            return DropdownStyleHelper.dropdownBuilder(
                context, selectedItem, displayText, isDarkMode);
          },
          onChanged: (Map<String, dynamic>? selectedOffPlan) {
            setState(() {
              _onAuction = selectedOffPlan?["id"].toString() ?? '';
              widget.onLocationSelected(_town, _subRegion, _propertyType,
                  _leaseType, _onAuction, _offPlan);
            });
          },
          validator: (value) {
            if (value == null) {
              // Optionally return a validation error here
            }
            return null;
          },
          compareFn: (item, selectedItem) => item["id"] == selectedItem["id"],
        ),
      ),
    );
  }
}
