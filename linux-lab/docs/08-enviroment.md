# Linux Fundamentals — Environment Variables

## Goal

Understand how Linux processes receive and use environment variables.

Commands:

```text
env / printenv       → inspect environment
echo "$VAR"          → display variable
export               → pass variable to child processes
unset                → remove variable
/proc/<PID>/environ  → inspect process environment
```

## Shell Variable

```bash
APP_NAME="petclinic"
echo "$APP_NAME"
```

Result:

```text
petclinic
```

This is a **shell variable**, not automatically an environment variable.

```bash
printenv APP_NAME
```

May return nothing.

## `export`

```bash
export APP_NAME
```

Now:

```bash
printenv APP_NAME
```

Result:

```text
petclinic
```

Mental model:

```text
APP_NAME="petclinic"
        ↓
shell variable
        ↓
export APP_NAME
        ↓
environment variable
        ↓
child processes
```

## Child Processes

```bash
export APP_NAME="petclinic"
bash
echo "$APP_NAME"
```

Result:

```text
petclinic
```

The child process inherits the exported environment.

```text
Parent shell
     ↓
exported environment
     ↓
Child process
```

## `env` / `printenv`

Show all environment variables:

```bash
env
```

or:

```bash
printenv
```

Show one:

```bash
printenv HOME
printenv USER
printenv PATH
```

Typical variables:

```text
HOME=/home/user
USER=user
PATH=/usr/local/bin:/usr/bin:/bin
SHELL=/bin/bash
```

## `echo` and `$`

```bash
echo "$HOME"
```

`$HOME` means: expand the value of `HOME`.

Compare:

```bash
echo "$HOME"
echo "HOME"
```

The first prints the value.

The second prints:

```text
HOME
```

## `PATH`

`PATH` tells the shell where to search for executables.

```bash
echo "$PATH"
```

Example:

```text
/usr/local/bin:/usr/bin:/bin
```

When you run:

```bash
kubectl
```

the shell searches these directories for an executable named `kubectl`.

Find it with:

```bash
command -v kubectl
```

Mental model:

```text
kubectl
   ↓
search $PATH
   ↓
find executable
   ↓
run program
```

## `/proc/<PID>/environ`

Every Linux process has an environment.

Find the current shell PID:

```bash
echo $$
```

Inspect its environment:

```bash
tr '\0' '\n' < /proc/$$/environ
```

Filter it:

```bash
tr '\0' '\n' < /proc/$$/environ | grep APP
```

Mental model:

```text
Linux process
     ↓
/proc/<PID>/environ
     ↓
process environment
```
