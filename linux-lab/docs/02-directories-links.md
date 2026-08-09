# Linux Fundamentals — Files, Directories & Links

## Goal

In this exercise, I wanted to understand how Linux represents files internally and how different types of links work.

I focused on:

* inodes,
* directory entries,
* hard links,
* symbolic links,
* `ln`,
* `ln -s`,
* `readlink`,
* `stat`,
* the difference between `rm` and deleting the underlying file data.

---

## 1. Understanding inodes

A filename is not the file itself.

A simplified model is:

```text
filename
   ↓
directory entry
   ↓
inode
   ↓
file data
```

An inode contains filesystem metadata such as:

```text
permissions
owner
group
size
timestamps
link count
references to file data
```

I used:

```bash
ls -li
```

and:

```bash
stat file.txt
```

to inspect inode information.

---

## 2. Hard links

I created a hard link with:

```bash
ln file.txt hardlink.txt
```

Both names pointed to the same inode.

I verified this with:

```bash
ls -li
```

The simplified structure is:

```text
file.txt ────────┐
                 ↓
              inode
                 ↑
                 |
hardlink.txt ────┘
```

When I modified `file.txt`, the changes were visible through `hardlink.txt` because both names refer to the same underlying file.

---

## 3. Deleting the original hard link

I removed:

```bash
rm file.txt
```

The hard link still worked:

```bash
cat hardlink.txt
```

This helped me understand that `rm` removes a directory entry.

The inode remains accessible while another hard link still exists.

For example:

```text
Before:

file.txt ────────┐
                 ↓
              inode
                 ↑
                 |
hardlink.txt ────┘

Links = 2


After rm file.txt:

hardlink.txt
      ↓
    inode

Links = 1
```

---

## 4. Symbolic links

I created a symbolic link with:

```bash
ln -s file.txt symlink.txt
```

Unlike a hard link, a symbolic link has its own inode and stores a path to the target.

Conceptually:

```text
symlink.txt
     ↓
symlink inode
     ↓
"path: file.txt"
     ↓
target inode
```

I used:

```bash
readlink symlink.txt
```

to see the path stored by the symlink.

---

## 5. Hard link vs symbolic link

The main difference is:

```text
Hard link:

directory entry → same inode
```

while:

```text
Symbolic link:

directory entry
      ↓
symlink inode
      ↓
path
      ↓
target inode
```

Therefore, they behave differently when the original filename is removed.

---

## 6. Deleting the symlink target

After:

```bash
rm file.txt
```

the symbolic link still existed, but:

```bash
cat symlink.txt
```

failed.

This happens because the symlink stores a path to the target.

After the target directory entry is removed, the path can no longer be resolved.

The symlink becomes a:

```text
dangling / broken symbolic link
```

The important distinction is:

```text
Hard link
→ refers to the same inode

Symbolic link
→ refers to a path
```

---

## 7. `cp` vs `ln`

I also compared:

```bash
cp file.txt copy.txt
```

with:

```bash
ln file.txt hardlink.txt
```

`cp` creates an independent file with a new inode and copied data.

`ln` creates another directory entry pointing to the existing inode.

```text
cp:

file.txt → inode A
copy.txt → inode B


ln:

file.txt ────────┐
                 ↓
              inode A
                 ↑
                 |
hardlink.txt ────┘
```

---

## 8. What happens under the hood?

My current mental model is:

```text
filename
   ↓
directory entry
   ↓
inode
   ↓
file data
```

For a hard link:

```text
name A ───────┐
              ↓
           same inode
              ↑
              |
name B ───────┘
```

For a symbolic link:

```text
name
 ↓
symlink inode
 ↓
path
 ↓
target
 ↓
target inode
```

---

## 9. Production relevance

Understanding links is useful for:

* Linux configuration management,
* deployment directories,
* application version switching,
* container filesystems,
* Kubernetes volumes,
* ConfigMaps and Secrets.

For example, deployments can use a structure like:

```text
/opt/app/
├── current -> releases/2026-08-09
└── releases/
    ├── 2026-08-08
    └── 2026-08-09
```

The `current` symlink can point to the active application version.
