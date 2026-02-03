import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
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
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formData = {};
  File? _imageFile;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    _formKey.currentState!.save();
    setState(() => _isSubmitting = true);

    try {
      // Mock Image Upload (We would upload to Firebase Storage here and get URL)
      // String? imageUrl = await StorageService.upload(_imageFile); 
      String? imageUrl = _imageFile?.path; // Storing local path for mock

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

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Success"),
            content: const Text("Data submitted successfully!"),
            actions: [
              TextButton(onPressed: () {
                Navigator.pop(ctx); // Close dialog
                Navigator.pop(context); // Go back
              }, child: const Text("OK"))
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.program.name)),
      body: _isSubmitting 
          ? const Center(child: CircularProgressIndicator()) 
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                   // Dynamic Fields Loop
                   ...widget.program.fields.map((field) {
                     return Padding(
                       padding: const EdgeInsets.only(bottom: 16),
                       child: _buildFieldWidget(field),
                     );
                   }),
                   
                   const Divider(height: 32),
                   
                   // Image Proof
                   ListTile(
                     leading: const Icon(Icons.camera_alt),
                     title: const Text("Upload Proof"),
                     subtitle: _imageFile != null ? Text("Image Selected") : const Text("No image selected"),
                     trailing: _imageFile != null 
                         ? Image.file(_imageFile!, width: 40, height: 40, fit: BoxFit.cover)
                         : ConstrainedBox(constraints: const BoxConstraints(), child: const Icon(Icons.add_a_photo)), // Fix for potentially unbound Icon
                     onTap: _pickImage,
                   ),
                   
                   const SizedBox(height: 24),
                   ElevatedButton(
                     onPressed: _submitForm, 
                     child: const Text("SUBMIT DATA"),
                   ),
                ],
              ),
            ),
    );
  }

  Widget _buildFieldWidget(FieldDefinition field) {
    switch (field.type) {
      case FieldType.text:
      case FieldType.number:
        return TextFormField(
          decoration: InputDecoration(
            labelText: field.label + (field.required ? ' *' : ''),
          ),
          keyboardType: field.type == FieldType.number ? TextInputType.number : TextInputType.text,
          validator: (value) {
            if (field.required && (value == null || value.isEmpty)) {
              return '${field.label} is required';
            }
            return null;
          },
          onSaved: (val) => _formData[field.key] = field.type == FieldType.number ? num.tryParse(val ?? '') : val,
        );
      
      case FieldType.dropdown:
        return DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: field.label + (field.required ? ' *' : ''),
          ),
          items: field.options?.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList() ?? [],
          onChanged: (val) {}, // State update handled by onSaved
          validator: (value) {
            if (field.required && value == null) return 'Required';
            return null;
          },
          onSaved: (val) => _formData[field.key] = val,
        );

      case FieldType.date:
        return FormField<DateTime>(
          validator: (val) {
             if (field.required && _formData[field.key] == null) return 'Required';
             return null;
          },
          builder: (state) {
            return InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context, 
                  initialDate: DateTime.now(), 
                  firstDate: DateTime(2000), 
                  lastDate: DateTime(2100)
                );
                if (date != null) {
                  setState(() => _formData[field.key] = date.toIso8601String());
                  state.didChange(date);
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: field.label + (field.required ? ' *' : ''),
                  errorText: state.errorText,
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                child: Text(
                  _formData[field.key] != null 
                    ? _formData[field.key].toString().split('T')[0] 
                    : 'Select Date'
                ),
              ),
            );
          },
        );
        
      default:
        return const SizedBox.shrink();
    }
  }
}
