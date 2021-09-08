import 'dart:convert';
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
  bool _pressed = false;
  late String dir;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    bool? isConnected = await bluetooth.isConnected;
    List<BluetoothDevice> devices = [];
    try {
      devices = await bluetooth.getBondedDevices();
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
    var data = {
      'village_name': 'TAŞPINAR',
      'order_no': 420803,
      'name_surname': 'ÖMERİL FARUK İNCE',
      'weigher': '001:FABRİKA MERKEZ',
      'date': '20201120',
      'quantity': 25,
      'machine': '41914310001'
    };

    generateBarcodeImage(Barcode.code128(), '*0200187454*', 200, 80)
        .then((bytes) {
      bluetooth.isConnected.then((isConnected) {
        if (isConnected!) {
          bluetooth.printNewLine();
          bluetooth.printCustom(" : 0200187454", 1, 0);
          bluetooth.printCustom(
              "KÖY ADI".padRight(12) + ': ${data['village_name']}', 1, 0);
          bluetooth.printCustom(
              "GRUP SIRA NO".padRight(12) + ': ${data['order_no'].toString()}',
              1,
              0);
          bluetooth.printCustom(
              "AD SOYAD".padRight(12) + ': ${data['name_surname']}', 1, 0);
          bluetooth.printCustom(
              "KANTAR".padRight(12) + ': ${data['weigher'].toString()}', 1, 0);
          bluetooth.printCustom(
              "TARİH".padRight(12) + ': ${data['date']}', 1, 0);
          bluetooth.printCustom(
              "MİKTAR".padRight(12) + ': ${data['quantity'].toString()}', 1, 0);
          bluetooth.printCustom(
              "SOKUM MAKİNA".padRight(12) + ': ${data['machine'].toString()}',
              1,
              0);
          bluetooth.printCustom('Bu kart Yukarıdaki Tarihten', 1, 0);
          bluetooth.printCustom('İtibaren 3 Gün Geçerlidir:', 1, 0);
          bluetooth.printNewLine();
          bluetooth.printImageBytes(bytes);
          bluetooth.printNewLine();
          bluetooth.printNewLine();
        }
      });
    });
  }

  bool test(File file) {
    return file.existsSync();
  }

  Future<File> get _localFile async {
    final path = (await getApplicationDocumentsDirectory()).path;
    print('-------------------- local file path: ' + path);
    return File('$path/test.png');
  }

  Future<Uint8List> generateBarcodeImage(
      Barcode bc, String data, double? width, double? height) async {
    final image = im.Image(320, 100);
    im.fill(image, im.getColor(255, 255, 255));
    drawBarcode(image, bc, data, font: im.arial_24);

    final file = await _localFile;
    file.writeAsBytesSync(im.encodePng(image)); // save image
    final imageBytes = await loadImage(); // get image bytes from dir

    return imageBytes;
  }

  Future<Uint8List> loadImage() async {
    try {
      final file = await _localFile;
      final imageBytes = await file.readAsBytes();
      return imageBytes;
    } catch (e) {
      print(e);
      throw e;
    }
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
