// lib/services/device_info_service.dart
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:echosync/data/device.dart';
import 'package:network_info_plus/network_info_plus.dart';

class DeviceInfoService {
  final NetworkInfo _networkInfo = NetworkInfo();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  Future<String> get deviceIP async {
    return (await _networkInfo.getWifiIP()) ?? 'counter';
  }

  Future<String> get deviceName async {
    switch (Platform.operatingSystem) {
      case 'android':
        return (await _deviceInfo.androidInfo).model;
      case 'ios':
        return (await _deviceInfo.iosInfo).utsname.machine;
      default:
        return '21X';
    }
  }

  Future<Device> get deviceInfo async {
    return Device(ip: await deviceIP, name: await deviceName);
  }
}
