---
author: "ysw1912"
date: 2018-07-15T08:00:00+08:00
lastmod: 2018-07-15T10:50:00+08:00
title: "POSIX thread"
tags: [
    "C/C++"
]
categories: [
    "C/C++"
]
---

&emsp;&emsp;《APUE》这本书算是个字典了，本文算是对 pthread 的一些总结，主要是对原书中几段代码的解释说明，在读代码中记录知识点，技术含量不高。

&emsp;&emsp;首先给出一个以分离状态创建线程的函数。

```cpp
int make_thread(void* (*fn)(void*), void* arg)
{
    int             err;
    pthread_t       tid;
    pthread_attr_t  attr;

    err = pthread_attr_init(&attr);
    if (err != 0)
        return err;
    err = pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
    if (err == 0)
        err = pthread_create(&tid, &attr, fn, arg);
    pthread_attr_destroy(&attr);
    return err;
}
```

&emsp;&emsp;pthread 接口允许给“线程对象`pthread_t`”或“线程的同步对象”（如互斥量`pthread_mutex_t`、条件变量、锁等）关联相应的“属性对象”。使用`int pthread_attr_init(pthread_attr_t *attr)`可以为 attr 所指向的属性对象初始化内存空间，相应地释放内存使用`int pthread_attr_destroy(pthread_attr_t *attr)`。

&emsp;&emsp;一个属性对象可以代表多个属性。对于每个属性，都有一个设置属性值的函数。例如本例中设置“分离状态 detach state 属性”是使用`int pthread_attr_setdetachstate(pthread_attr_t *attr, int *detachstate)`。

&emsp;&emsp;创建新线程通过调用`int pthread_create(pthread_t *restrict tidp, const pthread_attr_t *restrict attr, void* (*start_rtn)(void*), void *restrict arg)`。

- 函数成功返回时，所创建的线程的 ID 会赋值给 tidp 所指，Linux 中线程 ID 用 unsigned long （%lu / 0x%lx）表示，每个线程可以通过调用`pthread_t pthread_self()`获得自身的 ID。
- attr 所指的是上述的线程属性对象，用来定制不同的属性。若设为 NULL，则表示默认属性。
- start_rtn 是新线程开始运行的函数地址。
- 该函数只有一个 void* 类型参数 arg，指向一个 struct，而这个 struct 中存储着 start_rtn 真正所需的参数，只需要将 arg 强制类型转换成 struct 指针即可。使用 void *arg 传递参数的方法大致如下，struct to_info 就存储着 timeout 函数（见后文）传递给 timeout_helper 函数的参数。

```cpp
typedef struct to_info
{
    void            (*to_fn)(void*);
    void *          to_arg;
    struct timespec to_wait;
}to_info;

void* timeout_helper(void* arg)
{
    struct to_info* tip = (struct to_info*)arg;
    clock_nanosleep(CLOCK_REALTIME, 0, &tip->to_wait, NULL);
    (*tip->to_fn)(tip->to_arg);
    free(arg);
    return 0;
}
```

&emsp;&emsp;一个线程一般使用`void pthread_exit(void *rval_ptr)`终止，也可以被同一进程的其他线程调用`int pthread_cancel(pthread_t tid)`取消。rval_ptr 相当于线程的返回值，如果不需要返回值可设为 NULL。但线程终止时，线程的底层存储资源并未立即被回收，可以通过调用`int pthread_join(pthread_t tid, void **rval_ptr)`阻塞调用线程，直到线程终止并获得其返回值，此时该终止的线程被置于“分离状态”。也可以使用`int pthread_detach(pthread_t tid)`分离线程。而本例的 make_thread 函数则通过修改传给 pthread_create 函数的线程属性对象，创建了一个开始就处于分离状态的线程，处于分离状态的线程会在退出时立即收回它所占用的资源。

&emsp;&emsp;不仅线程有属性，线程的同步对象也有属性。看这段代码。

```cpp
pthread_mutexattr_t attr;
pthread_mutex_t     mutex;

void retry(void* arg)
{
    printf("require mutex for the 2nd time.\n");
    pthread_mutex_lock(&mutex);
    
    FILE* fp = fopen("./retry.dat", "w+");
    fputs("This is a retry.", fp);
    fclose(fp);
    
    pthread_mutex_unlock(&mutex);
}

int main()
{
    int             err, condition, arg;
    struct timespec when;

    if ((err = pthread_mutexattr_init(&attr)) != 0) {
        fprintf(stderr, "pthread_mutexattr_init failed");
        exit(0);
    }
    if ((err = pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE)) != 0) {
        fprintf(stderr, "set recursive type failed");
        exit(0);
    }
    if ((err = pthread_mutex_init(&mutex, &attr)) != 0) {
        fprintf(stderr, "create recursive mutex failed");
        exit(0);
    }

    condition = 1;
    pthread_mutex_lock(&mutex);

    if (condition) {
        printf("retry when timeout (10s).\n");
        clock_gettime(CLOCK_REALTIME, &when);
        when.tv_sec += 10;
        arg = 0;
        timeout(&when, retry, (void*)((unsigned long)arg));
    }

    pthread_mutex_unlock(&mutex);
    sleep(15);

    return 0;
}
```

&emsp;&emsp;使用互斥量前，必须进行初始化。可以将其初始化赋值为 PTHREAD_MUTEX_INITIALIZER（只适用于静态分配），也可以使用`int pthread_mutex_init(pthread_mutex_t *restrict mutex, const pthread_mutexattr_t *restrict attr)`进行初始化。互斥量有 3 个常用属性：进程共享属性、健壮属性、类型属性。这里将互斥量设置为“递归类型”，允许同一线程在互斥量解锁前对它进行多次加锁，至于这样设置的原因，稍后分析。

&emsp;&emsp;main 函数中，设置好互斥量后，检查被该互斥量保护的条件 condition（本例中的条件并未具体给明含义）。若条件满足，则调用 timeout 函数，并将 retry 函数及其参数（retry 函数不需要参数，因此直接传 0）传递给 timeout 函数。

&emsp;&emsp;以下是 timeout “超时”函数，用于安排另一个函数 retry 在未来的某个时间运行。

```cpp
#define SEC2NSEC    1000000000
#define USEC2NSEC   1000

void timeout(const struct timespec* when, void (*func)(void*), void* arg)
{
    struct timespec now;
    struct to_info* tip;
    int             err;

    clock_gettime(CLOCK_REALTIME, &now);
    if (when->tv_sec > now.tv_sec ||
            (when->tv_sec == now.tv_sec && when->tv_nsec > now.tv_nsec)) {
        tip = (to_info*)malloc(sizeof(to_info));
        if (tip != NULL) {
            tip->to_fn = func;
            tip->to_arg = arg;
            tip->to_wait.tv_sec = when->tv_sec - now.tv_sec;
            if (when->tv_nsec >= now.tv_nsec) {
                tip->to_wait.tv_nsec = when->tv_nsec - now.tv_nsec;
            }
            else {
                tip->to_wait.tv_sec--;
                tip->to_wait.tv_nsec = SEC2NSEC - now.tv_nsec + when->tv_nsec;
            }
            err = make_thread(timeout_helper, (void*)tip);
            if (err == 0) {
                printf("make_thread success\n");
                return;
            }
            else 
                free(tip);
        }
    }
    (*func)(arg);
}
```

&emsp;&emsp;由 main 函数中的语句 “when.tv_sec += 10;” 可知，timeout 函数中，when 时刻在 now 时刻大约 10s 之后。timeout 函数创建一个线程，并让该线程执行 timeout_helper 函数，timeout_helper 函数则在等待大约 10s 后开始执行 retry 函数。retry 函数的执行效果就是程序运行约 10s 之后，在当前目录创建了一个 “retry.dat” 文件，而对这个文件的操作受到同一个 mutex 的保护。

&emsp;&emsp;现在解决之前的疑问，为什么要将互斥量 mutex 设置为递归类型？

&emsp;&emsp;这里由于 main 函数中明确指明 when 在 now 的 10s 之后，因此处理顺序是：

1. main 线程获取 mutex。
2. main 线程创建一个线程，该线程等待大约 10s。
3. main 线程释放 mutex，并等待 15s（为了不让进程直接退出）。
4. 被创建的线程等待 10s 后，执行 retry 函数，获取 mutex，文件操作后释放 mutex。

&emsp;&emsp;但假如以另一种情况进入 timeout 函数，这种情况中 when 时刻在 now 时刻之前，而我们希望在 when 时刻执行某个函数（这里是 retry），即安排函数运行的时间已经过去了，这时候应当直接调用该函数，而不是创建一个线程在那儿等待，即执行到 timeout 函数的最后一条语句。或者假如 timeout 函数中，malloc 分配 struct to_info 的内存失败，或者 make_thread 函数失败，即不能创建线程时，也会直接调用 retry 函数。这种情况的处理顺序是：

1. main 线程获取 mutex。
2. main 线程执行 timeout 函数，并接着执行 retry 函数。
3. main 线程在 retry 函数中再次获取 mutex，文件操作后释放 mutex。
4. main 线程释放 mutex，并等待 15s。

&emsp;&emsp;可见，如果不将 mutex 设置为允许递归加锁，则在第 3 步时会发生死锁。
