# Savanna Model website builder

Hakyll project for building the Savanna Model static site

## Releases

Every deployment should get a version bump and a changelog entry:

1. Add an entry to `changelog.markdown` describing the changes.
2. Increment the version in `VERSION` (semantic versioning: MAJOR for
   redesigns, MINOR for new features, PATCH for fixes and content updates).
   Keep `package.yaml` and `package.json` versions aligned.
3. Commit and push to `master` — GitHub Actions builds and deploys
   automatically.

The version from `VERSION` is shown in the site footer, and the changelog is
published at <https://savannamodel.info/changelog.html>.

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
