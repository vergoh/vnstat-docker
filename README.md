![GitHub Workflow Status (branch)](https://img.shields.io/github/workflow/status/vergoh/vnstat-docker/CI/master)
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

- [Latest released](https://humdi.net/vnstat/CHANGES) vnStat version
- vnStat daemon (`vnstatd`) is running as the primary process
- [thttpd](https://acme.com/software/thttpd/) provides vnStat image output (`vnstati`) via http (port 8685 by default)
- vnStat command line (`vnstat`)

## Building the container

```
docker build -t vergoh/vnstat .
```

## Running the container

```
docker run -d \
    --restart=unless-stopped \
    --network=host \
    -e HTTP_PORT=8685 \
    -v "/etc/localtime":"/etc/localtime":ro \
    -v "/etc/timezone":"/etc/timezone":ro \
    --name vnstat \
    vergoh/vnstat
```

- `--network=host` is necessary for accessing the network interfaces of the Docker host instead of being limited to monitoring the container specific interface
- `--privileged` may need to be used if the date within the container starts from 1970
  - The proper solution would be to update libseccomp2 to a more recent version than currently installed
- The http server port can be modified using the `HTTP_PORT` environment variable as shown in the example above
  - See the full list of available environment variables below
- Image output is available at `http://localhost:8685/` (using default port)
- Json output is available at `http://localhost:8685/json.cgi` (using default port)
- Add `-v some_local_directory:/var/lib/vnstat` to map the database directory to the local filesystem if easier access/backups is needed
- It takes around 5 minutes for the initial data to become available for interfaces having traffic

Command line interface can be accessed with:

```
docker exec vnstat vnstat --help
```

## docker-compose.yml

```
version: "3.7"
services:

  vnstat:
    image: vergoh/vnstat:latest
    container_name: vnstat
    restart: unless-stopped
    network_mode: "host"
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /etc/timezone:/etc/timezone:ro
      - vnstatdb:/var/lib/vnstat
    environment:
      - HTTP_PORT=8685
      - LARGE_FONTS=0
      - CACHE_TIME=1
      - RATE_UNIT=1

volumes:
  vnstatdb:
```

## Environment variables

Name | Description | Default value
--- | --- | ---
HTTP_PORT | Port of the web server | 8586
SERVER_NAME | Name of the server in the web page title | Output of `hostname` command
LARGE_FONTS | Use large fonts in images (0: no, 1: yes) | 0
CACHE_TIME | Cache created images for given number of minutes (0: disabled) | 1
RATE_UNIT | Used traffic rate unit, 0: bytes, 1: bits | 1
