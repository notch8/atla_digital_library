# Atla Digital Library

Atla staff use this repository as their digital library.

----
## Table of Contents
  * [Running the stack](#running-the-stack)
    * [Versions](#versions)
    * [Important URL's](#important-urls)
    * [With Docker](#with-docker)
      * [Install Docker](#install-docker)
      * [Start the server](#start-the-server)
      * [Run migrations and seed the database](#run-migrations-and-seed-the-database)
      * [Stop the app and services](#stop-the-app-and-services)
      * [RSpec](#rspec)
  * [Statistics Not Updating](#statistics-not-updating)
  * [Backups](#backups)
    * [Backup Tools](#backup-tools)
    * [What is Backed Up](#what-is-backed-up)
      * [Hyrax](#hyrax)
    * [Backup Schedule](#backup-schedule)
  * [Restore Procedure](#restore-procedure)
----
## Running the stack
### Versions
  - Ruby 2.5.3
  - Rails 5.1.6
  - Hyrax 2.3.3

### Important URL's
- Local site: http://atla.test (http://localhost:3000/ if not using dory)
  - There is no "admin" link so you must go to http://atla.test/dashboard (or http://localhost:3000/dashboard if not using dory) to access the backend
- Staging site: http://dl-staging.atla.com
- Production site:
- Solr:
- Delayed Jobs:

### With Docker
We distribute two configuration files:
- `docker-compose.yml` is set up for development / running the specs
- `docker-compose-prod.yml` is for running the stack in a production setting

#### Install Docker
- Download [Docker Desktop](https://www.docker.com/products/docker-desktop) and log in

#### Configure your local environment
1. Create an empty `.env.development` file

#### Start the server
This project has a containerized development environment managed with with `stack_car`.

```sh
git clone git@gitlab.com:notch8/atla_digital_library.git
cd atla_digital_library
sc up
```

The app should now be available at http://atla.test.

#### Run migrations and seed the database
On the first run, you may need to run some setup:

* run database migrations
* seed the database with collection types and the default admin set

```sh
sc be rails db:create db:schema:load db:migrate db:seed
```
Once these are done, you may need to stop and start the containers to ensure Delayed Job is picking up the database migration.

#### Stop the app and services
- Press `Ctrl + C` in the window where `sc up` is running
- When that's done `sc stop` shuts down the running containers

#### RSpec
In a new tab/window:
```
sc be rails spec
```

## Troubleshooting
- if you see the following error: `mesg: ttyname failed: Inappropriate ioctl for device` and a list of files that already exist, for example `cp: cannot create regular file './public/uv/dist/lib/p-p4r1bdpj.system.entry.js': File exists`
  - run `yarn` (in local shell, not inside container)

- If you `rails db:seed` will not run, or you get the following bulkrax error when trying to edit an importer: `Faraday::ConnectionFailed in Bulkrax::Importers::Edit`
  - run `dc restart fcrepo`

- If you are not able to run the seeds/not able to see the seeded importer, run:
  - `rails hyrax:default_collection_types:create`
  - `rails hyrax:default_admin_set:create`
  - `rails db:seed`

## Statistics Not Updating

Statistics can be updated manually by running `UpdateStatisticalDataJob.perform_later` in the rails console.

Once run, the job will automatically schedule itself to run again in the future.

## Backups
### Backup Tools

We use the [backup gem](http://backup.github.io/backup/v4/) to perform our backups. It has a lot of built in tools for dealing with most of the stack and runs very dependably. An email is sent at the end of each daily backup. This is set as a cron job on the Tomcat server and configured via the `ops/roles/notch8.backups` role.

### What is Backed Up
#### Hyrax

For Hyrax we backup the database that Hyrax uses directly (to store users and session info), along with the database that Fedora uses. We back up all config files and derivatives (to speed restoration). Code is already in Gitlab and thus does not need separate backup. The Solr indexes are not backed up currently as they can be regenerated and are large.

### Backup Schedule

Currently backups are taken nightly. This can be scaled up or down easily by editing the cron jobs on the servers.


## Restore Procedure

Backups are encrypted and stored in S3. To restore backups, first download the correct backup files from S3.  At that point the backup needs to be decrypted as per [instructions here](http://backup.github.io/backup/v4/encryptor-openssl/).  Password is found in the secure env files under `backup_password`. After the tar file is decrypted Postgresql restore is done via the psql command and uploaded files can be copied back in to place manually. At that point Fedora, Solr and Passenger can all be restarted.
