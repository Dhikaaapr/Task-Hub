<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use Illuminate\Console\Scheduling\Schedule;
use App\Console\Commands\CheckTaskDeadlines;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // Schedule the task deadline checker
        $this->callAfterResolving(Schedule::class, function (Schedule $schedule) {
            $schedule->command('tasks:check-deadlines')
                     ->everyMinute()  // Check every minute for approaching deadlines
                     ->withoutOverlapping();
        });
    }
}