import 'dart:async';
import 'dart:io';
import "dart:math" as math;

import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';
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
                  bool hasPermissions = await FlutterBackground.hasPermissions;
                  bool success = await FlutterBackground.initialize(
                      androidConfig: androidConfig);
                  bool bg = await FlutterBackground.enableBackgroundExecution();
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
