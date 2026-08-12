# Linux Fundamentals — Text Processing

## Goal

I practiced basic Linux text-processing commands using an `application.log` file.

Commands:

```text
grep → filter
less → inspect
tail → view the end
wc → count
sort → order/group
| → connect commands
```

## Log File

```text
INFO Application started
INFO User logged in
ERROR Database connection failed
WARN Connection retry
ERROR Database connection failed
INFO User logged out
ERROR Connection refused
ERROR Database connection failed
WARN Connection retry
ERROR Connection refused
INFO Application stopped
```

## `grep` — Filter

Show errors:

```bash
grep ERROR application.log
```

Count errors:

```bash
grep ERROR application.log | wc -l
```

Result:

```text
5
```

Show warnings:

```bash
grep WARN application.log
```

## `less` — Inspect

```bash
less application.log
```

Useful:

```text
/ERROR → search
n      → next match
q      → quit
```

## `tail` — End of File

```bash
tail application.log
```

Last 5 lines:

```bash
tail -5 application.log
```

Follow a growing log:

```bash
tail -f application.log
```

## `wc` — Count

Count lines:

```bash
wc -l application.log
```

Result:

```text
11
```

Count errors:

```bash
grep ERROR application.log | wc -l
```

## `sort` — Order

```bash
sort application.log
```

Sort errors:

```bash
grep ERROR application.log | sort
```

## Pipes

A pipe sends the output of one command to another:

```bash
command1 | command2
```

Example:

```bash
grep ERROR application.log | wc -l
```

## Useful Pipeline

Find the most common errors:

```bash
grep ERROR application.log | sort | uniq -c | sort -nr
```

Result:

```text
3 ERROR Database connection failed
2 ERROR Connection refused
```

The pipeline:

```text
grep
 ↓
filter errors
 ↓
sort
 ↓
group identical lines
 ↓
uniq -c
 ↓
count
 ↓
sort -nr
 ↓
most frequent first
```

## Key Takeaway

```text
grep  → filter
less  → inspect
tail  → end/follow
wc    → count
sort  → order/group
uniq  → count duplicates
|     → connect commands
```

