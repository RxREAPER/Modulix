import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modulix/services/alarm_clock_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('com.modulix.app/alarm_clock');
  final List<MethodCall> log = <MethodCall>[];

  setUp(() {
    log.clear();
    AlarmClockService.instance.forcePlatformChannelInTests = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      log.add(methodCall);
      switch (methodCall.method) {
        case 'canScheduleExactAlarms':
          return true;
        case 'scheduleAlarmClock':
          return true;
        case 'cancelAlarmClock':
          return true;
        case 'openExactAlarmSettings':
          return true;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    AlarmClockService.instance.forcePlatformChannelInTests = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('canScheduleExactAlarms calls native channel and returns true', () async {
    final result = await AlarmClockService.instance.canScheduleExactAlarms();
    expect(result, isTrue);
    expect(log.single.method, 'canScheduleExactAlarms');
  });

  test('scheduleAlarm passes future timestamp, title, and isBreak correctly', () async {
    final futureTime = DateTime.now().add(const Duration(minutes: 25));
    final result = await AlarmClockService.instance.scheduleAlarm(
      targetTime: futureTime,
      title: 'Nephrology High-Yield',
      isBreak: false,
    );

    expect(result, isTrue);
    expect(log.single.method, 'scheduleAlarmClock');
    final Map<dynamic, dynamic> args = log.single.arguments as Map<dynamic, dynamic>;
    expect(args['triggerMs'], futureTime.millisecondsSinceEpoch);
    expect(args['title'], 'Nephrology High-Yield');
    expect(args['isBreak'], isFalse);
  });

  test('scheduleAlarm skips past timestamp and returns false without invoking channel', () async {
    final pastTime = DateTime.now().subtract(const Duration(seconds: 10));
    final result = await AlarmClockService.instance.scheduleAlarm(
      targetTime: pastTime,
      title: 'Past Session',
      isBreak: false,
    );

    expect(result, isFalse);
    expect(log.isEmpty, isTrue);
  });

  test('cancelAlarm calls native cancelAlarmClock channel', () async {
    final result = await AlarmClockService.instance.cancelAlarm();
    expect(result, isTrue);
    expect(log.single.method, 'cancelAlarmClock');
  });

  test('openExactAlarmSettings calls native openExactAlarmSettings channel', () async {
    final result = await AlarmClockService.instance.openExactAlarmSettings();
    expect(result, isTrue);
    expect(log.single.method, 'openExactAlarmSettings');
  });
}
