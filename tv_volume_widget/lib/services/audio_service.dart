import 'dart:async';
import 'package:flutter/services.dart';
import '../models/audio_device.dart';

class AudioService {
  static const _channel = MethodChannel('com.tvvolumewidget/audio');

  static final AudioService _instance = AudioService._();
  factory AudioService() => _instance;
  AudioService._();

  Future<List<AudioDevice>> getOutputDevices() async {
    try {
      final result = await _channel.invokeMethod('getOutputDevices');
      if (result is List) {
        return result
            .map((e) => AudioDevice.fromMap(e as Map<dynamic, dynamic>))
            .toList();
      }
    } catch (e) {
      print('Error getting output devices: $e');
    }
    return [];
  }

  Future<AudioDevice?> getDefaultDevice() async {
    try {
      final result = await _channel.invokeMethod('getDefaultDevice');
      if (result is Map) {
        return AudioDevice.fromMap(result);
      }
    } catch (e) {
      print('Error getting default device: $e');
    }
    return null;
  }

  Future<bool> setDefaultDevice(AudioDevice device) async {
    try {
      final result = await _channel.invokeMethod('setDefaultDevice', {
        'deviceId': device.id,
      });
      return result == true;
    } catch (e) {
      print('Error setting default device: $e');
      return false;
    }
  }

  Future<double> getVolume([String deviceId = '']) async {
    try {
      final result = await _channel.invokeMethod('getVolume', {
        'deviceId': deviceId,
      });
      if (result is double) return result;
      if (result is int) return result.toDouble();
    } catch (e) {
      print('Error getting volume: $e');
    }
    return 0.0;
  }

  Future<bool> setVolume(double volume, [String deviceId = '']) async {
    try {
      final result = await _channel.invokeMethod('setVolume', {
        'deviceId': deviceId,
        'volume': volume.clamp(0.0, 1.0),
      });
      return result == true;
    } catch (e) {
      print('Error setting volume: $e');
      return false;
    }
  }

  Future<bool> getMute([String deviceId = '']) async {
    try {
      final result = await _channel.invokeMethod('getMute', {
        'deviceId': deviceId,
      });
      return result == true;
    } catch (e) {
      print('Error getting mute: $e');
      return false;
    }
  }

  Future<bool> setMute(bool mute, [String deviceId = '']) async {
    try {
      final result = await _channel.invokeMethod('setMute', {
        'deviceId': deviceId,
        'mute': mute,
      });
      return result == true;
    } catch (e) {
      print('Error setting mute: $e');
      return false;
    }
  }
}
