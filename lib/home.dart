import 'dart:async';

import 'dart:io';
import "dart:math" as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_easy_permission/constants.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:twilio_programmable_video/twilio_programmable_video.dart';
import 'package:twiliovideo/twilioservice.dart';
import 'package:twiliovideo/video_call.dart';
import 'package:uuid/uuid.dart';

import 'config.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final androidConfig = FlutterBackgroundAndroidConfig(
    notificationTitle: "Twillio app",
    notificationText: "twilio app running in the background",
    notificationImportance: AndroidNotificationImportance.Default,
    notificationIcon: AndroidResource(
        name: 'background_icon',
        defType: 'drawable'), // Default is ic_launcher from folder mipmap
  );
  TextEditingController nameController = TextEditingController();

  // FlutterEasyPermission? _easyPermission =;
  Permission _permission = Permission.bluetooth;
  PermissionStatus _permissionStatus = PermissionStatus.denied;

  bool permGranted = false;

  // Future<PermissionStatus> _getBlutoothPermission() async {
  //   if (defaultTargetPlatform == TargetPlatform.android) {
  //     final setting = await requestPermissionsIOS();
  //     if (setting.authorizationStatus == AuthorizationStatus.authorized) {
  //       return PermissionStatus.granted;
  //     } else {
  //       return PermissionStatus.denied;
  //     }
  //   } else {
  //     return Permission.bluetooth.request();
  //   }
  // }
  void _listenForPermissionStatus() async {
    // final status = await _permission.status;
    // setState(() => _permissionStatus = status);
  }

  Future<void> requestPermission() async {
    if (_permissionStatus.isDenied) {
      permGranted = false;
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect
      ].request();
      if (statuses[Permission.bluetoothScan]!.isGranted &&
          statuses[Permission.bluetoothAdvertise]!.isGranted &&
          statuses[Permission.bluetoothConnect]!.isGranted) {
        permGranted = true;
      } //check each permission status after.
    }
  }

  getPermission() {
    switch (_permissionStatus) {
      case PermissionStatus.denied:
        return false;
      case PermissionStatus.granted:
        return true;
      case PermissionStatus.limited:
        return true;
      default:
        return false;
    }
  }

  void initState() {
    super.initState();
    _listenForPermissionStatus();
//     const permissions = [Permissions.];
// const permissionGroup = [PermissionGroup.Bluetooth];
//     FlutterEasyPermission.request(
//                  perms: permissions,permsGroup: permissionGroup,rationale:"Test permission requests here");
//     _easyPermission = FlutterEasyPermission()
//       ..addPermissionCallback(
//         onGranted: (requestCode, perms, perm) {
//           debugPrint("Android Authorized:$perms");
//           debugPrint("iOS Authorized:$perm");
//         },
//         onDenied: (requestCode, perms, perm, isPermanent) {
//           if (isPermanent) {
//             FlutterEasyPermission.showAppSettingsDialog(title: "Camera");
//           } else {
//             debugPrint("Android Deny authorization:$perms");
//             debugPrint("iOS Deny authorization:$perm");
//           }
//         },
//       );
  }

  void dispose() {
    // _easyPermission!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_call_outlined,
              size: 40,
            ),
            SizedBox(width: 10),
            Text("Twilio Video"),
          ],
        ),
      ),
      body: Center(
        child: Container(
          height: 110,
          margin: const EdgeInsets.all(15),
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                    border: InputBorder.none,
                    labelText: 'Enter Name',
                    hintText: 'Enter Your Name'),
              ),
              ElevatedButton(
                // onPressed: () => _connectToRoom(),

                onPressed: () async {
                  await requestPermission();
                  //bool p = getPermission();

                  bool hasPermissions = await FlutterBackground.hasPermissions;
                  bool success = await FlutterBackground.initialize(
                      androidConfig: androidConfig);
                  // bool bg = await FlutterBackground.enableBackgroundExecution();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => VideoCall(
                              username: nameController.text.toString(),
                            )),
                  );
                },
                child: Text("Join Room"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
