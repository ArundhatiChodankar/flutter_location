import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'service.dart';
import 'package:mime_type/mime_type.dart';
import 'package:signature/signature.dart';

class MyHttpOverrides extends HttpOverrides{
  @override
  HttpClient createHttpClient(SecurityContext? context){
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port)=> true;
  }
}
void main() {
    HttpOverrides.global = MyHttpOverrides();;
    runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: LocationPage(),
    );
  }
}

class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  _LocationPageState createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  String location = 'Click on Get Location to see current location';
  List images = [];
  List signatures = [];

  @override
  void initState() {
    super.initState();
     getImages(false);
     getImages(true);
  }



  Future<void> getImages(bool isSignature) async {
    String apiUrl = isSignature ? '/flutter/signature' : '/flutter/image';

    try {
      final response = await APIService.instance.request(
        apiUrl,
        DioMethod.get,
        contentType: 'application/json',
      );
      if (response.statusCode == 200) {
        print('API call successful: ${response.data}');
        if(isSignature) {
          signatures = response.data;
        }
        else {
          images = response.data;
        }
        setState(() {

        });
      } else {
        print('API call failed: ${response.statusMessage}');
      }
    } catch (e) {
      print('Network error occurred: $e');
    }
  }

  Future<void> imageUpload(Uint8List? file, String fileName, bool isSignature) async {
    String? mimeType = mime(fileName);
    String? mimee = mimeType?.split('/')[0];
    String? type = mimeType?.split('/')[1];

    String apiUrl = isSignature ? 'https://lcnf.online:3000/flutter/signature' : 'https://lcnf.online:3000/flutter/image';

    try {
      Dio dio = Dio();
      dio.options.headers["Content-Type"] = "multipart/form-data";
      FormData formData = FormData.fromMap({
        // 'image':await MultipartFile.fromFile(file.path.toString(), filename: fileName, contentType: DioMediaType(mimee!, type!), ),
        'image': MultipartFile.fromBytes(file!, filename: fileName, contentType: DioMediaType(mimee!, type!), ),
        'name':fileName
      });
      Response response = await dio
          .post(apiUrl, data: formData)
          .catchError((e) => print(e.response.toString()));
    } catch (e) {
      print('Network error occurred: $e');
    }
    finally{
      isSignature ? getImages(true) : getImages(false);
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled, don't continue
      _showLocationEnableDialog();
      return Future.error('Location services are disabled.');
    }

    // Check for location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // Get the current location
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      location = 'Lat: ${position.latitude}, Long: ${position.longitude}';
    });
  }

  FilePickerResult? result;

  final SignatureController _controller = SignatureController(
    penStrokeWidth: 5,
    penColor: Colors.red,
    exportBackgroundColor: Colors.blue,
  );

  @override
  void dispose() {

    _controller.dispose();
    super.dispose();
  }


  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       backgroundColor: Colors.blue,
  //       title: const Text(kIsWeb ? 'LCNF Web' : 'LCNF App'),
  //     ),
  //     body: Center(
  //       child: Column(
  //         mainAxisAlignment: MainAxisAlignment.start,
  //         children: <Widget>[
  //           Padding(
  //             padding: const EdgeInsets.only(top: 10.0),
  //             child: Text(location)),
  //           const SizedBox(height: 20),
  //           ElevatedButton(
  //             onPressed: _getCurrentLocation,
  //             child: const Text('Get Location'),
  //           ),
  //           Padding(
  //             padding: const EdgeInsets.only(top: 10.0),
  //             child: ElevatedButton(
  //               onPressed: () async {
  //                 result = await FilePicker.platform.pickFiles(
  //                     withData: true,
  //                     allowMultiple: false,
  //                     type: FileType.image);
  //                 if (result == null) {
  //                    print("No file selected");
  //                 } else {
  //                   setState(() {});
  //                   for (var element in result!.files) {
  //                     print(element.name);
  //                     imageUpload(element.bytes, element.name, false);
  //                   }
  //                 }
  //                 }, child: const Text("Pick Image"),
  //               ),
  //             ),
  //           Expanded(
  //               child: GridView.count(
  //                 primary: false,
  //                 padding: const EdgeInsets.all(20),
  //                 crossAxisSpacing: 10,
  //                 mainAxisSpacing: 10,
  //                 crossAxisCount: 2,
  //                 children:
  //                   images.map((value) {
  //                     return Container(
  //                       alignment: Alignment.center,
  //                       margin: EdgeInsets.all(8),
  //                       decoration: BoxDecoration(border: Border.all(color: Colors.black),),
  //                       // child: Image.network('https://picsum.photos/250?image=9'),
  //                       child: Image.network('${APIService.instance.baseUrl}/${value["url"].replaceAll("files", "images")}'),
  //
  //                     );
  //                   }).toList(),
  //             )
  //           ),
  //           Padding(
  //             padding: const EdgeInsets.only(top: 10.0),
  //             child:
  //               Signature(
  //                 controller: _controller,
  //                 height: 150,
  //                 width: 150,
  //                 backgroundColor: Colors.black12,
  //             ),
  //           ),
  //           Padding(
  //             padding: const EdgeInsets.only(top: 10.0),
  //             child:
  //             ElevatedButton(
  //               onPressed: () async {
  //                 if (_controller.isNotEmpty) {
  //                   final Uint8List? data =
  //                   await _controller.toPngBytes();
  //                   if (data != null) {
  //                     await imageUpload(data, 'Signature.png', true);
  //                   }
  //                 }
  //               },
  //               child: const Text('Save Signature'),
  //             ),
  //           ),
  //           Padding(
  //             padding: const EdgeInsets.only(top: 10.0),
  //             child:
  //             ElevatedButton(
  //               onPressed: () async {
  //                 if (_controller.isNotEmpty) {
  //                    _controller.undo();
  //                 }
  //               },
  //               child: const Text('Undo Signature'),
  //             ),
  //           ),
  //           Expanded(
  //               child: GridView.count(
  //                 primary: false,
  //                 padding: const EdgeInsets.all(20),
  //                 crossAxisSpacing: 10,
  //                 mainAxisSpacing: 10,
  //                 crossAxisCount: 2,
  //                 children:
  //                 signatures.map((value) {
  //                   return Container(
  //                     alignment: Alignment.center,
  //                     margin: EdgeInsets.all(8),
  //                     decoration: BoxDecoration(border: Border.all(color: Colors.black),),
  //                     // child: Image.network('https://picsum.photos/250?image=9'),
  //                     child: Image.network('${APIService.instance.baseUrl}/${value["url"].replaceAll("files", "images")}'),
  //
  //                   );
  //                 }).toList(),
  //               )
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(kIsWeb ? 'LCNF Web' : 'LCNF App'),
      ),
      body: ListView(

          children: <Widget> [
            Align(child: Padding(padding: const EdgeInsets.only(top: 10.0),
                child: Text(location)),),
                const SizedBox(height: 20),
           Align(child:  ElevatedButton(
             onPressed: _getCurrentLocation,
             child: const Text('Get Location'),
           ),),
            Align(child: Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: ElevatedButton(
                onPressed: () async {
                  result = await FilePicker.platform.pickFiles(
                      withData: true,
                      allowMultiple: false,
                      type: FileType.image);
                  if (result == null) {
                    print("No file selected");
                  } else {
                    setState(() {});
                    for (var element in result!.files) {
                      print(element.name);
                      imageUpload(element.bytes, element.name, false);
                    }
                  }
                }, child: const Text("Pick Image"),
              ),
            ),),
            GridView.count(
              crossAxisCount: 3,
              physics: NeverScrollableScrollPhysics(), // to disable GridView's scrolling
              shrinkWrap: true, // You won't see infinite size error
              children: images.map((value) {
                        return Container(
                          alignment: Alignment.center,
                          margin: EdgeInsets.all(8),
                          decoration: BoxDecoration(border: Border.all(color: Colors.black),),
                          // child: Image.network('https://picsum.photos/250?image=9'),
                          child: Image.network('${APIService.instance.baseUrl}/${value["url"].replaceAll("files", "images")}'),

                        );
                      }).toList(),
            ),
    Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child:
                  Signature(
                    controller: _controller,
                    height: 150,
                    width: 150,
                    backgroundColor: Colors.black12,
                ),
              ),
              Align(child:Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child:
                ElevatedButton(
                  onPressed: () async {
                    if (_controller.isNotEmpty) {
                      final Uint8List? data =
                      await _controller.toPngBytes();
                      if (data != null) {
                        await imageUpload(data, 'Signature.png', true);
                      }
                    }
                  },
                  child: const Text('Save Signature'),
                ),
              ),),
            Align(
              child:  Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child:
                ElevatedButton(
                  onPressed: () async {
                    if (_controller.isNotEmpty) {
                      _controller.undo();
                    }
                  },
                  child: const Text('Undo Signature'),
                ),
              ),),
            GridView.count(
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              crossAxisCount: 3,

              physics: NeverScrollableScrollPhysics(), // to disable GridView's scrolling
              shrinkWrap: true, // You won't see infinite size error
              children:   signatures.map((value) {
                      return Container(
                        alignment: Alignment.center,
                        margin: EdgeInsets.all(8),
                        decoration: BoxDecoration(border: Border.all(color: Colors.black),),
                        // child: Image.network('https://picsum.photos/250?image=9'),
                        child: Image.network('${APIService.instance.baseUrl}/${value["url"].replaceAll("files", "images")}'),

                      );
                    }).toList(),
            ),



          ],
        )

    );
  }
  void _showLocationEnableDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Services Disabled'),
          content: const Text('Please enable location services to use this feature.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

}


