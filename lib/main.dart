import 'package:flutter/material.dart';

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

class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  void _showAddEventModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddEventModal(),
    );
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          EventCard(
            title: 'General Assembly Meeting',
            tag: 'Meeting',
            tagColor: Colors.blueAccent,
            date: 'Oct 24, 2023',
            isRecorded: false,
            hours: '4 Hours',
          ),
          EventCard(
            title: 'Coastal Cleanup Drive',
            tag: 'Cleanup',
            tagColor: Colors.green,
            date: 'Oct 10, 2023',
            isRecorded: true,
            hours: '6 Hours',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEventModal(context),
        backgroundColor: const Color(0xFF1B61F3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }
}

class AddEventModal extends StatefulWidget {
  const AddEventModal({super.key});

  @override
  State<AddEventModal> createState() => _AddEventModalState();
}

class _AddEventModalState extends State<AddEventModal> {
  int duration = 2;
  DateTime selectedDate = DateTime(2023, 10, 5);

  @override
  Widget build(BuildContext context) {
    // We wrap the modal in a Theme widget to force light mode styles locally
    return Theme(
      data: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF1B61F3),
        colorScheme: const ColorScheme.light(primary: Color(0xFF1B61F3)),
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
                  _buildTextField("e.g., Annual General Assembly"),
                  const SizedBox(height: 20),
                  _buildLabel("Event Type"),
                  _buildDropdownField("Select type..."),
                  const SizedBox(height: 20),
                  _buildLabel("Duration (Hours)"),
                  _buildNumberPicker(),
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
              const Text("New Event", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1A1C1E))),
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

  Widget _buildTextField(String hint) {
    return TextField(
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildDropdownField(String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(hint, style: TextStyle(color: Colors.grey[600])),
          const Icon(Icons.unfold_more, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildNumberPicker() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _pickerButton(Icons.remove, const Color(0xFFE8F0FE), const Color(0xFF1B61F3), () {
            if (duration > 1) setState(() => duration--);
          }),
          Text("$duration", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          _pickerButton(Icons.add, const Color(0xFF1B61F3), Colors.white, () {
            setState(() => duration++);
          }),
        ],
      ),
    );
  }

  Widget _pickerButton(IconData icon, Color bg, Color iconColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: iconColor, size: 20),
      ),
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
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B61F3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: const Text("Create Event", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

class EventCard extends StatelessWidget {
  final String title;
  final String tag;
  final Color tagColor;
  final String date;
  final bool isRecorded;
  final String hours;

  const EventCard({super.key, required this.title, required this.tag, required this.tagColor, required this.date, required this.isRecorded, required this.hours});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
              Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
              Text(hours, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
