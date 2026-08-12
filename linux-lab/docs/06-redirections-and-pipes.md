# Linux Fundamentals — Redirections & Pipes

## Goal

I learned how Linux processes communicate using **stdin, stdout and stderr**, and how Bash redirects and connects these streams.

I focused on:

* `stdin`, `stdout`, `stderr`
* file descriptors `0`, `1`, `2`
* `>`, `>>`, `2>`, `2>>`, `<`
* `2>&1`
* pipes `|`
* `/dev/null`

---

## 1. Standard Streams

Every process has:

```text
stdin  → input
stdout → normal output
stderr → errors / diagnostics
```

File descriptors:

```text
0 → stdin
1 → stdout
2 → stderr
```

By default:

```text
stdin  → terminal
stdout → terminal
stderr → terminal
```

---

## 2. Basic Redirections

```bash
command > output.log
```

→ stdout → file, **overwrite**

```bash
command >> output.log
```

→ stdout → file, **append**

```bash
command 2> error.log
```

→ stderr → file, **overwrite**

```bash
command 2>> error.log
```

→ stderr → file, **append**

```bash
command < input.txt
```

→ file → stdin

---

## 3. stdout + stderr

```bash
command > output.log 2>&1
```

→ both go to `output.log`

```text
stdout → output.log
stderr → output.log
```

`2>&1` means:

> stderr → current destination of stdout

---

## 4. Order Matters

These are different:

```bash
command > output.log 2>&1
```

```text
stdout → output.log
stderr → output.log
```

and:

```bash
command 2>&1 > output.log
```

```text
stdout → output.log
stderr → terminal
```

Why?

```text
Bash processes redirections from left to right.
```

---

## 5. Pipes

```bash
command1 | command2
```

means:

```text
command1 stdout → command2 stdin
```

Example:

```bash
cat application.log | grep ERROR
```

```text
cat stdout → pipe → grep stdin
grep stdout → terminal
```

`stderr` is **not automatically piped**.

To include stderr:

```bash
command1 2>&1 | command2
```

---

## 6. `/dev/null`

```bash
command > /dev/null
```

→ discard stdout

```bash
command 2> /dev/null
```

→ discard stderr

```bash
command > /dev/null 2>&1
```

→ discard stdout + stderr

---

## 7. Production Relevance

These concepts are used constantly in:

* Bash scripts
* CI/CD
* Docker
* Kubernetes
* logging
* troubleshooting

Example:

```bash
./deploy.sh > deploy.log 2> deploy-error.log
```

```text
stdout → deploy.log
stderr → deploy-error.log
```

---

# Key Takeaways

```text
0 → stdin
1 → stdout
2 → stderr
```

```text
>    → overwrite stdout
>>   → append stdout
2>   → overwrite stderr
2>>  → append stderr
<    → redirect stdin
```

```bash
2>&1
```

→ stderr gets the **current destination of stdout**.

```bash
command1 | command2
```

→ stdout of `command1` becomes stdin of `command2`.

Most important:

```text
Redirection → changes where a stream goes.
Pipe        → connects stdout of one process to stdin of another.
```
