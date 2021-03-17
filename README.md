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

Style and JavaScript development takes place in the [`frontend`](frontend) directory. To set it up, from that directory, run `pnpx install`. `pnpx gulp watch` allows for changes to update the static files in CAP. `pnpx gulp` builds the static files for production use.
