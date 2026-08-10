# Linux Fundamentals — Users, Groups & Permissions

## Goal

In this exercise, I learned how Linux identifies users and controls access to files.

I focused on:

* users, UIDs and GIDs,
* groups,
* file ownership,
* `rwx` permissions,
* `chmod`,
* `chown`,
* `chgrp`,
* `umask`.

---

## 1. Users & Groups

I used:

```bash
whoami
id
groups
```

Linux identifies users using a **UID** and groups using **GIDs**.

Simplified model:

```text
USER
 │
 ├── UID
 ├── primary GID
 └── supplementary groups
```

---

## 2. File permissions

I used:

```bash
ls -l
```

Example:

```text
-rwxr-x---
```

Permissions are divided into:

```text
rwx | r-x | ---
 │     │     │
owner group others
```

Where:

```text
r = read
w = write
x = execute
```

For directories, `x` means the ability to access/traverse the directory.

---

## 3. Numeric permissions

Permissions can be represented numerically:

```text
r = 4
w = 2
x = 1
```

For example:

```bash
chmod 750 script.sh
```

means:

```text
750
│││
││└── others = ---
│└─── group  = r-x
└──── owner  = rwx
```

So:

```text
750 = rwxr-x---
640 = rw-r-----
```

---

## 4. Ownership

I learned the difference between:

```bash
chmod 750 script.sh
```

and:

```bash
chown alice:developers script.sh
```

`chmod` changes permissions.

`chown` changes the owner and group.

`chgrp` changes only the group.

---

## 5. How Linux decides access

Linux checks the relationship between the process and the file:

```text
process
   │
   ├── UID
   └── groups
        │
        ▼
      file
        │
        ├── owner
        ├── group
        └── permissions
```

If the process is the owner, Linux uses **owner permissions**.

Otherwise, if it belongs to the file's group, Linux uses **group permissions**.

Otherwise, it uses **others permissions**.

---

## 6. `umask`

I used:

```bash
umask
```

`umask` restricts permissions assigned to newly created files and directories.

A common example is:

```text
umask 022
```

which typically results in:

```text
file      → 644
directory → 755
```

---

## 7. Production relevance

Linux users, groups and permissions are fundamental to:

* application processes,
* deployment scripts,
* CI/CD runners,
* containers,
* mounted volumes,
* least-privilege security.

These concepts directly connect to Kubernetes:

```yaml
securityContext:
  runAsNonRoot: true
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
```

Kubernetes security builds on Linux process and permission mechanisms.
