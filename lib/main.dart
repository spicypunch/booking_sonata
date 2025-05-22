import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('Firebase 초기화 시작');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('Firebase 초기화 완료');
  runApp(
    MaterialApp(
      home: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isBooked = false;

  @override
  void initState() {
    super.initState();
    _checkBooking();
  }

  Future<void> _checkBooking() async {
    final booked = await isBookedNow();
    setState(() {
      _isBooked = booked;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(250, 80),
            textStyle: const TextStyle(fontSize: 24),
          ),
          child: const Text('날짜와 시간 선택'),
          onPressed: _isBooked
              ? null
              : () async {
                  print('날짜 선택 시작');
                  DateTime? startDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  print('날짜 선택 완료: $startDate');
                  if (startDate == null) return;

                  TimeOfDay? startTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (startTime == null) return;

                  DateTime? endDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (endDate == null) return;

                  TimeOfDay? endTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (endTime == null) return;

                  final startDateTime = DateTime(
                    startDate.year,
                    startDate.month,
                    startDate.day,
                    startTime.hour,
                    startTime.minute,
                  );
                  final endDateTime = DateTime(
                    endDate.year,
                    endDate.month,
                    endDate.day,
                    endTime.hour,
                    endTime.minute,
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '선택: '
                        '${startDateTime.toString()} - ${endDateTime.toString()}',
                      ),
                    ),
                  );

                  await saveBooking(startDateTime, endDateTime);
                  await _checkBooking();
                },
        ),
      ),
    );
  }
}

Future<void> saveBooking(DateTime start, DateTime end) async {
  try {
    final ref = FirebaseDatabase.instance.ref('booking');
    await ref.set({
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
    });
    print('예약 데이터 저장 성공');
  } catch (e) {
    print('예약 데이터 저장 실패: $e');
  }
}

Future<bool> isBookedNow() async {
  final ref = FirebaseDatabase.instance.ref('booking');
  final snapshot = await ref.get();
  if (!snapshot.exists) return false;

  final data = snapshot.value as Map;
  final start = DateTime.parse(data['start']);
  final end = DateTime.parse(data['end']);
  final now = DateTime.now();

  return (now.isAtSameMomentAs(start) || now.isAfter(start)) &&
      (now.isAtSameMomentAs(end) || now.isBefore(end));
}
