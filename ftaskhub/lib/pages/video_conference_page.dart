import 'package:flutter/material.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';

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
  final _jitsiMeetPlugin = JitsiMeet();

  Future<void> _launchMeeting() async {
    var options = JitsiMeetConferenceOptions(
      room: widget.meetingId,
      configOverrides: {
        "startWithAudioMuted": true,
        "startWithVideoMuted": true,
        "subject": widget.meetingName,
      },
      featureFlags: {
        "unsaferoomwarning.enabled": false,
      },
      userInfo: JitsiMeetUserInfo(
        displayName: "TaskHub User",
        email: "user@taskhub.com",
      ),
    );

    await _jitsiMeetPlugin.join(options);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background/Placeholder
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey[900],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.video_camera_front,
                  color: Colors.white,
                  size: 100,
                ),
                const SizedBox(height: 24),
                const Text(
                  "Ready to join?",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Meeting: ${widget.meetingName}",
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 48),
                ElevatedButton.icon(
                  onPressed: _launchMeeting,
                  icon: const Icon(Icons.video_call),
                  label: const Text("Launch Meeting"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "This will open safe & free Jitsi Meet",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          
          // Close button
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}