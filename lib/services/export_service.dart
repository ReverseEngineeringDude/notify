import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/submission_model.dart';
import '../models/program_model.dart';
import '../models/user_model.dart';

class ExportService {
  Future<void> exportSubmissionsToPdf(List<SubmissionModel> submissions, ProgramModel program, Map<String, String> userNames) async {
    final pdf = pw.Document();

    // Prepare data
    List<List<String>> data = [];
    
    // Header
    List<String> header = [
      "ID",
      "User",
      "Time",
      "Ward",
    ];
    for (var field in program.fields) {
      header.add(field.label);
    }
    data.add(header);

    int index = 1;
    for (var submission in submissions) {
      List<String> row = [
        (index++).toString(), // Sequential ID: 1, 2, 3...
        userNames[submission.submittedBy] ?? "Unknown", // Human Readable Name
        DateFormat('MM-dd HH:mm').format(submission.timestamp),
        submission.wardId,
      ];
      for (var field in program.fields) {
        row.add(submission.data[field.key]?.toString() ?? "");
      }
      data.add(row);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text("${program.name} Submissions", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
             pw.Table.fromTextArray(
              context: context,
              data: data,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 10),
            ),
          ];
        },
      ),
    );

    await _sharePdfFile(pdf, "${program.name}_submissions.pdf");
  }

  Future<void> exportUsersToPdf(List<UserModel> users) async {
    final pdf = pw.Document();
     List<List<String>> data = [
      ["User ID", "Name", "Email", "Role", "Ward"],
    ];

    for (var user in users) {
      data.add([
        user.uid,
        user.name ?? "N/A",
        user.email,
        user.role.name,
        user.wardId ?? "N/A",
      ]);
    }

    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) {
           return [
            pw.Header(
              level: 0,
              child: pw.Text("User Management Export", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Table.fromTextArray(
              context: context,
              data: data,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 10),
            ),
          ];
        }
      )
    );

    await _sharePdfFile(pdf, "users_export.pdf");
  }

  Future<void> _sharePdfFile(pw.Document pdf, String fileName) async {
    final directory = await getTemporaryDirectory();
    final path = "${directory.path}/$fileName";
    final file = File(path);
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(path)], text: 'Here is your exported PDF.');
  }
}
