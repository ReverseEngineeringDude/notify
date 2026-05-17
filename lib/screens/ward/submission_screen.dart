
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:flutter/material.dart' show Colors, Icons, Theme; // Minimal material for compatibility
import 'package:provider/provider.dart';
import '../../services/haptic_service.dart';

import 'package:uuid/uuid.dart';
import '../../models/program_model.dart';
import '../../models/submission_model.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';

class SubmissionScreen extends StatefulWidget {
  final ProgramModel program;

  const SubmissionScreen({super.key, required this.program});

  @override
  State<SubmissionScreen> createState() => _SubmissionScreenState();
}

class _SubmissionScreenState extends State<SubmissionScreen> {
  final Map<String, dynamic> _formData = {};

  bool _isSubmitting = false;

  // Controllers for text fields to manage state
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    // Initialize controllers
    for (var field in widget.program.fields) {
      if (field.type == FieldType.text || field.type == FieldType.number) {
        _controllers[field.key] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }



  Future<void> _submitForm() async {
    // Validate
    for (var field in widget.program.fields) {
      if (field.required) {
        bool isEmpty = false;
        if (field.type == FieldType.text || field.type == FieldType.number) {
          if (_controllers[field.key]!.text.isEmpty) isEmpty = true;
        } else {
          if (_formData[field.key] == null || _formData[field.key].toString().isEmpty) isEmpty = true;
        }

        if (isEmpty) {
          HapticService.error();
          showCupertinoDialog(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text("Missing Input"),
              content: Text("${field.label} is required."),
              actions: [CupertinoDialogAction(child: const Text("OK"), onPressed: () => Navigator.pop(ctx))],
            ),
          );
          return;
        }
      }
      
      // Save text values to formData
      if (field.type == FieldType.text) {
        _formData[field.key] = _controllers[field.key]!.text;
      } else if (field.type == FieldType.number) {
        _formData[field.key] = num.tryParse(_controllers[field.key]!.text);
      }
    }
    
    setState(() => _isSubmitting = true);

    try {
      String? imageUrl = null; // Proof submission removed as per request

      final user = Provider.of<AuthService>(context, listen: false).currentUser;

      final submission = SubmissionModel(
        id: const Uuid().v4(),
        programId: widget.program.id,
        wardId: user?.wardId ?? 'Unknown',
        timestamp: DateTime.now(),
        data: _formData,
        latitude: null,
        longitude: null,
        imageUrl: imageUrl,
        submittedBy: user?.uid ?? 'Unknown',
      );

      await Provider.of<FirestoreService>(context, listen: false).submitEntry(submission);
      
      HapticService.success();

      if (mounted) {
        await showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text("Success"),
            content: const Text("Data submitted successfully!"),
            actions: [
              CupertinoDialogAction(
                child: const Text("OK"),
                onPressed: () {
                  Navigator.pop(ctx); 
                  Navigator.pop(context); 
                },
              )
            ],
          ),
        );
      }
    } catch (e) {
      HapticService.error();
      if (mounted) {
         showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text("Error"),
            content: Text(e.toString()),
            actions: [CupertinoDialogAction(child: const Text("OK"), onPressed: ()=>Navigator.pop(ctx))],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.program.name),
      ),
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: SafeArea(
        child: _isSubmitting 
          ? const Center(child: CupertinoActivityIndicator()) 
          : ListView(
              children: [
                 if (widget.program.fields.isNotEmpty)
                   CupertinoFormSection.insetGrouped(
                     header: const Text("ENTRY DETAILS"),
                     children: widget.program.fields.map((field) {
                       return _buildFieldWidget(field);
                     }).toList(),
                   ),
                 

                 
                 Padding(
                   padding: const EdgeInsets.all(16.0),
                   child: CupertinoButton.filled(
                     onPressed: () {
                         HapticService.mediumImpact();
                         _submitForm();
                     }, 
                     child: const Text("Submit Data"),
                   ),
                 ),
                 const SizedBox(height: 40),
              ],
            ),
      ),
    );
  }

  Widget _buildFieldWidget(FieldDefinition field) {
    switch (field.type) {
      case FieldType.text:
      case FieldType.number:
        return CupertinoTextFormFieldRow(
          controller: _controllers[field.key],
          placeholder: field.label,
          keyboardType: field.type == FieldType.number ? TextInputType.number : TextInputType.text,
          prefix: field.required 
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                   const Text("*", style: TextStyle(color: CupertinoColors.destructiveRed)),
                   const SizedBox(width: 4),
                   Text(field.label),
                ],
              ) 
            : Text(field.label),
        );
      
      case FieldType.dropdown:
        return GestureDetector(
          onTap: () {
            HapticService.selectionClick();
            showCupertinoModalPopup(
              context: context,
              builder: (ctx) => CupertinoActionSheet(
                title: Text("Select ${field.label}"),
                actions: field.options?.map((opt) => CupertinoActionSheetAction(
                  child: Text(opt),
                  onPressed: () {
                    setState(() => _formData[field.key] = opt);
                    Navigator.pop(ctx);
                  },
                )).toList() ?? [],
                cancelButton: CupertinoActionSheetAction(
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            );
          },
          child: CupertinoFormRow(
            prefix: field.required 
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                   const Text("*", style: TextStyle(color: CupertinoColors.destructiveRed)),
                   const SizedBox(width: 4),
                   Text(field.label),
                ],
              ) 
            : Text(field.label),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  _formData[field.key]?.toString() ?? "Select",
                  style: TextStyle(
                    color: _formData[field.key] != null 
                    ? CupertinoColors.label.resolveFrom(context) 
                    : CupertinoColors.placeholderText.resolveFrom(context)
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(CupertinoIcons.chevron_up_chevron_down, size: 14, color: CupertinoColors.systemGrey),
              ],
            ),
          ),
        );

      case FieldType.date:
        return GestureDetector(
          onTap: () {
            HapticService.selectionClick();
            showCupertinoModalPopup(
              context: context,
              builder: (c) => Container(
                height: 216,
                padding: const EdgeInsets.only(top: 6.0),
                margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                color: CupertinoColors.systemBackground.resolveFrom(context),
                child: SafeArea(
                  top: false,
                  child: CupertinoDatePicker(
                    initialDateTime: DateTime.tryParse(_formData[field.key] ?? '') ?? DateTime.now(),
                    mode: CupertinoDatePickerMode.date,
                    use24hFormat: true,
                    onDateTimeChanged: (date) {
                      setState(() => _formData[field.key] = date.toIso8601String());
                    },
                  ),
                ),
              ),
            );
          },
          child: CupertinoFormRow(
            prefix: field.required 
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                   const Text("*", style: TextStyle(color: CupertinoColors.destructiveRed)),
                   const SizedBox(width: 4),
                   Text(field.label),
                ],
              ) 
            : Text(field.label),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  _formData[field.key] != null 
                    ? DateTime.parse(_formData[field.key]).toIso8601String().split('T')[0]
                    : "Select Date",
                  style: TextStyle(
                    color: _formData[field.key] != null 
                    ? CupertinoColors.label.resolveFrom(context) 
                    : CupertinoColors.placeholderText.resolveFrom(context)
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(CupertinoIcons.calendar, size: 16, color: CupertinoColors.systemGrey),
              ],
            ),
          ),
        );
        
      default:
        return const SizedBox.shrink();
    }
  }
}
