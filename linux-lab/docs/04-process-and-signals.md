# Linux Fundamentals — Processes & Signals

## Goal

In this exercise, I learned how Linux manages running programs and how processes communicate through signals.

I focused on:

* processes vs programs,
* PID and PPID,
* process hierarchy,
* process ownership,
* `ps`,
* `pstree`,
* `kill`,
* `SIGINT`,
* `SIGTERM`,
* `SIGKILL`,
* graceful shutdown.

---

## 1. Program vs Process

A program is code stored on disk.

A process is a running instance of that program.

```text
program
   ↓
process
   ├── PID
   ├── PPID
   └── UID/GID
```

The same program can have multiple processes.

---

## 2. PID & PPID

Every process has a **PID (Process ID)**.

`PPID` identifies the parent process.

```text
bash
PID=1000
   │
   └── sleep
       PID=1200
       PPID=1000
```

I used:

```bash
ps
ps -f
ps -o pid,ppid,user,cmd
pstree -p
```

to inspect processes and their relationships.

---

## 3. Process identity

A process runs with a user identity represented by:

```text
UID
GID
groups
```

This connects processes with the Linux permissions model:

```text
PROCESS
   │
   ├── UID/GID
   ▼
KERNEL
   │
   ▼
FILE PERMISSIONS
```

---

## 4. Signals

Signals are notifications sent to processes.

I focused on:

```text
SIGINT   → interrupt
SIGTERM  → request graceful termination
SIGKILL  → force termination
```

For example:

```bash
kill <PID>
```

normally sends:

```text
SIGTERM
```

while:

```bash
kill -9 <PID>
```

sends:

```text
SIGKILL
```

---

## 5. Graceful shutdown

`SIGTERM` gives an application an opportunity to clean up before exiting.

For example:

```text
SIGTERM
   ↓
stop accepting work
   ↓
finish current work
   ↓
close connections
   ↓
cleanup
   ↓
exit
```

`SIGKILL` cannot be handled by the application and should generally be used only when graceful termination fails.

---

## 6. Production relevance

Processes and signals are fundamental to:

* Docker containers,
* Kubernetes Pods,
* rolling deployments,
* graceful application shutdown,
* CI/CD jobs,
* resource management.

This directly connects to Kubernetes:

```text
Pod termination
      ↓
    SIGTERM
      ↓
application cleanup
      ↓
terminationGracePeriodSeconds
      ↓
SIGKILL if still running
```
