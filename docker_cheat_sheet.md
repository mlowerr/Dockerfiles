# Updated Docker Cheat Sheet: Common Activities to Learn

This version adds:
- **why** each command exists
- **terminology**
- **ephemeral vs persistent**
- the **difference between `docker run` and `docker exec`**

## 1. Core concepts first

This is the part to get straight before memorizing commands.

### Key terms

| Term | What it is | Ephemeral or persistent? | Why it matters |
|---|---|---:|---|
| **Image** | A read-only template/blueprint used to create containers | **Persistent** until you delete it | You do not “enter” an image. You create containers **from** it. Docker’s docs describe `docker run` as creating a new container from an image. |
| **Container** | A runnable instance of an image | Usually **ephemeral**, unless you preserve it or mount data outside it | This is the actual running or stopped thing you interact with. A container can accumulate changes relative to its original image. |
| **Volume** | Docker-managed persistent storage | **Persistent** | Use this for app/database data you want to survive container replacement. Docker recommends volumes as the preferred persistence mechanism. |
| **Bind mount** | A direct mapping from a host path into a container | **Persistent on the host** | Best when you want container processes and host tools to work on the same files, such as source code. |
| **Dockerfile** | A text file containing instructions to build an image | **Persistent** as a file | This is the repeatable build recipe. |
| **Registry** | A remote store for images | **Persistent remote storage** | Needed when you want to push/pull images across machines or teams. |

### Image vs container

This is the most important distinction:

- An **image** is a **blueprint**
- A **container** is a **specific instance created from that blueprint**

Practical analogy:
- **Image** = class/template
- **Container** = object/instance

You can have:
- **one image**
- **many containers** created from that one image

That is why you can run multiple containers from the same image without them inherently conflicting. `docker run` creates a **new** container from an image.

### What is ephemeral vs persistent in normal Docker use?

#### Usually ephemeral
- container process state
- files written inside the container’s writable layer
- shell sessions opened with `docker exec`
- temporary containers started with `--rm`

#### Usually persistent
- images
- named volumes
- bind-mounted host files/directories
- Dockerfiles
- registries / pushed images

Critical nuance:
- A **stopped container still exists** until you remove it, and Docker says you can restart it with its previous changes intact using `docker start`. So containers are often *treated as ephemeral*, but they are not automatically destroyed unless you remove them or ran them with `--rm`.

---

## 2. Check what exists

### Why you use these
Use these commands to answer:
- What containers are running?
- What containers exist but are stopped?
- What images are already on this machine?
- What persistent storage objects exist?

### Commands

#### Running containers
```bash
docker ps
```

#### All containers, including stopped
```bash
docker ps -a
```

#### Images on your system
```bash
docker images
# or
docker image ls
```

#### Volumes
```bash
docker volume ls
```

#### Networks
```bash
docker network ls
```

### What these tell you
- `docker ps`: active containers only
- `docker ps -a`: active + stopped containers
- `docker images`: reusable local image inventory
- `docker volume ls`: persistent Docker-managed data stores
- `docker network ls`: Docker networking objects

---

## 3. Pull and run containers

### Why you use these
Use these when you want to:
- get an image onto your machine
- create a brand-new container from an image
- start a containerized app

### Commands

#### Pull an image
```bash
docker pull ubuntu:24.04
```

#### Run interactively
```bash
docker run -it ubuntu:24.04 bash
```

#### Run in background
```bash
docker run -d --name my-nginx -p 8080:80 nginx
```

#### Give the container a name
```bash
docker run --name myapp -d myimage
```

### `docker run` explained

`docker run`:
1. uses an **image**
2. creates a **new container**
3. starts it

Docker’s reference explicitly says `docker run` runs a command in a **new container**, pulling the image if needed and starting the container.

### Ephemeral vs persistent here

- The **container** created by `docker run` is a separate object
- If you add `--rm`, that container is **ephemeral by design** and is removed automatically when it exits
- If you do **not** use `--rm`, the stopped container remains until removed
- The **image** remains on disk until you delete it

### Common confusion
Running this twice:
```bash
docker run nginx
docker run nginx
```

does **not** “resume” the same container.  
It creates **two different containers** from the same image.

---

## 4. `docker run` vs `docker exec`

This is one of the most important distinctions.

| Command | What it does | When to use it | Persistence implications |
|---|---|---|---|
| `docker run` | Creates and starts a **new container** from an image | Start a new app/container | New container object is created; its writable state is tied to that container unless externalized |
| `docker exec` | Runs an **additional command inside an already running container** | Get a shell, inspect files, run a one-off command inside a live container | Does **not** create a new container; the exec’d process exists only while it runs |

Docker documents `docker exec` as running a new command in a **running container**, and only while the container’s primary process is running. It is not restarted automatically if the container restarts.

### Practical examples

#### Start a new Ubuntu container
```bash
docker run -it ubuntu:24.04 bash
```

This creates a **new** container.

#### Open a shell in an already running container
```bash
docker exec -it mycontainer bash
```

This does **not** create a new container. It just starts a shell process inside the existing one.

### Mental model

- `docker run` = **make me a new container**
- `docker exec` = **let me do something inside that container that already exists**

### Why this matters

If you forget this distinction, you will often:
- accidentally create duplicate containers
- think your changes “disappeared”
- be confused why `docker exec` fails on stopped containers

`docker exec` requires the target container to already be **running**.

---

## 5. Start, stop, restart, delete

### Why you use these
Use these to manage the lifecycle of existing containers.

### Commands

#### Stop a running container
```bash
docker stop mycontainer
```

#### Start a stopped container
```bash
docker start mycontainer
```

#### Restart a container
```bash
docker restart mycontainer
```

#### Remove a container
```bash
docker rm mycontainer
```

#### Force remove a running container
```bash
docker rm -f mycontainer
```

### Why these matter

- `stop` preserves the container object; it just stops the process
- `start` resumes that existing container
- `restart` cycles it
- `rm` deletes the container object

Docker explicitly notes that you can restart a stopped container with its previous changes intact using `docker start`.

### Ephemeral vs persistent here

- A stopped container is still **present**
- Once you `docker rm` it, its writable container layer is gone
- Data in **volumes** or **bind mounts** survives container removal
- Data stored only in the container’s writable layer does not

---

## 6. Get inside a running container

### Why you use these
Use these to:
- troubleshoot
- inspect files
- run admin tasks
- open an interactive shell

### Commands

#### Open a shell
```bash
docker exec -it mycontainer sh
```

or, if bash exists:
```bash
docker exec -it mycontainer bash
```

#### Run a one-off command
```bash
docker exec mycontainer ls -la /app
```

### Why not use `docker run` for this?
Because `docker run` would create a **new container**.  
If your goal is to inspect the one already running, use `docker exec`.

### Ephemeral vs persistent here
- The `exec` session itself is **ephemeral**
- Any file changes you make inside the container affect that container’s writable layer
- Those changes survive until the container is removed, but are **not the same thing as durable storage**
- For durable data, use a volume or bind mount

---

## 7. View logs and status

### Why you use these
Use these to answer:
- Is the container healthy?
- What is it doing?
- Why did it fail?
- Is it consuming too many resources?

### Commands

#### Show logs
```bash
docker logs mycontainer
```

#### Follow logs live
```bash
docker logs -f mycontainer
```

#### Show container resource usage
```bash
docker stats
```

#### Inspect detailed metadata
```bash
docker inspect mycontainer
```

### What these do
- `logs`: stdout/stderr output from the container
- `stats`: live resource stream for running containers
- `inspect`: low-level JSON metadata about config/state/mounts/networking

### Ephemeral vs persistent here
- Logs may or may not be retained long-term depending on logging setup
- `stats` output is live/ephemeral
- `inspect` shows persisted object configuration and state as Docker currently knows it

---

## 8. Copy files in and out

### Why you use these
Use these when you need to:
- pull config/data/logs out of a container
- inject a file into a container
- back up a directory from a container

### Commands

#### Container → local
```bash
docker cp mycontainer:/path/in/container/file.txt ./file.txt
```

#### Local → container
```bash
docker cp ./file.txt mycontainer:/path/in/container/file.txt
```

#### Copy a directory
```bash
docker cp mycontainer:/app/logs ./logs
```

### Why this matters
`docker cp` is the fast way to move files between your machine and a specific container without setting up mounts first.

### Ephemeral vs persistent here
- Copying **out** of a container preserves a snapshot on your host
- Copying **into** a container writes into that container’s filesystem unless the target path is volume-mounted or bind-mounted
- If you later remove the container, files written only into the container layer disappear with it

---

## 9. Build images

### Why you use these
Use these when you want:
- repeatable environments
- versioned packaging of an application
- a reusable base for multiple containers

### Commands

#### Build from Dockerfile in current directory
```bash
docker build -t myapp:latest .
```

#### Build with a different Dockerfile
```bash
docker build -f Dockerfile.dev -t myapp:dev .
```

#### Show image history
```bash
docker image history myapp:latest
```

### Terminology
- **Build**: turn a Dockerfile plus build context into an image
- **Tag**: assign a name/version to an image
- **Layer**: an image is composed of layered filesystem changes

### Ephemeral vs persistent here
- Build containers used internally during image creation are temporary implementation details
- The resulting **image** is persistent until deleted

---

## 10. Tag and push images

### Why you use these
Use these when you want to:
- name images clearly
- version them
- publish them to a registry
- move images between machines/teams

### Commands

#### Tag an image
```bash
docker tag myapp:latest myusername/myapp:latest
```

#### Log in
```bash
docker login
```

#### Push to a registry
```bash
docker push myusername/myapp:latest
```

### Why this matters
Without tagging and pushing, your image is only local.

### Ephemeral vs persistent here
- Local image tag: persistent locally
- Registry copy: persistent remotely
- Authentication session may be temporary depending on your environment

---

## 11. Save and export

### Why you use these
Use these when you need:
- offline transfer of images
- image backups
- ad hoc extraction of a container filesystem

### Commands

#### Save an image as a tar archive
```bash
docker image save -o myimage.tar myapp:latest
```

#### Load an image tar archive
```bash
docker image load -i myimage.tar
```

#### Export a container filesystem
```bash
docker export -o mycontainer.tar mycontainer
```

### Important distinction: `save` vs `export`

| Command | Operates on | What you get |
|---|---|---|
| `docker image save` | image | image archive |
| `docker export` | container | flattened container filesystem |

### Ephemeral vs persistent here
- The tar files you create are persistent host files
- `docker export` is **not** a proper volume backup mechanism for persistent mounted data

---

## 12. Clean up unused stuff

### Why you use these
Use these to recover disk space and remove dead objects.

### Commands

#### Remove stopped containers
```bash
docker container prune
```

#### Remove unused images
```bash
docker image prune
```

#### Remove unused volumes
```bash
docker volume prune
```

#### Remove everything unused
```bash
docker system prune
```

### Why this matters
Docker accumulates:
- stopped containers
- dangling images
- unused networks
- unused volumes

### Risk
Some of these are not easily reversible.  
Especially be careful with:
- `docker volume prune`
- `docker system prune`

### Ephemeral vs persistent here
These commands delete objects that were persistent until you explicitly removed them.

---

## 13. Persist data properly

### Why you use these
Use volumes when data must outlive a container:
- databases
- uploaded files
- app state
- caches you want to keep

### Commands

#### Create a named volume
```bash
docker volume create mydata
```

#### Mount it into a container
```bash
docker run -d --name db -v mydata:/var/lib/postgresql/data postgres
```

### Why volumes exist
Containers are replaceable.  
Volumes give you storage that is not tied to one container’s lifecycle.

### Ephemeral vs persistent here
- container: replaceable / often ephemeral
- volume: persistent

This is the correct mental model for stateful containers.

---

## 14. Use bind mounts for local development

### Why you use these
Use bind mounts when you want:
- the host and container to see the same files
- live code editing from your editor
- direct control over where files live on the host

### Command

#### Mount current directory into container
```bash
docker run -it --rm -v "$PWD":/workspace -w /workspace python:3.12 bash
```

### Volume vs bind mount

| Storage type | Best for | Managed by | Host path control |
|---|---|---|---|
| **Volume** | persistent app/data storage | Docker | indirect |
| **Bind mount** | local development and shared file access | you / host filesystem | direct |

### Ephemeral vs persistent here
- The container may be ephemeral, especially with `--rm`
- The host files are persistent
- The mount makes the container a temporary user of persistent host files

---

## 15. Basic Dockerfile concepts

### Why you use this
Use a Dockerfile when you want reproducibility.  
Do **not** rely on manually “tweaking” containers forever if you want a maintainable setup.

### Minimal example
```dockerfile
FROM ubuntu:24.04
WORKDIR /app
COPY . /app
RUN apt-get update && apt-get install -y curl
CMD ["bash"]
```

### What the instructions mean
- `FROM`: base image
- `WORKDIR`: default working directory
- `COPY`: copy files into image
- `RUN`: execute build-time commands
- `CMD`: default runtime command

### Ephemeral vs persistent here
- Dockerfile: persistent source artifact
- Built image: persistent output
- Containers launched from that image: replaceable runtime instances

---

## 16. Common `docker run` flags worth memorizing

### Why you use these
These are the minimum viable flags for most day-to-day work.

| Flag | Meaning | Why you use it |
|---|---|---|
| `-it` | interactive + TTY | shell access |
| `-d` | detached | background service |
| `--name` | container name | easier management |
| `-p HOST:CONTAINER` | publish port | reach app from host |
| `-v SRC:DST` | mount storage | persistence / file sharing |
| `-w` | working directory | convenient execution context |
| `-e KEY=VALUE` | environment variable | runtime config |
| `--rm` | auto-remove on exit | explicitly ephemeral container |

### Important note on `--rm`
If you use `--rm`, the container is intentionally disposable.  
That is appropriate for:
- temporary shells
- one-off commands
- dev/test scratch containers

It is usually **not** what you want when you are trying to preserve state in the container itself.

---

## 17. Recommended learning sequence

1. Understand **image vs container vs volume**
2. `docker ps`, `docker ps -a`, `docker images`
3. `docker pull`
4. `docker run`
5. `docker exec`
6. `docker logs`
7. `docker cp`
8. `docker stop`, `docker start`, `docker rm`
9. volumes and bind mounts
10. `docker build`
11. prune/cleanup commands

That sequence builds the right lifecycle mental model first, which is the part most people get wrong.

---

## 18. Command block to keep handy

```bash
# inspect what exists
docker ps
docker ps -a
docker images
docker volume ls

# create a NEW container from an image
docker run -it ubuntu:24.04 bash
docker run -d --name web -p 8080:80 nginx

# run a command INSIDE an existing running container
docker exec -it web sh
docker logs -f web

# move files
docker cp web:/etc/nginx/nginx.conf ./nginx.conf
docker cp ./nginx.conf web:/etc/nginx/nginx.conf

# build / publish
docker build -t myapp:latest .
docker tag myapp:latest myusername/myapp:latest
docker login
docker push myusername/myapp:latest

# persistent storage
docker volume create mydata
docker run -d --name db -v mydata:/var/lib/postgresql/data postgres

# cleanup
docker stop web
docker rm web
docker image prune
docker system prune
```

## Bottom line

The highest-value distinctions are:

1. **Image vs container**
   - image = blueprint
   - container = instance

2. **`docker run` vs `docker exec`**
   - `run` = create/start a **new** container
   - `exec` = run a command inside an **existing running** container

3. **Ephemeral vs persistent**
   - container writable state is disposable unless you deliberately preserve it
   - volumes and bind mounts are your persistence mechanisms
