import 'package:audio_session/audio_session.dart';
import 'package:family_chatify/models/chat_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import '../../../utils/colors.dart';
import '../../chat_page.dart';


class ChatPlayerItemView extends StatefulWidget {
  ChatMessage item;
  bool isOwn;

  ChatPlayerItemView(this.item, {Key? key, required this.isOwn}) : super(key: key);

  @override
  _ChatPlayerItemViewState createState() => _ChatPlayerItemViewState();
}

class _ChatPlayerItemViewState extends State<ChatPlayerItemView> {
  String audioDuration = "";
  bool _enabled = false;
  late double seconds, minuits, hour;

  Color? color;
  double progress = 0.0;
  double maxProgress = 0.0;

  Future<void> _init() async {
    // Inform the operating system of our app's audio attributes etc.
    // We pick a reasonable default for an app that plays speech.
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    // Listen to errors during playback.
    ChatPage.player.positionStream.listen((event) {
      if(mounted) {
        setState(() {
          progress = ChatPage.activeAudio == widget.item.content ? event.inSeconds.toDouble() : 0.0;
        });
      }
    });

    ChatPage.player.durationStream.listen((event) {
      if(mounted) {
        setState(() {
          maxProgress = ChatPage.activeAudio == widget.item.content ? event?.inSeconds.toDouble() ?? 0 : 0.0;
        });
      }
    });

    ChatPage.player.processingStateStream.listen((event) {
      if(mounted){
      setState(() {
        _buildPausePlayAction();
      });}
    });

    ChatPage.player.playbackEventStream.listen((event) {},
        onError: (Object e, StackTrace stackTrace) {
      print('A stream error occurred: $e');
    });
    // Try to load audio from a source and catch any errors.
    // try {
    //   await ChatPage.player.setAudioSource(
    //       AudioSource.uri(Uri.parse(HOST_VOICE + (widget.item.voise ?? ""))));
    // } catch (e) {
    //   print("Error loading audio source: $e");
    // }
  }

  @override
  void initState() {
    super.initState();
    if(widget.isOwn){
      color = Color.fromRGBO(51, 49, 68, 1.0);
    } else {
      color = BLUE;
    }
    // WidgetsBinding.instance?.addObserver(this);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.black,
    ));
    _init();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: _buildPausePlayAction()),
            Stack(
              children: [
                Positioned(child: _buildDuration(), right: 20),
                Slider(
                  divisions: 1000,
                  activeColor: color,
                  inactiveColor: Colors.grey.shade300,
                  onChanged: (value) {
                    setState(() {
                      progress = value;
                      ChatPage.player.seek(Duration(seconds: value.toInt()));
                      ChatPage.player.play();
                    });
                  },
                  onChangeStart: (value) {},
                  onChangeEnd: (value) {},
                  value: progress,
                  min: 0,
                  max: maxProgress,
                )
              ],
            )
          ],
        ),
      ],
    );
  }

  Widget _buildPausePlayAction() {
    final processingState = ChatPage.activeAudio == widget.item.content
        ? ChatPage.player.processingState
        : null;
    final playing = ChatPage.activeAudio == widget.item.content
        ? ChatPage.player.playing
        : null;
    if (processingState == ProcessingState.loading ||
        processingState == ProcessingState.buffering) {
      return Container(
        width: 45,
        height: 45,
        child: CircularProgressIndicator(color: color),
      );

    } else if (playing != true) {
      return InkWell(
        onTap: () async {
          try {
            await ChatPage.player.stop();
            ChatPage.activeAudio = widget.item.content ?? "";
            await ChatPage.player.setAudioSource(AudioSource.uri(Uri.parse(widget.item.content)));
            await ChatPage.player.play();
          } catch (e) {
            print("Error loading audio source: $e");
          }
        },
        child: Image.asset("assets/images/play_button.png", color: color, width: 45, height: 45),
      );
    } else {
      return InkWell(
        onTap: () async {
          try {
            await ChatPage.player.pause();
          } catch (e) {
            print("Error loading audio source: $e");
          }
        },
        child: Image.asset("assets/images/pause_button.png", color: color, width: 45, height: 45),
      );
    }
  }

  Widget _buildDuration() {
    return Container(
        child: Text(
      "${convertedDuration(progress)} / ${convertedDuration(maxProgress)}",
      style: TextStyle(fontFamily: "regular", color: WHITE , fontSize: 12.0),
    ));
  }

  String convertedDuration(double seconds) {
    seconds = (seconds) % 60;
    minuits = (seconds / 60) % 60;
    // hour = seconds / (60 * 60);

    // int hours = hour.toInt();
    int min = minuits.toInt();
    int sec = seconds.toInt();

    audioDuration = (min < 10 ? "0$min" : min.toString()) + ":" + (sec < 10 ? "0$sec" : sec.toString());

    return audioDuration;
  }

  @override
  void dispose() {
    super.dispose();
  }
}
