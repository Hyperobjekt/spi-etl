#!/bin/sh

#
# This script is used to generate the tilesets for
# 2010 Census Tracts for SPI.
# Usage: ./tract-tilesets.sh <source CSV> [<output tileset directory>]
#

# exit early if no source data
if [ -z "$1" ]
  then
    echo "No source CSV provided."
    exit 1
fi

# output to directory if 2nd arg is set, otherwise mbtiles
[ -z "$2" ] &&
   TILESET_OUTPUT="-o tracts.mbtiles" ||
   TILESET_OUTPUT="-e $2"

mkdir -p _proc
echo "Downloading 2010 Census Tracts GeoJSON..."
aws s3 cp s3://$SPI_TILESET_BUCKET/tracts.geojson.gz ./_proc
gzip -d ./_proc/tracts.geojson.gz
echo "Joining CSV file with GeoJSON..."
tippecanoe-json-tool --extract=GEOID \
  --empty-csv-columns-are-null ./_proc/tracts.geojson | \
  LC_ALL=C sort | \
  tippecanoe-json-tool --csv=$1 > ./_proc/tracts.data.json
echo "Generating tilesets..."
tippecanoe $TILESET_OUTPUT -f \
  -l tracts ./_proc/tracts.data.json \
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
aws s3 cp $2 s3://$SPI_TILESET_BUCKET/$SPI_DATA_VERSION/tracts/ --recursive