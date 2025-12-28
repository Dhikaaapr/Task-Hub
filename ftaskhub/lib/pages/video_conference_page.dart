import 'package:flutter/material.dart';

class VideoConferencePage extends StatefulWidget {
  final String meetingId;
  final String meetingName;

  const VideoConferencePage({
    super.key,
    required this.meetingId,
    this.meetingName = "Group Meeting",
  });

  @override
  State<VideoConferencePage> createState() => _VideoConferencePageState();
}

class _VideoConferencePageState extends State<VideoConferencePage> {
  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _isJoined = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main video area
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey[900],
            child: _isJoined
                ? const Center(
                    child: Icon(
                      Icons.videocam,
                      color: Colors.white,
                      size: 100,
                    ),
                  )
                : const Center(
                    child: Text(
                      "Waiting to join meeting...",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
          ),
          
          // Top bar with meeting info
          SafeArea(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.video_call, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.meetingName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.info, color: Colors.white),
                    onPressed: () {
                      _showMeetingInfo();
                    },
                  ),
                ],
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Toggle microphone
                    _buildControlButton(
                      icon: _isMuted ? Icons.mic_off : Icons.mic,
                      color: _isMuted ? Colors.red : Colors.white,
                      onPressed: () {
                        setState(() {
                          _isMuted = !_isMuted;
                        });
                      },
                    ),
                    
                    // Join/leave call button
                    _buildLargeControlButton(
                      icon: _isJoined ? Icons.call_end : Icons.videocam,
                      color: _isJoined ? Colors.red : Colors.green,
                      label: _isJoined ? "Leave" : "Join",
                      onPressed: () {
                        setState(() {
                          _isJoined = !_isJoined;
                        });
                      },
                    ),
                    
                    // Toggle video
                    _buildControlButton(
                      icon: _isVideoOff ? Icons.videocam_off : Icons.videocam,
                      color: _isVideoOff ? Colors.red : Colors.white,
                      onPressed: () {
                        setState(() {
                          _isVideoOff = !_isVideoOff;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.black54,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24),
      ),
      child: Center(
        child: IconButton(
          icon: Icon(icon, color: color),
          onPressed: onPressed,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildLargeControlButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMeetingInfo() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Meeting Info"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Meeting ID: ${widget.meetingId}"),
              const SizedBox(height: 8),
              const Text("Meeting Name: Team Standup"),
              const SizedBox(height: 8),
              Text("Participants: ${_isJoined ? "You and 2 others" : "Waiting for participants..."}"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }
}