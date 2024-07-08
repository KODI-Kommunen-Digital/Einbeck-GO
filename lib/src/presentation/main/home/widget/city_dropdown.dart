import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class CitiesDropDown extends StatefulWidget {
  final ValueSetter<String>? setLocationCallback;
  final List<String>? cityTitlesList;
  final String? hintText;
  final String? selectedOption;

  const CitiesDropDown({
    super.key,
    required this.setLocationCallback,
    required this.cityTitlesList,
    this.hintText,
    this.selectedOption,
  });

  @override
  State<CitiesDropDown> createState() => _CitiesDropDownState();
}

class _CitiesDropDownState extends State<CitiesDropDown> {
  final TextEditingController typeAheadController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.selectedOption != null && widget.selectedOption!.isNotEmpty) {
      typeAheadController.text = widget.selectedOption!;
    }

    _focusNode.addListener(() {
      setState(() {}); // Trigger rebuild on focus change
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    typeAheadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: TypeAheadFormField(
            textFieldConfiguration: TextFieldConfiguration(
              controller: typeAheadController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: widget.hintText,
                border: const OutlineInputBorder(),
                suffixIcon:
                    _focusNode.hasFocus && typeAheadController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                typeAheadController.clear();
                              });
                            },
                          )
                        : const Icon(Icons.arrow_drop_down),
              ),
            ),
            suggestionsCallback: (String pattern) async {
              return widget.cityTitlesList!
                  .where((item) =>
                      item.toLowerCase().contains(pattern.toLowerCase()))
                  .toList();
            },
            itemBuilder: (BuildContext context, suggestion) {
              return ListTile(
                title: Text(suggestion),
              );
            },
            onSuggestionSelected: (suggestion) {
              setState(() {
                typeAheadController.text = suggestion;
              });
              if (widget.setLocationCallback != null) {
                widget.setLocationCallback!(suggestion);
              }
            },
          ),
        ),
      ),
    );
  }
}
