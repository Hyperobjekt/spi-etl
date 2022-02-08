#!/bin/sh

# load env vars
export $(echo $(cat .env | sed 's/#.*//g' | sed 's/\r//g' | xargs) | envsubst)

# defaults
DEPLOY=0
BUILD_TILESETS=0
REGIONS=(states cities tracts)

# process command line args
while getopts 'dtr:h' opt; do
  case "$opt" in
    d)
      DEPLOY=1
      ;;

    t)
      BUILD_TILESETS=1
      ;;

    r)
      arg="$OPTARG"
      REGIONS=($arg)
      ;;

    ?|h)
      echo "Usage: $(basename $0) [-t] [-d] [-r region]"
      echo "  -t: build tilesets"
      echo "  -d: deploy tilesets"
      echo "  -r: region to build (default: all)"
      exit 1
      ;;
  esac
done
shift "$(($OPTIND -1))"

# setup processing folders
rm -rf _proc

for REGION in ${REGIONS[@]}; do
  mkdir -p _proc/$REGION
  echo "building $REGION"
  aws s3 cp s3://$SPI_DATA_BUCKET/$SPI_DATA_VERSION/source/$REGION.csv ./_proc/$REGION.csv
  echo "shaping source data"
  if [ "$REGION" = "states" ] || [ "$REGION" = "cities" ]; then
    # convert states or cities from long to wide format, remove "score_" prefix for variables, and sort by GEOID
    node ./scripts/long2wide.mjs ./_proc/$REGION.csv | \
      sed -e 's/score_//g' | \
      csvsort -c 1 --no-inference > ./_proc/$REGION.wide.csv
  else
    # rename geoid to GEOID and sort by GEOID
    cat ./_proc/$REGION.csv | \
      sed -e 's/geoid/GEOID/g' | \
      csvsort -c 1 --no-inference > ./_proc/$REGION.wide.csv
  fi
  # pull the extents for the region (use to determine scales)
  node ./scripts/extract-extents.mjs ./_proc/$REGION.wide.csv ./_proc/$REGION.extents.csv
  if [ $DEPLOY = 1 ] && [ $BUILD_TILESETS = 1 ]; then
    echo "uploading static data to S3"
    aws s3 cp ./_proc/$REGION.extents.csv s3://$SPI_DATA_BUCKET/$SPI_DATA_VERSION/output/$REGION-extents.csv
    aws s3 cp ./_proc/$REGION.wide.csv s3://$SPI_DATA_BUCKET/$SPI_DATA_VERSION/output/$REGION-full.csv
    echo "building tileset"
    ./scripts/$REGION-tilesets.sh ./_proc/$REGION.wide.csv ./_proc/$REGION
  elif [ $DEPLOY = 0 ] && [ $BUILD_TILESETS = 1 ]; then
    echo "building tileset"
    ./scripts/$REGION-tilesets.sh ./_proc/$REGION.wide.csv
  elif [ $DEPLOY = 1 ] && [ $BUILD_TILESETS = 0 ]; then
    echo "uploading static data to S3"
    aws s3 cp ./_proc/$REGION.extents.csv s3://$SPI_DATA_BUCKET/$SPI_DATA_VERSION/output/$REGION-extents.csv
    aws s3 cp ./_proc/$REGION.wide.csv s3://$SPI_DATA_BUCKET/$SPI_DATA_VERSION/output/$REGION-full.csv
  else
    echo "skipping tileset build and deploy.  use -t to build tilesets and -d to deploy"
  fi
  echo "done!"
done
