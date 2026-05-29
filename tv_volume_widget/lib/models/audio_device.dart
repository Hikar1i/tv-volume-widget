class AudioDevice {
  final String id;
  final String name;
  final String type; // speaker, headphone, headset, tv, bluetooth, usb, digital
  final int formFactor;

  const AudioDevice({
    required this.id,
    required this.name,
    required this.type,
    this.formFactor = 0,
  });

  factory AudioDevice.fromMap(Map<dynamic, dynamic> map) {
    return AudioDevice(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Unknown Device',
      type: map['type'] as String? ?? 'speaker',
      formFactor: map['formFactor'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioDevice && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'AudioDevice(id: $id, name: $name, type: $type)';
}
