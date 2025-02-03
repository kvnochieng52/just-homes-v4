import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:http/http.dart' as http;

class LocationFormField extends StatefulWidget {
  final String apiKey;
  final Function(String?)? onSaved;
  final String? initialValue;
  final String hintText;

  const LocationFormField({
    Key? key,
    required this.apiKey,
    this.onSaved,
    this.initialValue,
    this.hintText = "Search for a location",
  }) : super(key: key);

  @override
  _LocationFormFieldState createState() => _LocationFormFieldState();
}

class _LocationFormFieldState extends State<LocationFormField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<Map?> getCountyFromPlaceId(String placeId) async {
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?place_id=$placeId&key=${widget.apiKey}';
    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (data['status'] == 'OK') {
      List addressComponents = data['results'][0]['address_components'];

      print("ADDRESS   ---->" + addressComponents.toString());
      Map<String, dynamic> addressInfo = {};

      for (var component in addressComponents) {
        if (component['types'].contains('administrative_area_level_1')) {
          addressInfo["county"] = component['long_name'];
        }

        if (component['types'].contains('sublocality_level_1')) {
          addressInfo["locality"] = component['long_name'];
        }
      }

      return addressInfo;
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: widget.initialValue,
      onSaved: widget.onSaved,
      builder: (FormFieldState<String> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => _focusNode.requestFocus(),
              child: GooglePlaceAutoCompleteTextField(
                textEditingController: _controller,
                googleAPIKey: widget.apiKey,
                focusNode: _focusNode,
                inputDecoration: InputDecoration(
                  hintText: widget.hintText,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                ),
                countries: ['ke'],
                isLatLngRequired: false,
                getPlaceDetailWithLatLng: (Prediction prediction) async {
                  if (prediction.placeId != null) {
                    final county = await getCountyFromPlaceId(prediction.placeId!);
                    state.didChange(county.toString());
                    _controller.text = prediction.description ?? '';
                  }
                },
                itemClick: (Prediction prediction) async {
                  if (prediction.placeId != null) {
                    final county = await getCountyFromPlaceId(prediction.placeId!);
                    state.didChange(county.toString());
                    _controller.text = prediction.description ?? '';
                  }
                },
                // Fixed itemBuilder signature
                itemBuilder: (context, index, prediction) => ListTile(
                  title: Text(prediction.description ?? ''),
                ),
                debounceTime: 300,
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  state.errorText ?? '',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        );
      },
    );
  }
}