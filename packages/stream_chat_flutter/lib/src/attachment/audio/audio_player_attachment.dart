import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:stream_chat_flutter/src/attachment/audio/audio_loading_attachment.dart';
import 'package:stream_chat_flutter/src/attachment/audio/audio_wave_slider.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

List<int> _audioBars() {
  return [
    50,
    75,
    100,
    150,
    200,
    255,
    200,
    150,
    100,
    75,
    50,
    75,
    100,
    150,
    200,
    0,
    0,
    0,
    0,
    0,
    0,
    255,
    200,
    150,
    100,
    75,
    50,
    75,
    100,
    150,
    200,
    255,
    200,
    0,
    0,
    0,
    0,
    0,
    0,
    150,
    100,
    75,
    50,
    75,
    100,
    150,
    200,
    255,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    200,
  ];
}

/// Docs
class AudioPlayerMessage extends StatefulWidget {
  /// Docs
  const AudioPlayerMessage({
    super.key,
    required this.player,
    required this.audioFile,
    this.index,
    this.fileSize,
    this.actionButton,
    this.singleAudio = false,
  });

  /// Docs
  final AudioPlayer player;

  /// Docs
  final int? index;

  /// Docs
  final int? fileSize;

  /// Docs
  final AttachmentFile? audioFile;

  /// Docs
  final Widget? actionButton;

  final bool singleAudio;

  @override
  AudioPlayerMessageState createState() => AudioPlayerMessageState();
}

/// Docs
class AudioPlayerMessageState extends State<AudioPlayerMessage> {
  var _seeking = false;
  StreamSubscription<PlayerState>? stateSubscription;

  @override
  void initState() {
    super.initState();

    void playerStateListener(PlayerState state) async {
      if (state.processingState == ProcessingState.completed) {
        await widget.player.stop();
        await widget.player.seek(Duration.zero, index: 0);
      }
    }

    widget.player.playerStateStream.listen(playerStateListener);
  }

  /// Docs
  void onError(Object e, StackTrace st) {
    if (e is PlayerException) {
      print('Error code: ${e.code}');
      print('Error message: ${e.message}');
    } else {
      print('An error occurred: $e');
    }
  }

  @override
  void dispose() {
    super.dispose();

    widget.player.dispose();
    stateSubscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration?>(
      stream: widget.player.durationStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(8),
            height: 56,
            child: Row(
              children: <Widget>[
                _controlButton(),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _timer(snapshot.data!),
                    _fileSizeWidget(widget.fileSize),
                  ],
                ),
                _audioWaveSlider(snapshot.data!),
                _speedAndActionButton(),
              ],
            ),
          );
        } else if (snapshot.hasError) {
          print(snapshot.error);
          return const Center(child: Text('Error!!'));
        } else {
          return const AudioLoadingMessage();
        }
      },
    );
  }

  Widget _controlButton() {
    return StreamBuilder<int?>(
      initialData: 0,
      stream: widget.player.currentIndexStream,
      builder: (context, snapshot) {
        final currentIndex = snapshot.data;
        return StreamBuilder<bool>(
          initialData: false,
          stream: widget.player.playingStream,
          builder: (context, snapshot) {
            final playingCurrentAudio =
                snapshot.data == true && currentIndex == widget.index;

            final color = playingCurrentAudio ? Colors.red : Colors.blue;
            final icon = playingCurrentAudio ? Icons.pause : Icons.play_arrow;

            final playButton = Padding(
              padding: const EdgeInsets.only(right: 4),
              child: GestureDetector(
                onTap: () {
                  if (playingCurrentAudio) {
                    _pause();
                  } else {
                    _play();
                  }
                },
                child: Icon(icon, color: color),
              ),
            );

            return playButton;
          },
        );
      },
    );
  }

  Widget _speedAndActionButton() {
    return StreamBuilder<bool>(
      stream: widget.player.playingStream,
      initialData: false,
      builder: (context, snapshot) {
        if (snapshot.data == true &&
            widget.player.currentIndex == widget.index) {
          return StreamBuilder<double>(
            stream: widget.player.speedStream,
            builder: (context, snapshot) {
              final speed = snapshot.data ?? 1;
              return TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(30, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(speed.toString()),
                onPressed: () {
                  setState(() {
                    if (speed == 2) {
                      widget.player.setSpeed(1);
                    } else {
                      widget.player.setSpeed(speed + 0.5);
                    }
                  });
                },
              );
            },
          );
        } else {
          return widget.actionButton ?? const SizedBox.shrink();
        }
      },
    );
  }

  Widget _fileSizeWidget(int? fileSize) {
    if (fileSize != null) {
      return Text(
        fileSize.toHumanReadableSize(),
        style: const TextStyle(fontSize: 10),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _timer(Duration totalDuration) {
    return StreamBuilder<Duration>(
      stream: widget.player.positionStream,
      builder: (context, snapshot) {
        if (snapshot.hasData &&
            (widget.player.currentIndex == widget.index &&
                (widget.player.playing ||
                    snapshot.data!.inMilliseconds > 0 ||
                    _seeking))) {
          final minutes = _twoDigits(snapshot.data!.inMinutes);
          final seconds = _twoDigits(snapshot.data!.inSeconds);

          return Text('$minutes:$seconds');
        } else {
          final minutes = _twoDigits(totalDuration.inMinutes);
          final seconds = _twoDigits(totalDuration.inSeconds);

          return Text('$minutes:$seconds');
        }
      },
    );
  }

  Widget _audioWaveSlider(Duration totalDuration) {
    return StreamBuilder<int?>(
      initialData: 0,
      stream: widget.player.currentIndexStream,
      builder: (context, snapshot) {
        final currentIndex = snapshot.data;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: AudioWaveSlider(
              bars: _audioBars(),
              progressStream: widget.player.positionStream.map((duration) =>
                  _sliderValue(duration, totalDuration, currentIndex)),
              onChangeStart: (val) {
                setState(() {
                  _seeking = true;
                });
              },
              onChanged: (val) {
                widget.player.pause();
                widget.player.seek(
                  totalDuration * val,
                  index: widget.index ?? 0,
                );
              },
              onChangeEnd: () {
                setState(() {
                  _seeking = false;
                });
              },
            ),
          ),
        );
      },
    );
  }

  double _sliderValue(
    Duration duration,
    Duration totalDuration,
    int? currentIndex,
  ) {
    if (widget.index != currentIndex) {
      return 0;
    } else {
      return min(duration.inMicroseconds / totalDuration.inMicroseconds, 1);
    }
  }

  /// Docs
  Future<void> _play() {
    if (widget.index == widget.player.currentIndex) {
      return widget.player.play();
    } else {
      widget.player.seek(Duration.zero, index: widget.index);
      return widget.player.play();
    }
  }

  /// Docs
  Future<void> _pause() {
    return widget.player.pause();
  }

  String _twoDigits(int value) {
    return value.remainder(60).toString().padLeft(2, '0');
  }
}
