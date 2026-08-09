# Linux Fundamentals — Filesystem

## Goal

I started learning Linux fundamentals as part of my transition towards DevOps.

In this exercise, I wanted to understand the basics of the Linux filesystem, mainly:

* how to navigate through the filesystem,
* the difference between absolute and relative paths,
* how to create directories and files,
* how to find files,
* how to inspect file information,
* the difference between `du` and `df`,
* what the most important Linux directories are used for.

---

## 1. Creating the lab

I created a small Linux lab inside my main project:

```text
/home/vboxuser/enterprise-platform/
```

First, I created the `linux-lab` directory:

```bash
mkdir linux-lab
cd linux-lab
```

Then I created a simple application-like structure:

```text
linux-lab/
├── app/
│   ├── bin/
│   │   └── start.sh
│   ├── config/
│   │   └── application.yaml
│   └── logs/
│       └── application.log
├── backup/
└── tmp/
```

I used:

```bash
mkdir
```

to create directories and:

```bash
touch
```

to create empty files.

---

## 2. Using `find`

I used:

```bash
find .
```

to inspect the structure of the lab.

I can also limit the results to directories:

```bash
find . -type d
```

or regular files:

```bash
find . -type f
```

I also searched for specific file types:

```bash
find . -name "*.log"
find . -name "*.yaml"
```

For example:

```text
./app/logs/application.log
./app/config/application.yaml
```

### What I learned

`find` will be very useful during troubleshooting when I know what I am looking for but I don't know the exact location of the file.

For example, if I need to find configuration files or logs:

```bash
find /var/log -name "*.log"
```

---

## 3. `pwd` and navigating the filesystem

I used:

```bash
pwd
```

to check where I currently am.

The result was:

```text
/home/vboxuser/enterprise-platform/linux-lab
```

`pwd` means:

```text
print working directory
```

I also used:

```bash
cd ..
```

to move one directory up.

Important path symbols:

```text
/   root directory
.   current directory
..  parent directory
~   home directory of the current user
```

For example, if I am in:

```text
/home/vboxuser/enterprise-platform/linux-lab
```

then:

```bash
cd ..
```

moves me to:

```text
/home/vboxuser/enterprise-platform
```

---

## 4. Absolute vs relative paths

An absolute path starts from the root directory `/`.

Example:

```text
/home/vboxuser/enterprise-platform/linux-lab/app/logs/application.log
```

This path has the same meaning regardless of my current working directory.

A relative path does not start with `/`.

For example:

```text
app/logs/application.log
```

Its meaning depends on my current working directory.

---

## 5. Using `stat`

I wanted to inspect information about `application.log`.

After running:

```bash
stat linux-lab/app/logs/application.log
```

I got information about:

```text
size
blocks
inode
links
owner
group
permissions
timestamps
```

Initially the file was empty:

```text
size: 0
Blocks: 0
```

After adding log content, it became:

```text
size: 120
Blocks: 8
```

This was interesting because the logical file size and the amount of filesystem space allocated to the file are not necessarily the same.

The filesystem block size was:

```text
4096 bytes
```

and the file had:

```text
8 blocks
```

Since `stat` reports blocks in 512-byte units:

```text
8 × 512 bytes = 4096 bytes
```

So the file contained only 120 bytes of data but occupied one 4096-byte filesystem block.

This is something I want to understand better when I get to inodes and filesystem internals.

---

## 6. Using `du`

I checked the size of my lab using:

```bash
du linux-lab
```

I got:

```text
4       linux-lab/tmp
4       linux-lab/app/bin
4       linux-lab/app/config
4       linux-lab/app/logs
16      linux-lab/app
4       linux-lab/backup
28      linux-lab
```

I can also use:

```bash
du -sh .
```

to get a more readable summary.

### What I learned

`du` means:

```text
disk usage
```

It answers the question:

> How much filesystem space is being used by these files/directories?

---

## 7. Using `df`

I then checked the filesystem capacity:

```bash
df -h
```

The important result was:

```text
/dev/sda2        60G   53G  4.3G  93% /
```

So my root filesystem is currently:

```text
Total:      60 GB
Used:       53 GB
Available:  4.3 GB
Usage:      93%
```

### `du` vs `df`

The way I currently remember the difference is:

```text
du
↓
How much space do these specific files/directories use?

df
↓
How much space is available on the filesystem?
```

So if I get an alert like:

```text
Disk almost full
```

I would start with:

```bash
df -h
```

to identify the filesystem.

Then I could investigate what is consuming the space with:

```bash
du -sh /*
```

---

## 8. Important Linux directories

I also learned the basic purpose of several important Linux directories.

### `/etc`

Configuration files.

Examples:

```text
/etc/ssh/
/etc/nginx/
/etc/systemd/
```

### `/var`

Data that changes while the system is running.

For example:

```text
/var/log/
/var/lib/
/var/cache/
```

### `/tmp`

Temporary data.

### `/home`

User home directories.

For example:

```text
/home/vboxuser
```

### `/opt`

Often used for additional or locally installed applications.

For example:

```text
/opt/petclinic
```

### `/usr`

Contains many system programs, libraries and other resources.

### `/proc`

A pseudo-filesystem exposing information about processes and the Linux kernel.

For example:

```bash
cat /proc/cpuinfo
cat /proc/meminfo
```

---

## 9. What happens under the hood?

For a command like:

```bash
cat /etc/hostname
```

It receives the path:

```text
/etc/hostname
```

and tries to open and read it.

My simplified mental model is:

```text
Shell
  ↓
cat
  ↓
Linux kernel
  ↓
filesystem
  ↓
/etc/hostname
  ↓
read
  ↓
terminal
```

So the application runs in user space and communicates with the Linux kernel, which provides access to the filesystem and other system resources