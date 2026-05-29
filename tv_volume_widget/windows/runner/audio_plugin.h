#ifndef AUDIO_PLUGIN_H_
#define AUDIO_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>

class AudioPlugin {
 public:
  static void RegisterWithRegistrar(
      FlutterDesktopPluginRegistrarRef registrar);

  virtual ~AudioPlugin();

 private:
  AudioPlugin(flutter::PluginRegistrarWindows* registrar);

  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // Audio device methods
  flutter::EncodableValue GetOutputDevices();
  flutter::EncodableValue GetDefaultDevice();
  bool SetDefaultDevice(const std::string& device_id);
  double GetVolume(const std::string& device_id);
  bool SetVolume(const std::string& device_id, double volume);
  bool GetMute(const std::string& device_id);
  bool SetMute(const std::string& device_id, bool mute);

  // Helper
  std::string GetDeviceType(int form_factor, const std::wstring& name);

  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
};

#endif  // AUDIO_PLUGIN_H_
