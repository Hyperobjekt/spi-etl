# SPI ETL Pipeline

## Requirements

- aws-cli
- tippecanoe
- nodejs
- csvkit

> TODO: create a docker container with the above requirements installed

## Building the tilesets + data

Use the `build.sh` script to build tilesets and static data.

```sh
Usage: build.sh [-t] [-d] [-r region]
  -t: build tilesets
  -d: deploy data + tilesets to S3
  -r: region to build (default: all)
```

**Example:** build and deploy all data

```
./build.sh -d
```

**Example:** build tracts tileset and data, by don't deploy the tilesets

```
./build.sh -t -r tracts
```

## Source Data and Deploy Endpoints

Source data is stored and deployed in S3. Edit the `.env` vars to change the buckets / keys. Source data should be stored in a folder corresponding to the current data version number. The data output will be uploaded in a folder corresponding to the data version number.
