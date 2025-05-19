// import 'package:flutter/material.dart';
// import 'dart:async';

// class Home extends StatelessWidget {
//   const Home({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: <Widget>[
//             Text('$timercho'),
//             ElevatedButton(
//               onPressed: () {
//                 if (!_timer.isActive) {
//                   timercho = 10;
//                   startTimer();
//                 }
//               },
//               child: Text(_timer.isActive ? '타이머 실행 중' : '타이머 시작')
//             )
//           ],
//         ),
//     );
//   }
// }
import 'package:flutter/material.dart';

class test000 extends StatefulWidget {
  // const test000({super.key, required this.title});

  // final String title;

  @override
  State<test000> createState() => test000State();
}

class test000State extends State<test000> {
  // const test000State({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: Text('test000'),
      ),
    );
  }
}