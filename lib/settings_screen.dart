import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  _SettingScreenState createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  late SharedPreferences _prefs;
  bool _isPlottingEnabled = true;
  bool _isQuickRecordEnabled = false;
  bool _isScheduleRecordingEnabled = true;
  bool _isAutoSyncEnabled = true;
  String _recordingLength = "30s";
  String _frequency = "440Hz";

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _isPlottingEnabled = _prefs.getBool('plotting') ?? true;
      _isQuickRecordEnabled = _prefs.getBool('quickRecord') ?? false;
      _isScheduleRecordingEnabled = _prefs.getBool('scheduleRecording') ?? true;
      _isAutoSyncEnabled = _prefs.getBool('autoSync') ?? true;
      _recordingLength = _prefs.getString('recordingLength') ?? '30s';
      _frequency = _prefs.getString('frequency') ?? '440Hz';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.transparent,
        title: Text('Settings'),
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            buildRow('Plotting', buildSwitch(_isPlottingEnabled, (value) {
              setState(() {
                _isPlottingEnabled = value;
                _prefs.setBool('plotting', value);
              });
            })),
            buildRow('Automatic Sync', buildSwitch(_isAutoSyncEnabled, (value) {
              setState(() {
                _isAutoSyncEnabled = value;
                _prefs.setBool('autoSync', value);
              });
            })),
            buildRow('Quick Record', buildSwitch(_isQuickRecordEnabled, (value) {
              setState(() {
                _isQuickRecordEnabled = value;
                _prefs.setBool('quickRecord', value);
              });
            })),
            buildRow('Recording Length', buildTextField(_recordingLength, (value) {
              setState(() {
                _recordingLength = value;
                _prefs.setString('recordingLength', value);
              });
            })),
            buildRow('Frequency', buildTextField(_frequency, (value) {
              setState(() {
                _frequency = value;
                _prefs.setString('frequency', value);
              });
            })),
            buildRow('Schedule Recording', buildSwitch(_isScheduleRecordingEnabled, (value) {
              setState(() {
                _isScheduleRecordingEnabled = value;
                _prefs.setBool('scheduleRecording', value);
              });
            })),
          ],
        ),
      ),
    );
  }

  Widget buildRow(String label, Widget widget) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 16.0),
            ),
            widget,
          ],
        ),
        SizedBox(height: 16.0),
        Divider(),
      ],
    );
  }

  Widget buildSwitch(bool value, ValueChanged<bool> onChanged) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeColor: Colors.green,
      inactiveThumbColor: Colors.grey[200],
      inactiveTrackColor: Colors.grey[300],
    );
  }

  Widget buildTextField(String text, ValueChanged<String> onChanged) {
    return Expanded(
      child: TextField(
        controller: TextEditingController(text: text),
        onChanged: onChanged,
        textAlign: TextAlign.left,
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
          border: OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }
}
