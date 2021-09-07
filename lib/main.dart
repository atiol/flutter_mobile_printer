import 'dart:io';
import 'dart:typed_data';
import 'package:barcode_image/barcode_image.dart';
import 'package:image/image.dart' as im;
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _device;
  bool _connected = false;
  String pathImage = '';
  String svgPath = '';
  bool _pressed = false;
  String? dir;
  String fileName = '';

  @override
  void initState() {
    super.initState();
    initPlatformState();
    initSavetoPath();
  }

  initSavetoPath() async {
    dir = (await getExternalStorageDirectory())?.path;
  }

  Future<void> initPlatformState() async {
    bool? isConnected = await bluetooth.isConnected;
    List<BluetoothDevice> devices = [];
    try {
      devices = await bluetooth.getBondedDevices();
      print('[InitPlatformState] Devices: $devices');
    } on PlatformException {
      // TODO - Error
      print('[PlatformException] !!! error !!!');
    }

    bluetooth.onStateChanged().listen((state) {
      switch (state) {
        case BlueThermalPrinter.CONNECTED:
          setState(() {
            _connected = true;
            _pressed = false;
          });
          print('Device connected!');
          break;
        case BlueThermalPrinter.DISCONNECTED:
          setState(() {
            _connected = false;
            _pressed = false;
          });
          print('Device disconnected!');
          break;
        default:
          print(state);
          break;
      }
    });

    if (!mounted) return;
    setState(() {
      _devices = devices;
    });

    if (isConnected!) {
      setState(() {
        _connected = true;
        _pressed = false;
      });
    } else {
      print('Not connected!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: Colors.lime,
        accentColor: Colors.limeAccent,
      ),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text('KONYA ŞEKER FAB. A.Ş'),
        ),
        body: Container(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView(
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: 10,
                    ),
                    Text(
                      'Cihaz:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                      width: 30,
                    ),
                    Expanded(
                      child: DropdownButton(
                        items: _getDeviceItems(),
                        onChanged: (value) =>
                            setState(() => _device = value as BluetoothDevice),
                        value: _device,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: () {
                        initPlatformState();
                      },
                      child: Text(
                        'Yenile',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        primary: Colors.black,
                      ),
                    ),
                    SizedBox(
                      width: 20,
                    ),
                    ElevatedButton(
                      onPressed: _pressed
                          ? null
                          : _connected
                              ? _disconnect
                              : _connect,
                      child: Text(
                        _connected ? 'Bağlantıyı Kes' : 'Bağlan',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        primary: _connected ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding:
                      const EdgeInsets.only(left: 10.0, right: 10.0, top: 50),
                  child: ElevatedButton(
                    onPressed: () {
                      _connected ? _testPrint() : null;
                    },
                    child: Text(
                      'YAZDIR',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      primary: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<DropdownMenuItem<BluetoothDevice>> _getDeviceItems() {
    List<DropdownMenuItem<BluetoothDevice>> items = [];
    if (_devices.isEmpty) {
      items.add(DropdownMenuItem(
        child: Text('NONE'),
        value: null,
      ));
    } else {
      _devices.forEach((device) {
        items.add(DropdownMenuItem(
          child: Text(device.name!),
          value: device,
        ));
      });
    }
    return items;
  }

  void _connect() {
    if (_device == null) {
      show('No device selected.');
    } else {
      bluetooth.isConnected.then((isConnected) {
        print('[_connect] IsConnected: $isConnected');
        if (!isConnected!) {
          bluetooth.connect(_device!).catchError((error) {
            setState(() => _pressed = false);
          });
          setState(() => _pressed = true);
        }
      });
    }
  }

  void _disconnect() {
    bluetooth.disconnect();
    setState(() => _pressed = true);
  }

//write to app path
  Future<void> writeToFile(ByteData data, String path) {
    final buffer = data.buffer;
    return new File(path).writeAsBytes(
        buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  }

  void _testPrint() async {
    generateBarcodeImage(Barcode.code128(), 'BARCODE\t128', 200, 80)
        .then((bytes) {
      print('###################### image bytes length');
      print(bytes.length);
      bluetooth.isConnected.then((isConnected) {
        if (isConnected!) {
          // bluetooth.printCustom("KONYA ŞEKER FAB.", 3, 1);
          // bluetooth.printNewLine();
          // bluetooth.printImage(pathImage);
          // bluetooth.printLeftRight("LEFT", "RIGHT", 0);
          // bluetooth.printLeftRight("LEFT", "RIGHT", 1);
          // bluetooth.printNewLine();
          // bluetooth.printLeftRight("LEFT", "RIGHT", 2);
          // bluetooth.printCustom("Body left", 1, 0);
          // bluetooth.printCustom("Body right", 0, 2);
          // bluetooth.printNewLine();
          // bluetooth.printImage(fileName);
          bluetooth.printImageBytes(bytes);
          bluetooth.printNewLine();
          // bluetooth.printCustom("KONYA ŞEKER FAB.", 2, 1);
          // bluetooth.printNewLine();
          // bluetooth.paperCut();
        }
      });
    });
  }

  bool test(File file) {
    return file.existsSync();
  }

  // Future<void> generateBarcode(
  //     Barcode bc, String data, double? width, double? height) async {
  //   fileName = '$dir/test.svg';
  //   print('FileName: $fileName');

  //   final svg = bc.toSvg(data, width: width ?? 200, height: height ?? 80);
  //   File file = await File(fileName).writeAsString(svg);
  //   print('file exists: ' + test(file).toString());
  // }

  Future<Uint8List> generateBarcodeImage(
      Barcode bc, String data, double? width, double? height) async {
    final image = im.Image(200, 80);
    im.fill(image, im.getColor(255, 255, 255));
    drawBarcode(image, bc, data, font: im.arial_24);
    final bytes = image.getBytes();
    return bytes;
  }

  Future show(
    String message, {
    Duration duration: const Duration(seconds: 3),
  }) async {
    await new Future.delayed(new Duration(milliseconds: 100));
    _messengerKey.currentState?.showSnackBar(
      new SnackBar(
        content: new Text(
          message,
          style: new TextStyle(
            color: Colors.white,
          ),
        ),
        duration: duration,
      ),
    );
  }
}
