# UPGRADING TERRAFORM VERSIONS

Upgrading terraform versions can be a pain, this script allows you to upgrade all services
quickly. Scanning through a list of terraform services and upgrading the travis.yml.

## Expected behaviour
`upgrade-terraform` will iterate through all services provided. If any have local changes or are not on a master branch, the
script will exit with an error.

## Usage
```bash
upgrade-terraform <file-containing-space-separated-paths> <desired-version>
```

### Parameters
1. `file-containing-space-separated-paths` is the path to a line separated file containing the services
that you which to upgrade.
1. `desired-version` is the new terraform version to apply to travis.yml. It must match the expected format of `0.12.2[0-9]`

## Example Usage

This will upgrade all api services to 0.12.24.
```bash
./upgrade-terraform.sh terraform-services.txt 0.12.24
```

