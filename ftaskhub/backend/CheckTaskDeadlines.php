<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\Task;
use App\Models\Group;
use App\Services\NotificationService;
use Carbon\Carbon;

class CheckTaskDeadlines extends Command
{
    protected $signature = 'tasks:check-deadlines';
    protected $description = 'Check for tasks approaching their deadlines and send notifications';

    private $notificationService;

    public function __construct(NotificationService $notificationService)
    {
        parent::__construct();
        $this->notificationService = $notificationService;
    }

    public function handle()
    {
        $this->info('Checking for tasks approaching deadlines...');

        // Define the time intervals to check (in minutes)
        $intervals = [
            60,    // 1 hour
            720,   // 12 hours 
            1440   // 24 hours
        ];

        foreach ($intervals as $interval) {
            $this->checkDeadlineInterval($interval);
        }

        $this->info('Task deadline check completed.');
    }

    private function checkDeadlineInterval(int $minutesBeforeDeadline): void
    {
        $targetTime = Carbon::now()->addMinutes($minutesBeforeDeadline);
        $bufferStart = $targetTime->copy()->subMinutes(2); // 2-minute buffer
        $bufferEnd = $targetTime->copy()->addMinutes(2);   // 2-minute buffer

        $tasks = Task::whereBetween('due_date', [$bufferStart, $bufferEnd])
                     ->where('status', '!=', 'done') // Only notify for incomplete tasks
                     ->get();

        foreach ($tasks as $task) {
            $this->createDeadlineNotification($task, $minutesBeforeDeadline);
        }
    }

    private function createDeadlineNotification(Task $task, int $minutesBeforeDeadline): void
    {
        // Get the group for the task
        $group = Group::find($task->group_id);
        if (!$group) {
            $this->error("Group not found for task {$task->id}");
            return;
        }

        // Determine the time remaining string
        $timeRemaining = $this->formatTimeRemaining($minutesBeforeDeadline);

        // Create notification for the task assignee
        $this->notificationService->createTaskDeadlineNotification(
            $task->assignee_id,
            $task,
            $group->name,
            $timeRemaining
        );

        // Optionally, notify other group members about the approaching deadline
        $this->notifyOtherGroupMembers($task, $group, $timeRemaining);
    }

    private function notifyOtherGroupMembers(Task $task, Group $group, string $timeRemaining): void
    {
        // Get all group members except the assignee
        $members = $group->members()
                        ->where('users.id', '!=', $task->assignee_id)
                        ->get();

        foreach ($members as $member) {
            $this->notificationService->createTaskDeadlineNotification(
                $member->id,
                $task,
                $group->name,
                $timeRemaining
            );
        }
    }

    private function formatTimeRemaining(int $minutes): string
    {
        if ($minutes >= 1440) { // 24 hours or more
            $days = floor($minutes / 1440);
            return "{$days} day" . ($days > 1 ? 's' : '');
        } elseif ($minutes >= 60) { // 1 hour or more
            $hours = floor($minutes / 60);
            return "{$hours} hour" . ($hours > 1 ? 's' : '');
        } else { // Less than 1 hour
            return "{$minutes} minute" . ($minutes > 1 ? 's' : '');
        }
    }
}