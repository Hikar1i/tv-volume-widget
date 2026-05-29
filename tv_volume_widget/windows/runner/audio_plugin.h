#ifndef AUDIO_PLUGIN_H_
#define AUDIO_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>

class AudioPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  AudioPlugin(flutter::PluginRegistrarWindows* registrar);

  virtual ~AudioPlugin();

 private:
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

  flutter::PluginRegistrarWindows* registrar_;
};

#endif  // AUDIO_PLUGIN_H_
