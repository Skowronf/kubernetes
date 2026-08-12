# Linux Fundamentals — Exit Codes

## Goal

I learned how Linux processes communicate success or failure using **exit codes**, and how Bash uses them for automation and control flow.

I focused on:

* exit codes,
* `$?`,
* `exit`,
* `return`,
* `&&` / `||`,
* `if`,
* exit codes and signals.

---

## 1. Exit Codes

Every process terminates with an exit status.

```text
0        → success
non-zero → failure or another condition
```

Example:

```bash
true
echo $?
```

→ `0`

```bash
false
echo $?
```

→ `1`

---

## 2. `$?`

`$?` contains the exit status of the **previous command**.

It is overwritten by the next command:

```bash
false
echo "hello"
echo $?
```

→ `0`

To preserve it:

```bash
false
status=$?
```

---

## 3. `exit` vs `return`

```bash
exit 1
```

terminates the entire script with exit code `1`.

```bash
return 1
```

returns from a function.

```text
return → leave function
exit   → terminate script
```

---

## 4. `if`, `&&`, `||`

Bash uses exit codes for control flow.

```bash
if command; then
    echo "success"
else
    echo "failure"
fi
```

```bash
command1 && command2
```

→ run `command2` only if `command1` succeeds.

```bash
command1 || command2
```

→ run `command2` if `command1` returns non-zero.

---

## 5. Non-zero Doesn't Always Mean Error

Commands can use non-zero exit codes for different meanings.

For `grep`:

```text
0 → match found
1 → no match
2 → error
```

Therefore:

```text
non-zero ≠ always "something went wrong"
```

I need to understand the exit-code semantics of the specific command.

---

## 6. Exit Codes & Signals

A commonly observed convention is:

```text
128 + signal number
```

For example:

```text
SIGTERM (15) → 143
SIGKILL (9)  → 137
```

In Kubernetes, `137` can commonly indicate an OOM kill.

---

## 7. Production Relevance

Exit codes are fundamental to:

* Bash scripts,
* CI/CD,
* Docker,
* Kubernetes Jobs,
* container restarts,
* deployment automation,
* troubleshooting.

The basic flow is:

```text
process
   ↓
exit code
   ↓
shell
   ↓
CI/CD / Docker / Kubernetes
   ↓
automation decision
```

## Key Takeaways

```text
0        → success
non-zero → another condition / failure
```

```bash
$?
```

→ previous command's exit status.

```bash
exit N
```

→ terminate script with status `N`.

```bash
return N
```

→ return from function.

Most important:

```text
exit codes are signals for automation,
not just error numbers.
```