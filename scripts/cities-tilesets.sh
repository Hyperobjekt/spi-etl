#!/bin/sh

#
# This script is used to generate the tilesets for
# 2010 Census Places for SPI.
# Usage: ./cities-tilesets.sh <source CSV> [<output tileset directory>]
#

# exit early if no source data
if [ -z "$1" ]
  then
    echo "No source CSV provided."
    exit 1
fi

# output to directory if 2nd arg is set, otherwise mbtiles
[ -z "$2" ] &&
   TILESET_OUTPUT="-o cities.mbtiles" ||
   TILESET_OUTPUT="-e $2"

mkdir -p _proc
echo "Downloading 2010 Census Places GeoJSON..."
aws s3 cp s3://$SPI_GEOJSON_BUCKET/cities.geojson.gz ./_proc
gzip -d ./_proc/cities.geojson.gz

echo "Creating city center points GeoJSON..."
mapshaper ./_proc/cities.geojson \
  -filter-fields GEOID,STATE,NAME \
  -join $1 keys=GEOID,GEOID string-fields=GEOID \
  -filter 'Boolean(this.properties.bhn)' \
  -rename-fields state=STATE,name=NAME \
  -points inner \
  -o - format=geojson | \
  tippecanoe-json-tool --extract=GEOID \
    --empty-csv-columns-are-null | \
    LC_ALL=C sort > ./_proc/cities.centers.geojson

echo "Creating choropleth GeoJSON..."
mapshaper ./_proc/cities.geojson \
  -filter-fields GEOID,STATE,NAME \
  -join $1 keys=GEOID,GEOID string-fields=GEOID \
  -filter 'Boolean(this.properties.bhn)' \
  -rename-fields state=STATE,name=NAME \
  -o - format=geojson | \
  tippecanoe-json-tool --extract=GEOID \
    --empty-csv-columns-are-null | \
    LC_ALL=C sort > ./_proc/cities.data.json

echo "Generating tilesets..."
tippecanoe $TILESET_OUTPUT -f \
  -L cities:./_proc/cities.data.json \
  -L cities-centers:./_proc/cities.centers.geojson \
  --read-parallel --maximum-zoom=10 --minimum-zoom=2 \
  --extend-zooms-if-still-dropping --attribute-type=GEOID:string \
  --generate-ids \
  --empty-csv-columns-are-null --coalesce-densest-as-needed \
  --simplification=10 --simplify-only-low-zooms --detect-shared-borders
echo "Tiles generation complete."
if [ -z "$2" ]
  then
    exit 0
fi
aws s3 cp $2 s3://$SPI_TILESET_BUCKET/$SPI_DATA_VERSION/cities/ --recursive \
    --content-type application/x-protobuf \
    --content-encoding gzip \
    --exclude "*.json"
aws s3 cp $2/metadata.json s3://$SPI_TILESET_BUCKET/$SPI_DATA_VERSION/cities/metadata.json \
    --content-type application/json