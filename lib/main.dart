import 'package:eyes4me/instructionsbottomsheet.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:convert';
import 'dart:io';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  await Permission.camera.request();
  final cameras = await availableCameras();
  final selectedCamera = cameras
      .firstWhere((camera) => camera.lensDirection == CameraLensDirection.back);
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((value) => runApp(MyApp(
            camera: selectedCamera,
          )));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.camera});
  final CameraDescription camera;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eyes4Me',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0x00000000),
      ),
      home: CameraScreen(
        camera: camera,
      ),
    );
  }
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key, required this.camera});
  final CameraDescription camera;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool isPending = false;
  bool isSpeaking = false;

  FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();

    // set orientation

    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.veryHigh,
    );
    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
    _controller.setFlashMode(FlashMode.off);
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  Future<http.Response> fetchMlTextResponse() async {
    XFile? photo = await _controller.takePicture();
    List<int> bytes = await photo.readAsBytes();
    String base64Image = base64Encode(bytes);

    return http.post(
        Uri.parse(
          'https://api.openai.com/v1/chat/completions',
        ),
        headers: <String, String>{
          'Authorization': 'Bearer OPENAI-API-KEY',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          "model": "gpt-4o-mini",
          "messages": [
            {
              "role": "user",
              "content": [
                {
                  "type": "text",
                  "text":
                      "Descrivi rapidamente la foto, evidenziando solo gli elementi principali e la loro posizione rispetto a me. Evita dettagli superflui; basta orientarsi."
                },
                {
                  "type": "image_url",
                  "image_url": {"url": "data:image/png;base64,$base64Image"}
                }
              ]
            },
          ],
        }));
  }

  handleViewRequest() async {
    if (!isPending) {
      // INITAL STATE
      Vibration.vibrate(duration: 300);
      setState(() {
        isSpeaking = false;
        isPending = true;
      });

      // SET THE TTS ENGINE
      await flutterTts.setLanguage("it-IT");
      if (!Platform.isIOS) {
        await flutterTts.setSharedInstance(true);
        await flutterTts.setIosAudioCategory(
            IosTextToSpeechAudioCategory.playback,
            [IosTextToSpeechAudioCategoryOptions.defaultToSpeaker],
            IosTextToSpeechAudioMode.defaultMode);
      }

      flutterTts.setCompletionHandler(() {
        setState(() {
          isSpeaking = false;
          isPending = false;
        });
        Vibration.vibrate(duration: 100, amplitude: 128);
      });

      // ACTUAL REQUEST
      final response = await fetchMlTextResponse();
      if (response.statusCode == 200) {
        final responseText =
            jsonDecode(utf8.decode(response.bodyBytes))['choices'][0]['message']
                ['content'];
        print(
            "------------------------------------------------------------------------------");
        // print(responseText);
        print(responseText);
        print(
            "------------------------------------------------------------------------------");
        setState(() {
          isSpeaking = true;
        });
        await flutterTts.speak(responseText);
      } else {
        setState(() {
          isPending = false;
        });
        print(response.body);
        await Vibration.vibrate(duration: 200, amplitude: 128);
        await Future.delayed(const Duration(milliseconds: 300));
        await Vibration.vibrate(duration: 200, amplitude: 128);
        await Future.delayed(const Duration(milliseconds: 300));
        await Vibration.vibrate(duration: 200, amplitude: 128);
        throw Exception('FAILURE IN CONTACTING OPENAI');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fill this out in the next steps.
    return Scaffold(
      body: SafeArea(
        child: Stack(children: [
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                FlutterNativeSplash.remove();
                return Column(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Semantics(
                        label: "Pulsante per iniziare l'analisi della scena",
                        child: GestureDetector(
                          onTap: () {
                            handleViewRequest();
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(
                                left: 8.0, right: 8.0, top: 8.0, bottom: 0.0),
                            child: SizedBox(
                              width: double.infinity,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(30.0),
                                child: CameraPreview(_controller),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      child: isPending
                          ? Semantics(
                              excludeSemantics: true,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 9.0),
                                child: LinearProgressIndicator(
                                  value: isSpeaking ? 1 : null,
                                  backgroundColor: Colors.black,
                                ),
                              ),
                            )
                          : Semantics(
                              excludeSemantics: true,
                              child: const SizedBox(
                                height: 12.0,
                              ),
                            ),
                    ),
                  ],
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
          Positioned(
              bottom: 16.0,
              right: 16.0,
              child: Semantics(
                  label: "Pulsante per aprire le istruzioni d'uso",
                  child: const InstructionsBottomSheet())),
        ]),
      ),
    );
  }
}
