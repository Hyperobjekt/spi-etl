#!/bin/sh

#
# This script is used to generate the tilesets for US States for SPI.
# Usage: ./states-tilesets.sh <source CSV> [<output tileset directory>]
#

# exit early if no source data
if [ -z "$1" ]
  then
    echo "No source CSV provided."
    exit 1
fi

# output to directory if 2nd arg is set, otherwise mbtiles
[ -z "$2" ] &&
   TILESET_OUTPUT="-o states.mbtiles" ||
   TILESET_OUTPUT="-e $2"

mkdir -p _proc
echo "Downloading States GeoJSON..."
aws s3 cp s3://$SPI_GEOJSON_BUCKET/states.geojson.gz ./_proc
gzip -d ./_proc/states.geojson.gz
echo "Joining CSV file with GeoJSON..."

echo "Creating choropleth GeoJSON..."
mapshaper ./_proc/states.geojson \
  -filter-fields GEOID,STATE,NAME \
  -join $1 keys=GEOID,GEOID string-fields=GEOID \
  -rename-fields state=STATE,name=NAME \
  -o - format=geojson | \
  tippecanoe-json-tool --extract=GEOID \
    --empty-csv-columns-are-null | \
    LC_ALL=C sort > ./_proc/states.data.json

# tippecanoe-json-tool --extract=GEOID \
#   --empty-csv-columns-are-null ./_proc/states.geojson | \
#   LC_ALL=C sort | \
#   tippecanoe-json-tool --csv=$1 > ./_proc/states.data.json

echo "Generating tilesets..."
tippecanoe $TILESET_OUTPUT -f \
  -l states ./_proc/states.data.json \
  --read-parallel --maximum-zoom=10 --minimum-zoom=1 \
  --extend-zooms-if-still-dropping --attribute-type=GEOID:string \
  --generate-ids \
  --empty-csv-columns-are-null --coalesce-densest-as-needed \
  --simplification=10 --simplify-only-low-zooms --detect-shared-borders
echo "Tiles generation complete."
if [ -z "$2" ]
  then
    exit 0
fi


aws s3 cp $2 s3://$SPI_TILESET_BUCKET/$SPI_DATA_VERSION/states/ --recursive \
    --content-type application/x-protobuf \
    --content-encoding gzip \
    --exclude "*.json"
aws s3 cp $2/metadata.json s3://$SPI_TILESET_BUCKET/$SPI_DATA_VERSION/states/metadata.json \
    --content-type application/json