import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class EditResults extends StatefulWidget {
  final Map<String, dynamic>? classificatoinMap;
  const EditResults({super.key, required this.classificatoinMap});

  @override
  State<EditResults> createState() => _EditResultsState();
}

class _EditResultsState extends State<EditResults> {
  List<String> dropDownMenuItems = [
    'Kana\'a',
    'Black Mesa',
    'Sosi',
    'Dogoszhi',
    'Flagstaff',
    'Tusayan',
    'Kayenta',
  ];

  late String classificationSelection = '';

  // final MapController _mapController = MapController();
  late LatLng _currentCenter;

  @override
  void initState() {
    super.initState();
    _currentCenter = LatLng(
      double.parse(widget.classificatoinMap!['latitude'].toString()),
      double.parse(widget.classificatoinMap!['longitude'].toString()),
    );
  }

  void onSaveClassificatoin(Map<String, dynamic>? classificatoinMap) async {
    // Use the tracked center (updated by onPositionChanged)
    LatLng centerLatLng = _currentCenter;

    Map<String, dynamic>? newClassificationMap = classificatoinMap;

    if (classificationSelection.isNotEmpty) {
      newClassificationMap?['primaryClassification'] = classificationSelection;
    }

    newClassificationMap?['latitude'] = centerLatLng.latitude;
    newClassificationMap?['longitude'] = centerLatLng.longitude;

    if (mounted) {
      Navigator.pop(context, newClassificationMap);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 32,
              ),
              const SizedBox(
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Edit Results',
                    style: TextStyle(
                      fontSize: 60,
                      fontFamily: 'Uber',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              DropdownMenu(
                onSelected: (selectedClassification) {
                  classificationSelection = selectedClassification.toString();
                },
                width: MediaQuery.of(context).size.width - 32,
                label: const Text('Classification'),
                initialSelection:
                    widget.classificatoinMap?['primaryClassification'],
                dropdownMenuEntries: dropDownMenuItems
                    .map<DropdownMenuEntry<String>>((String value) {
                  return DropdownMenuEntry<String>(value: value, label: value);
                }).toList(),
              ),
              const SizedBox(
                height: 32,
              ),
              // Container(
              //   decoration: BoxDecoration(
              //       color: Theme.of(context)
              //           .colorScheme
              //           .secondaryContainer, // select color from current theme scheme
              //       borderRadius: const BorderRadius.all(Radius.circular(5))),
              //   width: MediaQuery.of(context).size.width,
              //   height: MediaQuery.of(context).size.width,
              //   child: Stack(
              //     alignment: Alignment.center,
              //     children: [
              //       ClipRRect(
              //         borderRadius: BorderRadius.circular(5),
              //         child: FlutterMap(
              //           mapController: _mapController,
              //           options: MapOptions(
              //             initialCenter: _currentCenter,
              //             initialZoom: 14,
              //             onPositionChanged: (position, hasGesture) {
              //               _currentCenter = position.center;
              //             },
              //           ),
              //           children: [
              //             TileLayer(
              //               urlTemplate:
              //                   'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              //             ),
              //           ],
              //         ),
              //       ),
              //       Container(
              //         decoration: BoxDecoration(
              //           color: const Color.fromARGB(140, 3, 142, 255),
              //           borderRadius: BorderRadius.circular(100),
              //           border: Border.all(
              //             width: 2,
              //             color: Colors.white,
              //           ),
              //         ),
              //         // can we change this according to the map zoom factor?
              //         height: 130,
              //         width: 130,
              //       ),
              //       Container(
              //         decoration: BoxDecoration(
              //           color: Colors.blue,
              //           borderRadius: BorderRadius.circular(100),
              //           border: Border.all(
              //             width: 2,
              //             color: Colors.white,
              //           ),
              //         ),
              //         height: 20,
              //         width: 20,
              //       ),
              //     ],
              //   ),
              // ),
              const SizedBox(
                height: 16,
              ),
              Center(
                
                  child: FilledButton(
                      onPressed: () =>
                          onSaveClassificatoin(widget.classificatoinMap),
                      child: const Text('Save'))),
              Center(
                  child: TextButton(
                      onPressed: () {
                        Navigator.pop(context, widget.classificatoinMap);
                      },
                      child: const Text('Back'))),
            ],
          ),
        ),
      ),
    );
  }
}
