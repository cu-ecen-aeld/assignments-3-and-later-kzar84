#include <stdbool.h>
#include <stdio.h>
#include <syslog.h>
#include <unistd.h>
#include <fcntl.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>

void m_exit(int exit_code) {
    closelog();
    exit(exit_code);
}

void write_file(const char* fln, const char* str) {
    // Open file
    int fd = open(fln, O_WRONLY | O_CREAT | O_TRUNC, S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP);
    if (fd == -1) {
        syslog(LOG_ERR, "Unable to create file %s", fln);
        m_exit(1);
    }

    // Write to file
    ssize_t nr;
    nr = write(fd, str, strlen(str));
    if (nr == -1) {
        syslog(LOG_ERR, "Unable to write %s to %s", str, fln);
        m_exit(1);
    }
    syslog(LOG_DEBUG, "Writing %s to %s", str, fln);
    
    // Close file
    if (close(fd) == -1) {
        syslog(LOG_ERR, "Error closing %s after writing", fln);
    }
}


int main(int argc, char *argv[]) {
    // Set up logger
    openlog(NULL, 0, LOG_USER);

    // Parse args
    if (argc != 3) {
        syslog(LOG_ERR, "Missing arguments, must provide file path and write string");
        m_exit(1);
    }
    const char* writefile = argv[1];
    const char* writestr = argv[2];

    write_file(writefile, writestr);

    closelog();

    return 0;
}