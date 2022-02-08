import { readFileSync, writeFileSync } from "fs";
import { csvParse, csvFormat, autoType } from "d3-dsv";
import { extent, mean, median, quantile } from "d3-array";

/**
 * This script re-formats the scorecard data from long to wide format
 * Usage: node extract-extents.mjs <input-file> <output-file>
 */

const filename = process.argv[2];
const output = process.argv[3];
const stringData = readFileSync(filename, { encoding: "utf8", flag: "r" });
const data = csvParse(stringData, autoType);
const extents = data.columns.reduce((result, col) => {
  // ignore rank, imputed, and performance columns
  if (col.endsWith("_r")) return result;
  if (col.endsWith("_i")) return result;
  if (col.endsWith("_p")) return result;
  if (col === "GEOID") return result;
  const extentValue = extent(data, (row) => row[col]);
  result[col] = {
    id: col,
    min: extentValue[0],
    max: extentValue[1],
    q1: quantile(data, 0.01, (row) => row[col]),
    q99: quantile(data, 0.99, (row) => row[col]),
    median: median(data, (row) => row[col]),
    avg: mean(data, (row) => row[col]),
  };
  return result;
}, {});

const wideCsv = csvFormat(
  Object.values(extents).sort((a, b) => {
    if (a.id < b.id) return -1;
    if (a.id > b.id) return 1;
    return 0;
  }),
  ["id", "min", "max", "q1", "q99", "median", "avg"]
);
if (output) writeFileSync(output, wideCsv);
if (!output) process.stdout.write(wideCsv);
