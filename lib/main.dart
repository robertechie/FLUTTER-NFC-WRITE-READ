import 'dart:convert';
import 'dart:io';
import 'package:android_id/android_id.dart';
//import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show Uint8List, ValueNotifier, kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_nfc_hce/flutter_nfc_hce.dart';
import 'package:nfc_manager/nfc_manager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // void initState() {
  //   super.initState();
  //   _permissionCheck();
  // }

  ValueNotifier<dynamic> resultR = ValueNotifier(null);
  final _flutterNfcHcePlugin = FlutterNfcHce();
  bool _showNFCScanDialog = false;
  var platformVersion;
  bool? isNfcHceSupported;
  bool? isSecureNfcEnabled;
  bool? isNfcEnabled;

  void _getInfo() async {
    platformVersion = await _flutterNfcHcePlugin.getPlatformVersion();
    isNfcHceSupported = await _flutterNfcHcePlugin.isNfcHceSupported();
    isSecureNfcEnabled = await _flutterNfcHcePlugin.isSecureNfcEnabled();
    isNfcEnabled = await _flutterNfcHcePlugin.isNfcEnabled();
  }

  void _onScanButtonPressed() async {
    var content = await getDeviceId();
    try {
      NfcManager.instance.stopSession();
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }

    _getInfo();

    if (kDebugMode) {
      print('content - $content');
    }
    var result = await _flutterNfcHcePlugin.startNfcHce(content!);

    if (kDebugMode) {
      print('---------------------------------->${result!}');
    }

    setState(() {
      _showNFCScanDialog = true;
    });
  }

  Future<void> _tagRead() async {
    try {
      await _flutterNfcHcePlugin.stopNfcHce();
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }

    if (kDebugMode) {
      print('-------------->tag read start......');
    }

    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      if (kDebugMode) {
        print('-------------->tag discovered');
      }
      if (kDebugMode) {
        print('-------------->tag.data: ${tag.data}');
      }

      resultR.value =
          tag.data['ndef']['cachedMessage']['records'][0]['payload'];
      var d = tag.data['ndef']['cachedMessage']['records'][0]['payload'];

      if (kDebugMode) {
        print('Identifier $d');
      }

      var record = tag.data['ndef']['cachedMessage']['records'][0];

      //var identifier = Uint8List.fromList(record['identifier']);
      //if (kDebugMode) {
      //   print('Identifier - $identifier');
      // }

      var payload = Uint8List.fromList(record['payload']);

      //var type = Uint8List.fromList(record['type']);

      // var typeNameFormat = Uint8List.fromList([record['typeNameFormat']]);
      // print(typeNameFormat);

      var error = [
        2,
        101,
        110,
        67,
        105,
        97,
        111,
        44,
        32,
        99,
        111,
        109,
        101,
        32,
        118,
        97,
        63
      ]; // \^BenCiao, come v<…>

      if (payload.toString() != error.toString()) {
        resultR.value = utf8.decode(Uint8List.fromList(payload.sublist(1)));
      } else {
        if (kDebugMode) {
          print('Please retry scanning');
        }
      }

      // decoing
      // String payloadStr = const Utf8Codec().decode(payload);
      // String typeStr = const Utf8Codec().decode(type);
      // String typeNameFormatStr = const Utf8Codec().decode(typeNameFormat);

      //decoding value print
      // if (kDebugMode) {
      //   print('Payload: $payloadStr');
      // }
      // if (kDebugMode) {
      //   print('Type: $typeStr');
      // }
      // if (kDebugMode) {
      //   print('TypeNameFormat: $typeNameFormatStr');
      // }
      NfcManager.instance.stopSession();
    });
  }

  void _permissionCheck() async {
    if (!(await NfcManager.instance.isAvailable())) {
      if (Platform.isAndroid) {
        //  AppSettings.openAppSettingsPanel(AppSettingsPanelType.nfc);
      }
    }
  }

  Future<String?> getDeviceId() async {
  const androidId = AndroidId();
    var androidInfo = await androidId.getId();
    return androidInfo; // Unique ID of the Android device
  }

// for hce
  void _onCloseButtonPressed() async {
    await _flutterNfcHcePlugin.stopNfcHce();

    setState(() {
      _showNFCScanDialog = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin Nfc Hce example app'),
        ),
        body: Container(
          child: Stack(
            children: [
              // Background widget
              Container(
                color: Colors.transparent,
                child: Center(
                  child: Column(
                    children: [
                      Text('platformVersion: ${platformVersion ?? ""}'),
                      const SizedBox(height: 5),
                      Text(
                          'isSupportNfcHceFeature: ${isNfcHceSupported ?? ""}'),
                      const SizedBox(height: 5),
                      Text(
                          'isSupportSecureNfcSupported: ${isSecureNfcEnabled ?? ""}'),
                      const SizedBox(height: 5),
                      Text('isNfcEnagle: ${isNfcEnabled ?? ""}'),
                      Expanded(
                        child: Flex(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          direction: Axis.vertical,
                          children: [
                            Flexible(
                              flex: 2,
                              child: Container(
                                margin: const EdgeInsets.all(4),
                                constraints: const BoxConstraints.expand(),
                                decoration: BoxDecoration(border: Border.all()),
                                child: SingleChildScrollView(
                                  child: ValueListenableBuilder<dynamic>(
                                    valueListenable: resultR,
                                    builder: (context, value, _) =>
                                        Text('${value ?? ''}'),
                                  ),
                                ),
                              ),
                            ),
                            Flexible(
                              flex: 3,
                              child: GridView.count(
                                padding: const EdgeInsets.all(4),
                                crossAxisCount: 2,
                                childAspectRatio: 4,
                                crossAxisSpacing: 4,
                                mainAxisSpacing: 4,
                                children: [
                                  ElevatedButton(
                                      child: const Text('Tag Read'),
                                      onPressed: () async {
                                        _tagRead();
                                      }),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
              // NFC Scan Dialog
              if (_showNFCScanDialog)
                GestureDetector(
                  onTap: _onCloseButtonPressed,
                  child: Container(
                    color: Colors.black54,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/nfc_tag.png',
                            width: 100, height: 100),
                        const SizedBox(height: 16),
                        const Text(
                          'Start Nfc Hce',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _onScanButtonPressed,
          child: const Icon(Icons.nfc),
        ),
      ),
    );
  }
}
