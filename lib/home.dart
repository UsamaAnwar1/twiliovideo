import 'dart:async';
import 'dart:io';
import "dart:math" as math;

import 'package:flutter/material.dart';
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
          margin: const EdgeInsets.all(15),
          child: ElevatedButton(
            // onPressed: () => _connectToRoom(),

            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const VideoCall()),
              );
            },
            child: Text("Join Room"),
          ),
        ),
      ),
    );
  }
}
