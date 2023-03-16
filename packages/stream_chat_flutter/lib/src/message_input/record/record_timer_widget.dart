import 'dart:async';

import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

/// Docs
class RecordTimer extends StatefulWidget {
  /// Docs
  const RecordTimer({
    super.key,
    required this.recordState,
  });

  @override
  State<RecordTimer> createState() => _RecordTimerState();

  /// Docs
  final Stream<RecordState> recordState;
}

class _RecordTimerState extends State<RecordTimer> {
  Duration duration = Duration.zero;
  late Timer timer;
  late StreamSubscription<RecordState> recordStateSubscription;

  @override
  void initState() {
    super.initState();

    recordStateSubscription = widget.recordState.listen((state) {
      if (state == RecordState.record && !timer.isActive) {
        timer = Timer.periodic(
          const Duration(seconds: 1),
          (_) => _addTime.call(),
        );
      } else {
        timer.cancel();
      }
    });

    timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _addTime.call(),
    );
  }

  @override
  void dispose() {
    super.dispose();
    recordStateSubscription.cancel();
    timer.cancel();
  }

  void _addTime() {
    setState(() {
      duration += const Duration(seconds: 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      duration.toMinutesAndSeconds(),
      style: const TextStyle(fontSize: 18),
    );
  }
}