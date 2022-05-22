import { csvFormat, autoType } from "d3-dsv";
import { io } from "./utils.mjs";

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

const { data, write } = io({ process, parser });
const cols = ["GEOID"];
const wideData = data.reduce((result, row) => {
  const id = row[ROW_ID];
  if (!result[id]) result[id] = { GEOID: id };
  const metricId = row[METRIC];
  result[id][metricId] = row["value"];
  result[id][`${metricId}_r`] = row["rank"];
  result[id][`${metricId}_p`] = row["performance"];
  if (!cols.includes(metricId)) cols.push(metricId);
  if (!cols.includes(`${metricId}_r`)) cols.push(`${metricId}_r`);
  if (!cols.includes(`${metricId}_p`)) cols.push(`${metricId}_p`);
  return result;
}, {});

const wideCsv = csvFormat(
  Object.values(wideData).sort(
    (a, b) => parseInt(a["GEOID"]) - parseInt(b["GEOID"])
  ),
  cols
);
write(wideCsv);
