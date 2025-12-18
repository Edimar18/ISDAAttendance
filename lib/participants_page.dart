import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'db_helper.dart';

class ParticipantsPage extends StatefulWidget {
  const ParticipantsPage({super.key});

  @override
  State<ParticipantsPage> createState() => _ParticipantsPageState();
}

class _ParticipantsPageState extends State<ParticipantsPage> {
  late Future<List<Participant>> _participantsFuture;

  @override
  void initState() {
    super.initState();
    _refreshParticipants();
  }

  void _refreshParticipants() {
    setState(() {
      _participantsFuture = DatabaseHelper.instance.readAllParticipants();
    });
  }

  void _showAddParticipantModal(BuildContext context) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddParticipantModal(),
    );

    if (result == true) {
      _refreshParticipants();
    }
  }

  Future<void> _importCSV() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        
        // Read as string to handle line endings manually
        String csvString = await file.readAsString();
        
        // Normalize line endings to \n
        csvString = csvString.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

        // Parse with explicit EOL
        List<List<dynamic>> fields = const CsvToListConverter().convert(csvString, eol: '\n');

        int addedCount = 0;

        for (var row in fields) {
            if (row.length < 3) continue;

            String name = row[0].toString().trim();
            String course = row[1].toString().trim();
            String year = row[2].toString().trim();

            // Skip header
            if (name.toLowerCase() == 'name' && course.toLowerCase() == 'course') continue;
            
            if (name.isNotEmpty) {
                final participant = Participant(name: name, course: course, year: year);
                await DatabaseHelper.instance.createParticipant(participant);
                addedCount++;
            }
        }

        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Imported $addedCount participants')),
            );
            _refreshParticipants();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error importing CSV: $e')),
        );
      }
    }
  }

  Future<void> _deleteParticipant(int id) async {
    await DatabaseHelper.instance.deleteParticipant(id);
    _refreshParticipants();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Participants', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _importCSV,
            icon: const Icon(Icons.upload_file),
            tooltip: 'Import CSV',
          ),
        ],
      ),
      body: FutureBuilder<List<Participant>>(
        future: _participantsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('No participants found', style: TextStyle(color: Colors.grey)),
                    TextButton.icon(
                        onPressed: _importCSV,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Import via CSV'),
                    )
                  ],
                )
            );
          }

          final participants = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: participants.length,
            itemBuilder: (context, index) {
              final participant = participants[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Slidable(
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (context) => _deleteParticipant(participant.id!),
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        icon: Icons.delete,
                        label: 'Delete',
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFF1C1F26), borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFF1B61F3).withOpacity(0.2),
                          child: Text(participant.name[0].toUpperCase(), style: const TextStyle(color: Color(0xFF1B61F3), fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(participant.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                              const SizedBox(height: 4),
                              Text('${participant.course} - ${participant.year}', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddParticipantModal(context),
        backgroundColor: const Color(0xFF1B61F3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.person_add, color: Colors.white, size: 30),
      ),
    );
  }
}

class AddParticipantModal extends StatefulWidget {
  const AddParticipantModal({super.key});

  @override
  State<AddParticipantModal> createState() => _AddParticipantModalState();
}

class _AddParticipantModalState extends State<AddParticipantModal> {
  final _nameController = TextEditingController();
  final _courseController = TextEditingController();
  final _yearController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _courseController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF1B61F3),
        colorScheme: const ColorScheme.light(primary: Color(0xFF1B61F3)),
        inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        )
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Color(0xFFF8F9FB),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _buildLabel("Full Name"),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: "e.g., John Doe",
                      hintStyle: TextStyle(color: Colors.grey[400]),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildLabel("Course"),
                  TextField(
                    controller: _courseController,
                    decoration: InputDecoration(
                      hintText: "e.g., BSCS",
                      hintStyle: TextStyle(color: Colors.grey[400]),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildLabel("Year Level"),
                   TextField(
                    controller: _yearController,
                    decoration: InputDecoration(
                      hintText: "e.g., 3rd Year",
                      hintStyle: TextStyle(color: Colors.grey[400]),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
            _buildCreateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("New Participant", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1A1C1E))),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  child: const Icon(Icons.close, size: 20, color: Colors.black54),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF323639), fontSize: 14)),
    );
  }

  Widget _buildCreateButton() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _saveParticipant,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B61F3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: const Text("Add Participant", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  void _saveParticipant() async {
    if (_nameController.text.isEmpty || _courseController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill name and course')));
      return;
    }

    final participant = Participant(
      name: _nameController.text,
      course: _courseController.text,
      year: _yearController.text,
    );

    await DatabaseHelper.instance.createParticipant(participant);
    if (mounted) {
        Navigator.pop(context, true);
    }
  }
}
