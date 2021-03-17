# `cap` &mdash; the public front-end for the Canadiana Access Platform

## Development

```
$ git clone git@github.com:crkn-rcdr/cap.git
$ cp docker-compose.override.yml.example docker-compose.override.yml
```

Replace `CAP_PASSWORD` wherever it's found with the value found in the shared vault in 1Password. Then, you can build and start a local dev environment:

```
$ docker-compose up --build
```

Make sure that every site you want to view locally has an entry in `/etc/hosts` with each subdomain suffixed with `-dev`:

```
127.0.0.1   www-dev.canadiana.ca
127.0.0.1   heritage-dev.canadiana.ca
```

Style and JavaScript development takes place in the [`frontend`](frontend) directory. To set it up, from that directory, run `pnpx install`. `pnpx gulp watch` allows for changes to update the static files in CAP. `pnpx gulp` builds the static files for production use.
