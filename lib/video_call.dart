import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import "dart:math" as math;
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:twilio_programmable_video/twilio_programmable_video.dart';
import 'package:twiliovideo/config.dart';
import 'package:twiliovideo/home.dart';
import 'package:twiliovideo/participant_widget.dart';
import 'package:twiliovideo/twilioservice.dart';
import 'package:uuid/uuid.dart';

class VideoCall extends StatefulWidget {
  String? username;
  VideoCall({Key? key, required this.username}) : super(key: key);

  @override
  State<VideoCall> createState() => _VideoCallState();
}

class _VideoCallState extends State<VideoCall> with WidgetsBindingObserver {
  final Completer<Room> _completer = Completer<Room>();
  Widget? _remoteParticipantWidget;
  List<ParticipantWidget> _participants = [];
  List<ParticipantWidget> _cpparticipants = [];
  bool _isFrontCamera = true;
  bool _isAudioMuted = false;
  bool _isVideoMuted = false;

  Room? _room;
  CameraCapturer? _capturer;
  LocalVideoTrack? _localVideoTrack;
  LocalAudioTrack? _localAudioTrack;
  TwilioFunctionsService tfs = TwilioFunctionsService();
  ParticipantWidget _buildParticipant({
    required Widget? child,
    required Key key,
    required String sid,
  }) {
    return ParticipantWidget(
      key: key,
      child: child!,
      sid: sid,
    );
  }

  String? trackId;
  late Timer _timer;
  _remoteVideoTrack(RemoteVideoTrackSubscriptionEvent evt) {
    setState(() {
      /*  if (_participants
          .where((element) => element.sid == evt.remoteVideoTrack.sid)
          .toList()
          .isEmpty) { */
      //_remoteParticipantWidget = evt.remoteVideoTrack.widget();
      _participants.add(_buildParticipant(
          child: evt.remoteVideoTrack.widget(key: UniqueKey()),
          key: UniqueKey(),
          sid: evt.remoteParticipant.sid.toString()));
      _cpparticipants = [..._participants];
      //  }
    });
  }

  _onConnected(Room? room) {
    print("Connected to ${room?.name}");

    if (room != null) {
      if (room.remoteParticipants.isNotEmpty) {
        room.remoteParticipants.first.onVideoTrackSubscribed
            .listen(_remoteVideoTrack);
      }
      _participants.add(_buildParticipant(
          child: _localVideoTrack!.widget(key: UniqueKey(), mirror: true),
          sid: 'local',
          key: UniqueKey()));
      _cpparticipants = [..._participants];

      setState(() {});
      // _completer.complete(room);
    }
  }

  _onConnectFailure(RoomConnectFailureEvent event) {
    print("Failed to connect to room ${event.room.name} ");
    print(event.exception.toString());
    _completer.completeError(event.exception.toString());
  }

  _onParticipantConnected(RoomParticipantConnectedEvent roomEvent) {
    print("============================================================");
    print("remote particiant has connected to the room");
    print(
        'ConferenceRoom._onParticipantConnected, ${roomEvent.remoteParticipant.sid}');
    roomEvent.remoteParticipant.onVideoTrackSubscribed
        .listen(_remoteVideoTrack);
  }

  _onParticipantDisConnected(RoomParticipantDisconnectedEvent event) {
    print("============================================================");
    print("remote particiant has connected to the room");
    _participants
        .removeWhere(((element) => element.sid == event.remoteParticipant.sid));
    setState(() {});
  }

  final StreamController<bool> _onAudioEnabledStreamController =
      StreamController<bool>.broadcast();
  late Stream<bool> onAudioEnabled;
  final StreamController<bool> _onVideoEnabledStreamController =
      StreamController<bool>.broadcast();
  late Stream<bool> onVideoEnabled;

  Future<void> _onHangup() async {
    print('onHangup');
    // await disconnect();
    print('ConferenceRoom.disconnect()');
    // await TwilioProgrammableVideo.disableAudioSettings();
    if (_room != null) await _room!.disconnect();
    //  Navigator.of(context).pop();
  }

  Future<void> switchCamera() async {
    print('ConferenceRoom.switchCamera()');
    if (_capturer != null) {
      final sources = await CameraSource.getSources();
      final source = sources.firstWhere((source) {
        if (_capturer!.source!.isFrontFacing) {
          return source.isBackFacing;
        }
        return source.isFrontFacing;
      });

      await _capturer!.switchCamera(source);
    }
  }

  Future<void> toggleVideoEnabled(bool videoEnabled) async {
    final tracks = _room!.localParticipant?.localVideoTracks ?? [];
    final localVideoTrack = tracks.isEmpty ? null : tracks[0].localVideoTrack;
    if (localVideoTrack == null) {
      print(
          'ConferenceRoom.toggleVideoEnabled() => Track is not available yet!');
      return;
    }
    await localVideoTrack.enable(videoEnabled);

    // var index = _participants
    //     .indexWhere((ParticipantWidget participant) => !participant.isRemote);
    // if (index < 0) {
    //   return;
    // }
    // _participants[index] =
    //     _participants[index].copyWith(videoEnabled: localVideoTrack.isEnabled);
    // Debug.log(
    //     'ConferenceRoom.toggleVideoEnabled() => ${localVideoTrack.isEnabled}');
    _onVideoEnabledStreamController.add(videoEnabled);
    // notifyListeners();
  }

  Future<void> toggleAudioEnabled() async {
    final tracks = _room!.localParticipant?.localAudioTracks ?? [];
    final localAudioTrack = tracks.isEmpty ? null : tracks[0].localAudioTrack;
    if (localAudioTrack == null) {
      print(
          'ConferenceRoom.toggleAudioEnabled() => Track is not available yet!');
      return;
    }
    await localAudioTrack.enable(!localAudioTrack.isEnabled);

    print(
        'ConferenceRoom.toggleAudioEnabled() => ${localAudioTrack.isEnabled}');
    _onAudioEnabledStreamController.add(localAudioTrack.isEnabled);
  }
  // Future<void> disconnect() async {
  //   _timer.cancel();
  // }

  Future<Room?> _connectToRoom() async {
    if (_localVideoTrack == null && _localVideoTrack == null) {
      try {
        EasyLoading.show(status: 'loading...');
        print("connect me to a room");
//         final sources = await CameraSource.getSources();
//         _capturer = CameraCapturer(
//           sources.firstWhere((source) => source.isFrontFacing),
//         );
//         // _capturer = CameraCapturer(CameraSource.FRONT_CAMERA);
//         _localVideoTrack = LocalVideoTrack(true, _capturer!);
//         _localAudioTrack = LocalAudioTrack(true, "local-audio-trak");

        // String accessKey = "";
//         // if (Platform.isAndroid) {
//         //   accessKey = AppConfig.androidAccessKey;
//         // }
// //
//         // if (Platform.isIOS) {
//         accessKey = await tfs.createToken("usama");
//         // accessKey = AppConfig.iosAccessKey;
//         // }

//         final connectOptions = ConnectOptions(
//           accessKey,
//           roomName: "bo0tman",
//           preferredAudioCodecs: [OpusCodec()],
//           preferredVideoCodecs: [H264Codec()],
//           audioTracks: [_localAudioTrack!],
//           videoTracks: [_localVideoTrack!],
//           enableAutomaticSubscription: true,
//         );

        // var ok = await TwilioProgrammableVideo.requestPermissionForCameraAndMicrophone();
        // await TwilioProgrammableVideo.setSpeakerphoneOn(true);
        final sources = await CameraSource.getSources();
        // await TwilioProgrammableVideo.setAudioSettings(speakerphoneEnabled: false, bluetoothPreferred: false);
        _capturer = CameraCapturer(
          sources.firstWhere((source) => source.isFrontFacing),
        );
        _localVideoTrack = LocalVideoTrack(true, _capturer!);
        // var widget = localVideoTrack.widget();
        await TwilioProgrammableVideo.setAudioSettings(
            speakerphoneEnabled: false, bluetoothPreferred: false);
        print(_capturer);
        trackId = const Uuid().v4();
        print(trackId);
        String accessKey = await tfs.createToken(widget.username!);
        print(accessKey);
        var connectOptions = ConnectOptions(
          accessKey,
          roomName: AppConfig.roomname,
          preferredAudioCodecs: [OpusCodec()],
          audioTracks: [LocalAudioTrack(true, 'audio_track-$trackId')],
          dataTracks: [
            LocalDataTrack(
              DataTrackOptions(name: 'data_track-$trackId'),
            )
          ],
          videoTracks: [LocalVideoTrack(true, _capturer!)],
          enableNetworkQuality: true,
          networkQualityConfiguration: NetworkQualityConfiguration(
            remote: NetworkQualityVerbosity.NETWORK_QUALITY_VERBOSITY_MINIMAL,
          ),
          enableDominantSpeaker: true,
        );
        print(connectOptions);
        _room = await TwilioProgrammableVideo.connect(connectOptions);

        // setState(() {});

        print(_room);
        // setState(() {});

        _room?.onConnected.listen(_onConnected);
        _room?.onConnectFailure.listen(_onConnectFailure);
        _room?.onParticipantConnected.listen(_onParticipantConnected);
        _room?.onParticipantDisconnected.listen(_onParticipantDisConnected);
        EasyLoading.dismiss();
      } catch (e) {
        print("we got error: ");
        print(e);
      }
    }

    return _completer.future;
  }

  @override
  void initState() {
    // TODO: implement initState
    print("onit");
    WidgetsBinding.instance.addObserver(this);
    _connectToRoom();
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        // print("app in resumed");
        Navigator.of(context).push(
          MaterialPageRoute(
              builder: (context) => VideoCall(
                    username: widget.username,
                  )),
        );
        // _connectToRoom();
        // //await toggleVideoEnabled(true);

        // setState(() {});
        break;
      case AppLifecycleState.inactive:
        print("app in inactive");
        break;
      case AppLifecycleState.paused:

        // _localAudioTrack = null;
        // _localVideoTrack = null;

        await _onHangup();
        Navigator.of(context).pop();
        // Navigator.of(context).push(
        //   MaterialPageRoute(builder: (context) => HomePage()),
        // );

        //_onVideoEnabledStreamController.close();
        //_onAudioEnabledStreamController.close();
        /*   _participants.clear();
        if (_localVideoTrack != null) {
          _localVideoTrack!.unpublish();
          _localVideoTrack!.release();
          _localVideoTrack = null;
          _localVideoTrack = null;
        } */
        print("app in paused");
        break;
      case AppLifecycleState.detached:
        print("app in detached");
        break;
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _onVideoEnabledStreamController.close();
    _onAudioEnabledStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _onHangup();
        Navigator.pop(context, true);
        return true;
      },
      child: Scaffold(
        // appBar: AppBar(
        //   title: const Text('Video'),
        // ),
        body: Column(
          children: [
            Stack(
              children: [
                _buildParticipants(context),
                // Container(height: 400, child: _participants[0].child),
                // Container(height: 200, child: _participants[0].child),

                /* Expanded(
                    child: FutureBuilder(
                      future: _completer.future,
                      builder: (context, AsyncSnapshot<Room> snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child:
                                Text("error occurred while establishing connection"),
                          );
                        }
                        if (snapshot.hasData) {
                          return Container(
                            // margin: EdgeInsets.only(bottom: 80),
    
                            child: _localVideoTrack!.widget(key: ValueKey('test')),
                          );
                        }
                        return Center(child: CircularProgressIndicator());
                      },
                    ),
                  ), */
                // _buildParticipants(context)
                /*  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Placeholder(child: _remoteParticipantWidget),
                    ),
                  ),
     */
                //  Positioned(
                //   top: 100,
                //   left: 10,
                //   child: SizedBox(
                //     height: 150,
                //     width: 150,
                //     child: ClipRRect(
                //       borderRadius: BorderRadius.circular(10),
                //       child: Placeholder(child: _remoteParticipantWidget),
                //     ),
                //   ),
                // ),
                // Positioned(
                //   bottom: 10,
                //   left: 0,
                //   right: 0,
                //   child: Container(
                //     child: Row(
                //       children: [
                //         ElevatedButton(
                //           onPressed: () => switchCamera(),
                //           style: ElevatedButton.styleFrom(
                //             shape: CircleBorder(),
                //             padding: const EdgeInsets.all(10),
                //           ),
                //           child: Icon(Icons.switch_camera),
                //         ),
                //         ElevatedButton(
                //           onPressed: () {
                //             toggleAudioEnabled();
                //             // _localAudioTrack!.enable(!_isAudioMuted);
                //             setState(() {
                //               _isAudioMuted = !_isAudioMuted;
                //             });
                //           },
                //           style: ElevatedButton.styleFrom(
                //             shape: CircleBorder(),
                //             padding: const EdgeInsets.all(10),
                //             primary: _isAudioMuted ? Colors.red : Colors.blue,
                //           ),
                //           child:
                //               Icon(_isAudioMuted ? Icons.mic_off : Icons.mic),
                //         ),
                //         ElevatedButton(
                //           onPressed: () async {
                //             // if (_isVideoMuted) {
                //             toggleVideoEnabled(_isVideoMuted);

                //             // await _localVideoTrack!.enable(
                //             //   !_localVideoTrack!.isEnabled,
                //             // );
                //             // _onVideoEnabledStreamController
                //             //     .add(_localVideoTrack!.isEnabled);

                //             setState(() {
                //               _isVideoMuted = !_isVideoMuted;
                //             });
                //           },
                //           style: ElevatedButton.styleFrom(
                //             shape: CircleBorder(),
                //             padding: const EdgeInsets.all(10),
                //             primary: _isVideoMuted ? Colors.red : Colors.blue,
                //           ),
                //           child: Icon(_isVideoMuted
                //               ? Icons.videocam_off
                //               : Icons.videocam),
                //         ),
                //         ClipOval(
                //           child: Material(
                //             color: Colors.red, // Button color
                //             child: InkWell(
                //               splashColor: Colors.grey, // Splash color
                //               onTap: () => _onHangup(),
                //               child: SizedBox(
                //                 width: 56,
                //                 height: 56,
                //                 child: Icon(
                //                   Icons.phone,
                //                   color: Colors.white,
                //                 ),
                //               ),
                //             ),
                //           ),
                //         )
                //       ],
                //     ),
                //   ),
                // ),
              ],
            ),
            // Container(
            //   child: Row(
            //     children: [
            //       ElevatedButton(
            //         onPressed: () => switchCamera(),
            //         style: ElevatedButton.styleFrom(
            //           shape: CircleBorder(),
            //           padding: const EdgeInsets.all(10),
            //         ),
            //         child: Icon(Icons.switch_camera),
            //       ),
            //       ElevatedButton(
            //         onPressed: () {
            //           toggleAudioEnabled();
            //           // _localAudioTrack!.enable(!_isAudioMuted);
            //           setState(() {
            //             _isAudioMuted = !_isAudioMuted;
            //           });
            //         },
            //         style: ElevatedButton.styleFrom(
            //           shape: CircleBorder(),
            //           padding: const EdgeInsets.all(10),
            //           primary: _isAudioMuted ? Colors.red : Colors.blue,
            //         ),
            //         child: Icon(_isAudioMuted ? Icons.mic_off : Icons.mic),
            //       ),
            //       ElevatedButton(
            //         onPressed: () async {
            //           // if (_isVideoMuted) {
            //           toggleVideoEnabled(!_isVideoMuted);

            //           // await _localVideoTrack!.enable(
            //           //   !_localVideoTrack!.isEnabled,
            //           // );
            //           // _onVideoEnabledStreamController
            //           //     .add(_localVideoTrack!.isEnabled);

            //           setState(() {
            //             _isVideoMuted = !_isVideoMuted;
            //           });
            //         },
            //         style: ElevatedButton.styleFrom(
            //           shape: CircleBorder(),
            //           padding: const EdgeInsets.all(10),
            //           primary: _isVideoMuted ? Colors.red : Colors.blue,
            //         ),
            //         child: Icon(
            //             _isVideoMuted ? Icons.videocam_off : Icons.videocam),
            //       ),
            //       ClipOval(
            //         child: Material(
            //           color: Colors.red, // Button color
            //           child: InkWell(
            //             splashColor: Colors.grey, // Splash color
            //             onTap: () => _onHangup(),
            //             child: SizedBox(
            //               width: 56,
            //               height: 56,
            //               child: Icon(
            //                 Icons.phone,
            //                 color: Colors.white,
            //               ),
            //             ),
            //           ),
            //         ),
            //       )
            //     ],
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipants(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final children = <Widget>[];
    _buildOverlayLayout(context, size, children);
    return Stack(children: children);
  }

  void _buildOverlayLayout(
      BuildContext context, Size size, List<Widget> children) {
    if (_participants.length == 1) {
      children.add(
        Container(
            height: MediaQuery.of(context).size.height - 60,
            width: MediaQuery.of(context).size.width,
            child: Card(child: _participants[0])),
      );
    }
    if (_participants.length == 2) {
      children.add(
        Container(
          height: MediaQuery.of(context).size.height - 60,
          width: MediaQuery.of(context).size.width,
          child: Card(
            child: _participants[0],
          ),
        ),
      );

      children.add(
        Container(
          height: MediaQuery.of(context).size.height / 2 - 30,
          width: MediaQuery.of(context).size.width,
          child: Card(
            child: _participants[1],
          ),
        ),
      );
    }
    if (_participants.length == 3) {
      children.add(
        Container(
          height: MediaQuery.of(context).size.height - 60,
          width: MediaQuery.of(context).size.width,
          child: Card(
            child: _participants[0],
          ),
        ),
      );

      children.add(
        Container(
          height: MediaQuery.of(context).size.height / 2 - 30,
          width: MediaQuery.of(context).size.width,
          child: Card(
            child: _participants[1],
          ),
        ),
      );
      children.add(
        Container(
          height: MediaQuery.of(context).size.height / 2 - 30,
          width: MediaQuery.of(context).size.width / 2,
          child: Card(
            child: _participants[2],
          ),
        ),
      );
    }
    if (_participants.length == 4) {
      children.add(
        Container(
          height: MediaQuery.of(context).size.height - 60,
          width: MediaQuery.of(context).size.width,
          child: Card(
            child: _participants[0],
          ),
        ),
      );
      children.add(
        Container(
          height: MediaQuery.of(context).size.height - 60,
          width: MediaQuery.of(context).size.width / 2,
          child: Card(
            child: _participants[1],
          ),
        ),
      );
      children.add(
        Container(
          height: MediaQuery.of(context).size.height / 2 - 30,
          width: MediaQuery.of(context).size.width,
          child: Card(
            child: _participants[2],
          ),
        ),
      );
      children.add(
        Container(
          height: MediaQuery.of(context).size.height / 2 - 30,
          width: MediaQuery.of(context).size.width / 2,
          child: Card(
            child: _participants[3],
          ),
        ),
      );
    } else {
      children.add(Container(
        height: 40,
        width: 40,
        color: Colors.red,
      ));
    }
    /*  children.add(GridView.builder(
        gridDelegate:
            SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
        itemCount: _participants.length,
        itemBuilder: (BuildContext context, int index) {
          return Card(
            child: _participants[index],
          );
        })); */
  }
}
