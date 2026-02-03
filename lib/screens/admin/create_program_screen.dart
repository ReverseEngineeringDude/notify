import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/program_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/common/modern_scaffold.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/animated_entry.dart';

class CreateProgramScreen extends StatefulWidget {
  final ProgramModel? programToEdit;

  const CreateProgramScreen({super.key, this.programToEdit});

  @override
  State<CreateProgramScreen> createState() => _CreateProgramScreenState();
}

class _CreateProgramScreenState extends State<CreateProgramScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late DateTime _startDate;
  late DateTime _endDate;
  late List<FieldDefinition> _fields;
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      if (widget.programToEdit != null) {
        _nameController = TextEditingController(text: widget.programToEdit!.name);
        _startDate = widget.programToEdit!.startDate;
        _endDate = widget.programToEdit!.endDate;
        _fields = List.from(widget.programToEdit!.fields);
      } else {
        _nameController = TextEditingController();
        _startDate = DateTime.now();
        _endDate = DateTime.now().add(const Duration(days: 7));
        _fields = [];
      }
      _isInit = false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addField() {
    setState(() {
      _fields.add(FieldDefinition(
        key: const Uuid().v4(), // Temporary key
        label: 'New Field',
        type: FieldType.text,
      ));
    });
    _showEditFieldDialog(_fields.length - 1);
  }

  void _editField(int index) {
    _showEditFieldDialog(index);
  }

  void _removeField(int index) {
    setState(() {
      _fields.removeAt(index);
    });
  }

  void _showEditFieldDialog(int index) {
    final field = _fields[index];
    final labelController = TextEditingController(text: field.label);
    FieldType selectedType = field.type;
    bool isRequired = field.required;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Field"),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: labelController,
                  decoration: const InputDecoration(labelText: "Field Label"),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<FieldType>(
                  value: selectedType,
                  items: FieldType.values.map((t) => DropdownMenuItem(
                    value: t,
                    child: Text(t.name.toUpperCase()),
                  )).toList(),
                  onChanged: (val) => setState(() => selectedType = val!),
                  decoration: const InputDecoration(labelText: "Field Type"),
                ),
                CheckboxListTile(
                  title: const Text("Required"),
                  value: isRequired,
                  onChanged: (val) => setState(() => isRequired = val!),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _fields[index] = FieldDefinition(
                  key: labelController.text.toLowerCase().replaceAll(' ', '_'), // Generate key from label
                  label: labelController.text,
                  type: selectedType,
                  required: isRequired,
                );
              });
              Navigator.pop(context);
              // Trigger parent rebuild to update list
              this.setState(() {}); 
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _saveProgram() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fields.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Add at least one field")));
      return;
    }

    final program = ProgramModel(
      id: widget.programToEdit?.id ?? const Uuid().v4(),
      name: _nameController.text,
      startDate: _startDate,
      endDate: _endDate,
      fields: _fields,
      isActive: widget.programToEdit?.isActive ?? true,
    );

    try {
      await Provider.of<FirestoreService>(context, listen: false).createProgram(program);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModernScaffold(
      appBar: AppBar(
        title: Text(widget.programToEdit != null ? "Edit Program" : "Create Program"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedEntry(
                child: GlassCard(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: "Program Name"),
                        validator: (v) => v!.isEmpty ? "Required" : null,
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text("Start Date"),
                        subtitle: Text(_startDate.toString().split(' ')[0]),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final d = await showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                          if (d != null) setState(() => _startDate = d);
                        },
                      ),
                      const Divider(),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text("End Date"),
                        subtitle: Text(_endDate.toString().split(' ')[0]),
                        trailing: const Icon(Icons.class_outlined), // Changed icon to avoid duplicate calendar look, or keep calendar
                        onTap: () async {
                          final d = await showDatePicker(context: context, initialDate: _endDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                          if (d != null) setState(() => _endDate = d);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Form Fields", style: Theme.of(context).textTheme.titleLarge),
                    IconButton(
                      onPressed: _addField,
                      icon: const Icon(Icons.add_circle, color: Colors.indigo, size: 30),
                      tooltip: "Add Field",
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
               if (_fields.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("No fields added yet. Add fields to build your form.", style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
                ),
              ..._fields.asMap().entries.map((entry) {
                int idx = entry.key;
                FieldDefinition f = entry.value;
                return AnimatedEntry(
                  delay: Duration(milliseconds: idx * 100),
                  child: GlassCard(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(f.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("${f.type.name.toUpperCase()} ${f.required ? '• Required' : ''}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _editField(idx)),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => _removeField(idx)),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveProgram,
                child: Text(widget.programToEdit != null ? "Update Program" : "Publish Program"),
              ),
              const SizedBox(height: 40), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }
}
