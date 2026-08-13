# Linux Fundamentals — Networking

## Goal

Understand the networking concepts required for Docker and Kubernetes.

Core concepts:

- IP address
- Port
- Endpoint
- TCP / UDP
- Socket
- localhost
- 127.0.0.1
- 0.0.0.0
- Loopback
- Network interface
- Routing
- Network namespace

Core commands:

- `ip addr` → interfaces and IP addresses
- `ip route` → routing table
- `ss` → sockets and listening ports
- `ping` → ICMP connectivity
- `nc` → TCP connectivity
- `curl` → HTTP connectivity

---

## IP, Port, Endpoint

An IP address identifies a network address/interface.

    192.168.1.100
    10.0.0.5

A port identifies a service.

    22    → SSH
    80    → HTTP
    443   → HTTPS
    5432  → PostgreSQL
    8080  → Spring Boot

Basic mental model:

    IP + PORT = endpoint

Example:

    10.0.0.15:8080

---

## TCP vs UDP

### TCP

Connection-oriented and reliable.

    connection
    ordered data
    retransmission
    flow control

Common examples:

    HTTP
    HTTPS
    SSH
    PostgreSQL

### UDP

Connectionless and datagram-based.

    no built-in delivery guarantee
    no built-in ordering
    lower overhead

Common examples:

    DNS
    DHCP
    real-time traffic

---

## Socket

A socket is an OS abstraction used by applications for network communication.

Mental model:

    Application
        ↓
    Socket
        ↓
    TCP / UDP
        ↓
    IP
        ↓
    Network interface

Inspect sockets:

    ss
    ss -lnt
    ss -lntp

Options:

    -l → listening
    -n → numeric
    -t → TCP
    -p → process

---

## Network Interface

Inspect interfaces:

    ip addr
    ip -br addr

Typical interfaces:

    lo
    eth0
    wlan0

Mental model:

    interface
        ↓
    IP address
        ↓
    network connectivity

---

## localhost, Loopback and 127.0.0.1

`lo` is the loopback interface.

`127.0.0.1` is the IPv4 loopback address.

`localhost` is a hostname that normally resolves to loopback.

    localhost
        ↓
    127.0.0.1
        ↓
    lo
        ↓
    local network namespace

Example:

    curl http://localhost:8080

is normally equivalent to:

    curl http://127.0.0.1:8080

---

## 0.0.0.0

When used as a bind/listen address:

    0.0.0.0:8080

means:

    listen on all IPv4 interfaces

Compare:

    127.0.0.1:8080
    → loopback only

    0.0.0.0:8080
    → all IPv4 interfaces

`0.0.0.0` is normally used for binding, not as a destination.

---

## 10.x.x.x

`10.0.0.0/8` is private IPv4 address space.

Examples:

    10.0.0.1
    10.10.0.5
    10.244.1.20

It is commonly used by:

    cloud networks
    Docker
    Kubernetes
    VPNs
    private networks

Important:

    10.x.x.x ≠ Kubernetes

---

## Routing

Inspect the routing table:

    ip route

Mental model:

    destination IP
          ↓
    routing table
          ↓
    network interface / gateway

Remember:

    ip addr
    → what network configuration do I have?

    ip route
    → where should traffic go?

---

## Connectivity Tools

### ping

Tests ICMP/IP connectivity:

    ping -c 3 127.0.0.1

`ping` working does not mean the application works.

### nc

Tests TCP connectivity:

    nc -vz 127.0.0.1 8080

### curl

Tests HTTP/application connectivity:

    curl http://127.0.0.1:8080

Useful mental model:

    ping → IP/ICMP
    nc   → TCP
    curl → HTTP

---

## Connection Refused vs Timeout

### Connection refused

Usually:

    destination reachable
    +
    nothing accepting the connection

Check:

    ss -lntp

Possible causes:

    wrong port
    application not listening
    wrong bind address
    application stopped

### Timeout

Usually means no expected response arrived.

Possible causes:

    firewall
    routing problem
    network policy
    unreachable destination
    packet filtering

---

## Practical Lab

Start a server:

    python3 -m http.server 8080 --bind 127.0.0.1

Check:

    ss -lnt

Test:

    curl http://127.0.0.1:8080
    curl http://localhost:8080
    nc -vz 127.0.0.1 8080

Stop:

    Ctrl+C

Start on all interfaces:

    python3 -m http.server 8080 --bind 0.0.0.0

Check:

    ss -lnt

Find IP:

    ip -br addr

Test:

    curl http://MY_IP:8080

---

## Kubernetes Connection

Suppose a Pod has:

    Pod IP = 10.244.1.15

If Spring Boot listens on:

    127.0.0.1:8080

traffic sent to:

    10.244.1.15:8080

cannot reach that listener.

Normally the application should listen on:

    0.0.0.0:8080

Mental model:

    Service
       ↓
    Pod IP:8080
       ↓
    Pod network interface
       ↓
    Spring Boot
       ↓
    0.0.0.0:8080

---

## Network Namespace

`localhost` is relative to the network namespace.

Host:

    localhost
    → host network namespace

Container:

    localhost
    → container network namespace

Kubernetes Pod:

    localhost
    → Pod network namespace

Therefore:

    localhost inside a Pod
    ≠ Kubernetes node

---

## Key Mental Model

    Application
        ↓
    Socket
        ↓
    TCP / UDP
        ↓
    IP
        ↓
    Network interface
        ↓
    Routing
        ↓
    Network

Remember:

    IP + PORT = endpoint
    lo = loopback interface
    127.0.0.1 = loopback IPv4 address
    localhost = local hostname
    0.0.0.0 = all IPv4 interfaces when binding
    10.x.x.x = private IPv4 range
    ss = sockets
    ping = ICMP/IP
    nc = TCP
    curl = HTTP

---
