import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'db_helper.dart';

class AttendancePage extends StatefulWidget {
  final Event event;

  const AttendancePage({super.key, required this.event});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  late Future<List<AttendanceRecord>> _attendanceFuture;
  List<Participant> _allParticipants = [];
  bool _isLoadingParticipants = true;

  // Sorting
  bool _sortByTimeInAsc = false;

  @override
  void initState() {
    super.initState();
    _refreshAttendance();
    _loadParticipants();
  }

  void _refreshAttendance() {
    setState(() {
      _attendanceFuture = DatabaseHelper.instance.getAttendanceForEvent(widget.event.id!);
    });
  }

  Future<void> _loadParticipants() async {
    final participants = await DatabaseHelper.instance.readAllParticipants();
    if (mounted) {
      setState(() {
        _allParticipants = participants;
        _isLoadingParticipants = false;
      });
    }
  }

  void _addAttendee() async {
    // Show a dialog or modal with search
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddAttendeeModal(
        eventId: widget.event.id!,
        allParticipants: _allParticipants,
        onAdded: _refreshAttendance,
      ),
    );
  }

  Future<void> _setTimeOut(AttendanceRecord record) async {
    final now = DateTime.now();
    await DatabaseHelper.instance.updateTimeOut(record.id!, now);
    _refreshAttendance();
  }

  Future<void> _timeOutAll() async {
    final now = DateTime.now();
    await DatabaseHelper.instance.timeOutAll(widget.event.id!, now);
    _refreshAttendance();
  }

  Future<void> _exportCSV() async {
    try {
      final records = await DatabaseHelper.instance.getAttendanceForEvent(widget.event.id!);
      
      List<List<dynamic>> csvData = [
        ['Name', 'Time In', 'Time Out']
      ];

      for (var record in records) {
        csvData.add([
          record.participant?.name ?? 'Unknown',
          DateFormat('yyyy-MM-dd HH:mm:ss').format(record.timeIn),
          record.timeOut != null ? DateFormat('yyyy-MM-dd HH:mm:ss').format(record.timeOut!) : 'N/A'
        ]);
      }

      String csvString = const ListToCsvConverter().convert(csvData);
      
      final tempDir = await getTemporaryDirectory();
      final fileName = 'attendance_${widget.event.title.replaceAll(' ', '_')}.csv';
      final file = await File('${tempDir.path}/$fileName').create();
      await file.writeAsString(csvString);

      if (mounted) {
         // Share the file
         await Share.shareXFiles([XFile(file.path)], text: 'Attendance for ${widget.event.title}');
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error exporting CSV: $e')));
      }
    }
  }

  void _toggleSort() {
    setState(() {
      _sortByTimeInAsc = !_sortByTimeInAsc;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                const Text('Attendance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text(widget.event.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.grey)),
            ]
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _exportCSV,
            icon: const Icon(Icons.file_download),
            tooltip: 'Export CSV',
          ),
          IconButton(
            onPressed: _timeOutAll,
            icon: const Icon(Icons.timer_off),
            tooltip: 'Time Out All',
          ),
          IconButton(
            onPressed: _toggleSort,
            icon: Icon(_sortByTimeInAsc ? Icons.arrow_upward : Icons.arrow_downward),
            tooltip: 'Sort by Time In',
          ),
        ],
      ),
      body: FutureBuilder<List<AttendanceRecord>>(
        future: _attendanceFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          var records = snapshot.data ?? [];
          
          if (records.isEmpty) {
             return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.playlist_add_check, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('No attendance recorded yet', style: TextStyle(color: Colors.grey)),
                  ],
                )
            );
          }

          // Sort
          records.sort((a, b) {
            if (_sortByTimeInAsc) {
              return a.timeIn.compareTo(b.timeIn);
            } else {
              return b.timeIn.compareTo(a.timeIn);
            }
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              return _AttendanceCard(
                  record: record,
                  onTimeOut: () => _setTimeOut(record),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAttendee,
        backgroundColor: const Color(0xFF1B61F3),
        child: const Icon(Icons.person_add_alt_1, color: Colors.white),
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final AttendanceRecord record;
  final VoidCallback onTimeOut;

  const _AttendanceCard({required this.record, required this.onTimeOut});

  @override
  Widget build(BuildContext context) {
    // final dateFormat = DateFormat('hh:mm a'); // Unused
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1F26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text(record.participant?.name ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                                Text('${record.participant?.course ?? ""} - ${record.participant?.year ?? ""}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                        ),
                    ),
                    if (record.timeOut == null)
                        TextButton(
                            onPressed: onTimeOut,
                            style: TextButton.styleFrom(
                                backgroundColor: Colors.redAccent.withOpacity(0.1),
                                foregroundColor: Colors.redAccent
                            ),
                            child: const Text('Time Out'),
                        )
                    else 
                         Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                            child: const Text("Completed", style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.white10),
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                    _TimeColumn(label: "Time In", time: record.timeIn, color: Colors.blueAccent),
                    _TimeColumn(label: "Time Out", time: record.timeOut, color: Colors.orangeAccent),
                ],
            )
        ],
      ),
    );
  }
}

class _TimeColumn extends StatelessWidget {
  final String label;
  final DateTime? time;
  final Color color;

  const _TimeColumn({required this.label, this.time, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
                time != null ? DateFormat('hh:mm a').format(time!) : '--:--',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
        ],
    );
  }
}

class _AddAttendeeModal extends StatefulWidget {
  final int eventId;
  final List<Participant> allParticipants;
  final VoidCallback onAdded;

  const _AddAttendeeModal({required this.eventId, required this.allParticipants, required this.onAdded});

  @override
  State<_AddAttendeeModal> createState() => _AddAttendeeModalState();
}

class _AddAttendeeModalState extends State<_AddAttendeeModal> {
  final TextEditingController _searchController = TextEditingController();
  List<Participant> _filteredParticipants = [];

  @override
  void initState() {
    super.initState();
    _filteredParticipants = widget.allParticipants;
    _searchController.addListener(_filterParticipants);
  }
  
  void _filterParticipants() {
      final query = _searchController.text.toLowerCase();
      setState(() {
          _filteredParticipants = widget.allParticipants.where((p) {
              return p.name.toLowerCase().contains(query) || 
                     p.course.toLowerCase().contains(query);
          }).toList();
      });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _markPresent(Participant participant) async {
      await DatabaseHelper.instance.addAttendance(widget.eventId, participant.id!, DateTime.now());
      widget.onAdded();
      if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF1C1F26),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
            Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                    children: [
                        const SizedBox(width: 40), // Spacer for centering
                        const Expanded(child: Center(child: Text("Select Attendee", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)))),
                         IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close, color: Colors.white70),
                        ),
                    ],
                ),
            ),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.black26,
                        hintText: "Search name or course...",
                        hintStyle: const TextStyle(color: Colors.white38),
                        prefixIcon: const Icon(Icons.search, color: Colors.white38),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                ),
            ),
            const SizedBox(height: 10),
            Expanded(
                child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredParticipants.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white10),
                    itemBuilder: (context, index) {
                        final p = _filteredParticipants[index];
                        return ListTile(
                            title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            subtitle: Text("${p.course} - ${p.year}", style: const TextStyle(color: Colors.grey)),
                            trailing: ElevatedButton(
                                onPressed: () => _markPresent(p),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1B61F3),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    minimumSize: Size.zero, 
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text("Time In"),
                            ),
                        );
                    },
                ),
            ),
        ],
      ),
    );
  }
}