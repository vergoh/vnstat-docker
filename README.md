# vnStat in a container

vnStat is a console-based network traffic monitor that uses the network
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
and output examples.

## Container content

- Latest released vnStat version
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
    --network=host \
    -e HTTP_PORT=8685 \
    -v "/etc/localtime":"/etc/localtime":ro \
    -v "/etc/timezone":"/etc/timezone":ro \
    --name vnstat \
    vnstat
```

- `--network=host` is necessary for accessing the network interfaces of the Docker host instead of being limited to monitoring the container specific interface
- The http server port can be modified with the `HTTP_PORT` environment as shown in the example above
- Image output is available at `http://localhost:8685/` (using default port)
- Json output is available at `http://localhost:8685/json.cgi` (using default port)
- Add `-v some_local_directory:/var/lib/vnstat` to map the database directory to the local filesystem if easier access/backups is needed

Command line interface can be accessed with:

```
docker exec -t vnstat vnstat --help
```
