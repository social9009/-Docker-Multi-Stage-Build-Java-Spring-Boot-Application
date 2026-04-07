# 🐳 Docker Multi-Stage Build — Java Spring Boot Application

<div align="center">

![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Java](https://img.shields.io/badge/Java_17-ED8B00?style=for-the-badge&logo=openjdk&logoColor=white)
![Spring Boot](https://img.shields.io/badge/Spring_Boot_3.1-6DB33F?style=for-the-badge&logo=springboot&logoColor=white)
![Maven](https://img.shields.io/badge/Maven_3.9-C71A36?style=for-the-badge&logo=apachemaven&logoColor=white)
![Alpine](https://img.shields.io/badge/Alpine_Linux-0D597F?style=for-the-badge&logo=alpinelinux&logoColor=white)

<br/>

**Hands-on project demonstrating Docker Multi-Stage Builds with a Java Spring Boot application.**
**Ships only the compiled JAR in a minimal Alpine image — no Maven, no build tools in production.**

<br/>

*Built by [Akshay Sawant](mailto:akshaysawant9009@gmail.com) — AWS DevOps Engineer | Hinjawadi, Pune*

---

### 🏆 What This Project Proves

```
STAGE                IMAGE USED                          SIZE
────────────────────────────────────────────────────────────────
Single-Stage   →   maven:3.9.3-eclipse-temurin-17    ~700 MB+
Multi-Stage    →   amazoncorretto:17-alpine            489 MB
                   (Maven + build tools NOT included)
────────────────────────────────────────────────────────────────
✅ Only the compiled JAR ships to production — nothing else.
```

</div>

---

## 📌 Table of Contents

- [What This Project Does](#-what-this-project-does)
- [Project Structure](#-project-structure)
- [The Java Application](#-the-java-application)
- [Understanding pom.xml](#-understanding-pomxml)
- [Multi-Stage Dockerfile Explained](#-multi-stage-dockerfile-explained)
- [Apple Silicon vs Intel — Important Note](#-apple-silicon-vs-intel--important-note)
- [Step-by-Step Terminal Commands](#-step-by-step-terminal-commands)
- [Real Terminal Output](#-real-terminal-output)
- [How Multi-Stage Works — Visual](#-how-multi-stage-works--visual)
- [Run and Test](#-run-and-test)
- [Size Comparison](#-size-comparison)
- [Key Learnings](#-key-learnings)
- [Clone This Project](#-clone-this-project)
- [Push to GitHub](#-push-to-github)

---

## 🎯 What This Project Does

This project runs a **Spring Boot REST API** inside a Docker container built with a **multi-stage Dockerfile**.

The goal is to show that:
1. **Stage 1** uses Maven to compile the Java code and package it into a `.jar` file
2. **Stage 2** takes *only that `.jar`* and drops it into a minimal Alpine JRE image
3. Maven, source code, and all build tooling are **automatically discarded** — they never reach production

The app exposes one endpoint:
```
GET http://localhost:8080/
→ "Hello from Multi-Stage Docker + Java!"
```

---

## 📁 Project Structure

```
app-java/
│
├── 📄 README.md                      ← This documentation
├── 📄 pom.xml                        ← Maven config (defines JAR name + dependencies)
├── 📄 dockerfile.multistage          ← Multi-Stage Dockerfile (Intel/AMD64/Linux)
├── 📄 dockerfile.multistage.apple    ← Multi-Stage Dockerfile (Apple Silicon M1/M2/M3)
├── 📄 .gitignore                     ← Ignores target/, .class, .jar files
│
└── 📁 src/
    └── 📁 main/
        └── 📁 java/
            └── 📁 com/
                └── 📁 example/
                    └── 📄 DemoApplication.java   ← Spring Boot REST Controller
```

---

## ☕ The Java Application

**File:** `src/main/java/com/example/DemoApplication.java`

```java
package com.example;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.*;

@SpringBootApplication
@RestController
public class DemoApplication {

    public static void main(String[] args) {
        SpringApplication.run(DemoApplication.class, args);
    }

    @GetMapping("/")
    public String home() {
        return "Hello from Multi-Stage Docker + Java!";
    }
}
```

**What it does:**
- Bootstraps a Spring Boot application
- Registers a single REST endpoint at `/`
- Returns a plain text response on every GET request
- Runs on **port 8080** by default

---

## 📦 Understanding pom.xml

> **pom.xml is critical** — it tells Maven what to build and what the output JAR will be named.

```xml
<groupId>com.example</groupId>
<artifactId>demo</artifactId>
<version>1.0.0</version>
<packaging>jar</packaging>      ← Tells Maven to produce a .jar file (not .war)
```

### 🔑 How the JAR filename is determined:

```
JAR filename format:  {artifactId}-{version}.{packaging}
                      demo        -1.0.0    .jar
                      ↓
               demo-1.0.0.jar   ← This is what Maven produces in target/
```

This is why the Dockerfile uses:
```dockerfile
COPY --from=builder /app/target/*.jar app.jar
#                              ↑
#                   Matches demo-1.0.0.jar
#                   (wildcard * avoids hardcoding version)
```

### Packaging Types in Java:

| `<packaging>` value | Output file | Used for |
|--------------------|-------------|---------|
| `jar` | `app.jar` | Standalone Spring Boot apps ✅ |
| `war` | `app.war` | Apps deployed on Tomcat/WildFly |
| `pom` | No binary | Parent/aggregator projects |

---

## 🐳 Multi-Stage Dockerfile Explained

### For Intel / AMD64 / Linux — `dockerfile.multistage`

```dockerfile
# ─────────────────────────────────────────────────────────
# Stage 1: BUILD
# Full Maven + JDK image — compiles and packages the app
# ─────────────────────────────────────────────────────────
FROM maven:3.9.3-eclipse-temurin-17 AS builder
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

# ─────────────────────────────────────────────────────────
# Stage 2: RUN
# Minimal Alpine JDK image — only the JAR runs here
# ─────────────────────────────────────────────────────────
FROM eclipse-temurin:17-jdk-alpine
WORKDIR /app
COPY --from=builder /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

### For Apple Silicon M1/M2/M3 — `dockerfile.multistage.apple`

```dockerfile
# ─────────────────────────────────────────────────────────
# Stage 1: BUILD — Amazon Corretto supports ARM64
# ─────────────────────────────────────────────────────────
FROM maven:3.9.3-amazoncorretto-17 AS builder
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

# ─────────────────────────────────────────────────────────
# Stage 2: RUN — Alpine + Amazon Corretto JRE
# ─────────────────────────────────────────────────────────
FROM amazoncorretto:17-alpine
WORKDIR /app
COPY --from=builder /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

### Line-by-Line Breakdown:

**Stage 1 — Builder:**

| Line | Command | Why |
|------|---------|-----|
| `FROM maven:3.9.3-... AS builder` | Pull full Maven + JDK image | Named `builder` so Stage 2 can reference it |
| `WORKDIR /app` | Set working directory | All files go under `/app` |
| `COPY pom.xml .` | Copy Maven config first | Allows Docker layer caching of dependencies |
| `COPY src ./src` | Copy source code | Copied after pom.xml for better caching |
| `RUN mvn clean package -DskipTests` | Compile + package to JAR | `-DskipTests` speeds up build |

> 💡 **Why copy `pom.xml` before `src`?**
> Docker builds layer by layer. If only source code changes (not dependencies), Docker reuses the cached `mvn` dependency download layer — making rebuilds much faster.

**Stage 2 — Runner:**

| Line | Command | Why |
|------|---------|-----|
| `FROM eclipse-temurin:17-jdk-alpine` | Minimal Alpine JDK | No Maven, no build tools — just enough to run Java |
| `WORKDIR /app` | Set working directory | Fresh directory in the new image |
| `COPY --from=builder /app/target/*.jar app.jar` | ⭐ Copy only the JAR | Maven, source code, dependencies stay in Stage 1 |
| `EXPOSE 8080` | Document the port | Spring Boot default port |
| `ENTRYPOINT ["java", "-jar", "app.jar"]` | Start the app | Runs the JAR directly |

---

## 🍎 Apple Silicon vs Intel — Important Note

> ⚠️ This is a real error you will hit on Apple M1/M2/M3 chips if you use the wrong image.

### The Error on Apple Silicon:

```bash
indrasurya@akshays-MacBook-Air app-java % docker build -t java-multi-app -f dockerfile.multistage .

ERROR: failed to build: failed to solve:
maven:3.9.3-openjdk-17: failed to resolve source metadata
docker.io/library/maven:3.9.3-openjdk-17: not found
```

### Why This Happens:

```
Apple M1/M2/M3 chips use ARM64 architecture.
openjdk images are built for AMD64 (Intel/Linux) only.
Docker on Apple Silicon cannot pull AMD64-only images by default.
```

### The Fix — Use Amazon Corretto images:

```
❌ Doesn't work on M1/M2/M3:
   FROM maven:3.9.3-openjdk-17       ← AMD64 only
   FROM maven:3.9.3-eclipse-temurin-17 ← AMD64 only

✅ Works on M1/M2/M3 (ARM64 compatible):
   FROM maven:3.9.3-amazoncorretto-17     ← Multi-arch ✅
   FROM amazoncorretto:17-alpine          ← Multi-arch ✅
```

### Quick Reference — Which Dockerfile to Use:

```
┌─────────────────────────────────────────────────────────────┐
│  Running on Intel/AMD64/Linux?                              │
│  → Use: dockerfile.multistage                               │
│     FROM maven:3.9.3-eclipse-temurin-17 AS builder         │
│     FROM eclipse-temurin:17-jdk-alpine                     │
├─────────────────────────────────────────────────────────────┤
│  Running on Apple M1 / M2 / M3 (ARM64)?                    │
│  → Use: dockerfile.multistage.apple                         │
│     FROM maven:3.9.3-amazoncorretto-17 AS builder          │
│     FROM amazoncorretto:17-alpine                           │
└─────────────────────────────────────────────────────────────┘
```

---

## 💻 Step-by-Step Terminal Commands

### Step 1 — Create the Folder Structure

```bash
mkdir app-java
cd app-java
mkdir -p src/main/java/com/example
```

### Step 2 — Verify Structure

```bash
ls
# pom.xml  src/

cd src/main/java/com/example
ls
# DemoApplication.java
```

### Step 3 — Build the Docker Image

**On Intel / AMD64 / Linux:**
```bash
docker build -t java-multi-app -f dockerfile.multistage .
```

**On Apple Silicon M1/M2/M3:**
```bash
docker build -t java-multi-app -f dockerfile.multistage.apple .
```

### Step 4 — Verify the Image Was Built

```bash
docker images java-multi-app
```

Expected output:
```
IMAGE                  ID              DISK USAGE    CONTENT SIZE
java-multi-app:latest  23651a77762e      489 MB        168 MB
```

### Step 5 — Run the Container

```bash
docker run -d --name java-app -p 8080:8080 java-multi-app
```

### Step 6 — Verify Container is Running

```bash
docker ps
```

Expected output:
```
CONTAINER ID   IMAGE            COMMAND               CREATED        STATUS
a05f10c92b8e   java-multi-app   "java -jar app.jar"   8 seconds ago  Up 7 seconds
PORTS: 0.0.0.0:8080->8080/tcp    NAMES: java-app
```

### Step 7 — Test the Application

```bash
curl http://localhost:8080
# Output: Hello from Multi-Stage Docker + Java!
```

Or open in browser: 🌐 [http://localhost:8080](http://localhost:8080)

---

## 📟 Real Terminal Output

Exact terminal session from this project:

```bash
# ── Create folder structure ───────────────────────────────────────────
indrasurya@akshays-MacBook-Air docker % mkdir -p src/main/java/com/example/
indrasurya@akshays-MacBook-Air docker % ls
pom.xml  src

# ── Navigate and create Java file ────────────────────────────────────
indrasurya@akshays-MacBook-Air app-java % cd src/main/java/com/example
indrasurya@akshays-MacBook-Air example % vim DemoApplication.java
indrasurya@akshays-MacBook-Air example % cat DemoApplication.java
package com.example;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.*;

@SpringBootApplication
@RestController
public class DemoApplication {
    public static void main(String[] args) {
        SpringApplication.run(DemoApplication.class, args);
    }

    @GetMapping("/")
    public String home() {
        return "Hello from Multi-Stage Docker + Java!";
    }
}

# ── ❌ Failed attempt on Apple Silicon with wrong image ───────────────
indrasurya@akshays-MacBook-Air app-java % docker build -t java-multi-app -f dockerfile.multistage .
ERROR: maven:3.9.3-openjdk-17: not found
# Reason: openjdk images are AMD64-only, Apple M chips are ARM64

# ── ✅ Fixed with Amazon Corretto (ARM64 compatible) ──────────────────
indrasurya@akshays-MacBook-Air app-java % docker build -t java-multi-app -f dockerfile.multistage.apple .
[+] Building ... FINISHED

# ── Check image size ──────────────────────────────────────────────────
IMAGE                     ID              DISK USAGE    CONTENT SIZE
java-multi-app:latest     23651a77762e      489 MB        168 MB

# ── Run the container ─────────────────────────────────────────────────
indrasurya@akshays-MacBook-Air app-java % docker run -d --name java-app -p 8080:8080 java-multi-app
a05f10c92b8e46480469ee8bea880cbdfd6f55015ddc4f81522afd2dcb02c95c

# ── Verify container is running ───────────────────────────────────────
indrasurya@akshays-MacBook-Air app-java % docker ps
CONTAINER ID   IMAGE            COMMAND               PORTS                     NAMES
a05f10c92b8e   java-multi-app   "java -jar app.jar"   0.0.0.0:8080->8080/tcp    java-app
```

---

## 🎬 How Multi-Stage Works — Visual

```
docker build -t java-multi-app -f dockerfile.multistage.apple .
         │
         ▼
┌──────────────────────────────────────────────────────────────────────┐
│  STAGE 1 — "builder"                                                 │
│                                                                      │
│  maven:3.9.3-amazoncorretto-17  (~600 MB)                            │
│       ↓                                                              │
│  COPY pom.xml            ← dependencies cached here                  │
│       ↓                                                              │
│  COPY src/               ← source code copied                        │
│       ↓                                                              │
│  mvn clean package       ← compiles + creates JAR                    │
│       ↓                                                              │
│  target/demo-1.0.0.jar   ← only this file moves to Stage 2          │
│                 │                                                    │
│  Maven, tools,  │  ← ALL OF THIS IS DISCARDED                       │
│  source code    │     never enters final image                       │
└─────────────────┼────────────────────────────────────────────────────┘
                  │
                  │  COPY --from=builder /app/target/*.jar app.jar
                  ▼
┌──────────────────────────────────────────────────────────────────────┐
│  STAGE 2 — final image                                               │
│                                                                      │
│  amazoncorretto:17-alpine  (~200 MB)                                 │
│       +                                                              │
│  app.jar  (~5-10 MB)                                                 │
│       =                                                              │
│  java-multi-app:latest  →  489 MB  ✅                                │
│                                                                      │
│  Contains: JRE + your JAR only. Nothing else.                        │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 🚀 Run and Test

```bash
# Run the container
docker run -d --name java-app -p 8080:8080 java-multi-app

# Test with curl
curl http://localhost:8080
# → Hello from Multi-Stage Docker + Java!

# View logs
docker logs java-app

# Stop and remove
docker stop java-app
docker rm   java-app
```

Open in browser: 🌐 [http://localhost:8080](http://localhost:8080)

---

## 📊 Size Comparison

### Java vs Go Multi-Stage Results:

```
Language   Build Type     Final Image Size    Notes
──────────────────────────────────────────────────────────────────
Java       Multi-Stage    489 MB              JVM is large but Alpine helps
Go         Multi-Stage     21.9 MB            Static binary = near zero overhead
Go         Single-Stage    1.29 GB            Full Go toolchain included
──────────────────────────────────────────────────────────────────
```

### Why Java Multi-Stage is Still Larger Than Go:

```
Go result is tiny because:
  → Go compiles to a single static binary
  → No runtime needed (binary runs directly on the OS)
  → Works perfectly on scratch/alpine

Java result is larger because:
  → Java needs the JVM (Java Virtual Machine) to run
  → JVM itself is ~200 MB even in Alpine variant
  → You cannot use scratch or remove the JRE
  → Still: 489 MB vs 700 MB+ is a meaningful improvement
```

### Java Image Size Ladder:

```
maven:3.9.3 (full)              ████████████████████████  ~700 MB+
eclipse-temurin:17-jdk          ████████████████           ~480 MB
eclipse-temurin:17-jdk-alpine   █████████████              ~400 MB
amazoncorretto:17-alpine        ████████████               ~489 MB
gcr.io/distroless/java17        █████████                  ~220 MB  ← most secure
```

---

## 💡 Key Learnings

### ✅ What Multi-Stage Solves for Java

```
Without Multi-Stage:
  Final image = Maven + JDK + source code + JAR
  Everything used to build is shipped to production
  Size: 700 MB+ with unnecessary tools

With Multi-Stage:
  Final image = JRE (Alpine) + compiled JAR only
  Maven, source code, build cache stay in Stage 1
  Size: 489 MB — much leaner and more secure
```

### 🔑 Key Commands Explained

```bash
# mvn clean package -DskipTests
# ├── clean      → delete previous build artifacts
# ├── package    → compile + test + package into JAR
# └── -DskipTests → skip unit tests (faster CI builds)

# COPY --from=builder /app/target/*.jar app.jar
# ├── --from=builder  → reference Stage 1 by its AS name
# ├── /app/target/*.jar → wildcard matches demo-1.0.0.jar
# └── app.jar         → rename to simple name in Stage 2

# ENTRYPOINT ["java", "-jar", "app.jar"]
# └── exec form (JSON array) — preferred over shell form
#     shell form: CMD java -jar app.jar  ← doesn't handle signals properly
#     exec form:  ENTRYPOINT ["java","-jar","app.jar"] ← correct
```

### ⚠️ Common Mistakes & Fixes

```
❌ MISTAKE: Wrong image for Apple Silicon
   Error:   maven:3.9.3-openjdk-17: not found
   FIX:     Use maven:3.9.3-amazoncorretto-17  (multi-arch)

❌ MISTAKE: Hardcoding the JAR version
   Wrong:   COPY --from=builder /app/target/demo-1.0.0.jar app.jar
   Problem: Every version bump breaks the Dockerfile
   FIX:     COPY --from=builder /app/target/*.jar app.jar
            (wildcard always matches regardless of version)

❌ MISTAKE: COPY --from typo
   Wrong:   COPY --form=builder ...   (typo: form vs from)
   FIX:     COPY --from=builder ...

❌ MISTAKE: Forgetting to check packaging type in pom.xml
   If pom.xml has <packaging>war</packaging>
   → Maven produces app.war, not app.jar
   → Container will fail: "app.jar not found"
   FIX:     Always verify pom.xml has <packaging>jar</packaging>
            for standalone Spring Boot apps
```

### 🏆 Best Base Image by Language

| Language | Stage 1 (Build) | Stage 2 (Run) | Notes |
|----------|----------------|---------------|-------|
| **Java** | `maven:3.9-amazoncorretto-17` | `amazoncorretto:17-alpine` | Safe for M1/M2/M3 |
| **Java** | `maven:3.9-eclipse-temurin-17` | `eclipse-temurin:17-jdk-alpine` | Intel/Linux only |
| **Java** | Any Maven image | `gcr.io/distroless/java17` | Most secure option |
| **Go** | `golang:1.21` | `alpine:3.19` or `scratch` | Smallest possible |
| **Node** | `node:18` | `node:18-alpine` | Balanced |
| **Python** | `python:3.11` | `python:3.11-slim` | Avoid Alpine for Python |

---

## 📥 Clone This Project

```bash
# Clone the repo
git clone https://github.com/social9009/app-java.git
cd app-java

# Build (Intel/Linux)
docker build -t java-multi-app -f dockerfile.multistage .

# Build (Apple M1/M2/M3)
docker build -t java-multi-app -f dockerfile.multistage.apple .

# Run
docker run -d --name java-app -p 8080:8080 java-multi-app

# Test
curl http://localhost:8080
# → Hello from Multi-Stage Docker + Java!
```

---

## 🔗 Related Projects in This Series

[![Go Multi-Stage](https://img.shields.io/badge/Docker--3-Go_Multi--Stage_Build-00ADD8?style=for-the-badge&logo=go)](https://github.com/social9009/Go-App)
[![Docker Image Types](https://img.shields.io/badge/Docker--2-Image_Types_%26_Sizes-2496ED?style=for-the-badge&logo=docker)](https://github.com/social9009/docker-image-types)
[![SonarQube](https://img.shields.io/badge/Project-SonarQube_CI/CD-4E9BCD?style=for-the-badge&logo=sonarqube)](https://github.com/social9009/SonarQube-Project)

---

## 📬 Author

**Akshay Sawant** — AWS DevOps Engineer | AWS Solutions Architect Associate

[![Email](https://img.shields.io/badge/Email-akshaysawant9009@gmail.com-D14836?style=flat-square&logo=gmail)](mailto:akshaysawant9009@gmail.com)
[![GitHub](https://img.shields.io/badge/GitHub-social9009-181717?style=flat-square&logo=github)](https://github.com/social9009)
[![Location](https://img.shields.io/badge/Location-Hinjawadi_Pune-4285F4?style=flat-square&logo=googlemaps)](https://maps.google.com)

---

<div align="center">

⭐ **Star this repo if it helped you understand Java Multi-Stage Docker Builds!** ⭐

*Docker Series: Image Types → Go Multi-Stage → Java Multi-Stage → coming next: Python + Node*

</div>
