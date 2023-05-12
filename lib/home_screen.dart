import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:date_time_picker/date_time_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:mozzwear/settings_screen.dart';
import 'package:tflite_audio/tflite_audio.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'listScreen.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity/connectivity.dart';



class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}
class _MyHomePageState extends State<MyHomePage> {
  late File _audioFile;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  late StreamSubscription _audioSubscription;
  late Stream audioStream;
  late final RecorderController recorderController;
  late IOSink _sink;
  StreamController<List<double>>? audioFFT;
  String _startTime = "";
  String _endTime = "";
  int _repeatCycle = 0;


  AndroidInitializationSettings androidInitializationSettings =
  AndroidInitializationSettings('app_icon');
  IOSInitializationSettings iosInitializationSettings =
  IOSInitializationSettings();



  String _sound = "Press the button to start";
  bool _recording = false;


  late Stream<Map<dynamic, dynamic>> result;
  FlutterSoundRecorder _recorderFinal = FlutterSoundRecorder();

  bool _isRecording = false;
  List<charts.Series<dynamic, String>> _seriesList = [];
  late SharedPreferences _prefs;
  bool _isPlottingEnabled = true;
  bool _isQuickRecordEnabled = false;
  bool _isScheduleRecordingEnabled = true;
  bool _isAutoSyncEnabled = true;
  String _recordingLength = "30s";
  String _frequency = "440Hz";


  @override
  void initState()  {
    super.initState();
    final AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('app_icon');
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        _prefs = prefs;
        _isPlottingEnabled = prefs.getBool('isPlottingEnabled') ?? true;
        _isQuickRecordEnabled = prefs.getBool('isQuickRecordEnabled') ?? false;
        _isScheduleRecordingEnabled = prefs.getBool('isScheduleRecordingEnabled') ?? true;
        _isAutoSyncEnabled = prefs.getBool('isAutoSyncEnabled') ?? true;
        _recordingLength = prefs.getString('recordingLength') ?? "30s";
        _frequency = prefs.getString('frequency') ?? "440Hz";
      });
    });



    tz.initializeTimeZones();
     List<charts.Series<dynamic, String>> _seriesList =[];
    _recorderFinal.openAudioSession();
    _initialiseController();
    StreamController<List<double>> audioFFT ;





    TfliteAudio.loadModel(
        model: 'assets/soundclassifier.tflite',
        label: 'assets/labels.txt',
        inputType: 'rawAudio',
        numThreads: 1,
        isAsset: true);
  }
  @override
  void dispose() {
    _recorderFinal.closeAudioSession();

    super.dispose();
  }

  void _scheduleRecording(TimeOfDay startTime, TimeOfDay endTime, int repeatCycle) async {
   print("_scheduleRecording  ");
    print(startTime );
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    final IOSInitializationSettings initializationSettingsIOS =
    IOSInitializationSettings();
    final InitializationSettings initializationSettings =
    InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS);
   await flutterLocalNotificationsPlugin.initialize(initializationSettings,
       onSelectNotification: (String? payload) async {
         if (payload != null && payload == 'myFunction') {

           _startRecording();
         }
       });
    var androidDetails = new AndroidNotificationDetails(
        'channel id', 'channel NAME', 'CHANNEL DESCRIPTION',
        importance: Importance.high);
    var platformDetails = new NotificationDetails(android: androidDetails);

    DateTime now = DateTime.now();
    DateTime startDateTime = DateTime(now.year, now.month, now.day, startTime.hour, startTime.minute);

    // If the start time is in the past, add a day to it
   if (startDateTime.isBefore(now)) {
     startDateTime = startDateTime.add(Duration(days: 1));
   }


    print("Start");
    print(startDateTime);
    await flutterLocalNotificationsPlugin.zonedSchedule(
        0,
        'Recording Scheduled',
        'Your recording has been scheduled for ${startTime.format(context)}',
        tz.TZDateTime.from(startDateTime, tz.local),
        platformDetails,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'myFunction');
  }


  // Function to show popup for scheduling recording
  Future<void> _showScheduleRecordingPopup() async {
    TimeOfDay startTime = TimeOfDay.now();
    TimeOfDay endTime = TimeOfDay.now();
    int repeatCycle = 0;

    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Schedule Recording"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DateTimePicker(
                  type: DateTimePickerType.time,
                  initialValue: '',
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                  icon: Icon(Icons.access_time),
                  timeLabelText: 'Start Time',
                  onChanged: (val) {
                    setState(() {
                      startTime = TimeOfDay.fromDateTime(DateTime.parse("${DateTime.now().toIso8601String().substring(0, 10)} $val:00"));
                    });
                  },
                ),
                SizedBox(
                  height: 10,
                ),
                DateTimePicker(
                  type: DateTimePickerType.time,
                  initialValue: '',
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                  icon: Icon(Icons.access_time),
                  timeLabelText: 'End Time',
                  onChanged: (val) {
                    setState(() {
                      endTime = TimeOfDay.fromDateTime(DateTime.parse("${DateTime.now().toIso8601String().substring(0, 10)} $val:00"));
                    });
                  },
                ),
                SizedBox(
                  height: 10,
                ),
                TextField(
                  controller: TextEditingController(text: repeatCycle.toString()),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      hintText: "Repeat Cycle",
                      border: OutlineInputBorder()),
                  onChanged: (val) => repeatCycle = int.parse(val),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (startTime == null || endTime == null) {
                    // Display an error message if the start or end time is not selected
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text("Error"),
                          content: Text("Please select start and end times."),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text("OK"),
                            ),
                          ],
                        );
                      },
                    );
                  } else if (repeatCycle > 30) {
                    // Display an error message if the repeat cycle is greater than 30
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text("Error"),
                          content: Text("Repeat cycle must be 30 or less."),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text("OK"),
                            ),
                          ],
                        );
                      },
                    );
                  } else {
                    // Schedule the recording if all fields are valid
                    setState(() {
                      _startTime = startTime.format(context);
                      _endTime = endTime.format(context);
                      _repeatCycle = repeatCycle;
                    });
                    print("st");
                    print(startTime);
                    _scheduleRecording(startTime, endTime, repeatCycle);
                    Navigator.pop(context);
                  }
                },
                child: Text("Save"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("Cancel"),
              ),
            ],
          );
        },
    );
  }

  void _initialiseController() {
    recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 16000;
  }
  void _generateData() {
    final random = Random();
    List<Point> data = List.generate(2, (index) => Point(index, random.nextInt(100)));
    _seriesList = [
      charts.Series<dynamic, String>(
        id: 'Prediction',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (dynamic point, _) => point.x.toString(),
        measureFn: (dynamic point, _) => point.y,
        data: data,
      )
    ];
  }

  Future<List<String>> _loadLabels(String path) async {
    final data = await rootBundle.loadString(path);
    return data
        .split('\n')
        .map((label) => label.trim())
        .where((label) => label.isNotEmpty)
        .toList();
  }
  Future<String> _getFilePath() async {
    final Directory appDirectory = await getApplicationDocumentsDirectory();
    final String filePath = '${appDirectory.path}/audio_recording_${DateTime.now().millisecondsSinceEpoch}.wav';
    return filePath;
  }
  Future<void> _startRecording() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Microphone permission not granted');
    }
    String recognition = "";
    final String filePath = await _getFilePath();

    if(recorderController.isRecording){

      final path = await recorderController.stop();

    }
   // await _recorderFinal.startRecorder(toFile: filePath);
    await recorderController.record(path: filePath! );

    result = TfliteAudio.startAudioRecognition(
      numOfInferences: 1,
      sampleRate: 44100,
      audioLength: 44032,
      bufferSize: 22016,
    );

    result.listen((event) {
      recognition = event["recognitionResult"];
    }).onDone(() {
      setState(() {

        _isRecording = true;
        _sound = recognition.split(" ")[1];

      }

      );

    });



  }
  Future<void> _stopRecording() async {
    final path = await recorderController.stop();
     bool connection  = await checkInternetConnection();
    _generateData();
    if(connection == true  &&  _prefs.getBool('autoSync') ?? true == true) {
      Fluttertoast.showToast(
          msg: "Sync Successfully",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.grey,
          textColor: Colors.white,
          fontSize: 16.0
      );

    }

    else if ( connection == false ){
      Fluttertoast.showToast(
          msg: "Sync Failed Please Connect to Internet",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.grey,
          textColor: Colors.white,
          fontSize: 16.0 );
    }

    else{
      Fluttertoast.showToast(
          msg: "Auto Sync is  disabled",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.grey,
          textColor: Colors.white,
          fontSize: 16.0);
    }
    setState(() {
      _isRecording = false;
    });

  }
  Future<bool> checkInternetConnection() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile || connectivityResult == ConnectivityResult.wifi) {
      return true;
    } else {
      return false;
    }
  }
  void _recorder() {
    String recognition = "";
    if (!_recording) {
      setState(() => _recording = true);

      result = TfliteAudio.startAudioRecognition(
        numOfInferences: 1,

        sampleRate: 44100,
        audioLength: 44032,
        bufferSize: 22016,
      );
      result.listen((event) {
        recognition = event["recognitionResult"];
      }).onDone(() {
        setState(() {
          _recording = false;
          _sound = recognition.split(" ")[1];
        });
      });
    }
  }

  void _stop() {
    TfliteAudio.stopAudioRecognition();
    setState(() => _recording = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     // extendAppBar: true,
      appBar: AppBar(
        title: Text(
          'MozzWear',
          style: TextStyle(color: Colors.blue, fontSize: 30.0),
        ),
        backgroundColor: Colors.transparent,

        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.settings,size:30.0),
            color: Colors.blue,
            onPressed: () {

              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingScreen()),);
            },
          ),
        ],
      ),
      body: Center(

        child: Column(


          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,

                children: <Widget>[
                  _isRecording ? AudioWaveforms(
                    size: Size(MediaQuery.of(context).size.width, 100.0),
                    recorderController: recorderController,
                    enableGesture: true,
                    waveStyle: const WaveStyle(
                      waveColor: Colors.black,
                      extendWaveform: true,
                      showMiddleLine: false,
                    ), decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15.0),
                    color: const Color(0xFFFFFFFF),
                  ),
                  ):Container(
                      width:
                      MediaQuery.of(context).size.width / 1.7,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                  ),
                ]


            ),
            SizedBox(height: 20),
        GestureDetector(
          onLongPress: _showScheduleRecordingPopup,
            child: MaterialButton(

              onPressed: (){
                if (_isRecording) {
                  _stopRecording();
                } else {
                  _startRecording();
                }
              },

              color: _recording ? Colors.grey : Colors.pink,
              textColor: Colors.white,
              child: Icon(Icons.mic, size: 60),
              shape: CircleBorder(),
              padding: EdgeInsets.all(25),
            ),
        ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AudioListScreen()),);
                      },
                      child: Icon(
                        Icons.cloud,
                        color: Colors.blue,
                        size: 50,
                      ),
                    ),
                    Text(
                      'Sync',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ],
                ),
                SizedBox(width: 50),
                Column(
                  children: [
                    InkWell(
                      onTap: () {},
                      child: Icon(
                        Icons.delete,
                        color: Colors.blue,
                        size: 50,
                      ),
                    ),
                    Text(
                      'Delete',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ],
                ),



              ],
            ),
            SizedBox(height: 20),
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.center,
            //     children:[
            //
            //       Text(
            //         '$_sound',
            //         style: Theme.of(context).textTheme.headline5,
            //       ),
            //
            //     ]
            //
            //
            // ),
            SizedBox(height: 10),

          ],
        ),
      ),
    );
  }
}
class Recording {
  final String filePath;
  final Duration duration;

  Recording({
    required this.filePath,
    required this.duration,
  });
}
class Task {
  final String task;
  final double value;

  Task(this.task, this.value);
}

class Point {
  final int x;
  final int y;
  Point(this.x, this.y);
}