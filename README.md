# Savanna Model website builder

Hakyll project for building the Savanna Model static site

## Build

### Nix shell (optional)

For local development on NixOS:

```
$ nix-shell
```

### Semantic UI and Gulp dependencies

```
$ npm install
$ cd semantic
$ npx gulp build
```

Use `npx gulp watch` for frequent changes to Semantic UI source files.

### Hakyll site exectuable

```
$ stack build
```

Use `stack build --fast --file-watch` for active development on `site.hs` file.

### Generate Savanna Model site

```
$ stack exec -- site build
```

Use `stack exec -- site watch` for active development on template files.

## Preview

```
$ stack exec -- site watch
```

Then visit http://127.0.0.1:8000 to view the generated site.

## Deploy

Deployment is automated via GitHub Actions. Pushing to `main` triggers a build
and deploys the generated site to the
[savannamodel-website](https://github.com/dmp1ce/savannamodel-website) repository.

### Manual deploy

To manually deploy, use the deploy script from the website repo:

```
$ cd ../savannamodel-website
$ ./deploy.sh /path/to/savannamodel-hakyll
```

### CI/CD setup

The GitHub Actions workflow requires a `DEPLOY_KEY` secret containing an SSH
private key with push access to the `savannamodel-website` repository.
