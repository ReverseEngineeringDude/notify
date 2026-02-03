enum FieldType {
  text,
  number,
  date,
  dropdown,
}

class FieldDefinition {
  final String key;
  final String label;
  final FieldType type;
  final bool required;
  final List<String>? options; // For dropdowns

  FieldDefinition({
    required this.key,
    required this.label,
    required this.type,
    this.required = false,
    this.options,
  });

  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'label': label,
      'type': type.name,
      'required': required,
      'options': options,
    };
  }

  factory FieldDefinition.fromMap(Map<String, dynamic> map) {
    return FieldDefinition(
      key: map['key'] ?? '',
      label: map['label'] ?? '',
      type: FieldType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => FieldType.text,
      ),
      required: map['required'] ?? false,
      options: map['options'] != null ? List<String>.from(map['options']) : null,
    );
  }
}

class ProgramModel {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final List<FieldDefinition> fields;
  final bool isActive;

  ProgramModel({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.fields,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'fields': fields.map((f) => f.toMap()).toList(),
      'isActive': isActive,
    };
  }

  factory ProgramModel.fromMap(Map<String, dynamic> map, String id) {
    return ProgramModel(
      id: id,
      name: map['name'] ?? '',
      startDate: DateTime.tryParse(map['startDate'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(map['endDate'] ?? '') ?? DateTime.now(),
      fields: map['fields'] != null
          ? (map['fields'] as List).map((i) => FieldDefinition.fromMap(i)).toList()
          : [],
      isActive: map['isActive'] ?? true,
    );
  }
}
