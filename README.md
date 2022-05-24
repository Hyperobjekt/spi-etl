# SPI ETL Pipeline

## Requirements

- aws-cli
- tippecanoe
- nodejs
- csvkit
- mapshaper
- gettext

> TODO: create a docker container with the above requirements installed

## Building the tilesets + data

> **Warning:** if you are deploying, ensure the SPI_DATA_VERSION in .env will not overwrite the version currently used in production. Instead, increment the version number in the .env file and then update the frontend to point to the new data version.

Use the `build.sh` script to build tilesets and static data.

```sh
Usage: build.sh [-t] [-d] [-r region]
  -t: build tilesets
  -d: deploy output to s3
  -r: region to build (default: all)
```

**Example:** build and deploy data for all regions

```
./build.sh -d
```

**Example:** build and deploy data and tilesets for all regions

```
./build.sh -d -t
```

**Example:** build tracts tileset and data but do not deploy to S3

```
./build.sh -t -r tracts
```

## Source Data and Deploy Endpoints

Source data is stored and deployed in S3. Edit the `.env` vars to change the buckets / keys. Source data should be stored in a folder corresponding to the current data version number. The data output will be uploaded in a folder corresponding to the data version number.
