import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:record/record.dart';
import '../../../../../../utils/colors.dart';
import '../../createfoldervoice/create_folder.dart';
import '../globals.dart';
import 'flow_shader.dart';
import 'lottie_animation.dart';

class RecordButton extends StatefulWidget {
  Function voicePath;
  Function edit;

  RecordButton( {
    Key? key,
    required this.voicePath,
    required this.edit,
    required this.animController,
  }) : super(key: key);

  final AnimationController animController;

  @override
  State<RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<RecordButton> {
  static const double size = 55;

  final double lockerHeight = 200;
  double timerWidth = 0;

  late Animation<double> buttonScaleAnimation;
  late Animation<double> timerAnimation;
  late Animation<double> lockerAnimation;
  bool permission = false;

  DateTime? startTime;
  Timer? timer;
  String recordDuration = "00:00";
  Record? record;

  bool isLocked = false;
  bool showLottie = false;

  @override
  void initState() {
    super.initState();
    buttonScaleAnimation = Tween<double>(begin: 1, end: 2).animate(
      CurvedAnimation(
        parent: widget.animController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticInOut),
      ),
    );
    widget.animController.addListener(() {
      if(mounted) {
        setState(() {});
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    timerWidth =
        MediaQuery.of(context).size.width - 2 * Globals.defaultPadding - 4;
    timerAnimation =
        Tween<double>(begin: timerWidth + Globals.defaultPadding, end: 0)
            .animate(
      CurvedAnimation(
        parent: widget.animController,
        curve: const Interval(0.2, 1, curve: Curves.easeIn),
      ),
    );
    lockerAnimation =
        Tween<double>(begin: lockerHeight + Globals.defaultPadding, end: 0)
            .animate(
      CurvedAnimation(
        parent: widget.animController,
        curve: const Interval(0.2, 1, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    timer = null;
    record?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        lockSlider(),
        cancelSlider(),
        audioButton(),
        if (isLocked) timerLocked(),
      ],
    );
  }

  Widget lockSlider() {
    return Positioned(
      bottom: -lockerAnimation.value,
      child: Container(
        height: lockerHeight,
        width: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Globals.borderRadius),
          color: CYAN,
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const FaIcon(FontAwesomeIcons.lock,
                size: 20, color: WHITE),
            const SizedBox(height: 8),
            FlowShader(
              direction: Axis.vertical,
              child: Column(
                children: const [
                  Icon(Icons.keyboard_arrow_up),
                  Icon(Icons.keyboard_arrow_up),
                  Icon(Icons.keyboard_arrow_up),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget cancelSlider() {
    return Positioned(
      right: -timerAnimation.value,
      child: Container(
        height: size,
        width: timerWidth,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Globals.borderRadius),
          color: CYAN,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              showLottie ? const LottieAnimation() : Text(recordDuration),
              const SizedBox(width: size),
              FlowShader(
                child: Row(
                  children:  [
                    Icon(Icons.keyboard_arrow_left),
                    Text("Slide to cancel")
                  ],
                ),
                duration: const Duration(seconds: 3),
                flowColors: const [Colors.white, Colors.grey],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget timerLocked() {
    return Container(
      height: size,
      width: timerWidth,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Globals.borderRadius),
        color: CYAN,
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 8, right: 8),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              Text(recordDuration),
              FlowShader(
                child: const Text("Tap lock to stop"),
                duration: const Duration(seconds: 3),
                flowColors: const [Colors.white, Colors.grey],
              ),
              Row(
                children: [
                  IconButton(
                      onPressed: () async {
                        Vibrate.feedback(FeedbackType.success);
                        timer?.cancel();
                        timer = null;
                        startTime = null;
                        recordDuration = "00:00";

                        var filePath = await Record().stop();
                        debugPrint("Cancelled recording");
                        File(filePath!).delete();
                        debugPrint("Deleted $filePath");
                        debugPrint("Stop Record");
                        setState(() {
                          isLocked = false;
                        });
                        widget.edit(true);
                      },
                      icon: const Icon(
                        Icons.stop,
                        size: 30,
                        color: Colors.red,
                      )),
                  IconButton(
                      onPressed: () async {
                        Vibrate.feedback(FeedbackType.success);
                        timer?.cancel();
                        timer = null;
                        startTime = null;
                        recordDuration = "00:00";

                        var filePath = await Record().stop();
                        widget.voicePath(filePath);
                        debugPrint("Send Record");
                        setState(() {
                          isLocked = false;
                        });
                        widget.edit(true);
                      },
                      icon: const Icon(
                        Icons.send,
                        size: 24,
                        color: WHITE,
                      )),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget audioButton() {
    return GestureDetector(
      child: Transform.scale(
        scale: buttonScaleAnimation.value,
        child: Container(
          child: Icon(Icons.mic, color: Colors.white),
          height: size,
          width: size,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: CYAN,
          ),
        ),
      ),
      onLongPressDown: (_) async {
        debugPrint("onLongPressDown");
        if (await Record().hasPermission()) {
          widget.animController.forward();
          widget.edit(false);
        }
      },
      onLongPressEnd: (details) async {
        debugPrint("onLongPressEnd");
        if (await Record().hasPermission()) {
          if (isCancelled(details.localPosition, context)) {
            Vibrate.feedback(FeedbackType.heavy);

            timer?.cancel();
            timer = null;
            startTime = null;
            recordDuration = "00:00";

            setState(() {
              showLottie = true;
            });

            Timer(const Duration(milliseconds: 1440), () async {
              widget.animController.reverse();
              debugPrint("Cancelled recording");
              var filePath = await record?.stop();
              debugPrint(filePath);
              File(filePath!).delete();
              debugPrint("Deleted $filePath");
              showLottie = false;
            });
            widget.edit(true);
          } else if (checkIsLocked(details.localPosition)) {
            widget.animController.reverse();

            Vibrate.feedback(FeedbackType.heavy);
            debugPrint("Locked recording");
            debugPrint(details.localPosition.dy.toString());
            debugPrint("Locked recording");
            setState(() {
              isLocked = true;
            });
            widget.edit(false);
          } else {
            widget.animController.reverse();

            Vibrate.feedback(FeedbackType.success);

            timer?.cancel();
            timer = null;
            startTime = null;
            recordDuration = "00:00";

            var filePath = await Record().stop();
            debugPrint(filePath);
            widget.voicePath(filePath);
            widget.edit(true);
          }
        }
      },
      onLongPressCancel: () async {
        debugPrint("onLongPressCancel");
        if (await Record().hasPermission()) {
          widget.animController.reverse();
          widget.edit(true);
        }
      },
      onLongPress: () async {
        debugPrint("onLongPress");
        if (await Record().hasPermission()) {
          widget.animController.forward();
          Vibrate.feedback(FeedbackType.success);
          record = Record();
          await record?.start(
            path: "${await CreateFolder().createFolderInAppDocDir("record")}audio_${DateTime.now().millisecondsSinceEpoch}.mp4",
            encoder: AudioEncoder.AAC,
            bitRate: 128000,
            samplingRate: 44100,
          );
          startTime = DateTime.now();
          timer = Timer.periodic(const Duration(seconds: 1), (_) {
            final minDur = DateTime.now().difference(startTime!).inMinutes;
            final secDur = DateTime.now().difference(startTime!).inSeconds % 60;
            String min = minDur < 10 ? "0$minDur" : minDur.toString();
            String sec = secDur < 10 ? "0$secDur" : secDur.toString();
            setState(() {
              recordDuration = "$min:$sec";
            });
          });
          widget.edit(false);
        }
      },
    );
  }

  bool checkIsLocked(Offset offset) {
    return (offset.dy < -35);
  }

  bool isCancelled(Offset offset, BuildContext context) {
    return (offset.dx < -(MediaQuery.of(context).size.width * 0.2));
  }
}