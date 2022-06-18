![GitHub Workflow Status (branch)](https://img.shields.io/github/workflow/status/vergoh/vnstat-docker/release/master)
![Docker Image Size (tag)](https://img.shields.io/docker/image-size/vergoh/vnstat/latest)

# vnStat in a container

vnStat is a network traffic monitor that uses the network
interface statistics provided by the kernel as information source. This
means that vnStat won't actually be sniffing any traffic and also ensures
light use of system resources regardless of network traffic rate.

By default, traffic statistics are stored on a five minute level for the last
48 hours, on a hourly level for the last 4 days, on a daily level for the
last 2 full months and on a yearly level forever. The data retention durations
are fully user configurable. Total seen traffic and a top days listing is also
provided.

See the [official webpage](https://humdi.net/vnstat/) or the
[GitHub repository](https://github.com/vergoh/vnstat) for additional details
and output examples. An example of the included image output is also
[available](https://humdi.net/vnstat/cgidemo/).

## Container content

- vnStat daemon (`vnstatd`) is running as the primary process
- [lighttpd](https://www.lighttpd.net/) provides vnStat image output (`vnstati`) via http (port 8685 on all interfaces by default)
- vnStat command line (`vnstat`)

## Supported tags in Docker Hub

- [`vergoh/vnstat:latest`](https://github.com/vergoh/vnstat-docker/blob/master/Dockerfile) - [latest released](https://github.com/vergoh/vnstat/releases) vnStat version
- [`vergoh/vnstat:dev`](https://github.com/vergoh/vnstat-docker/blob/master/Dockerfile-dev) - [latest commit](https://github.com/vergoh/vnstat/commits/master) from GitHub repository

Version specific tags are available starting from `2.7` with the latest release being the same as `latest` tag. `latest` and `dev` are automatically built at least once every month to include possible build time dependency updates.

Currently `latest` also includes updated versions of `vnstat.cgi` and `vnstat-json.cgi` for improved configurability.

## Building the container

```sh
docker build -t vergoh/vnstat .
```

## Running the container

```sh
docker run -d \
    --restart=unless-stopped \
    --network=host \
    -e HTTP_PORT=8685 \
    -v /etc/localtime:/etc/localtime:ro \
    -v /etc/timezone:/etc/timezone:ro \
    --name vnstat \
    vergoh/vnstat
```

- `--network=host` is necessary for accessing the network interfaces of the Docker host instead of being limited to monitoring the container specific interface
- Volumes `/etc/localtime` and `/etc/timezone` are used to configure the container to use the same time zone as the host is using
  - Alternatively the `TZ` environment variable can be used (`-e TZ=`) with a [supported value](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones), localtime and timezone volumes are overridden if used in combination
- `--privileged` may need to be used if the date within the container starts from 1970
  - The proper solution would be to update libseccomp2 to a more recent version than currently installed
- The http server binds by default to all interfaces using the port specified with the `HTTP_PORT` variable. As `--network=host` needs to be enabled, the usual Docker port mapping with `-p` or `--publish` isn't available with this container. Visibility of the http server can be restricted using firewall rules or binding the http server to a specific IP address using the `HTTP_BIND` variable. Localhost access can be enforced by setting `HTTP_BIND` as `127.0.0.1`
  - See the full list of available environment variables below
  - Alternatively see the two container solution using docker-compose explained below
- Image output is available at `http://localhost:8685/` (using default port)
- Json output is available at `http://localhost:8685/json.cgi` (using default port)
- Add `-v some_local_directory:/var/lib/vnstat` to map the database directory to the local filesystem if easier access/backups is needed

Command line interface can be accessed with:

```sh
docker exec vnstat vnstat --help
```

## docker-compose.yml

Two example docker-compose compose files are provided:

[`docker-compose.yml`](https://github.com/vergoh/vnstat-docker/blob/master/docker-compose.yml) is the more simple example with both the vnStat daemon and the httpd running in the same container. While this example works without changes for most users, it results in the httpd also using host networking which may not be a wanted feature for some users.

[`docker-compose_isolated_httpd.yml`](https://github.com/vergoh/vnstat-docker/blob/master/docker-compose_isolated_httpd.yml) consist of two containers running from the same image. The vnStat daemon is running in the first container (`vnstat`) with host networking in order to access all network interfaces but doesn't provide any services or bind to ports. The second container (`vnstati`) doesn't use host networking but provides the httpd which accesses the statistics using a shared volume in read-only mode.

## Environment variables

Name | Description | Default value
--- | --- | ---
HTTP_PORT | Port of the http server, use `0` to disable http server | 8685
HTTP_BIND | IP address for the http server to bind, use `127.0.0.1` to bind only to localhost and prevent remote access | `*`, all addresses
HTTP_LOG | Http server log output file, use `/dev/stdout` for output to console and `/dev/null` to disable logging | `/dev/stdout`
SERVER_NAME | Name of the server in the web page title | Output of `hostname` command
LARGE_FONTS | Use large fonts in images (0: no, 1: yes) | 0
CACHE_TIME | Cache created images for given number of minutes (0: disabled) | 1
RATE_UNIT | Used traffic rate unit, 0: bytes, 1: bits | 1
PAGE_REFRESH | Page auto refresh interval in seconds (0: disabled) | 0
RUN_VNSTATD | Start vnStat daemon (0: no, 1: yes) | 1
TZ | Set time zone ([list of supported values](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)), overrides configuration from possible `/etc/localtime` and `/etc/timezone` volumes | *unset*

## Usage tips

### Add descriptive interface name

```sh
docker exec vnstat vnstat -i eno3 --setalias "Basement switch"
```

### Stop monitoring unnecessary interface

```sh
docker exec vnstat vnstat -i br-20f8582bfc70 --remove --force
```

### Add interface for monitoring

1. Check that the interface is visible on the list of available interfaces:

    ```sh
    docker exec vnstat vnstat --iflist
    ```

2. Add the interface

    ```sh
    docker exec vnstat vnstat -i br-20f8582bfc70 --add
    ```

3. The daemon will notice the change within 5 minutes and start monitoring the interface

## Troubleshooting

- All images show `no data available` after the container has been started.
  - The database write interval is 5 minutes so it will take up to 5 minutes for the initial data to become available.

- Is the container running?

    ```sh
    docker ps
    ```

- What does the container log?

    ```sh
    docker logs vnstat
    ```

- Using a Synology NAS and timezone isn't correct?
  - Use `/etc/TZ:/etc/localtime:ro` instead of `/etc/localtime:/etc/localtime:ro` or use the `TZ` environment variable.

- Container log shows `Latest database update is in the future (db: 2037-04-03 18:16:49 > now: 1970-01-01 02:00:00)` or something similar with `now` being in 1970.
  - Use `--privileged` or upgrade libseccomp2 to a much more recent version.
