import 'package:flutter/material.dart';
import '../models/task_hub_service.dart';
import '../models/task.dart';

class ChatPage extends StatefulWidget {
  final String groupTitle;
  final List<String> members;

  const ChatPage({super.key, required this.groupTitle, required this.members});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController messageController = TextEditingController();
  final List<ChatMessage> messages = [];
  final TaskHubService _taskHubService = TaskHubService();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _taskHubService.initialize();
    // Add some sample messages
    messages.add(ChatMessage(
      sender: "Andhika",
      text: "Welcome to the group chat!",
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      type: MessageType.text,
    ));
    messages.add(ChatMessage(
      sender: "System",
      text: "Andhika updated the progress of 'UI Design' to 75%",
      timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
      type: MessageType.progressUpdate,
    ));
  }

  void _sendMessage() async {
    final text = messageController.text.trim();
    if (text.isNotEmpty && !_isSending) {
      setState(() {
        _isSending = true;
      });

      // Simulate sending message
      await Future.delayed(const Duration(milliseconds: 300));

      setState(() {
        messages.add(ChatMessage(
          sender: "You",
          text: text,
          timestamp: DateTime.now(),
          type: MessageType.text,
        ));
        messageController.clear();
        _isSending = false;
      });
    }
  }

  void _sendProgressUpdate(Task task, int newProgress) {
    final progressUpdateText =
        "Updated progress of '${task.title}' to $newProgress%";

    setState(() {
      messages.add(ChatMessage(
        sender: "You",
        text: progressUpdateText,
        timestamp: DateTime.now(),
        type: MessageType.progressUpdate,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        title: Text(widget.groupTitle),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
        backgroundColor: const Color(0xFF0A2E5C),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (String result) {
              if (result == 'members') {
                _showMembersBottomSheet();
              } else if (result == 'progress') {
                _showProgressUpdatesBottomSheet();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'members',
                child: Text('Group Members'),
              ),
              const PopupMenuItem<String>(
                value: 'progress',
                child: Text('Progress Updates'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true, // New messages appear at the bottom
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[messages.length - 1 - index];
                final isMe = message.sender == "You";

                return Align(
                  alignment: isMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 14,
                    ),
                    decoration: BoxDecoration(
                      color: _getMessageColor(message, isMe),
                      borderRadius: _getMessageBorderRadius(message, isMe),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (message.type == MessageType.progressUpdate) ...[
                          Row(
                            children: [
                              const Icon(
                                Icons.trending_up,
                                size: 16,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "Progress Update",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _getTextColor(isMe, message.type),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          message.text,
                          style: TextStyle(
                            color: _getTextColor(isMe, message.type),
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTime(message.timestamp),
                          style: TextStyle(
                            fontSize: 11,
                            color: _getTimeColor(isMe),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                // Task progress button
                PopupMenuButton<Task>(
                  onSelected: (Task task) {
                    _showProgressUpdateDialog(task);
                  },
                  itemBuilder: (BuildContext context) {
                    // Get tasks for this group
                    final tasks = _taskHubService.getTasksByGroup("dummy_group_id");
                    return tasks.map((task) {
                      return PopupMenuItem<Task>(
                        value: task,
                        child: Row(
                          children: [
                            const Icon(Icons.trending_up, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${task.title} (${task.progress}%)',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.trending_up,
                      color: Color(0xFF0A2E5C),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Message input
                Expanded(
                  child: TextField(
                    controller: messageController,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      fillColor: Colors.grey[200],
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Send button
                CircleAvatar(
                  backgroundColor: const Color(0xFF0A2E5C),
                  child: IconButton(
                    icon: Icon(
                      _isSending ? Icons.hourglass_empty : Icons.send,
                      color: Colors.white,
                    ),
                    onPressed: _isSending ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getMessageColor(ChatMessage message, bool isMe) {
    if (message.type == MessageType.progressUpdate) {
      return Colors.blue[50]!;
    }
    return isMe ? Colors.lightBlueAccent : Colors.white.withValues(alpha: 0.9);
  }

  BorderRadius _getMessageBorderRadius(ChatMessage message, bool isMe) {
    if (isMe) {
      return BorderRadius.only(
        topLeft: const Radius.circular(20),
        topRight: const Radius.circular(5),
        bottomLeft: const Radius.circular(20),
        bottomRight: const Radius.circular(20),
      );
    } else {
      return BorderRadius.only(
        topLeft: const Radius.circular(5),
        topRight: const Radius.circular(20),
        bottomLeft: const Radius.circular(20),
        bottomRight: const Radius.circular(20),
      );
    }
  }

  Color _getTextColor(bool isMe, MessageType type) {
    if (type == MessageType.progressUpdate) {
      return Colors.blue[800]!;
    }
    return isMe ? Colors.white : Colors.black87;
  }

  Color _getTimeColor(bool isMe) {
    return isMe ? Colors.white70 : Colors.grey[600]!;
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return "Just now";
    } else if (difference.inMinutes < 60) {
      return "${difference.inMinutes}m ago";
    } else if (difference.inHours < 24) {
      return "${difference.inHours}h ago";
    } else {
      return "${difference.inDays}d ago";
    }
  }

  void _showMembersBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Group Members",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            ...widget.members.map(
              (m) => ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF0A2E5C),
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(m),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showProgressUpdatesBottomSheet() {
    final progressMessages = messages
        .where((msg) => msg.type == MessageType.progressUpdate)
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Progress Updates",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            if (progressMessages.isEmpty)
              const Center(
                child: Text("No progress updates yet"),
              )
            else
              ...progressMessages.map(
                (msg) => ListTile(
                  leading: const Icon(
                    Icons.trending_up,
                    color: Colors.blue,
                  ),
                  title: Text(msg.text),
                  subtitle: Text(
                    _formatTime(msg.timestamp),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showProgressUpdateDialog(Task task) {
    int progressValue = task.progress;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Task Progress'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Updating: ${task.title}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Slider(
                value: progressValue.toDouble(),
                min: 0,
                max: 100,
                divisions: 100,
                label: '${progressValue.round()}%',
                activeColor: const Color(0xFF0A2E5C),
                onChanged: (double value) {
                  setState(() {
                    progressValue = value.round();
                  });
                },
              ),
              Text(
                '${progressValue.round()}%',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _taskHubService.updateTaskProgress(task.id, progressValue);
                _sendProgressUpdate(task, progressValue);
                Navigator.of(context).pop();
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }
}

// Enum for message types
enum MessageType { text, progressUpdate }

// Class to represent a chat message
class ChatMessage {
  final String sender;
  final String text;
  final DateTime timestamp;
  final MessageType type;

  ChatMessage({
    required this.sender,
    required this.text,
    required this.timestamp,
    required this.type,
  });
}
