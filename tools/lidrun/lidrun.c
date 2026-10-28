#define _DARWIN_C_SOURCE
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/file.h>
#include <sys/wait.h>
#include <poll.h>
#include <fcntl.h>
#include <signal.h>
#include <unistd.h>
#include <errno.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <mach-o/dyld.h>
#ifndef LIDRUN_TEST
#include <IOKit/ps/IOPowerSources.h>
#include <IOKit/ps/IOPSKeys.h>
#endif

#define FAILURE 125
#define INTERVAL 200
#define EXTERNAL_TIMEOUT 5000
#ifdef LIDRUN_TEST
#define OFF_TIMEOUT 2000
#else
#define OFF_TIMEOUT (EXTERNAL_TIMEOUT * 5)
#endif
static volatile sig_atomic_t interrupted;
static int statefd = -1, lockfd = -1;
static uid_t owner;
static char executable[PATH_MAX];

static long long now_ms(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (long long)ts.tv_sec * 1000 + ts.tv_nsec / 1000000;
}
static void on_signal(int sig) { interrupted = sig; }
static void report(const char *s) { fprintf(stderr, "lidrun: %s\n", s); }
static int write_all(int fd, const char *s) {
    size_t n = strlen(s);
    while (n) {
        ssize_t w = write(fd, s, n);
        if (w < 0 && errno == EINTR) continue;
        if (w <= 0) return -1;
        s += w; n -= (size_t)w;
    }
    return 0;
}
static void close_fds(void) {
    int limit = getdtablesize();
    for (int fd = 3; fd < limit; fd++) close(fd);
}
static int pipe_cloexec(int p[2]) {
    if (pipe(p)) return -1;
    if (fcntl(p[0], F_SETFD, FD_CLOEXEC) || fcntl(p[1], F_SETFD, FD_CLOEXEC)) {
        close(p[0]); close(p[1]); return -1;
    }
    return 0;
}
#ifndef LIDRUN_TEST
static int command(const char *path, char *const argv[], char *out, size_t cap) {
    int p[2], status = 0;
    if (pipe(p)) return -1;
    pid_t pid = fork();
    if (pid < 0) { close(p[0]); close(p[1]); return -1; }
    if (!pid) {
        dup2(p[1], STDOUT_FILENO);
        int nullfd = open("/dev/null", O_RDWR);
        if (nullfd >= 0) { dup2(nullfd, STDIN_FILENO); dup2(nullfd, STDERR_FILENO); }
        close_fds();
        char *const env[] = {"PATH=/usr/bin:/bin:/usr/sbin:/sbin", "LC_ALL=C", NULL};
        execve(path, argv, env);
        _exit(127);
    }
    close(p[1]);
    fcntl(p[0], F_SETFL, O_NONBLOCK);
    long long end = now_ms() + EXTERNAL_TIMEOUT;
    size_t used = 0;
    int result = -1, reaped = 0;
    for (;;) {
        char buf[1024];
        ssize_t n;
        while ((n = read(p[0], buf, sizeof(buf))) > 0) {
            if (used + (size_t)n >= cap) goto done;
            memcpy(out + used, buf, (size_t)n); used += (size_t)n;
        }
        pid_t w = waitpid(pid, &status, WNOHANG);
        if (w == pid) {
            reaped = 1;
            while ((n = read(p[0], buf, sizeof(buf))) > 0) {
                if (used + (size_t)n >= cap) goto done;
                memcpy(out + used, buf, (size_t)n); used += (size_t)n;
            }
            result = WIFEXITED(status) && WEXITSTATUS(status) == 0 ? 0 : -1;
            break;
        }
        if (w < 0 || now_ms() >= end) break;
        struct pollfd pollfd = {p[0], POLLIN, 0};
        poll(&pollfd, 1, 20);
    }
done:
    if (!reaped) {
        kill(pid, SIGKILL);
        while (waitpid(pid, &status, 0) < 0 && errno == EINTR) {}
    }
    close(p[0]); out[used] = 0;
    return result;
}
#endif
#ifdef LIDRUN_TEST
static const char *testdir(void) { return getenv("LIDRUN_TEST_DIR"); }
static int fake_read(const char *name) {
    char path[PATH_MAX], data[32];
    snprintf(path, sizeof(path), "%s/%s", testdir(), name);
    int fd = open(path, O_RDONLY | O_NOFOLLOW);
    if (fd < 0) return -1;
    ssize_t n = read(fd, data, sizeof(data) - 1); close(fd);
    if (n <= 0) return -1;
    data[n] = 0;
    return strcmp(data, "0\n") == 0 ? 0 : strcmp(data, "1\n") == 0 ? 1 : -1;
}
static void test_pause(const char *name) {
    if (fake_read(name) != 1) return;
    char path[PATH_MAX];
    snprintf(path, sizeof(path), "%s/%s.started", testdir(), name);
    int fd = open(path, O_WRONLY | O_CREAT, 0600);
    if (fd >= 0) close(fd);
    while (fake_read(name) == 1) poll(NULL, 0, 20);
}
static int setting(void) { return fake_read("setting"); }
static int power(int *ac, int *percent) {
    *ac = fake_read("ac");
    char path[PATH_MAX], buf[32], extra;
    snprintf(path, sizeof(path), "%s/battery", testdir());
    int fd = open(path, O_RDONLY | O_NOFOLLOW);
    if (fd < 0) return -1;
    ssize_t n = read(fd, buf, sizeof(buf) - 1); close(fd);
    if (n <= 0) return -1;
    buf[n] = 0;
    return *ac >= 0 && sscanf(buf, "%d %c", percent, &extra) == 1 &&
        *percent >= 0 && *percent <= 100 ? 0 : -1;
}
static int set_setting(int value) {
    char path[PATH_MAX];
    snprintf(path, sizeof(path), "%s/fail%d", testdir(), value);
    if (access(path, F_OK) == 0) return -1;
    snprintf(path, sizeof(path), "%s/setting", testdir());
    int fd = open(path, O_WRONLY | O_TRUNC | O_NOFOLLOW);
    if (fd < 0) return -1;
    int result = write_all(fd, value ? "1\n" : "0\n"); close(fd);
    return result;
}
#else
static int pmset_read(const char *arg, char *out, size_t cap) {
    char *const argv[] = {"/usr/bin/pmset", "-g", (char *)arg, NULL};
    return command(argv[0], argv, out, cap);
}
static int setting(void) {
    char out[32768];
    if (pmset_read(NULL, out, sizeof(out))) return -1;
    char *section = strstr(out, "System-wide power settings:");
    if (!section) return -1;
    strtok(section, "\n");
    char *line;
    while ((line = strtok(NULL, "\n"))) {
        char key[128], extra; int value;
        if (sscanf(line, " %127s %d %c", key, &value, &extra) == 2 &&
            strcmp(key, "SleepDisabled") == 0) return value == 0 || value == 1 ? value : -1;
        if (*line != ' ' && *line != '\t') break;
    }
    char *const argv[] = {"/usr/sbin/ioreg", "-r", "-l", "-d", "1", "-c", "IOPMrootDomain", NULL};
    if (command(argv[0], argv, out, sizeof(out))) return -1;
    if (strstr(out, "\"SleepDisabled\" = No")) return 0;
    if (strstr(out, "\"SleepDisabled\" = Yes")) return 1;
    return -1;
}
static int power(int *ac, int *percent) {
    int result = -1;
    CFTypeRef info = IOPSCopyPowerSourcesInfo();
    if (!info) return -1;
    CFArrayRef sources = IOPSCopyPowerSourcesList(info);
    if (!sources) { CFRelease(info); return -1; }
    for (CFIndex i = 0; i < CFArrayGetCount(sources); i++) {
        CFDictionaryRef d = IOPSGetPowerSourceDescription(info, CFArrayGetValueAtIndex(sources, i));
        if (!d) continue;
        CFTypeRef type = CFDictionaryGetValue(d, CFSTR(kIOPSTypeKey));
        if (!type || !CFEqual(type, CFSTR(kIOPSInternalBatteryType))) continue;
        CFTypeRef state = CFDictionaryGetValue(d, CFSTR(kIOPSPowerSourceStateKey));
        CFTypeRef current = CFDictionaryGetValue(d, CFSTR(kIOPSCurrentCapacityKey));
        CFTypeRef maximum = CFDictionaryGetValue(d, CFSTR(kIOPSMaxCapacityKey));
        int c, m;
        if (!state || !current || !maximum || CFGetTypeID(current) != CFNumberGetTypeID() ||
            CFGetTypeID(maximum) != CFNumberGetTypeID() ||
            !CFNumberGetValue(current, kCFNumberIntType, &c) ||
            !CFNumberGetValue(maximum, kCFNumberIntType, &m) || m <= 0 || c < 0 || c > m) break;
        *ac = CFEqual(state, CFSTR(kIOPSACPowerValue)) ? 1 :
            CFEqual(state, CFSTR(kIOPSBatteryPowerValue)) ? 0 : -1;
        *percent = (int)((long long)c * 100 / m);
        result = *ac < 0 ? -1 : 0;
        break;
    }
    CFRelease(sources); CFRelease(info);
    return result;
}
static int set_setting(int value) {
    char out[32768];
    char *const argv[] = {"/usr/bin/pmset", "-a", "disablesleep", value ? "1" : "0", NULL};
    return command(argv[0], argv, out, sizeof(out));
}
#endif
static int secure_file(int fd) {
    struct stat st;
    return fstat(fd, &st) == 0 && S_ISREG(st.st_mode) && st.st_uid == owner &&
        (st.st_mode & 0777) == 0600 && st.st_nlink == 1 ? 0 : -1;
}
static int open_state(void) {
#ifdef LIDRUN_TEST
    char path[PATH_MAX];
    snprintf(path, sizeof(path), "%s/state", testdir());
#else
    const char *path = "/private/var/db/lidrun";
#endif
    if (mkdir(path, 0755) && errno != EEXIST) return -1;
    statefd = open(path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW);
    struct stat st;
    if (statefd < 0 || fstat(statefd, &st) || !S_ISDIR(st.st_mode) ||
        st.st_uid != owner || (st.st_mode & 0777) != 0755) return -1;
    return 0;
}
static int journal(void) {
    int fd = openat(statefd, "journal", O_RDONLY | O_NOFOLLOW);
    if (fd < 0) return errno == ENOENT ? 0 : -1;
    char data[32];
    ssize_t n = read(fd, data, sizeof(data));
    int valid = secure_file(fd) == 0 && n == 18 && memcmp(data, "lidrun-v1 prior=0\n", 18) == 0;
    close(fd); return valid ? 1 : -1;
}
static int prepare(void) {
    int fd = openat(statefd, "journal", O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0600);
    if (fd < 0) return -1;
    int result = secure_file(fd) || write_all(fd, "lidrun-v1 prior=0\n") || fsync(fd);
    close(fd);
    if (fsync(statefd)) result = -1;
    return result;
}
static int restore(void) {
    int j = journal();
    if (j == 0) return 0;
    if (j < 0) { report("invalid recovery journal; refusing to change power settings"); return -1; }
    int value = setting();
    if (value < 0 || (value == 1 && set_setting(0)) || setting() != 0) {
        report("RESTORE FAILED; journal retained. Run lidrun recover after resolving the error"); return -1;
    }
    if (unlinkat(statefd, "journal", 0) || fsync(statefd)) return -1;
    return 0;
}

static int lock_file(const char *name) {
    int fd = openat(statefd, name, O_RDWR | O_CREAT | O_NOFOLLOW, 0600);
    if (fd < 0) return -1;
    if (secure_file(fd)) { close(fd); return -1; }
    return fd;
}
static int safe_power(void) {
    int ac, percent;
    return power(&ac, &percent) == 0 && (ac || percent > 10);
}
static int stop_requested(void) {
    int fd = openat(statefd, "stop", O_RDONLY | O_NOFOLLOW | O_NONBLOCK);
    if (fd < 0) return errno == ENOENT ? 0 : -1;
    struct stat st;
    int valid = !secure_file(fd) && !fstat(fd, &st) && st.st_size == 0;
    close(fd);
    return valid ? 1 : -1;
}
static void signals(void) {
    signal(SIGHUP, on_signal); signal(SIGINT, on_signal); signal(SIGTERM, on_signal);
    signal(SIGPIPE, SIG_IGN);
}
static int watchdog(int life, int result) {
    int failed = 0;
    long long next_check = now_ms() + 1000;
    if (!safe_power() || prepare() || set_setting(1) || setting() != 1 || !safe_power()) {
        report("could not enable and verify SleepDisabled"); restore(); return FAILURE;
    }
#ifdef LIDRUN_TEST
    test_pause("pause_ready");
#endif
    if (write_all(result, "R")) { restore(); return FAILURE; }
    for (;;) {
        struct pollfd p = {life, POLLIN | POLLHUP, 0};
        int n = poll(&p, 1, INTERVAL);
        if (n > 0 || interrupted || stop_requested() != 0) break;
        if (n < 0 && errno != EINTR) { failed = 1; break; }
        if (now_ms() < next_check) continue;
        next_check = now_ms() + 1000;
        if (!safe_power() || setting() != 1) {
            report("unsafe or unknown power state, low battery, or setting change; restoring");
            failed = 1; break;
        }
    }
    if (restore()) failed = 1;
    return failed ? FAILURE : 0;
}
static int guardian(int launcher, int completion) {
    if (setsid() < 0) return FAILURE;
    signals();
    int logfd = openat(statefd, "log", O_WRONLY | O_APPEND | O_CREAT | O_NOFOLLOW | O_NONBLOCK, 0600);
    if (logfd < 0 || secure_file(logfd)) return FAILURE;
    dup2(logfd, STDERR_FILENO); close(logfd);
    int life[2], result[2];
    if (pipe_cloexec(life) || pipe_cloexec(result)) return FAILURE;
    pid_t pid = fork();
    if (pid < 0) return FAILURE;
    if (!pid) {
        if (setsid() < 0) _exit(FAILURE);
        close(launcher); close(completion);
        close(life[1]); close(result[0]); close(STDIN_FILENO); close(STDOUT_FILENO);
        /* Frameworks require exec after fork; inherit only the four daemon capabilities. */
        int source[4] = {life[0], result[1], statefd, lockfd}, saved[4];
        for (int i = 0; i < 4; i++) {
            saved[i] = fcntl(source[i], F_DUPFD_CLOEXEC, 10);
            if (saved[i] < 0) _exit(FAILURE);
        }
        for (int i = 0; i < 4; i++) if (dup2(saved[i], 3 + i) < 0) _exit(FAILURE);
        for (int fd = 7, limit = getdtablesize(); fd < limit; fd++) close(fd);
        execl(executable, executable, "--watchdog", (char *)NULL);
        _exit(FAILURE);
    }
    close(life[0]); close(result[1]);
#ifdef LIDRUN_TEST
    char path[PATH_MAX]; snprintf(path, sizeof(path), "%s/pids", testdir());
    FILE *f = fopen(path, "w");
    if (f) { fprintf(f, "%d %d\n", getpid(), pid); fclose(f); }
#endif
    int status = 0, stopped = 0, ready = 0, committed = 0;
    for (;;) {
        struct pollfd p[3] = {{committed ? -1 : STDIN_FILENO, POLLIN | POLLHUP, 0},
            {result[0], POLLIN | POLLHUP, 0}, {launcher, POLLIN | POLLHUP, 0}};
        poll(p, 3, INTERVAL);
        if (!committed && (interrupted || p[2].revents || (p[0].revents & POLLHUP))) {
            if (!stopped) { close(life[1]); stopped = 1; }
        }
        if (!stopped && !committed && p[1].revents & POLLIN) {
            char c;
            if (read(result[0], &c, 1) == 1 && c == 'R') {
                ready = 1;
                if (write_all(STDOUT_FILENO, "READY\n")) { close(life[1]); stopped = 1; }
            }
        }
        if (!stopped && !committed && ready && p[0].revents & POLLIN) {
            char c;
            if (read(STDIN_FILENO, &c, 1) == 1 && c == 'C') {
                if (waitpid(pid, &status, WNOHANG) != 0) break;
                /* The launcher must still exist at the commit boundary. */
                struct pollfd l = {launcher, POLLIN | POLLHUP, 0};
                if (poll(&l, 1, 0) == 0 && !interrupted) {
                    committed = 1;
                    write_all(completion, "C"); close(completion); completion = -1;
                    write_all(STDOUT_FILENO, "ON\n");
                    close(STDIN_FILENO); close(STDOUT_FILENO); close(launcher); launcher = -1;
                    report("sleep prevention active; use lidrun off to restore");
                } else { close(life[1]); stopped = 1; }
            } else { close(life[1]); stopped = 1; }
        }
        if (committed && interrupted && !stopped) { close(life[1]); stopped = 1; }
        pid_t w = waitpid(pid, &status, WNOHANG);
        if (w == pid || (w < 0 && errno != EINTR)) break;
    }
    /* A killed watchdog may leave an in-flight pmset child in its session. */
    kill(-pid, SIGKILL);
    if (!stopped) close(life[1]);
    close(result[0]);
    int failed = !WIFEXITED(status) || WEXITSTATUS(status) != 0;
    if (restore()) failed = 1;
    report(failed ? "monitor stopped; check status and recovery journal" : "sleep prevention off; restored");
    return failed ? FAILURE : 0;
}
static int privileged_on(int control) {
    lockfd = lock_file("lock");
    if (lockfd < 0 || flock(lockfd, LOCK_EX | LOCK_NB)) {
        report("another lidrun is active"); return FAILURE;
    }
    if (journal() != 0 || setting() != 0) {
        report("requires verified SleepDisabled=0, safe power, and no recovery journal"); return FAILURE;
    }
    if (stop_requested() < 0) { report("unsafe stop marker"); return FAILURE; }
    if (unlinkat(statefd, "stop", 0) && errno != ENOENT) return FAILURE;
    if (fsync(statefd)) return FAILURE;
    int life[2], completion[2];
    if (pipe_cloexec(life) || pipe_cloexec(completion)) return FAILURE;
    pid_t pid = fork();
    if (pid < 0) return FAILURE;
    if (!pid) {
        close(control); close(life[1]); close(completion[0]);
#ifdef LIDRUN_TEST
        test_pause("pause_guard");
#endif
        _exit(guardian(life[0], completion[1]));
    }
    close(lockfd); lockfd = -1;
    close(life[0]); close(completion[1]); close(STDIN_FILENO); close(STDOUT_FILENO);
    int result = FAILURE;
    while (!interrupted) {
        struct pollfd p = {completion[0], POLLIN | POLLHUP, 0};
        if (poll(&p, 1, INTERVAL) > 0) {
            char c;
            if (read(completion[0], &c, 1) == 1 && c == 'C') result = 0;
            break;
        }
    }
    close(life[1]); close(completion[0]);
    if (result) { int status; while (waitpid(pid, &status, 0) < 0 && errno == EINTR) {} }
    return result;
}
static int privileged_off(void) {
    lockfd = lock_file("lock");
    if (lockfd < 0) return FAILURE;
    if (flock(lockfd, LOCK_EX | LOCK_NB)) {
        if (errno != EWOULDBLOCK || stop_requested() < 0) return FAILURE;
        int fd = openat(statefd, "stop", O_WRONLY | O_CREAT | O_NOFOLLOW | O_NONBLOCK, 0600);
        if (fd < 0) return FAILURE;
        int valid = !secure_file(fd) && stop_requested() == 1 && !fsync(fd) && !fsync(statefd);
        close(fd);
        if (!valid) return FAILURE;
        long long end = now_ms() + EXTERNAL_TIMEOUT * 4;
        while (flock(lockfd, LOCK_EX | LOCK_NB)) {
            if (errno != EWOULDBLOCK || now_ms() >= end || interrupted) {
                report("restoration unconfirmed; check status and run lidrun recover"); return FAILURE;
            }
            poll(NULL, 0, 20);
        }
    }
    if (restore()) return FAILURE;
    if (stop_requested() < 0) return FAILURE;
    if (unlinkat(statefd, "stop", 0) && errno != ENOENT) return FAILURE;
    return fsync(statefd) ? FAILURE : 0;
}
static int launch(const char *self, const char *mode, int *input, int *output, pid_t *pid) {
    int in[2], out[2];
    if (pipe_cloexec(in) || pipe_cloexec(out)) return -1;
    *pid = fork();
    if (*pid < 0) return -1;
    if (!*pid) {
        dup2(in[0], STDIN_FILENO); dup2(out[1], STDOUT_FILENO); close_fds();
#ifdef LIDRUN_TEST
        signal(SIGTERM, fake_read("auth_ignore_term") == 1 ? SIG_IGN : SIG_DFL);
        test_pause("pause_auth");
        if (fake_read("auth_fail") == 1) _exit(FAILURE);
        execl(self, self, mode, (char *)NULL);
#else
        execl("/usr/bin/sudo", "sudo", "--", self, mode, (char *)NULL);
#endif
        _exit(FAILURE);
    }
    close(in[0]); close(out[1]); *input = in[1]; *output = out[0];
    return 0;
}
static int invoke(const char *self, int enable) {
    int input, output, status = 0; pid_t pid;
    if (launch(self, enable ? "--on" : "--off", &input, &output, &pid)) return FAILURE;
    int confirmed = 0;
    char buf[64]; size_t used = 0;
    while (!interrupted) {
        struct pollfd p = {output, POLLIN | POLLHUP, 0};
        if (poll(&p, 1, INTERVAL) <= 0) continue;
        ssize_t n = read(output, buf + used, sizeof(buf) - used - 1);
        if (n <= 0) break;
        used += (size_t)n; buf[used] = 0;
        if (!enable && strstr(buf, "START\n")) { confirmed = 1; break; }
        if (enable && strstr(buf, "READY\n")) {
#ifdef LIDRUN_TEST
            test_pause("pause_commit");
#endif
            if (interrupted || write_all(input, "C")) break;
            used = 0; buf[0] = 0;
        }
        if (strstr(buf, "ON\n")) { confirmed = 1; break; }
        if (used == sizeof(buf) - 1) break;
    }
    close(input); close(output);
    int cancelled = 0, timed_out = 0;
    long long end = now_ms() + (enable ? EXTERNAL_TIMEOUT : OFF_TIMEOUT);
    for (;;) {
        if (!cancelled && (interrupted || now_ms() >= end)) {
            timed_out = !interrupted;
            kill(pid, SIGTERM); cancelled = 1;
            end = now_ms() + EXTERNAL_TIMEOUT;
        }
        pid_t w = waitpid(pid, &status, WNOHANG);
        if (w == pid) break;
        if ((w < 0 && errno != EINTR) || now_ms() >= end) {
            report("operation unconfirmed; check lidrun status and run lidrun recover"); return FAILURE;
        }
        poll(NULL, 0, 20);
    }
    if (timed_out) {
        report("operation unconfirmed; check lidrun status and run lidrun recover"); return FAILURE;
    }
    if (interrupted || !confirmed || !WIFEXITED(status) || WEXITSTATUS(status)) {
        report("operation failed or cancelled; check lidrun status and recovery log");
        return interrupted ? 128 + interrupted : FAILURE;
    }
    puts(enable ? "lidrun: on (use lidrun off to restore)" : "lidrun: off (no pending recovery journal)");
    return 0;
}
int main(int argc, char **argv) {
    umask(022); owner = 0;
#ifdef LIDRUN_TEST
    if (geteuid() == 0 || !testdir() || testdir()[0] != '/') { report("test binary requires non-root and absolute LIDRUN_TEST_DIR"); return FAILURE; }
    owner = geteuid();
#endif
    signals(); signal(SIGCHLD, SIG_DFL);
    if (argc == 2 && (!strcmp(argv[1], "--help") || !strcmp(argv[1], "-h"))) {
        puts("Usage: lidrun on | off | status | recover\nAC and battery supported; stops on unknown power or battery <=10% without AC."); return 0;
    }
    if (argc == 2 && !strcmp(argv[1], "status")) {
        int value = setting(), ac = -1, percent = -1;
        int valid = power(&ac, &percent) == 0;
        printf("SleepDisabled=%s AC=%s Battery=", value == 0 ? "0" : value == 1 ? "1" : "unknown",
            valid ? (ac ? "yes" : "no") : "unknown");
        if (valid) printf("%d%%\n", percent); else puts("unknown");
        return value < 0 || !valid ? FAILURE : 0;
    }
#ifndef LIDRUN_TEST
    int privileged = geteuid() == 0;
#else
    int privileged = 1;
#endif
    if (privileged && argc == 2 && !strcmp(argv[1], "--watchdog")) {
        statefd = 5; lockfd = 6;
        struct stat st;
        if (fstat(statefd, &st) || !S_ISDIR(st.st_mode) || st.st_uid != owner ||
            (st.st_mode & 0777) != 0755 || secure_file(lockfd)) return FAILURE;
        return watchdog(3, 4);
    }
    char self[PATH_MAX]; uint32_t size = sizeof(self);
    if (_NSGetExecutablePath(self, &size) || !realpath(self, executable)) return FAILURE;
    if (privileged && argc == 2 && (!strcmp(argv[1], "--on") || !strcmp(argv[1], "--off"))) {
        if (!strcmp(argv[1], "--off") && write_all(STDOUT_FILENO, "START\n")) return FAILURE;
        if (open_state()) { report("unsafe state directory"); return FAILURE; }
        int control = lock_file("control");
        if (control < 0) return FAILURE;
        while (flock(control, LOCK_EX | LOCK_NB)) {
            if (errno != EWOULDBLOCK || interrupted) return FAILURE;
            poll(NULL, 0, 20);
        }
        if (interrupted) return FAILURE;
        return !strcmp(argv[1], "--on") ? privileged_on(control) : privileged_off();
    }
    if (geteuid() == 0) { report("run the CLI as your ordinary user, never with sudo"); return FAILURE; }
    if (argc == 2 && (!strcmp(argv[1], "on") || !strcmp(argv[1], "off") || !strcmp(argv[1], "recover")))
        return invoke(executable, !strcmp(argv[1], "on"));
    report("invalid arguments; see lidrun --help"); return FAILURE;
}
