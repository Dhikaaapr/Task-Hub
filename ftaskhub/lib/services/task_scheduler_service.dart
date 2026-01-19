import 'dart:async';
import 'package:logging/logging.dart';
import 'package:intl/intl.dart';

final _log = Logger('TaskSchedulerService');

class TaskSchedulerService {
  // Timer for checking task deadlines
  Timer? _deadlineTimer;

  // Time intervals for deadline notifications (in hours)
  static const List<int> deadlineIntervals = [1, 12, 24]; // 1 hour, 12 hours, 24 hours before deadline

  // Start the scheduler
  void startScheduler() {
    // Check for upcoming deadlines every 10 minutes
    _deadlineTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      _checkUpcomingDeadlines();
    });

    // Also run an initial check
    _checkUpcomingDeadlines();
  }

  // Stop the scheduler
  void stopScheduler() {
    _deadlineTimer?.cancel();
  }

  // Check for upcoming task deadlines
  Future<void> _checkUpcomingDeadlines() async {
    try {
      // This would typically fetch tasks from the backend API
      // For now, I'll implement a placeholder that would connect to your backend
      await _checkTasksForDeadlineNotifications();
    } catch (e) {
      _log.warning('Error checking upcoming deadlines: $e');
    }
  }

  // This method would typically fetch tasks from your backend API
  // and check if any are approaching their deadlines
  Future<void> _checkTasksForDeadlineNotifications() async {
    // In a real implementation, this would:
    // 1. Fetch all tasks with due dates from the backend
    // 2. Calculate which tasks are approaching their deadlines based on the intervals
    // 3. Create notifications for those tasks

    // Placeholder implementation - in a real app, this would connect to your backend API
    _log.info('Checking for upcoming task deadlines...');

    // Example logic for calculating deadline notifications:
    // For each task with a due date:
    // - Calculate time until deadline
    // - If time matches one of our intervals, create a notification

    // This is where you would integrate with your backend API
    // to fetch tasks and create notifications
  }

  // Calculate time remaining until deadline
  String calculateTimeRemaining(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'less than a minute';
    }
  }

  // Check if a task is approaching its deadline based on the intervals
  bool isApproachingDeadline(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inMinutes;

    for (final interval in deadlineIntervals) {
      // Check if the deadline is within the interval window (with a 5-minute buffer)
      final intervalInMinutes = interval * 60;
      if (difference >= 0 && difference <= intervalInMinutes && difference > (intervalInMinutes - 5)) {
        return true;
      }
    }

    return false;
  }

  // Format date for display
  String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy - HH:mm').format(date);
  }
}