import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart'; // Haptics
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/program_model.dart';
import '../../services/firestore_service.dart';

class CreateProgramScreen extends StatefulWidget {
  final ProgramModel? programToEdit;

  const CreateProgramScreen({super.key, this.programToEdit});

  @override
  State<CreateProgramScreen> createState() => _CreateProgramScreenState();
}

class _CreateProgramScreenState extends State<CreateProgramScreen> {
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
        key: const Uuid().v4(),
        label: 'New Field',
        type: FieldType.text,
      ));
    });
    _showEditFieldDialog(_fields.length - 1);
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
    
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("Edit Field"),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              children: [
                const SizedBox(height: 16),
                CupertinoTextField(
                  controller: labelController,
                  placeholder: "Field Label",
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    showCupertinoModalPopup(
                      context: context,
                      builder: (c) => Container(
                        height: 200,
                        color: CupertinoColors.systemBackground.resolveFrom(context),
                        child: CupertinoPicker(
                          itemExtent: 32,
                          onSelectedItemChanged: (i) {
                            setState(() => selectedType = FieldType.values[i]);
                          },
                          children: FieldType.values.map((t) => Center(child: Text(t.name.toUpperCase()))).toList(),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: CupertinoColors.systemGrey4),
                      borderRadius: BorderRadius.circular(8),
                      color: CupertinoColors.systemBackground.resolveFrom(context),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "Type: ${selectedType.name.toUpperCase()}",
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        const Icon(CupertinoIcons.chevron_down, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Required"),
                    CupertinoSwitch(
                      value: isRequired,
                      onChanged: (val) => setState(() => isRequired = val),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              // Update parent state
              this.setState(() {
                _fields[index] = FieldDefinition(
                  key: labelController.text.toLowerCase().replaceAll(' ', '_'),
                  label: labelController.text,
                  type: selectedType,
                  required: isRequired,
                );
              });
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _saveProgram() async {
    if (_nameController.text.isEmpty) {
       showCupertinoDialog(
         context: context, 
         builder: (c) => CupertinoAlertDialog(
           title: const Text("Missing Info"),
           content: const Text("Program name is required"),
           actions: [CupertinoDialogAction(child: const Text("OK"), onPressed: () => Navigator.pop(c))],
         )
       );
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
      if (mounted) {
         showCupertinoDialog(
         context: context, 
         builder: (c) => CupertinoAlertDialog(
           title: const Text("Error"),
           content: Text(e.toString()),
           actions: [CupertinoDialogAction(child: const Text("OK"), onPressed: () => Navigator.pop(c))],
         )
       );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.programToEdit != null ? "Edit Program" : "Create Program"),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            HapticFeedback.mediumImpact();
            _saveProgram();
          },
          child: const Text("Save"),
        ),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            CupertinoFormSection.insetGrouped(
              header: const Text("PROGRAM DETAILS"),
              children: [
                CupertinoTextFormFieldRow(
                  controller: _nameController,
                  placeholder: "Program Name",
                  prefix: const Icon(CupertinoIcons.doc_text, color: CupertinoColors.systemGrey),
                ),
                _buildDatePickerRow("Start Date", _startDate, (d) => setState(() => _startDate = d)),
                _buildDatePickerRow("End Date", _endDate, (d) => setState(() => _endDate = d)),
              ],
            ),
            
            if (_fields.isNotEmpty)
              CupertinoFormSection.insetGrouped(
                header: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("FORM FIELDS"),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minSize: 0,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _addField();
                      },
                      child: const Row(
                        children: [
                          Icon(CupertinoIcons.add_circled, size: 20),
                          SizedBox(width: 4),
                          Text("Add Field"),
                        ],
                      ),
                    ),
                  ],
                ),
                children: _fields.asMap().entries.map((entry) {
                  int idx = entry.key;
                  FieldDefinition f = entry.value;
                  return CupertinoFormRow(
                    prefix: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                         const Icon(CupertinoIcons.square_list, color: CupertinoColors.systemGrey),
                         const SizedBox(width: 12),
                         Text(f.label),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(f.type.name.toUpperCase(), style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
                        if (f.required) 
                          const Text(" • Req", style: TextStyle(fontSize: 12, color: CupertinoColors.destructiveRed)),
                        const SizedBox(width: 8),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minSize: 0,
                          onPressed: () => _showEditFieldDialog(idx),
                          child: const Icon(CupertinoIcons.pencil, size: 20),
                        ),
                        const SizedBox(width: 16),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minSize: 0,
                          onPressed: () => _removeField(idx),
                          child: const Icon(CupertinoIcons.trash, color: CupertinoColors.destructiveRed, size: 20),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              )
            else
               Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("FORM FIELDS", style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 13)),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minSize: 0,
                        onPressed: _addField,
                        child: const Row(
                          children: [
                            Icon(CupertinoIcons.add_circled, size: 20),
                            SizedBox(width: 4),
                            Text("Add Field"),
                          ],
                        ),
                      ),
                    ],
                  ),
               ),
            
             if (_fields.isEmpty) 
               const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text("No fields added yet.", style: TextStyle(color: CupertinoColors.systemGrey)),
                  ),
                ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePickerRow(String label, DateTime date, Function(DateTime) onDateChanged) {
    return GestureDetector(
      onTap: () {
        showCupertinoModalPopup<void>(
          context: context,
          builder: (BuildContext context) => Container(
            height: 216,
            padding: const EdgeInsets.only(top: 6.0),
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            color: CupertinoColors.systemBackground.resolveFrom(context),
            child: SafeArea(
              top: false,
              child: CupertinoDatePicker(
                initialDateTime: date,
                mode: CupertinoDatePickerMode.date,
                use24hFormat: true,
                onDateTimeChanged: (DateTime newDate) {
                  onDateChanged(newDate);
                },
              ),
            ),
          ),
        );
      },
      child: CupertinoFormRow(
        prefix: Row(
          children: [
            const Icon(CupertinoIcons.calendar, color: CupertinoColors.systemGrey),
            const SizedBox(width: 12),
            Text(label),
          ],
        ),
        child: Text(
          "${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}",
          style: const TextStyle(color: CupertinoColors.systemGrey),
        ),
      ),
    );
  }
}
