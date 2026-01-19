# TaskHub Notification System

This document describes the implementation of the notification system for the TaskHub mobile application.

## Features

### 1. Group & Task Notifications
- When a user creates a group or joins an existing group, a notification appears in the notification icon (bell)
- All notifications are stored and displayed in a notification page inside the app

### 2. Task Deadline Notifications
- Each group can have multiple tasks created by different members
- When a task is approaching its deadline (24 hours, 12 hours, or 1 hour before), the system automatically triggers a notification
- The notification shows:
  - Task title
  - Group name
  - Remaining time before deadline

### 3. Real-time & Badge Indicator
- The notification icon displays a badge count when there are unread notifications
- Once a notification is opened, it's marked as read and the badge count is updated

## Architecture

### Frontend (Flutter)
- **Models**: `Notification`, `NotificationType`, `GroupNotificationData`, `TaskNotificationData`
- **Services**: 
  - `NotificationService`: Handles all notification operations
  - `NotificationApiService`: Handles API communication
  - `SupabaseNotificationService`: Handles Supabase communication
  - `NotificationProvider`: Manages notification state with Provider pattern
- **UI Components**:
  - `NotificationPage`: Displays all notifications
  - `NotificationBadge`: Shows unread count as a badge
  - `NotificationItem`: Individual notification display component

### Backend (Laravel/Supabase)
- **Models**: `Notification` model with relationships
- **Controllers**: `NotificationController` with CRUD operations
- **Services**: `NotificationService` with business logic
- **Commands**: `CheckTaskDeadlines` scheduled command for deadline notifications
- **Database**: `notifications` table with proper indexing

## Database Schema

```sql
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(255) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) NOT NULL,
    data JSONB,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);
CREATE INDEX idx_notifications_type ON notifications(type);
```

## API Endpoints

- `GET /api/notifications` - Get all notifications for user
- `GET /api/notifications/unread-count` - Get unread notifications count
- `POST /api/notifications` - Create a new notification
- `PUT /api/notifications/{id}/read` - Mark notification as read
- `PUT /api/notifications/mark-all-read` - Mark all notifications as read
- `DELETE /api/notifications/{id}` - Delete a notification

## Background Jobs

The system includes a scheduled job that runs every minute to check for tasks approaching their deadlines:

- Checks for tasks due in 1 hour, 12 hours, and 24 hours
- Creates deadline notifications for tasks approaching these timeframes
- Notifies both the task assignee and other group members

## Integration

The notification system supports both:
- Laravel API backend
- Supabase database backend

The `NotificationService` can be configured to use either backend via the `setBackend()` method.

## Usage

### Initializing the Notification System

```dart
// In your main app or login screen
final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
notificationProvider.initialize(userId, token: authToken);
```

### Creating Notifications

```dart
// Create a task deadline notification
await notificationService.createTaskDeadlineNotification(
  userId: userId,
  task: task,
  groupName: groupName,
  timeRemaining: '1 hour',
);
```

### Displaying Unread Count

```dart
Consumer<NotificationProvider>(
  builder: (context, notificationProvider, child) {
    return NotificationBadge(
      child: Icon(Icons.notifications),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => NotificationPage()),
      ),
    );
  },
)
```

## Scalability Considerations

- Proper database indexing for efficient queries
- Polling mechanism for real-time updates (could be enhanced with WebSocket for better performance)
- Background job scheduling for deadline notifications
- Support for multiple backend options (API and Supabase)

## Security

- All API endpoints require authentication
- Users can only access their own notifications
- Proper validation of input data

## Testing

The system includes integration tests to verify all components work together properly.