import 'package:custom_timer/custom_timer.dart';
import 'package:fitness_flutter/core/service/date_service.dart';
import 'package:flutter/material.dart';

class StartWorkoutTimer extends StatefulWidget {
  final int time;
  final bool isPaused;

  StartWorkoutTimer({
    required this.time,
    required this.isPaused,
  });

  @override
  _StartWorkoutTimerState createState() => _StartWorkoutTimerState();
}

class _StartWorkoutTimerState extends State<StartWorkoutTimer>
    with TickerProviderStateMixin {
  late CustomTimerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CustomTimerController(
      vsync: this,
      begin: Duration(seconds: widget.time),
      end: Duration(seconds: 0),
      initialState: widget.isPaused ? CustomTimerState.paused : CustomTimerState.counting,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(StartWorkoutTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPaused != oldWidget.isPaused) {
      if (widget.isPaused) {
        _controller.pause();
      } else {
        _controller.start();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomTimer(
      controller: _controller,
      builder: (context, remaining) {
        return Text(
          "${remaining.minutes.toString().padLeft(2, '0')}:${remaining.seconds.toString().padLeft(2, '0')}",
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        );
      },
    );
  }

  Widget _createPauseText() {
    final minutesSeconds = DateService.convertIntoSeconds(widget.time);
    return Text(
      "${minutesSeconds.minutes.toString().padLeft(2, '0')}:${minutesSeconds.seconds.toString().padLeft(2, '0')}",
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
