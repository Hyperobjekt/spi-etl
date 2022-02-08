import { readFileSync, writeFileSync } from "fs";
import { csvParse, csvFormat, autoType } from "d3-dsv";
import { extent } from "d3-array";

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
  const extentValue = extent(data, (row) => row[col]);
  result[col] = { id: col, min: extentValue[0], max: extentValue[1] };
  return result;
}, {});

const wideCsv = csvFormat(
  Object.values(extents).sort((a, b) => {
    if (a.id < b.id) return -1;
    if (a.id > b.id) return 1;
    return 0;
  }),
  ["id", "min", "max"]
);
if (output) writeFileSync(output, wideCsv);
if (!output) process.stdout.write(wideCsv);
