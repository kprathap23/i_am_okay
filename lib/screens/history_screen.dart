import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/checkin_model.dart';
import '../services/graphql_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoading = true;
  List<CheckIn> _checkIns = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCheckIns();
  }

  Future<void> _fetchCheckIns() async {
    try {
      final checkIns = await GraphQLService.getCheckIns();
      if (mounted) {
        setState(() {
          _checkIns = checkIns;
          _checkIns.sort((a, b) => (b.timestamp ?? b.createdAt ?? DateTime.now())
              .compareTo(a.timestamp ?? a.createdAt ?? DateTime.now()));
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Something went wrong. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF1F4ED8),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error loading history',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.red[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF333333)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _fetchCheckIns();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F4ED8),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_checkIns.isEmpty) {
      return const Center(
        child: Text(
          'No history available yet.',
          style: TextStyle(
            fontSize: 18.0,
            color: Color(0xFF333333),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchCheckIns,
      color: const Color(0xFF1F4ED8),
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _checkIns.length,
        itemBuilder: (context, index) {
          final checkIn = _checkIns[index];
          final date = (checkIn.timestamp ?? checkIn.createdAt ?? DateTime.now()).toLocal();
          final formattedDate = DateFormat('MMM d, yyyy').format(date);
          final formattedTime = DateFormat('h:mm a').format(date);

          return Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _showCheckInDetails(context, checkIn),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _getStatusColor(checkIn.status).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getStatusIcon(checkIn.status),
                        color: _getStatusColor(checkIn.status),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            checkIn.status,
                            style: const TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF000000),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$formattedDate at $formattedTime',
                            style: const TextStyle(
                              fontSize: 14.0,
                              color: Color(0xFF666666),
                            ),
                          ),
                          if (_hasValidLocation(checkIn.location)) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: Color(0xFF666666),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'Location available',
                                  style: TextStyle(
                                    fontSize: 12.0,
                                    color: Color(0xFF666666),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  bool _hasValidLocation(Map<String, dynamic>? location) {
    if (location == null) return false;
    try {
      final lat = double.tryParse(location['lat'].toString());
      final lng = double.tryParse(location['lng'].toString());
      return lat != null && lng != null && (lat != 0 || lng != 0);
    } catch (e) {
      return false;
    }
  }

  Future<void> _showCheckInDetails(BuildContext context, CheckIn checkIn) async {
    final date = (checkIn.timestamp ?? checkIn.createdAt ?? DateTime.now()).toLocal();
    final formattedDate = DateFormat('MMM d, yyyy').format(date);
    final formattedTime = DateFormat('h:mm a').format(date);

    double? lat;
    double? lng;

    if (checkIn.location != null) {
      if (checkIn.location!.containsKey('lat')) {
        lat = double.tryParse(checkIn.location!['lat'].toString());
      }
      if (checkIn.location!.containsKey('lng')) {
        lng = double.tryParse(checkIn.location!['lng'].toString());
      }
    }

    // Check if location is valid (not 0,0 and not null)
    final bool hasValidLocation = _hasValidLocation(checkIn.location);

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Check-in Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status: ${checkIn.status}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Date: $formattedDate'),
            Text('Time: $formattedTime'),
            const SizedBox(height: 16),
            if (hasValidLocation)
              const Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Color(0xFF1F4ED8)),
                  SizedBox(width: 4),
                  Text(
                    'Location available',
                    style: TextStyle(
                      color: Color(0xFF1F4ED8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            else
              const Text(
                'Location not available',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF333333),
            ),
            child: const Text('Close'),
          ),
          if (hasValidLocation)
            ElevatedButton.icon(
              onPressed: () async {
                final Uri navigationUrl =
                    Uri.parse('google.navigation:q=$lat,$lng');
                final Uri webUrl = Uri.parse(
                    'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
                try {
                  if (await canLaunchUrl(navigationUrl)) {
                    await launchUrl(navigationUrl);
                  } else if (await canLaunchUrl(webUrl)) {
                    await launchUrl(webUrl, mode: LaunchMode.externalApplication);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Could not open maps application')),
                      );
                    }
                  }
                } catch (e) {
                  debugPrint('Error launching map: $e');
                }
              },
              icon: const Icon(Icons.map, size: 18),
              label: const Text('Navigate'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F4ED8),
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ok':
      case 'safe':
        return Colors.green;
      case 'emergency':
      case 'danger':
        return Colors.red;
      default:
        return const Color(0xFF1F4ED8);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'ok':
      case 'safe':
        return Icons.check_circle_outline;
      case 'emergency':
      case 'danger':
        return Icons.warning_amber_rounded;
      default:
        return Icons.info_outline;
    }
  }
}
