#include "audio_plugin.h"

#include <windows.h>
#include <mmdeviceapi.h>
#include <endpointvolume.h>
#include <functiondiscoverykeys_devpkey.h>
#include <comdef.h>
#include <propsys.h>
#include <propvarutil.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>
#include <codecvt>
#include <locale>

#pragma comment(lib, "ole32.lib")
#pragma comment(lib, "propsys.lib")
#pragma comment(lib, "uuid.lib")

// IPolicyConfig GUID for Windows 10/11
// {870AF99C-171D-4F9E-AF0D-E63DF40C2BC9}
static const GUID CLSID_PolicyConfigClient =
    {0x870AF99C, 0x171D, 0x4F9E, {0xAF, 0x0D, 0xE6, 0x3D, 0xF4, 0x0C, 0x2B, 0xC9}};

static const GUID IID_IPolicyConfig =
    {0x870AF99C, 0x171D, 0x4F9E, {0xAF, 0x0D, 0xE6, 0x3D, 0xF4, 0x0C, 0x2B, 0xC9}};

// IPolicyConfig vtable interface (Windows 10/11)
MIDL_INTERFACE("870AF99C-171D-4F9E-AF0D-E63DF40C2BC9")
IPolicyConfig : public IUnknown {
 public:
  virtual HRESULT STDMETHODCALLTYPE GetMixFormat(
      PCWSTR, WAVEFORMATEX**) = 0;
  virtual HRESULT STDMETHODCALLTYPE GetDeviceFormat(
      PCWSTR, INT, WAVEFORMATEX**) = 0;
  virtual HRESULT STDMETHODCALLTYPE ResetDeviceFormat(PCWSTR) = 0;
  virtual HRESULT STDMETHODCALLTYPE SetDeviceFormat(
      PCWSTR, WAVEFORMATEX*, WAVEFORMATEX*) = 0;
  virtual HRESULT STDMETHODCALLTYPE GetProcessingPeriod(
      PCWSTR, INT, PINT64, PINT64) = 0;
  virtual HRESULT STDMETHODCALLTYPE SetProcessingPeriod(
      PCWSTR, PINT64) = 0;
  virtual HRESULT STDMETHODCALLTYPE GetShareMode(
      PCWSTR, struct DeviceShareMode*) = 0;
  virtual HRESULT STDMETHODCALLTYPE SetShareMode(
      PCWSTR, struct DeviceShareMode*) = 0;
  virtual HRESULT STDMETHODCALLTYPE GetPropertyValue(
      PCWSTR, const PROPERTYKEY&, PROPVARIANT*) = 0;
  virtual HRESULT STDMETHODCALLTYPE SetPropertyValue(
      PCWSTR, const PROPERTYKEY&, PROPVARIANT&) = 0;
  virtual HRESULT STDMETHODCALLTYPE SetDefaultEndpoint(
      __in PCWSTR wszDeviceId, __in ERole eRole) = 0;
  virtual HRESULT STDMETHODCALLTYPE SetEndpointVisibility(
      PCWSTR, INT) = 0;
};

// EndpointFormFactor enum
enum EndpointFormFactor {
  RemoteNetworkDevice = 0,
  Speakers = 1,
  LineLevel = 2,
  Headphones = 3,
  Microphone = 4,
  Headset = 5,
  Handset = 6,
  UnknownDigitalPassthrough = 7,
  SPDIF = 8,
  DigitalAudioDisplayDevice = 9,
  UnknownFormFactor = 10,
};

// Convert wide string to UTF-8
static std::string WideStringToUtf8(const std::wstring& wide) {
  if (wide.empty()) return std::string();
  int size_needed = WideCharToMultiByte(CP_UTF8, 0, &wide[0], (int)wide.size(),
                                        NULL, 0, NULL, NULL);
  std::string strTo(size_needed, 0);
  WideCharToMultiByte(CP_UTF8, 0, &wide[0], (int)wide.size(), &strTo[0],
                      size_needed, NULL, NULL);
  return strTo;
}

// Convert UTF-8 to wide string
static std::wstring Utf8ToWideString(const std::string& utf8) {
  if (utf8.empty()) return std::wstring();
  int size_needed = MultiByteToWideChar(CP_UTF8, 0, &utf8[0], (int)utf8.size(),
                                        NULL, 0);
  std::wstring wstrTo(size_needed, 0);
  MultiByteToWideChar(CP_UTF8, 0, &utf8[0], (int)utf8.size(), &wstrTo[0],
                      size_needed);
  return wstrTo;
}

// Get string from property store
static std::wstring GetPropertyStringValue(IPropertyStore* store,
                                            REFPROPERTYKEY key) {
  PROPVARIANT var;
  PropVariantInit(&var);
  std::wstring result;
  if (SUCCEEDED(store->GetValue(key, &var))) {
    if (var.vt == VT_LPWSTR && var.pwszVal) {
      result = var.pwszVal;
    }
    PropVariantClear(&var);
  }
  return result;
}

// Get uint32 from property store
static UINT GetPropertyUint32Value(IPropertyStore* store,
                                    REFPROPERTYKEY key) {
  PROPVARIANT var;
  PropVariantInit(&var);
  UINT result = 0;
  if (SUCCEEDED(store->GetValue(key, &var))) {
    if (var.vt == VT_UI4) {
      result = var.ulVal;
    }
    PropVariantClear(&var);
  }
  return result;
}

void AudioPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "com.tvvolumewidget/audio",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<AudioPlugin>(registrar);

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto& call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

AudioPlugin::AudioPlugin(flutter::PluginRegistrarWindows* registrar)
    : registrar_(registrar) {}

AudioPlugin::~AudioPlugin() {}

void AudioPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const std::string& method = method_call.method_name();

  if (method == "getOutputDevices") {
    result->Success(GetOutputDevices());
  } else if (method == "getDefaultDevice") {
    result->Success(GetDefaultDevice());
  } else if (method == "setDefaultDevice") {
    const auto* args = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (args) {
      auto it = args->find(flutter::EncodableValue("deviceId"));
      if (it != args->end()) {
        const std::string* device_id = std::get_if<std::string>(&it->second);
        if (device_id) {
          bool success = SetDefaultDevice(*device_id);
          result->Success(flutter::EncodableValue(success));
          return;
        }
      }
    }
    result->Error("INVALID_ARGS", "Missing deviceId parameter");
  } else if (method == "getVolume") {
    const auto* args = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (args) {
      auto it = args->find(flutter::EncodableValue("deviceId"));
      if (it != args->end()) {
        const std::string* device_id = std::get_if<std::string>(&it->second);
        if (device_id) {
          double volume = GetVolume(*device_id);
          result->Success(flutter::EncodableValue(volume));
          return;
        }
      }
    }
    result->Error("INVALID_ARGS", "Missing deviceId parameter");
  } else if (method == "setVolume") {
    const auto* args = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (args) {
      auto dev_it = args->find(flutter::EncodableValue("deviceId"));
      auto vol_it = args->find(flutter::EncodableValue("volume"));
      if (dev_it != args->end() && vol_it != args->end()) {
        const std::string* device_id = std::get_if<std::string>(&dev_it->second);
        const double* volume = std::get_if<double>(&vol_it->second);
        if (device_id && volume) {
          bool success = SetVolume(*device_id, *volume);
          result->Success(flutter::EncodableValue(success));
          return;
        }
      }
    }
    result->Error("INVALID_ARGS", "Missing parameters");
  } else if (method == "getMute") {
    const auto* args = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (args) {
      auto it = args->find(flutter::EncodableValue("deviceId"));
      if (it != args->end()) {
        const std::string* device_id = std::get_if<std::string>(&it->second);
        if (device_id) {
          bool mute = GetMute(*device_id);
          result->Success(flutter::EncodableValue(mute));
          return;
        }
      }
    }
    result->Error("INVALID_ARGS", "Missing deviceId parameter");
  } else if (method == "setMute") {
    const auto* args = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (args) {
      auto dev_it = args->find(flutter::EncodableValue("deviceId"));
      auto mute_it = args->find(flutter::EncodableValue("mute"));
      if (dev_it != args->end() && mute_it != args->end()) {
        const std::string* device_id = std::get_if<std::string>(&dev_it->second);
        const bool* mute = std::get_if<bool>(&mute_it->second);
        if (device_id && mute) {
          bool success = SetMute(*device_id, *mute);
          result->Success(flutter::EncodableValue(success));
          return;
        }
      }
    }
    result->Error("INVALID_ARGS", "Missing parameters");
  } else {
    result->NotImplemented();
  }
}

std::string AudioPlugin::GetDeviceType(int form_factor,
                                         const std::wstring& name) {
  std::string lower_name = WideStringToUtf8(name);
  // Convert to lowercase for comparison
  for (auto& c : lower_name) c = tolower(c);

  // Check form factor first
  switch (form_factor) {
    case DigitalAudioDisplayDevice:
      return "tv";
    case Headphones:
      return "headphone";
    case Headset:
      return "headset";
    case SPDIF:
      return "digital";
    case Speakers:
      // Check name for additional clues
      if (lower_name.find("hdmi") != std::string::npos) return "tv";
      if (lower_name.find("display") != std::string::npos) return "tv";
      if (lower_name.find("bluetooth") != std::string::npos) return "bluetooth";
      if (lower_name.find("usb") != std::string::npos) return "usb";
      return "speaker";
    case LineLevel:
      return "speaker";
    default:
      // Use name-based heuristics
      if (lower_name.find("hdmi") != std::string::npos) return "tv";
      if (lower_name.find("display") != std::string::npos) return "tv";
      if (lower_name.find("bluetooth") != std::string::npos) return "bluetooth";
      if (lower_name.find("headphone") != std::string::npos) return "headphone";
      if (lower_name.find("headset") != std::string::npos) return "headset";
      if (lower_name.find("usb") != std::string::npos) return "usb";
      return "speaker";
  }
}

flutter::EncodableValue AudioPlugin::GetOutputDevices() {
  flutter::EncodableList devices;

  HRESULT hr;
  IMMDeviceEnumerator* enumerator = nullptr;
  IMMDeviceCollection* collection = nullptr;

  hr = CoCreateInstance(__uuidof(MMDeviceEnumerator), NULL, CLSCTX_ALL,
                        __uuidof(IMMDeviceEnumerator), (void**)&enumerator);
  if (FAILED(hr) || !enumerator) {
    return flutter::EncodableValue(devices);
  }

  hr = enumerator->EnumAudioEndpoints(eRender, DEVICE_STATE_ACTIVE, &collection);
  if (FAILED(hr) || !collection) {
    enumerator->Release();
    return flutter::EncodableValue(devices);
  }

  UINT count = 0;
  collection->GetCount(&count);

  for (UINT i = 0; i < count; i++) {
    IMMDevice* device = nullptr;
    collection->Item(i, &device);
    if (!device) continue;

    LPWSTR device_id_w = nullptr;
    device->GetId(&device_id_w);
    std::wstring device_id = device_id_w ? device_id_w : L"";
    CoTaskMemFree(device_id_w);

    IPropertyStore* store = nullptr;
    device->OpenPropertyStore(STGM_READ, &store);
    if (!store) {
      device->Release();
      continue;
    }

    std::wstring friendly_name = GetPropertyStringValue(store, PKEY_Device_FriendlyName);
    UINT form_factor = GetPropertyUint32Value(store, PKEY_AudioEndpoint_FormFactor);

    std::string id_str = WideStringToUtf8(device_id);
    std::string name_str = WideStringToUtf8(friendly_name);
    std::string type_str = GetDeviceType(form_factor, friendly_name);

    flutter::EncodableMap device_map;
    device_map[flutter::EncodableValue("id")] = flutter::EncodableValue(id_str);
    device_map[flutter::EncodableValue("name")] = flutter::EncodableValue(name_str);
    device_map[flutter::EncodableValue("type")] = flutter::EncodableValue(type_str);
    device_map[flutter::EncodableValue("formFactor")] =
        flutter::EncodableValue(static_cast<int>(form_factor));

    devices.push_back(flutter::EncodableValue(device_map));

    store->Release();
    device->Release();
  }

  collection->Release();
  enumerator->Release();

  return flutter::EncodableValue(devices);
}

flutter::EncodableValue AudioPlugin::GetDefaultDevice() {
  flutter::EncodableMap result;

  IMMDeviceEnumerator* enumerator = nullptr;
  IMMDevice* device = nullptr;

  HRESULT hr = CoCreateInstance(__uuidof(MMDeviceEnumerator), NULL, CLSCTX_ALL,
                                __uuidof(IMMDeviceEnumerator), (void**)&enumerator);
  if (FAILED(hr) || !enumerator) {
    return flutter::EncodableValue(result);
  }

  hr = enumerator->GetDefaultAudioEndpoint(eRender, eConsole, &device);
  if (FAILED(hr) || !device) {
    enumerator->Release();
    return flutter::EncodableValue(result);
  }

  LPWSTR device_id_w = nullptr;
  device->GetId(&device_id_w);
  std::wstring device_id = device_id_w ? device_id_w : L"";
  CoTaskMemFree(device_id_w);

  IPropertyStore* store = nullptr;
  device->OpenPropertyStore(STGM_READ, &store);
  if (store) {
    std::wstring friendly_name = GetPropertyStringValue(store, PKEY_Device_FriendlyName);
    UINT form_factor = GetPropertyUint32Value(store, PKEY_AudioEndpoint_FormFactor);

    result[flutter::EncodableValue("id")] =
        flutter::EncodableValue(WideStringToUtf8(device_id));
    result[flutter::EncodableValue("name")] =
        flutter::EncodableValue(WideStringToUtf8(friendly_name));
    result[flutter::EncodableValue("type")] =
        flutter::EncodableValue(GetDeviceType(form_factor, friendly_name));

    store->Release();
  }

  device->Release();
  enumerator->Release();

  return flutter::EncodableValue(result);
}

bool AudioPlugin::SetDefaultDevice(const std::string& device_id) {
  std::wstring wide_id = Utf8ToWideString(device_id);

  IPolicyConfig* policy_config = nullptr;
  HRESULT hr = CoCreateInstance(CLSID_PolicyConfigClient, NULL, CLSCTX_ALL,
                                IID_IPolicyConfig, (void**)&policy_config);
  if (FAILED(hr) || !policy_config) {
    return false;
  }

  hr = policy_config->SetDefaultEndpoint(wide_id.c_str(), eConsole);
  if (SUCCEEDED(hr)) {
    policy_config->SetDefaultEndpoint(wide_id.c_str(), eMultimedia);
  }

  policy_config->Release();
  return SUCCEEDED(hr);
}

double AudioPlugin::GetVolume(const std::string& device_id) {
  std::wstring wide_id = Utf8ToWideString(device_id);

  IMMDeviceEnumerator* enumerator = nullptr;
  IMMDevice* device = nullptr;
  IAudioEndpointVolume* endpoint_volume = nullptr;

  HRESULT hr = CoCreateInstance(__uuidof(MMDeviceEnumerator), NULL, CLSCTX_ALL,
                                __uuidof(IMMDeviceEnumerator), (void**)&enumerator);
  if (FAILED(hr)) return 0.0;

  // If device_id is empty, get default device
  if (device_id.empty()) {
    hr = enumerator->GetDefaultAudioEndpoint(eRender, eConsole, &device);
  } else {
    hr = enumerator->GetDevice(wide_id.c_str(), &device);
  }
  enumerator->Release();

  if (FAILED(hr) || !device) return 0.0;

  hr = device->Activate(__uuidof(IAudioEndpointVolume), CLSCTX_ALL, NULL,
                        (void**)&endpoint_volume);
  device->Release();

  if (FAILED(hr) || !endpoint_volume) return 0.0;

  float level = 0.0f;
  endpoint_volume->GetMasterVolumeLevelScalar(&level);
  endpoint_volume->Release();

  return static_cast<double>(level);
}

bool AudioPlugin::SetVolume(const std::string& device_id, double volume) {
  std::wstring wide_id = Utf8ToWideString(device_id);

  IMMDeviceEnumerator* enumerator = nullptr;
  IMMDevice* device = nullptr;
  IAudioEndpointVolume* endpoint_volume = nullptr;

  HRESULT hr = CoCreateInstance(__uuidof(MMDeviceEnumerator), NULL, CLSCTX_ALL,
                                __uuidof(IMMDeviceEnumerator), (void**)&enumerator);
  if (FAILED(hr)) return false;

  if (device_id.empty()) {
    hr = enumerator->GetDefaultAudioEndpoint(eRender, eConsole, &device);
  } else {
    hr = enumerator->GetDevice(wide_id.c_str(), &device);
  }
  enumerator->Release();

  if (FAILED(hr) || !device) return false;

  hr = device->Activate(__uuidof(IAudioEndpointVolume), CLSCTX_ALL, NULL,
                        (void**)&endpoint_volume);
  device->Release();

  if (FAILED(hr) || !endpoint_volume) return false;

  float level = static_cast<float>(volume);
  if (level < 0.0f) level = 0.0f;
  if (level > 1.0f) level = 1.0f;

  hr = endpoint_volume->SetMasterVolumeLevelScalar(level, NULL);
  endpoint_volume->Release();

  return SUCCEEDED(hr);
}

bool AudioPlugin::GetMute(const std::string& device_id) {
  std::wstring wide_id = Utf8ToWideString(device_id);

  IMMDeviceEnumerator* enumerator = nullptr;
  IMMDevice* device = nullptr;
  IAudioEndpointVolume* endpoint_volume = nullptr;

  HRESULT hr = CoCreateInstance(__uuidof(MMDeviceEnumerator), NULL, CLSCTX_ALL,
                                __uuidof(IMMDeviceEnumerator), (void**)&enumerator);
  if (FAILED(hr)) return false;

  if (device_id.empty()) {
    hr = enumerator->GetDefaultAudioEndpoint(eRender, eConsole, &device);
  } else {
    hr = enumerator->GetDevice(wide_id.c_str(), &device);
  }
  enumerator->Release();

  if (FAILED(hr) || !device) return false;

  hr = device->Activate(__uuidof(IAudioEndpointVolume), CLSCTX_ALL, NULL,
                        (void**)&endpoint_volume);
  device->Release();

  if (FAILED(hr) || !endpoint_volume) return false;

  BOOL mute = FALSE;
  endpoint_volume->GetMute(&mute);
  endpoint_volume->Release();

  return mute != FALSE;
}

bool AudioPlugin::SetMute(const std::string& device_id, bool mute) {
  std::wstring wide_id = Utf8ToWideString(device_id);

  IMMDeviceEnumerator* enumerator = nullptr;
  IMMDevice* device = nullptr;
  IAudioEndpointVolume* endpoint_volume = nullptr;

  HRESULT hr = CoCreateInstance(__uuidof(MMDeviceEnumerator), NULL, CLSCTX_ALL,
                                __uuidof(IMMDeviceEnumerator), (void**)&enumerator);
  if (FAILED(hr)) return false;

  if (device_id.empty()) {
    hr = enumerator->GetDefaultAudioEndpoint(eRender, eConsole, &device);
  } else {
    hr = enumerator->GetDevice(wide_id.c_str(), &device);
  }
  enumerator->Release();

  if (FAILED(hr) || !device) return false;

  hr = device->Activate(__uuidof(IAudioEndpointVolume), CLSCTX_ALL, NULL,
                        (void**)&endpoint_volume);
  device->Release();

  if (FAILED(hr) || !endpoint_volume) return false;

  hr = endpoint_volume->SetMute(mute ? TRUE : FALSE, NULL);
  endpoint_volume->Release();

  return SUCCEEDED(hr);
}
