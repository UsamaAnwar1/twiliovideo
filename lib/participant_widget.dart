import 'package:flutter/material.dart';

class ParticipantWidget extends StatelessWidget {
  final Widget child;
  final String sid;

  const ParticipantWidget({
    required this.child,
    required Key key,
    required this.sid,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
