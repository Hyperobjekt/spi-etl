import { readFileSync, writeFileSync } from "fs";
import { csvParse, csvFormat, autoType } from "d3-dsv";

/**
 * This script re-formats the scorecard data from long to wide format
 * Usage: node long2wide.mjs <input-file> <output-file>
 */

const ROW_ID = "geoid";
const METRIC = "aspect";

/**
 * Auto type parser, but keeps GEOID as string
 * @param {*} row
 * @returns
 */
const parser = (row) => {
  const idValue = row[ROW_ID];
  delete row[ROW_ID];
  const result = {
    ...autoType(row),
    [ROW_ID]: idValue,
  };
  return result;
};

const filename = process.argv[2];
const output = process.argv[3];
const stringData = readFileSync(filename, { encoding: "utf8", flag: "r" });
const longData = csvParse(stringData, parser);
const cols = ["GEOID"];
const wideData = longData.reduce((result, row) => {
  const id = row[ROW_ID];
  if (!result[id]) result[id] = { GEOID: id };
  const metricId = row[METRIC];
  result[id][metricId] = row["value"];
  result[id][`${metricId}_r`] = row["rank"];
  result[id][`${metricId}_p`] = row["performance"];
  result[id][`${metricId}_i`] = row["imputed"];
  if (!cols.includes(metricId)) cols.push(metricId);
  if (!cols.includes(`${metricId}_r`)) cols.push(`${metricId}_r`);
  if (!cols.includes(`${metricId}_p`)) cols.push(`${metricId}_p`);
  if (!cols.includes(`${metricId}_i`)) cols.push(`${metricId}_i`);
  return result;
}, {});

const wideCsv = csvFormat(Object.values(wideData), cols);
if (output) writeFileSync(output, wideCsv);
if (!output) process.stdout.write(wideCsv);
