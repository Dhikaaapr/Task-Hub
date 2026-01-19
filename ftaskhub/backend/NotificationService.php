<?php

namespace App\Services;

use App\Models\Notification;
use App\Models\Task;
use App\Models\Group;
use App\Models\User;

class NotificationService
{
    /**
     * Create a group join notification
     */
    public function createGroupJoinNotification(string $userId, string $groupId, string $groupName): Notification
    {
        return Notification::create([
            'user_id' => $userId,
            'title' => 'Group Invitation',
            'message' => "You have been added to the group: $groupName",
            'type' => 'group_join',
            'data' => [
                'group_id' => $groupId,
                'group_name' => $groupName,
            ],
            'is_read' => false
        ]);
    }

    /**
     * Create a task deadline notification
     */
    public function createTaskDeadlineNotification(string $userId, Task $task, string $groupName, string $timeRemaining): Notification
    {
        return Notification::create([
            'user_id' => $userId,
            'title' => 'Task Deadline Approaching',
            'message' => "Task \"{$task->title}\" in group \"$groupName\" is due in $timeRemaining",
            'type' => 'task_deadline',
            'data' => [
                'task_id' => $task->id,
                'task_title' => $task->title,
                'group_id' => $task->group_id,
                'group_name' => $groupName,
                'due_date' => $task->due_date,
            ],
            'is_read' => false
        ]);
    }

    /**
     * Create a task assignment notification
     */
    public function createTaskAssignmentNotification(string $userId, Task $task, string $groupName): Notification
    {
        return Notification::create([
            'user_id' => $userId,
            'title' => 'Task Assigned',
            'message' => "You have been assigned to task: {$task->title} in group $groupName",
            'type' => 'task_assignment',
            'data' => [
                'task_id' => $task->id,
                'task_title' => $task->title,
                'group_id' => $task->group_id,
                'group_name' => $groupName,
                'due_date' => $task->due_date,
            ],
            'is_read' => false
        ]);
    }

    /**
     * Create a group created notification
     */
    public function createGroupCreatedNotification(string $userId, string $groupId, string $groupName): Notification
    {
        return Notification::create([
            'user_id' => $userId,
            'title' => 'Group Created',
            'message' => "New group created: $groupName",
            'type' => 'group_created',
            'data' => [
                'group_id' => $groupId,
                'group_name' => $groupName,
            ],
            'is_read' => false
        ]);
    }

    /**
     * Create a task created notification
     */
    public function createTaskCreatedNotification(string $userId, Task $task, string $groupName): Notification
    {
        return Notification::create([
            'user_id' => $userId,
            'title' => 'Task Created',
            'message' => "New task created: {$task->title} in group $groupName",
            'type' => 'task_created',
            'data' => [
                'task_id' => $task->id,
                'task_title' => $task->title,
                'group_id' => $task->group_id,
                'group_name' => $groupName,
                'due_date' => $task->due_date,
            ],
            'is_read' => false
        ]);
    }

    /**
     * Create notifications for all group members when a task is created
     */
    public function createTaskCreatedNotificationsForGroup(Task $task, Group $group): void
    {
        $members = $group->members()->where('users.id', '!=', $task->created_by)->get();
        
        foreach ($members as $member) {
            $this->createTaskCreatedNotification($member->id, $task, $group->name);
        }
    }

    /**
     * Create notifications for all group members when a group is created
     */
    public function createGroupCreatedNotificationsForMembers(Group $group, array $memberIds): void
    {
        foreach ($memberIds as $memberId) {
            $this->createGroupCreatedNotification($memberId, $group->id, $group->name);
        }
    }
}