import 'package:flutter/material.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';
import 'package:tuotu/common/config.dart';
import 'package:tuotu/common/global_variable.dart';


//自定义一个 StatefulWidget 来封装 StepProgressIndicator
// ignore: must_be_immutable
class StepProgress extends StatefulWidget {

  String ip = "";

  StepProgress(this.ip,{super.key});

  @override
  // ignore: no_logic_in_create_state
  State<StepProgress> createState() => _StepProgressState(ip);
}

class _StepProgressState extends State<StepProgress> {

  String _ip;
  
  _StepProgressState(this._ip);

  @override
  Widget build(BuildContext context) {
    return StepProgressIndicator(
      fallbackLength: remoteDevicesWidgetMaxSizeWidth,
      totalSteps: 100,
      currentStep: remoteDevicesData[_ip]!["progress"],
      size: 32,        //进度指示条的高度
      padding: 0,
      selectedColor: Colors.transparent,
      unselectedColor: Colors.grey,
      //2024-01-10
      //TODO  Radius.circular doesn't work very well when the Rect width is very small,so don't use Radius.circular property temporarily
      //roundedEdges: const Radius.circular(16),
    );
  }
}