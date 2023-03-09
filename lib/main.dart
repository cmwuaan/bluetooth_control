import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Bluetooth Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // // static const String data = "0";
  // // static const uuid = "";
  // BluetoothDevice? device;

  // Bluetooth state
  StreamSubscription<BluetoothState>? _stateSubscription;
  BluetoothState _state = BluetoothState.unknown;

  // Scan
  StreamSubscription? _scanSubscription;
  List<ScanResult> _scanResults = [];

  // Device
  BluetoothDevice? _device;
  bool _isConnected = false;

  // Services
  List<BluetoothService> _services = [];

  // Characteristics
  List<BluetoothCharacteristic> _characteristics = [];

  @override
  void initState() {
    super.initState();

    // Subscribe to Bluetooth state changes
    _stateSubscription = FlutterBlue.instance.state.listen((state) {
      setState(() {
        _state = state;
      });
    });
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _device?.disconnect();
    super.dispose();
  }

  void _startScan() {
    setState(() {
      _scanResults.clear();
    });
    _scanSubscription = FlutterBlue.instance.scan().listen((scanResult) {
      setState(() {
        _scanResults.add(scanResult);
      });
    });
  }

  void _stopScan() {
    _scanSubscription?.cancel();
  }

  void _connectToDevice(BluetoothDevice device) async {
    _device?.disconnect();
    setState(() {
      _isConnected = true;
      _device = device;
    });
    await _device?.connect();
    _services = await _device!.discoverServices();
    setState(() {});
  }

  Future<void> _writeData() async {
    if (_characteristics.isNotEmpty) {
// Choose the first characteristic
      final characteristic = _characteristics[0];
      await characteristic.write([1, 2, 3]);
    }
  }

  // // Init Bluetooth
  // FlutterBlue flutterBlue = FlutterBlue.instance;

  // _sendData(data, device) async {
  //   // Scan device
  //   flutterBlue.startScan(
  //     timeout: const Duration(seconds: 4),
  //   );

  //   // Wait
  //   flutterBlue.scanResults.listen((results) async {
  //     for (ScanResult r in results) {
  //       if (r.device.id == device.id) {
  //         flutterBlue.stopScan(); // Success
  //         device.connect(); // Connect to Device

  //         // Looking for service and characteristic HC-05
  //         List<BluetoothService> services = await device.discoverServices();
  //         for (BluetoothService service in services) {
  //           List<BluetoothCharacteristic> characteristics =
  //               service.characteristics;
  //           for (BluetoothCharacteristic characteristic in characteristics) {
  //             // Check characteristic TX HC-05
  //             if (characteristic.uuid.toString() == uuid) {
  //               characteristic.write(utf8.encode(data)); // Send data
  //               break;
  //             }
  //           }
  //         }
  //         break;
  //       }
  //     }
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Bluetooth state: $_state'),
            if (_state == BluetoothState.on)
              Column(
                children: [
                  ElevatedButton(
                    onPressed: _startScan,
                    child: Text('Scan'),
                  ),
                  ElevatedButton(
                    onPressed: _stopScan,
                    child: Text('Stop Scan'),
                  ),
                  if (_scanResults.isNotEmpty)
                    Column(
                      children: _scanResults.map((result) {
                        return ListTile(
                          title: Text(result.device.name ?? 'Unknown device'),
                          subtitle: Text(result.device.id.toString()),
                          trailing: ElevatedButton(
                            onPressed: () {
                              _connectToDevice(result.device);
                            },
                            child: Text('Connect'),
                          ),
                        );
                      }).toList(),
                    ),
                  if (_isConnected)
                    Column(
                      children: [
                        Text('Connected to ${_device!.name}'),
                        ElevatedButton(
                          onPressed: _writeData,
                          child: Text('Send Data'),
                        ),
                        if (_services.isNotEmpty)
                          Column(
                            children: _services.map((service) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Service: ${service.uuid}'),
                                  if (service.characteristics.isNotEmpty)
                                    Column(
                                      children: service.characteristics
                                          .map((characteristic) {
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                'Characteristic: ${characteristic.uuid}'),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                ],
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
