# `cap` &mdash; the public front-end for the Canadiana Access Platform

## Setup

To set up this repo:

```
$ git clone git@github.com:crkn-rcdr/cap.git
$ cp docker-compose.override.yml.example docker-compose.override.yml
```

In `docker-compose.override.yml`, replace `CAP_PASSWORD` wherever it's found with the value found in the shared vault in 1Password.

Every portal that you want to view locally requires an entry in `/etc/hosts` with each subdomain suffixed with `-dev`:

```
127.0.0.1   www-dev.canadiana.ca
127.0.0.1   heritage-dev.canadiana.ca
```

## Run

First, ensure that the [Access-Platform](https://github.com/crkn-rcdr/Access-Platform) development environment is running, as its `haproxy` service handles the reverse proxying required to point requests to each portal. You will also need to ensure that you're connected to the Canadiana VPN.

Build and start a local dev environment:

```
$ docker-compose up --build
```

## Development

### Config

CAP configuration can be found in two places. Making changes to configuration requires a webserver restart (see [Back-end Perl Code](#back-end-perl-code), below).

#### [`CAP/cap.conf`](CAP/cap.conf)

This file used to contain a lot of server and portal configuration that required occasional change, but everything important has been moved to files in [`CAP/conf`](CAP/conf).

#### [`CAP/conf`](CAP/conf)

This directory contains configuration files that are used by some of CAP's models. Of special note are the following:
- the JSON files in [`CAP/conf/i18n`](CAP/conf/i18n), which contain the strings that are used by the i18n system when handling `c.loc` directives
- the JSON files in [`CAP/conf/portals`](CAP/conf/portals), which contain portal configuration. Explanations of these properties can be found in [`CAP/lib/CAP/Portal.pm`](CAP/lib/CAP/Portal.pm)

### Back-end Perl code

Back-end Perl code can be found in [`CAP/lib`](CAP/lib). After making changes, you will need to send the HUP signal to the CAP process to restart the webserver:

```
$ docker-compose exec cap /bin/bash
...:/opt/cap$ kill -HUP 1
```

Set the `CATALYST_DEBUG` environment variable to `1` in `docker-compose.override.yml` to view debug output in the CAP logs.

Much of CAP's business logic is found in the [`CAP/lib/CIHM/Access`](CAP/lib/CIHM/Access) directory, which was created in an old attempt to separate this code out for other resources to use. There is an [outstanding ticket](https://github.com/crkn-rcdr/cap/issues/42) to move this content into [`CAP/lib/CAP/Model`](CAP/lib/CAP/Model).

External Perl dependencies are listed in [`CAP/cpanfile`](CAP/cpanfile).

### Templates

CAP uses [Template Toolkit](http://www.template-toolkit.org/docs/index.html) to build its HTML templates. The templates can be found in `cap/root/templates`. Each portal has its own template directory, where you can override common templates (found in the `Common` directory, naturally) with portal-specific things. A template directory looks like this:

- `blocks`: English/French chunks of HTML that can be inserted into templates
- `layout`: Page layout templates
- `pages`: Full HTML pages
- `partial`: Partial templates that are inserted into other templates

The templates in each template directory's root generally map to CAP Controller routes.

### CSS/JS

Style and JavaScript development takes place in the [`frontend`](frontend) directory. To set it up, with `pnpm` installed globally (as you'll have done for working with the Access-Platform repo):

```
$ cd frontend
$ pnpm install
```

This directory has a [gulpfile](frontend/gulpfile.js) which contains scripts for building CAP front-end assets. Run

```
$ pnpm exec gulp watch -r
```

to continuously rebuild the assets while working on them, and

```
$ pnpm exec gulp -r
```

to build the assets for production use. This is a very important step as the production build strips out unused [Bootstrap](https://getbootstrap.com/docs/4.6/getting-started/introduction/) styles.

Don't forget to update the 'r => <version>' for the cap.js import in main.tt if you've changed the JS code at all.

## Deployment

Use the following to deploy the `cap` image to our internal docker repository:

```
$ ./deployImage.sh
```

## Demo urls
- https://gac-demo.canadiana.ca/
- https://heritage-demo.canadiana.ca/
- https://mcgillarchives-demo.canadiana.ca/
- https://nrcan-demo.canadiana.ca/
- https://parl-demo.canadiana.ca/
- https://pub-demo.canadiana.ca/
- https://sve-demo.canadiana.ca/
- https://www-demo.canadiana.ca/

## Production urls
- https://gac.canadiana.ca/
- https://heritage.canadiana.ca/
- https://mcgillarchives.canadiana.ca/
- https://nrcan.canadiana.ca/
- https://parl.canadiana.ca/
- https://pub.canadiana.ca/
- https://sve.canadiana.ca/
- https://www.canadiana.ca/

