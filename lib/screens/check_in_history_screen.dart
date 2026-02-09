  import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/graphql_service.dart';
import '../models/checkin_model.dart';

class CheckInHistoryScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const CheckInHistoryScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<CheckInHistoryScreen> createState() => _CheckInHistoryScreenState();
}

class _CheckInHistoryScreenState extends State<CheckInHistoryScreen> {
  bool _isLoading = true;
  List<CheckIn> _checkIns = [];

  @override
  void initState() {
    super.initState();
    _fetchCheckIns();
  }

  Future<void> _fetchCheckIns() async {
    try {
      final checkIns = await GraphQLService.getCheckIns(
        where: {
          'userId': {'eq': widget.userId}
        },
      );

      if (mounted) {
        setState(() {
          // Sort by date descending
          _checkIns = checkIns..sort((a, b) => (b.timestamp ?? DateTime.now()).compareTo(a.timestamp ?? DateTime.now()));
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading history: $e')),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ok':
        return Colors.green;
      case 'not ok':
        return Colors.red;
      case 'missed':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.userName}\'s History'),
        backgroundColor: const Color(0xFF1F4ED8),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _checkIns.isEmpty
              ? const Center(
                  child: Text(
                    'No check-in history found.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _checkIns.length,
                  itemBuilder: (context, index) {
                    final checkIn = _checkIns[index];
                    final dateStr = DateFormat('MMM d, yyyy h:mm a').format((checkIn.timestamp ?? DateTime.now()).toLocal());
                    
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  dateStr,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(checkIn.status).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _getStatusColor(checkIn.status),
                                    ),
                                  ),
                                  child: Text(
                                    checkIn.status.toUpperCase(),
                                    style: TextStyle(
                                      color: _getStatusColor(checkIn.status),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (checkIn.metadata?['notes'] != null && checkIn.metadata!['notes'].isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Notes: ${checkIn.metadata!['notes']}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                            if (checkIn.location != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Location captured',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
