# Linux Fundamentals — `/proc`

## Goal

Understand `/proc` as a Linux **pseudo-filesystem** that exposes process and system/kernel information.

This is important for:

- Linux troubleshooting
- process inspection
- containers
- Docker
- Kubernetes
- PID namespaces
- signals
- file descriptors
- understanding what a process is actually doing

Core concepts:

- `/proc`
- pseudo-filesystem
- `/proc/<PID>`
- PID
- PPID
- process state
- command line
- executable
- environment
- current working directory
- file descriptors
- PID namespace
- containers

Core paths:

    /proc/<PID>/status
    /proc/<PID>/cmdline
    /proc/<PID>/environ
    /proc/<PID>/exe
    /proc/<PID>/cwd
    /proc/<PID>/fd/
    /proc/<PID>/maps

System information:

    /proc/cpuinfo
    /proc/meminfo
    /proc/uptime
    /proc/loadavg
    /proc/net

---

## What is `/proc`?

`/proc` is a **pseudo-filesystem** provided by the Linux kernel.

It is mounted at:

    /proc

It looks like a normal directory:

    ls /proc

but it does not behave like a normal filesystem such as:

    ext4
    xfs
    btrfs

The information exposed through `/proc` represents current kernel/process state.

Mental model:

    Application
        ↓
    read /proc/...
        ↓
    Linux kernel
        ↓
    current system/process information

So:

    cat /proc/uptime

does not mean:

    "read a normal file that somebody saved on disk"

It means:

    "ask the kernel to expose the current uptime through /proc"

---

## `/proc` Structure

A simplified `/proc` looks like:

    /proc
    │
    ├── 1/
    ├── 2/
    ├── 1234/
    ├── 5678/
    │
    ├── cpuinfo
    ├── meminfo
    ├── uptime
    ├── loadavg
    └── net/

Numeric directories normally represent processes:

    /proc/1
    /proc/1234
    /proc/5678

where:

    1
    1234
    5678

are PIDs.

---

## `/proc/<PID>`

Each process has a directory:

    /proc/<PID>/

Example:

    /proc/1234/

Important entries:

    /proc/1234/status
    /proc/1234/cmdline
    /proc/1234/environ
    /proc/1234/exe
    /proc/1234/cwd
    /proc/1234/fd/
    /proc/1234/maps

Mental model:

    /proc/<PID>/
        │
        ├── status
        ├── cmdline
        ├── environ
        ├── exe
        ├── cwd
        ├── fd/
        └── maps

Each exposes a different aspect of the process.

---

## `/proc/<PID>/status`

Inspect process metadata:

    cat /proc/1234/status

Important fields include:

    Name:
    State:
    Pid:
    PPid:
    Uid:
    Gid:
    VmSize:
    VmRSS:

This gives you information about the process from the kernel's perspective.

Example:

    Pid:    1234
    PPid:   1000
    Uid:    1000
    Gid:    1000
    State:  S (sleeping)

Mental model:

    /proc/<PID>/status
        ↓
    process identity
    process state
    parent process
    user/group
    memory information
    other process metadata

---

## PID and PPID

PID:

    Process ID

PPID:

    Parent Process ID

Example:

    PID 1000
      │
      └── PID 1234

means:

    process 1000
        ↓
    parent of 1234

Check:

    ps -o pid,ppid,cmd -p 1234

or:

    cat /proc/1234/status

Mental model:

    Parent
      │
      └── Child

This becomes extremely important in containers.

---

## `/proc/<PID>/cmdline`

Shows how the process was started.

Example:

    tr '\0' ' ' < /proc/1234/cmdline
    echo

Could produce:

    java -jar petclinic.jar --server.port=8080

Mental model:

    /proc/<PID>/cmdline
            ↓
    process arguments
            ↓
    how the process was invoked

---

## NUL-separated Arguments

`/proc/<PID>/cmdline` contains arguments separated by NUL characters.

Conceptually:

    java\0-jar\0petclinic.jar\0

not:

    java -jar petclinic.jar

To make it human-readable:

    tr '\0' ' ' < /proc/<PID>/cmdline
    echo

Mental model:

    argument 1
       ↓
    NUL
       ↓
    argument 2
       ↓
    NUL
       ↓
    argument 3

---

## `/proc/<PID>/exe`

Shows the executable associated with the process.

Inspect:

    readlink /proc/1234/exe

Example:

    /usr/bin/java

Compare:

    /proc/1234/cmdline
        ↓
    java -jar petclinic.jar

    /proc/1234/exe
        ↓
    /usr/bin/java

Mental model:

    cmdline
        ↓
    how was it invoked?

    exe
        ↓
    which executable is running?

---

## `/proc/<PID>/cwd`

Shows the process's current working directory.

Inspect:

    readlink /proc/1234/cwd

Example:

    /opt/petclinic

This matters when applications use relative paths.

Example:

    config/application.yaml

If:

    cwd → /opt/petclinic

then the application may look for:

    /opt/petclinic/config/application.yaml

Mental model:

    Process
        ↓
    current working directory
        ↓
    relative paths

---

## `/proc/<PID>/environ`

Shows the process environment.

Inspect:

    tr '\0' '\n' < /proc/1234/environ

Example:

    PATH=/usr/local/bin:/usr/bin
    HOME=/home/app
    USER=app
    DATABASE_HOST=postgres
    DATABASE_PASSWORD=secret

The environment is represented using NUL-separated variables.

---

## Security Consideration

Environment variables can contain sensitive information:

    DATABASE_PASSWORD=...
    API_TOKEN=...
    AWS_SECRET_ACCESS_KEY=...

Therefore:

    /proc/<PID>/environ

can potentially expose sensitive information to users/processes with sufficient permissions.

Mental model:

    environment variable
          ↓
        process
          ↓
    /proc/<PID>/environ
          ↓
    potentially inspectable

This is important when thinking about:

- Linux permissions
- containers
- Kubernetes
- Secrets
- process isolation

---

## `/proc/<PID>/fd`

Shows the process's file descriptors.

Inspect:

    ls -l /proc/1234/fd

Example:

    0 -> /dev/pts/0
    1 -> /dev/pts/0
    2 -> /dev/pts/0
    3 -> /var/log/app.log
    4 -> socket:[12345]

This connects directly to the File Descriptors module.

Mental model:

    Process
       │
       └── /proc/<PID>/fd
              │
              ├── 0 → stdin
              ├── 1 → stdout
              ├── 2 → stderr
              ├── 3 → file
              └── 4 → socket

Useful commands:

    readlink /proc/1234/fd/1

    readlink /proc/1234/fd/2

These tell you where stdout and stderr currently point.

---

## `/proc/<PID>/maps`

Shows the process's memory mappings.

Inspect:

    cat /proc/1234/maps

You may see mappings for:

- executable
- shared libraries
- heap
- stack
- memory-mapped files

You don't need to understand every field yet.

The important concept is:

    process
        ↓
    virtual memory
        ↓
    /proc/<PID>/maps

This becomes useful for deeper process and memory troubleshooting.

---

## System Information in `/proc`

`/proc` is not only about processes.

Examples:

    /proc/cpuinfo
    /proc/meminfo
    /proc/uptime
    /proc/loadavg
    /proc/net

### CPU

    cat /proc/cpuinfo

Provides CPU information visible to the system/process environment.

### Memory

    cat /proc/meminfo

Provides information such as:

    MemTotal
    MemFree
    MemAvailable
    Buffers
    Cached
    SwapTotal
    SwapFree

### Uptime

    cat /proc/uptime

Shows system uptime information.

### Load

    cat /proc/loadavg

Shows load-average information.

---

## `/proc` Is a Kernel Interface

Important mental model:

    /proc
       ↓
    kernel
       ↓
    process/system state

It is therefore useful for asking the kernel questions without needing a specialized tool.

For example:

    cat /proc/1234/status

is essentially asking:

    "Tell me about process 1234."

---

# PID Namespaces

This is the most important bridge from `/proc` to containers.

Containers use Linux namespaces to provide isolation.

One important namespace is:

    PID namespace

It controls the process IDs visible to processes.

---

## Host vs Container PIDs

Suppose the host sees:

    HOST

    PID 18472 → java

Inside a container, the same process might be visible as:

    CONTAINER

    PID 1 → java

This is not a contradiction.

The process can have different PID numbers depending on the PID namespace from which it is observed.

Mental model:

    HOST PID namespace

    PID 18472
        │
        │ same underlying process
        ▼
    CONTAINER PID namespace

    PID 1

---

## Container Process Tree

Example:

    Container

    PID 1 → java
    PID 2 → worker

From inside the container:

    ps

might show:

    PID   COMMAND
    1     java
    2     worker

But the host may see completely different PIDs.

---

## PID 1 Inside a Container

PID 1 is special.

Example:

    Container
       │
       └── PID 1 → java

When Kubernetes terminates the container:

    Kubernetes
        ↓
    container runtime
        ↓
    PID 1
        ↓
    SIGTERM

This connects directly to the Signals module.

---

## Common PID 1 Problem

Suppose:

    PID 1 → /bin/sh
               │
               └── PID 2 → java

Kubernetes sends:

    SIGTERM
       ↓
    PID 1 /bin/sh

It does not automatically mean:

    SIGTERM
       ↓
    PID 2 java

A signal targets a process.

It does not automatically propagate to all child processes.

Therefore, if PID 1 does not properly forward the signal:

    Kubernetes
        ↓
    SIGTERM
        ↓
    shell
        X
        ↓
      java

The Java process may continue running.

After:

    terminationGracePeriodSeconds

Kubernetes/container runtime may force termination with:

    SIGKILL

---

## `exec` and PID 1

Problematic wrapper:

    #!/usr/bin/env bash

    java -jar app.jar

Possible process tree:

    PID 1 → startup.sh
              │
              └── PID 2 → java

Better:

    #!/usr/bin/env bash

    exec java -jar app.jar

Now:

    PID 1 → java

`exec` replaces the shell process with Java.

The PID remains:

    PID 1

but the process image becomes:

    java

This improves signal handling and graceful shutdown behavior.

---

## Kubernetes Troubleshooting Example

Problem:

    Pod: petclinic
    Status: Running

But:

    kubectl delete pod petclinic

takes the full:

    terminationGracePeriodSeconds: 30

Hypothesis:

    Application is not receiving/handling SIGTERM correctly.

Inspect:

    kubectl exec petclinic -- ps -ef

Then:

    kubectl exec petclinic -- cat /proc/1/status

    kubectl exec petclinic -- \
        tr '\0' ' ' < /proc/1/cmdline

    kubectl exec petclinic -- \
        readlink /proc/1/exe

If you discover:

    PID 1 → /bin/sh
    PID 2 → java

you have a strong hypothesis that the shell/process structure may be involved in signal handling.

---

## Troubleshooting With `/proc`

When a process behaves unexpectedly, ask:

### Who is it?

    cat /proc/<PID>/status

### How was it started?

    tr '\0' ' ' < /proc/<PID>/cmdline
    echo

### What executable is running?

    readlink /proc/<PID>/exe

### Where is it running from?

    readlink /proc/<PID>/cwd

### What environment does it have?

    tr '\0' '\n' < /proc/<PID>/environ

### What does it have open?

    ls -l /proc/<PID>/fd

### What is its memory mapped?

    cat /proc/<PID>/maps

---

## Practical Lab

### 1. Find your shell PID

    echo $$

Suppose:

    4217

Inspect:

    ls /proc/4217

---

### 2. Inspect process status

    cat /proc/4217/status

Find:

    Pid
    PPid
    Uid
    Gid
    State

---

### 3. Inspect command line

    tr '\0' ' ' < /proc/4217/cmdline
    echo

---

### 4. Inspect executable

    readlink /proc/4217/exe

---

### 5. Inspect working directory

    readlink /proc/4217/cwd

---

### 6. Inspect environment

    tr '\0' '\n' < /proc/4217/environ

Be careful: environment variables can contain secrets.

---

### 7. Inspect file descriptors

    ls -l /proc/4217/fd

Inspect stdout:

    readlink /proc/4217/fd/1

Inspect stderr:

    readlink /proc/4217/fd/2

---

### 8. Create a test process

Run:

    sleep 300 &

Find the PID:

    pgrep sleep

Then inspect:

    cat /proc/<PID>/status

    tr '\0' ' ' < /proc/<PID>/cmdline
    echo

    readlink /proc/<PID>/exe

    readlink /proc/<PID>/cwd

    ls -l /proc/<PID>/fd

---

## Production Mental Model

When troubleshooting a process, `/proc` lets you build a picture of the process:

    Process
       │
       ├── Identity
       │      └── status
       │
       ├── Command
       │      └── cmdline
       │
       ├── Executable
       │      └── exe
       │
       ├── Working directory
       │      └── cwd
       │
       ├── Environment
       │      └── environ
       │
       ├── File descriptors
       │      └── fd/
       │
       └── Memory mappings
              └── maps

This is much more useful than memorizing commands.

---

## Common Mistakes

### Mistake 1

`/proc` is a normal directory containing files stored on disk.

Wrong.

It is a pseudo-filesystem exposing kernel information.

---

### Mistake 2

`/proc` only contains process information.

Wrong.

It also exposes system/kernel information:

    /proc/cpuinfo
    /proc/meminfo
    /proc/uptime
    /proc/loadavg
    /proc/net

---

### Mistake 3

`/proc/1` always means the host's PID 1.

Wrong.

It means:

    PID 1 in the relevant PID namespace.

---

### Mistake 4

A signal sent to PID 1 automatically kills all child processes.

Wrong.

Signals target processes.

Signal propagation depends on process behavior, signal handling, process groups, namespaces, and how the signal is sent.

---

### Mistake 5

`cmdline` and `exe` are the same thing.

Wrong.

    cmdline
        ↓
    how the process was invoked

    exe
        ↓
    executable associated with the process

---

## Key Mental Model

    /proc
       │
       ├── Process information
       │       │
       │       ├── /proc/<PID>/status
       │       ├── /proc/<PID>/cmdline
       │       ├── /proc/<PID>/environ
       │       ├── /proc/<PID>/exe
       │       ├── /proc/<PID>/cwd
       │       ├── /proc/<PID>/fd
       │       └── /proc/<PID>/maps
       │
       └── System information
               │
               ├── /proc/cpuinfo
               ├── /proc/meminfo
               ├── /proc/uptime
               ├── /proc/loadavg
               └── /proc/net

Remember:

    /proc
    → pseudo-filesystem provided by the Linux kernel

    /proc/<PID>
    → information about a process

    status
    → process state and metadata

    cmdline
    → process arguments

    exe
    → executable

    cwd
    → current working directory

    environ
    → process environment

    fd/
    → file descriptors

    maps
    → memory mappings

    PID namespace
    → changes which PIDs a process can see

    PID 1 inside a container
    ≠ necessarily PID 1 on the host

---

## DevOps / Kubernetes Connection

    Linux
      │
      ├── Processes
      │
      ├── Signals
      │
      ├── File descriptors
      │
      └── /proc
             │
             ▼
       PID namespace
             │
             ▼
         Container
             │
             ▼
        Kubernetes Pod
             │
             ├── PID 1
             ├── stdout/stderr
             ├── network namespace
             └── filesystem
             │
             ▼
       Application
             │
             ▼
          PetClinic

The goal is not to memorize `/proc` paths.

The goal is to use `/proc` to answer:

    "What is this process,
     how was it started,
     what does it have access to,
     what resources does it have open,
     and what is the kernel telling me about it?"