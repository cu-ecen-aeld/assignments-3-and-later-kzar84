#include "threading.h"
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>

// Optional: use these functions to add debug or error prints to your application
#define DEBUG_LOG(msg,...)
//#define DEBUG_LOG(msg,...) printf("threading: " msg "\n" , ##__VA_ARGS__)
#define ERROR_LOG(msg,...) printf("threading ERROR: " msg "\n" , ##__VA_ARGS__)

void* threadfunc(void* thread_param)
{
    // TODO: wait, obtain mutex, wait, release mutex as described by thread_data structure
    // hint: use a cast like the one below to obtain thread arguments from your parameter
    //struct thread_data* thread_func_args = (struct thread_data *) thread_param;
    
    struct thread_data* thread_func_args = (struct thread_data *) thread_param;

    // Wait to obtain
    int ret = usleep(thread_func_args->obtain_wait_time_ms*1000);
    if (ret != 0)
        return thread_param;

    // Lock
    pthread_mutex_lock(thread_func_args->mtx);
    if (ret != 0) {
        thread_func_args->thread_complete_success = false;
        return thread_param;
    }

    // Wait to release
    ret = usleep(thread_func_args->release_wait_time_ms*1000);
    if (ret != 0)
        return thread_param;

    // Unlock
    ret = pthread_mutex_unlock(thread_func_args->mtx);

    thread_func_args->thread_complete_success = true;

    return thread_param;
}


bool start_thread_obtaining_mutex(pthread_t *thread, pthread_mutex_t *mutex,int wait_to_obtain_ms, int wait_to_release_ms)
{
    /**
     * TODO: allocate memory for thread_data, setup mutex and wait arguments, pass thread_data to created thread
     * using threadfunc() as entry point.
     *
     * return true if successful.
     *
     * See implementation details in threading.h file comment block
     */

    // Create thread args struct
    struct thread_data *args = (struct thread_data*) malloc(sizeof(struct thread_data));
    args->obtain_wait_time_ms = wait_to_obtain_ms;
    args->release_wait_time_ms = wait_to_release_ms;
    args->mtx = mutex;
    args->thread_complete_success = false;

    int ret;

    ret = pthread_create(thread, NULL, threadfunc, (void*) args);
    if (ret != 0) {
        free(args);
        return false;
    }
    
    // I was initially detaching the thread which caused to to be unjoinable.
    // Referenced  https://github.com/cu-ecen-aeld/assignments-3-and-later-eazimi to find my mistake   
    // ret = pthread_detach(*thread);
    // if (ret == 0)
    //     return true;

    return true;
}

