import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'db_helper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ISD Attendance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F1115),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B61F3),
          brightness: Brightness.dark,
          surface: const Color(0xFF1C1F26),
        ),
        useMaterial3: true,
      ),
      home: const EventsPage(),
    );
  }
}

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  late Future<List<Event>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _refreshEvents();
  }

  void _refreshEvents() {
    setState(() {
      _eventsFuture = DatabaseHelper.instance.readAllEvents();
    });
  }

  void _showAddEventModal(BuildContext context, {Event? event}) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEventModal(event: event),
    );

    if (result == true) {
      _refreshEvents();
    }
  }

  Future<void> _deleteEvent(int id) async {
    await DatabaseHelper.instance.delete(id);
    _refreshEvents();
  }

  Future<void> _toggleAttendance(Event event) async {
    final updatedEvent = event.copyWith(isRecorded: !event.isRecorded);
    await DatabaseHelper.instance.update(updatedEvent);
    _refreshEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.cloud_off, color: Colors.grey)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
        ],
      ),
      body: FutureBuilder<List<Event>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No events found', style: TextStyle(color: Colors.grey)));
          }

          final events = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Slidable(
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (context) => _showAddEventModal(context, event: event),
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        icon: Icons.edit,
                        label: 'Edit',
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                      ),
                      SlidableAction(
                        onPressed: (context) => _deleteEvent(event.id!),
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        icon: Icons.delete,
                        label: 'Delete',
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onTap: () => _toggleAttendance(event),
                    child: EventCard(
                      title: event.title,
                      tag: event.type,
                      tagColor: _getTagColor(event.type),
                      date: event.date,
                      isRecorded: event.isRecorded,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEventModal(context),
        backgroundColor: const Color(0xFF1B61F3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  Color _getTagColor(String type) {
    switch (type) {
      case 'Leadership':
        return Colors.blueAccent;
      case 'Outreach':
        return Colors.green;
      case 'Thanksgiving':
        return Colors.orange;
      case 'Community Service':
        return Colors.purple;
      case 'Scholar Meeting':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }
}

class AddEventModal extends StatefulWidget {
  final Event? event;
  const AddEventModal({super.key, this.event});

  @override
  State<AddEventModal> createState() => _AddEventModalState();
}

class _AddEventModalState extends State<AddEventModal> {
  late DateTime selectedDate;
  late TextEditingController _titleController;
  String? _selectedType;
  
  final List<String> _eventTypes = [
    'Leadership',
    'Outreach',
    'Thanksgiving',
    'Community Service',
    'Scholar Meeting',
    'Seminar',
    'Workshop',
    'Fundraising'
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    selectedDate = widget.event?.date ?? DateTime.now();
    _titleController = TextEditingController(text: widget.event?.title);
    _selectedType = widget.event?.type;
  }

  @override
  void dispose() {
    _titleController.dispose();
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
        height: MediaQuery.of(context).size.height * 0.9,
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
                  _buildLabel("Event Name"),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: "e.g., Annual General Assembly",
                      hintStyle: TextStyle(color: Colors.grey[400]),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildLabel("Event Type"),
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    hint: Text("Select type...", style: TextStyle(color: Colors.grey[600])),
                    items: _eventTypes.map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedType = newValue;
                      });
                    },
                    decoration: const InputDecoration(), // Uses theme
                  ),
                  const SizedBox(height: 20),
                  _buildLabel("Select Date"),
                  _buildCalendar(),
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
              Text(widget.event == null ? "New Event" : "Edit Event", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1A1C1E))),
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

  Widget _buildCalendar() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
      child: CalendarDatePicker(
        initialDate: selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
        onDateChanged: (date) => setState(() => selectedDate = date),
      ),
    );
  }

  Widget _buildCreateButton() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _saveEvent,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B61F3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: Text(widget.event == null ? "Create Event" : "Update Event", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  void _saveEvent() async {
    if (_titleController.text.isEmpty || _selectedType == null) {
      // Basic validation
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    if (widget.event == null) {
      final event = Event(
        title: _titleController.text,
        type: _selectedType!,
        date: selectedDate,
        isRecorded: false,
      );
      await DatabaseHelper.instance.create(event);
    } else {
      final updatedEvent = widget.event!.copyWith(
        title: _titleController.text,
        type: _selectedType!,
        date: selectedDate,
      );
      await DatabaseHelper.instance.update(updatedEvent);
    }
    
    if (mounted) {
        Navigator.pop(context, true);
    }
  }
}

class EventCard extends StatelessWidget {

  final String title;

  final String tag;

  final Color tagColor;

  final DateTime date;

  final bool isRecorded;



  const EventCard({

    super.key,

    required this.title,

    required this.tag,

    required this.tagColor,

    required this.date,

    required this.isRecorded,

  });



  @override

  Widget build(BuildContext context) {

    return Container(

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(color: const Color(0xFF1C1F26), borderRadius: BorderRadius.circular(16)),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),

          const SizedBox(height: 12),

          Row(

            children: [

              Container(

                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),

                decoration: BoxDecoration(color: tagColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),

                child: Text(tag, style: TextStyle(color: tagColor, fontSize: 12, fontWeight: FontWeight.bold)),

              ),

              const SizedBox(width: 12),

              const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),

              const SizedBox(width: 4),

              Text(DateFormat.yMMMd().format(date), style: const TextStyle(color: Colors.grey, fontSize: 12)),

            ],

          ),

          const SizedBox(height: 12),

          const Divider(color: Colors.white12),

          Row(

            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [

              Row(

                children: [

                  Icon(isRecorded ? Icons.check_circle : Icons.circle, size: 14, color: isRecorded ? Colors.green : Colors.redAccent),

                  const SizedBox(width: 8),

                  Text(isRecorded ? 'Attendance recorded' : 'No attendance yet', style: const TextStyle(color: Colors.grey, fontSize: 12)),

                ],

              ),

            ],

          ),

        ],

      ),

    );

  }

}
