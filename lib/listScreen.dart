import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';

class AudioListScreen extends StatefulWidget {
  @override
  _AudioListScreenState createState() => _AudioListScreenState();
}

class _AudioListScreenState extends State<AudioListScreen> {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  List<File> _recordings = [];
  List<File> _selectedRecordings = [];
  bool isPlaying = false;
  FlutterSoundRecorder _recorderFinal = FlutterSoundRecorder();
  int _currentlyPlayingIndex = -1;
  @override
  void initState() {
    _player.openAudioSession();
    _recorderFinal.openAudioSession();

    super.initState();
    _loadRecordings();
  }

  Future<void> _loadRecordings() async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final List<FileSystemEntity> files = dir.listSync();

    setState(() {
      _recordings = files.whereType<File>().where((file) => file.path.endsWith('.wav')).toList();
    });
  }
  void _deleteAudioFile(int index) async {
    final file = _recordings[index];
    await file.delete();
    setState(() {
      _recordings.removeAt(index);
    });
  }

  Future<void> _playRecording(File recording, int index) async {
    if (_player.isPlaying) {
      await _player.stopPlayer();
      setState(() {
        _currentlyPlayingIndex = -1;
      });
    }
    await _player.startPlayer(fromURI: recording.path);
    setState(() {
      _currentlyPlayingIndex = index;
    });
  }

  Future<void> _stopPlaying() async {
    await _player.stopPlayer();
    setState(() {
      _currentlyPlayingIndex = -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recordings'),
      ),
      body: _recordings.isEmpty
          ? Center(
        child: Text('No recordings found'),
      )
          : ListView.builder(
        itemCount: _recordings.length,
        itemBuilder: (context, index) {
          final File recording = _recordings[index];
          return ListTile(
            title: Text(recording.path.split('/').last),
            subtitle: Text(recording.lastModifiedSync().toString()),
              leading: Checkbox(
                value: _selectedRecordings.contains(recording),
                onChanged: (value) {
                  setState(() {
                    if (value!) {
                      _selectedRecordings.add(recording);
                    } else {
                      _selectedRecordings.remove(recording);
                    }
                  });
                },
              ),
              onLongPress: () {
                setState(() {
                  if (_selectedRecordings.contains(recording)) {
                    _selectedRecordings.remove(recording);
                  } else {
                    _selectedRecordings.add(recording);
                  }
                });
              },
            trailing: Wrap(
                children: <Widget>[
                  if (_currentlyPlayingIndex == index)
                    IconButton(
                      icon: Icon(Icons.stop),
                      onPressed: () {
                        _stopPlaying();
                      },
                    )
                  else
                    IconButton(
                      icon: Icon(Icons.play_arrow),
                      onPressed: () {
                        _playRecording(recording, index);
                      },
                    ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        _deleteAudioFile(index);
                      });
                    },
                  ),
            ])


          );
        },
      ),
      floatingActionButton: _selectedRecordings.isEmpty
          ? FloatingActionButton(
        onPressed: () {
          _stopPlaying();
          Navigator.pop(context);
        },
        child: Icon(Icons.arrow_back),
      )
          : FloatingActionButton(
        onPressed: () async {
          final url = Uri.parse('http://humbug.ac.uk//send/');

          for (final recording in _recordings) {
            final filename = recording.path.split('/').last;

            final request = http.MultipartRequest('POST', url);

              request.fields['phone_info'] = "Andorid ";
            request.files.add(await http.MultipartFile.fromPath(
                  'wav_file', recording.path ));
            final response = await request.send();
            print(response.statusCode);
            if (response.statusCode == 200) {
              Fluttertoast.showToast(
                  msg: "Sync Successfully",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.CENTER,
                  timeInSecForIosWeb: 1,
                  backgroundColor: Colors.grey,
                  textColor: Colors.white,
                  fontSize: 16.0
              );
              print('Recordings sent successfully');
            } else {
              print('Error sending recordings');
            }
          }


        },
        child: Icon(Icons.sync),
      ),


    );
  }

  @override
  void dispose() {
    _player.closeAudioSession();
    super.dispose();
  }
}
