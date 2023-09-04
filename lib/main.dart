import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final bool _isMouse = kIsWeb || (!(Platform.isAndroid || Platform.isIOS));

void main() {
  runApp(const PrecisionApp());
}

class PrecisionApp extends StatelessWidget {
  const PrecisionApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    return MaterialApp(
      title: 'Precision',
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(primary: Color(0xFF5EDAB8)),
        useMaterial3: true,
      ),
      home: const GameWidget(title: 'PRECISION'),
    );
  }
}

class GameWidget extends StatefulWidget {
  const GameWidget({super.key, required this.title});

  final String title;

  @override
  State<GameWidget> createState() => _GameWidgetState();
}

class _GameWidgetState extends State<GameWidget> {
  static final int _maxMs = _isMouse ? 2000 : 6000;
  static final int _recoverMs = _isMouse ? 1300 : 2500;
  static const _msInterval = 50;

  double _btnSize = 20;

  int _leftMs = _maxMs;
  bool _isStarted = false;
  Timer? _timer;

  _State _state = _State.GAMING;
  int _x = 500, _y = 500;

  final List<int> _delays = [];
  int _lastTicks = DateTime.now().millisecondsSinceEpoch;
  int _lastDelay = 0;
  int _score = 0;

  void _startNewTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: _msInterval), (timer) {
      setState(() {
        final left = _leftMs -= _msInterval;
        if (left <= 0) {
          _stopTimer();
          _state = _State.FAILED;
        }
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  void _randomizeBtnPosition() {
    _btnSize = (10.0 + (Random().nextDouble() * 15));
    _x = Random().nextInt(1000) + 10;
    _y = Random().nextInt(1000) + 10;
  }

  void _onRestartPressed() {
    setState(() {
      _state = _State.GAMING;
      _score = 0;
      _lastDelay = 0;
      _leftMs = _maxMs;
      _lastTicks = DateTime.now().millisecondsSinceEpoch;
      _isStarted = false;
      _stopTimer();
      _x = 500;
      _y = 500;
    });
  }

  void _onButtonPressed() {
    final now = DateTime.now().millisecondsSinceEpoch;

    final isFirst = !_isStarted;
    final delay = isFirst ? 0 : now - _lastTicks;

    if (isFirst) {
      _isStarted = true;
      _startNewTimer();
    } else {
      _delays.add(delay);
    }

    setState(() {
      _score += (50 - _btnSize).toInt().clamp(1, 50);
      _leftMs = (_leftMs + _recoverMs).clamp(0, _maxMs);

      if (!isFirst) {
        _lastDelay = delay;
      }
      _lastTicks = now;
      _randomizeBtnPosition();
    });
  }

  void _onBackgroundPressed() {
    if (_isStarted) {
      setState(() {
        _stopTimer();
        _state = _State.FAILED;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final primaryColor = theme.colorScheme.primary;

    Widget body;
    switch (_state) {
      // region 게임 화면
      case _State.GAMING:
        body = InkWell(
          splashColor: Colors.black,
          enableFeedback: false,
          onTapDown: (_) => _onBackgroundPressed,
          onTap: _onBackgroundPressed,
          onLongPress: _onBackgroundPressed,
          child: Column(
            children: [
              LinearProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
                value: _leftMs.toDouble() / _maxMs,
              ),
              Flexible(
                  flex: _x,
                  child: Container(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text.rich(TextSpan(children: [
                            TextSpan(text: 'DELAY ', style: TextStyle(color: primaryColor)),
                            TextSpan(text: '${_lastDelay}ms'),
                          ])),
                          Text.rich(TextSpan(children: [
                            TextSpan(text: 'X ', style: TextStyle(color: primaryColor)),
                            TextSpan(text: '$_x'),
                            TextSpan(text: ' / ', style: TextStyle(color: Colors.grey)),
                            TextSpan(text: 'Y ', style: TextStyle(color: primaryColor)),
                            TextSpan(text: '$_y'),
                          ])),
                        ],
                      ),
                    ),
                  )),
              Row(
                children: [
                  Flexible(flex: _y, child: Container()),
                  SizedBox(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: _btnSize,
                          height: _btnSize,
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: InkWell(
                            splashColor: primaryColor,
                            onTap: _onButtonPressed,
                            child: Icon(Icons.close, size: _btnSize),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text('${_btnSize.toInt()}', style: TextStyle(color: primaryColor)),
                      ],
                    ),
                  ),
                  Flexible(flex: 1020 - _y, child: Container()),
                ],
              ),
              !_isStarted
                  ? Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Column(
                        children: [
                          Text(
                            '위 버튼을 정밀하게 터치하여 시작합니다.',
                            style: TextStyle(color: primaryColor),
                          ),
                          Text(
                            '숫자는 버튼의 크기를 나타냅니다.',
                            style: TextStyle(color: primaryColor),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(),
              Flexible(flex: 1020 - _x, child: Container()),
            ],
          ),
        );
        break;
      // endregion
      // region 점수 화면
      case _State.FAILED:
        final count = _delays.length;
        int totalDelay = 0;
        for (final d in _delays) {
          totalDelay += d;
        }
        final averageDelay =
            (count == 0 || totalDelay <= 0) ? 9999 : (totalDelay.toDouble() / count);

        body = Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                flex: 10,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('점수'),
                          Text(
                            '$_score',
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 120,
                            ),
                          ),
                        ],
                      ),
                      Text.rich(TextSpan(
                        children: [
                          TextSpan(text: '성공 ', style: TextStyle(color: primaryColor)),
                          TextSpan(text: '${count}회'),
                        ],
                        style: TextStyle(fontSize: 20),
                      )),
                      Text.rich(TextSpan(
                        children: [
                          TextSpan(text: '평균 속 ', style: TextStyle(color: primaryColor)),
                          TextSpan(text: '${averageDelay.toInt()}ms'),
                        ],
                        style: TextStyle(fontSize: 20),
                      )),
                    ],
                  ),
                ),
              ),
              Flexible(
                  flex: 4,
                  child: Column(
                    children: [
                      MaterialButton(
                        onPressed: _onRestartPressed,
                        color: Theme.of(context).colorScheme.primaryContainer,
                        child: const Text('RESTART'),
                      ),
                      SizedBox(height: 50),
                      const Text("배경이 터치되었거나 시간이 초과되었습니다."),
                    ],
                  ))
            ],
          ),
        );
        break;
      // endregion
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(
          widget.title,
          style: TextStyle(color: primaryColor),
        ),
      ),
      body: body,
    );
  }
}

enum _State {
  GAMING,
  FAILED,
}
