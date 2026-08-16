# Linux Fundamentals — File Descriptors

## Goal

Understand how Linux processes interact with files, terminals, pipes, sockets, and other resources through **file descriptors (FDs)**.

This is especially important for:

- Docker
- Kubernetes
- container logs
- application troubleshooting
- stdin/stdout/stderr
- pipes
- sockets
- `/proc`
- process debugging

Core concepts:

- File descriptor
- stdin / stdout / stderr
- FD 0 / 1 / 2
- Open files
- File descriptor table
- `/proc/<PID>/fd`
- pipes
- sockets
- `/dev/null`
- redirection
- process → kernel resource

---

## What is a File Descriptor?

A file descriptor is a small integer used by a process to refer to an **open resource** managed by the kernel.

Mental model:

    Process
        ↓
    File Descriptor
        ↓
    Kernel-managed resource

The resource can be:

- regular file
- terminal
- pipe
- socket
- device
- `/dev/null`

A file descriptor is **not the file itself**.

Example:

    FD 3
      ↓
    open file / socket / pipe

---

## Standard File Descriptors

Every normal process starts with three standard file descriptors:

    0 → stdin
    1 → stdout
    2 → stderr

Mental model:

    stdin
      ↓
    Process
      ↓
    stdout
    stderr

### FD 0 — stdin

Standard input.

The process reads data from FD 0.

Example:

    cat

can read from stdin.

### FD 1 — stdout

Standard output.

Normal program output is written to FD 1.

Example:

    echo "hello"

writes:

    hello

to stdout.

### FD 2 — stderr

Standard error.

Errors and diagnostic messages are normally written to FD 2.

Example:

    ls /does-not-exist

writes the error to stderr.

---

## stdin / stdout / stderr

Mental model:

    stdin
      ↓
    ┌─────────┐
    │ Process │
    └─────────┘
      ↓     ↓
    stdout stderr

Important:

    stdout ≠ stderr

They are separate file descriptors.

This allows them to be redirected independently.

---

## Inspecting File Descriptors

For the current shell:

    echo $$

returns the shell PID.

Then:

    ls -l /proc/$$/fd

Example:

    0 -> /dev/pts/0
    1 -> /dev/pts/0
    2 -> /dev/pts/0

This means:

    FD 0 → terminal
    FD 1 → terminal
    FD 2 → terminal

---

## `/proc/<PID>/fd`

Linux exposes a process's file descriptors through:

    /proc/<PID>/fd/

Example:

    /proc/1234/fd/

might contain:

    0
    1
    2
    3
    4

Inspect:

    ls -l /proc/1234/fd

Individual descriptors:

    ls -l /proc/1234/fd/0
    ls -l /proc/1234/fd/1
    ls -l /proc/1234/fd/2

Use `readlink`:

    readlink /proc/1234/fd/1
    readlink /proc/1234/fd/2

This tells you what the FD currently points to.

---

## Important: FD is NOT a Hard Link

Do not confuse:

    file descriptor

with:

    hard link

A hard link is:

    filename
        ↓
      inode

A file descriptor is:

    process
        ↓
    file descriptor
        ↓
    kernel-managed open resource

`/proc/<PID>/fd/<N>` is exposed as a link-like interface, but the FD itself is **not a hard link**.

---

## File Descriptor Table

Every process has a file descriptor table.

Mental model:

    Process
       │
       ▼
    FD table
       │
       ├── 0 → stdin
       ├── 1 → stdout
       ├── 2 → stderr
       ├── 3 → file
       ├── 4 → socket
       └── 5 → pipe

The process uses the integer:

    0
    1
    2
    3
    ...

to refer to these resources.

---

## Redirection

### stdout

Redirect stdout to a file:

    command > output.log

Equivalent conceptually to:

    FD 1 → output.log

Append instead of overwrite:

    command >> output.log

---

## stderr

Redirect stderr:

    command 2> error.log

Meaning:

    FD 2 → error.log

---

## stdout and stderr separately

    command > output.log 2> error.log

Mental model:

    FD 1 → output.log
    FD 2 → error.log

---

## stdout + stderr

Redirect stderr to the same destination as stdout:

    command > output.log 2>&1

Important:

    > output.log
        ↓
    redirect FD 1

    2>&1
        ↓
    make FD 2 point to the same destination as FD 1

So:

    FD 1 ──→ output.log
    FD 2 ──→ output.log

---

## Order Matters

These are not necessarily equivalent:

    command > output.log 2>&1

and:

    command 2>&1 > output.log

The shell processes redirections in order.

Correct common pattern:

    command > output.log 2>&1

means:

    stdout → output.log
    stderr → wherever stdout currently points

---

## `/dev/null`

`/dev/null` is a special device that discards data written to it.

Example:

    command > /dev/null

means:

    FD 1 → /dev/null

Output is discarded.

Discard stderr:

    command 2> /dev/null

Discard both:

    command > /dev/null 2>&1

Important:

    /dev/null is not broken.

It is a valid destination whose purpose is to discard data.

---

## Pipes

A pipe connects the stdout of one process to the stdin of another.

Example:

    command1 | command2

Mental model:

    command1
       │
       │ stdout
       ▼
      pipe
       │
       │ stdin
       ▼
    command2

Example:

    cat application.log | grep ERROR

Conceptually:

    cat
      FD 1
       ↓
      pipe
       ↓
      FD 0
    grep

---

## File Descriptors Can Refer to Pipes

Inspect:

    ls -l /proc/<PID>/fd

You may see something like:

    1 -> pipe:[12345]
    2 -> pipe:[12346]

This is normal.

A file descriptor does not have to point to a regular file.

It can point to:

- file
- pipe
- socket
- terminal
- device

---

## File Descriptors and Sockets

A network socket is also represented by a file descriptor.

Mental model:

    Application
        ↓
      FD 5
        ↓
      Socket
        ↓
      TCP/IP
        ↓
      Network

This means a process can have:

    FD 3 → configuration file
    FD 4 → database socket
    FD 5 → HTTP socket
    FD 6 → pipe

This is one reason file descriptors are so important for troubleshooting.

---

## File Descriptors and Processes

Mental model:

    Process
    │
    ├── PID
    ├── memory
    ├── environment
    ├── file descriptors
    │      ├── 0 → stdin
    │      ├── 1 → stdout
    │      ├── 2 → stderr
    │      ├── 3 → file
    │      └── 4 → socket
    └── signals

A process is not just "a program running".

It has resources and kernel-managed state associated with it.

---

## `/proc` Connection

Inspect a process:

    ls -l /proc/<PID>/fd

Example:

    /proc/1234/fd/

    0 -> /dev/pts/0
    1 -> /dev/pts/0
    2 -> /dev/pts/0
    3 -> /var/log/app.log
    4 -> socket:[12345]

This gives you a picture of what the process is connected to.

---

## Troubleshooting Logs

Suppose:

    Pod: petclinic
    Status: Running

But:

    kubectl logs petclinic

is almost empty.

First hypothesis:

    Application may not be writing logs to stdout/stderr.

Inspect the application's FDs:

    kubectl exec petclinic -- ls -l /proc/1/fd

Then:

    kubectl exec petclinic -- readlink /proc/1/fd/1
    kubectl exec petclinic -- readlink /proc/1/fd/2

You might find:

    FD 1 → /var/log/petclinic/application.log
    FD 2 → /var/log/petclinic/error.log

Now the hypothesis becomes:

    Application logs are going to files
    instead of stdout/stderr.

Therefore:

    kubectl logs
          ↓
    sees little/no output

while:

    /var/log/petclinic/application.log
          ↓
    contains the application logs

---

## `/dev/null` Logging Problem

Another possibility:

    FD 1 → /dev/null
    FD 2 → /dev/null

Then:

    stdout → discarded
    stderr → discarded

So:

    kubectl logs

cannot show those messages.

The important troubleshooting distinction:

    FD exists
        ↓
    destination is /dev/null
        ↓
    output is intentionally discarded

This is different from a broken or missing FD.

---

## Kubernetes Logging Connection

Kubernetes normally expects container applications to write logs to:

    stdout
    stderr

Conceptually:

    Application
        │
        ├── stdout
        │     ↓
        └── stderr
              ↓
        Container runtime
              ↓
        Kubernetes logging
              ↓
        kubectl logs

Therefore:

    kubectl logs

primarily shows what the container runtime captured from the container's stdout/stderr streams.

If an application writes only to:

    /var/log/app.log

that file is not automatically the same thing as container stdout.

---

## Important Kubernetes Troubleshooting Pattern

If:

    kubectl logs

is empty or missing expected logs:

Check:

    1. Is the application actually running?
    2. Is it the process you think is PID 1?
    3. Where does FD 1 point?
    4. Where does FD 2 point?
    5. Is the application writing to those streams?
    6. Is output being redirected?
    7. Is output being sent to a file?
    8. Is output being discarded?

Useful commands:

    ps -ef

    ls -l /proc/1/fd

    readlink /proc/1/fd/1

    readlink /proc/1/fd/2

---

## PID 1 Connection

Inside a container:

    PID 1

is the first process in that PID namespace.

Example:

    PID 1 → java
    PID 2 → worker

Inspect:

    cat /proc/1/status

    tr '\0' ' ' < /proc/1/cmdline
    echo

    ls -l /proc/1/fd

Important Kubernetes connection:

    Kubernetes
        ↓
    container runtime
        ↓
    PID 1
        ↓
    SIGTERM

If PID 1 is a shell instead of the application:

    PID 1 → /bin/sh
              │
              └── PID 2 → java

signal handling and logging behavior may need investigation.

---

## Common Mistake — Shell Wrapper

Problematic:

    #!/usr/bin/env bash

    java -jar app.jar

Possible process tree:

    PID 1 → startup.sh
              │
              └── PID 2 → java

Better when the script should hand control to the application:

    #!/usr/bin/env bash

    exec java -jar app.jar

Now:

    PID 1 → java

`exec` replaces the shell process with Java instead of creating Java as a child process.

This is important for:

- SIGTERM
- graceful shutdown
- Kubernetes termination
- process management

---

## Practical Lab

### 1. Inspect your shell

Find PID:

    echo $$

Inspect FDs:

    ls -l /proc/$$/fd

Inspect stdout:

    readlink /proc/$$/fd/1

Inspect stderr:

    readlink /proc/$$/fd/2

---

### 2. Test stdout and stderr

Run:

    echo "hello stdout"

Run:

    echo "hello stderr" >&2

Now redirect:

    echo "hello stdout" > output.log

    echo "hello stderr" 2> error.log

Inspect:

    cat output.log
    cat error.log

---

### 3. Redirect both

    command > output.log 2>&1

Then inspect:

    cat output.log

Both stdout and stderr should be in the same file.

---

### 4. Test `/dev/null`

    echo "hello" > /dev/null

Nothing is displayed.

Test:

    echo "error" >&2 2> /dev/null

Again, nothing is displayed.

---

### 5. Create a pipe

Run:

    echo "hello world" | cat

Mental model:

    echo
      ↓
    stdout
      ↓
    pipe
      ↓
    stdin
      ↓
    cat

---

## Production Mental Model

When debugging a process, don't just ask:

    "What command is running?"

Also ask:

    What does it have open?

Inspect:

    /proc/<PID>/fd

Mental model:

    Process
       │
       ├── FD 0 → input
       ├── FD 1 → output
       ├── FD 2 → errors
       ├── FD 3 → file
       ├── FD 4 → socket
       └── FD 5 → pipe

This can explain:

- missing logs
- broken pipes
- open files
- active network connections
- processes waiting for input
- unexpected output destinations

---

## Key Mental Model

    Process
        │
        ▼
    File Descriptor Table
        │
        ├── 0 → stdin
        ├── 1 → stdout
        ├── 2 → stderr
        ├── 3 → file
        ├── 4 → socket
        └── 5 → pipe

Remember:

    FD 0 = stdin
    FD 1 = stdout
    FD 2 = stderr

    /proc/<PID>/fd
    → inspect a process's file descriptors

    > file
    → redirect stdout

    >> file
    → append stdout

    2> file
    → redirect stderr

    2>&1
    → redirect stderr to stdout's current destination

    | 
    → connect stdout of one process to stdin of another

    /dev/null
    → discard data

    socket
    → can also be represented by a file descriptor

    FD ≠ hard link

    process
        ↓
    FD
        ↓
    kernel-managed resource

---

## DevOps Connection

    File Descriptors
          │
          ├── stdout / stderr
          │        ↓
          │    container logs
          │        ↓
          │    kubectl logs
          │
          ├── sockets
          │        ↓
          │    networking
          │        ↓
          │    Kubernetes
          │
          ├── pipes
          │        ↓
          │    processes
          │
          └── /proc/<PID>/fd
                   ↓
              troubleshooting

The goal is not to memorize FD numbers.

The goal is to ask:

    "What resource is this process connected to,
     and how can I verify it?"