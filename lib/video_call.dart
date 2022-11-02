import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import "dart:math" as math;
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:twilio_programmable_video/twilio_programmable_video.dart';
import 'package:twiliovideo/twilioservice.dart';
import 'package:uuid/uuid.dart';

class VideoCall extends StatefulWidget {
  const VideoCall({Key? key}) : super(key: key);

  @override
  State<VideoCall> createState() => _VideoCallState();
}

class _VideoCallState extends State<VideoCall> {
  final Completer<Room> _completer = Completer<Room>();
  Widget? _remoteParticipantWidget;

  bool _isFrontCamera = true;
  bool _isAudioMuted = false;
  bool _isVideoMuted = false;

  Room? _room;
  CameraCapturer? _capturer;
  LocalVideoTrack? _localVideoTrack;
  LocalAudioTrack? _localAudioTrack;
  TwilioFunctionsService tfs = TwilioFunctionsService();

  String? trackId;
  late Timer _timer;
  _remoteVideoTrack(RemoteVideoTrackSubscriptionEvent evt) {
    setState(() {
      _remoteParticipantWidget = evt.remoteVideoTrack.widget();
    });
  }

  _onConnected(Room? room) {
    print("Connected to ${room?.name}");
    if (room != null) {
      if (room.remoteParticipants.isNotEmpty) {
        room.remoteParticipants.first.onVideoTrackSubscribed
            .listen(_remoteVideoTrack);
      }
      _completer.complete(room);
    }
  }

  _onConnectFailure(RoomConnectFailureEvent event) {
    print("Failed to connect to room ${event.room.name} ");
    print(event.exception.toString());
    _completer.completeError(event.exception.toString());
  }

  _onParticipantConnected(RoomParticipantConnectedEvent roomEvent) {
    print("remote particiant has connected to the room");
    roomEvent.remoteParticipant.onVideoTrackSubscribed
        .listen(_remoteVideoTrack);
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
    Navigator.of(context).pop();
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

  Future<void> toggleVideoEnabled() async {
    final tracks = _room!.localParticipant?.localVideoTracks ?? [];
    final localVideoTrack = tracks.isEmpty ? null : tracks[0].localVideoTrack;
    if (localVideoTrack == null) {
      print(
          'ConferenceRoom.toggleVideoEnabled() => Track is not available yet!');
      return;
    }
    await localVideoTrack.enable(!localVideoTrack.isEnabled);

    // var index = _participants
    //     .indexWhere((ParticipantWidget participant) => !participant.isRemote);
    // if (index < 0) {
    //   return;
    // }
    // _participants[index] =
    //     _participants[index].copyWith(videoEnabled: localVideoTrack.isEnabled);
    // Debug.log(
    //     'ConferenceRoom.toggleVideoEnabled() => ${localVideoTrack.isEnabled}');
    _onVideoEnabledStreamController.add(localVideoTrack.isEnabled);
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

        _capturer = CameraCapturer(
          sources.firstWhere((source) => source.isFrontFacing),
        );
        _localVideoTrack = LocalVideoTrack(true, _capturer!);
        // var widget = localVideoTrack.widget();

        print(_capturer);
        trackId = const Uuid().v4();
        print(trackId);
        String accessKey = await tfs.createToken("test");
        print(accessKey);
        var connectOptions = ConnectOptions(
          accessKey,
          roomName: "bo0tman",
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
        print(_room);
        _room?.onConnected.listen(_onConnected);
        _room?.onConnectFailure.listen(_onConnectFailure);
        _room?.onParticipantConnected.listen(_onParticipantConnected);
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
    _connectToRoom();
    super.initState();
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
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Video'),
      // ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              child: Stack(
                children: [
                  FutureBuilder(
                    future: _completer.future,
                    builder: (context, AsyncSnapshot<Room> snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                              "error occurred while establishing connection"),
                        );
                      }
                      if (snapshot.hasData) {
                        return Container(
                          margin: EdgeInsets.only(bottom: 80),
                          // height: 600,
                          child: Transform(
                            alignment: Alignment.center,
                            transform:
                                Matrix4.rotationY(_isFrontCamera ? math.pi : 0),
                            child: _localVideoTrack!.widget(mirror: false),
                          ),
                        );
                      }
                      return Center(child: CircularProgressIndicator());
                    },
                  ),
                  Positioned(
                    bottom: 100,
                    right: 10,
                    child: SizedBox(
                      height: 150,
                      width: 150,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _remoteParticipantWidget,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 0,
                    right: 0,
                    child: Container(
                      child: Row(
                        children: [
                          ElevatedButton(
                            onPressed: () => switchCamera(),
                            style: ElevatedButton.styleFrom(
                              shape: CircleBorder(),
                              padding: const EdgeInsets.all(10),
                            ),
                            child: Icon(Icons.switch_camera),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              toggleAudioEnabled();
                              // _localAudioTrack!.enable(!_isAudioMuted);
                              setState(() {
                                _isAudioMuted = !_isAudioMuted;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              shape: CircleBorder(),
                              padding: const EdgeInsets.all(10),
                              primary: _isAudioMuted ? Colors.red : Colors.blue,
                            ),
                            child:
                                Icon(_isAudioMuted ? Icons.mic_off : Icons.mic),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              // if (_isVideoMuted) {
                              toggleVideoEnabled();

                              // await _localVideoTrack!.enable(
                              //   !_localVideoTrack!.isEnabled,
                              // );
                              // _onVideoEnabledStreamController
                              //     .add(_localVideoTrack!.isEnabled);

                              setState(() {
                                _isVideoMuted = !_isVideoMuted;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              shape: CircleBorder(),
                              padding: const EdgeInsets.all(10),
                              primary: _isVideoMuted ? Colors.red : Colors.blue,
                            ),
                            child: Icon(_isVideoMuted
                                ? Icons.videocam_off
                                : Icons.videocam),
                          ),
                          ClipOval(
                            child: Material(
                              color: Colors.red, // Button color
                              child: InkWell(
                                splashColor: Colors.grey, // Splash color
                                onTap: () => _onHangup(),
                                child: SizedBox(
                                  width: 56,
                                  height: 56,
                                  child: Icon(
                                    Icons.phone,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
