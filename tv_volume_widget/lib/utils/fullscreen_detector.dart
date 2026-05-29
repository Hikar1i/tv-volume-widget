import 'dart:async';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

class FullscreenDetector {
  static final FullscreenDetector _instance = FullscreenDetector._();
  factory FullscreenDetector() => _instance;
  FullscreenDetector._();

  Timer? _timer;
  bool _wasFullscreen = false;
  final _controller = StreamController<bool>.broadcast();

  Stream<bool> get onFullscreenChanged => _controller.stream;
  bool get isFullscreen => _wasFullscreen;

  void start({Duration interval = const Duration(seconds: 2)}) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => _check());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void _check() {
    try {
      final isFs = _isForegroundWindowFullscreen();
      if (isFs != _wasFullscreen) {
        _wasFullscreen = isFs;
        _controller.add(isFs);
      }
    } catch (_) {
      // Ignore errors from Win32 API calls
    }
  }

  bool _isForegroundWindowFullscreen() {
    final hwnd = GetForegroundWindow();
    if (hwnd == 0) return false;

    // Get window class name to skip our own window
    final classNameBuffer = calloc.allocate<Utf16>(512);
    final length = GetClassName(hwnd, classNameBuffer, 256);
    if (length > 0) {
      final cls = classNameBuffer.toDartString();
      calloc.free(classNameBuffer);
      if (cls.contains('FLUTTER_RUNNER_WIN32_WINDOW')) return false;
    } else {
      calloc.free(classNameBuffer);
    }

    // Get window rect
    final windowRect = calloc<RECT>();
    GetWindowRect(hwnd, windowRect);

    // Get the monitor this window is on
    final monitor = MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST);

    final monitorInfo = calloc<MONITORINFO>();
    monitorInfo.ref.cbSize = sizeOf<MONITORINFO>();
    GetMonitorInfo(monitor, monitorInfo);

    // Compare: if window rect matches monitor work area, it's fullscreen
    final isFullscreen =
        windowRect.ref.left <= monitorInfo.ref.rcMonitor.left &&
        windowRect.ref.top <= monitorInfo.ref.rcMonitor.top &&
        windowRect.ref.right >= monitorInfo.ref.rcMonitor.right &&
        windowRect.ref.bottom >= monitorInfo.ref.rcMonitor.bottom;

    calloc.free(windowRect);
    calloc.free(monitorInfo);

    return isFullscreen;
  }

  void dispose() {
    stop();
    _controller.close();
  }
}
