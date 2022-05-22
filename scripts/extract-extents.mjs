import { csvFormat } from "d3-dsv";
import { extent, mean, median, quantile } from "d3-array";
import { io } from "./utils.mjs";

/**
 * This script re-formats the scorecard data from long to wide format
 * Usage: node extract-extents.mjs <input-file> <output-file>
 */
const { data, write } = io({ process });
const extents = data.columns.reduce((result, col) => {
  // ignore rank, and performance columns
  if (col.endsWith("_r")) return result;
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
write(wideCsv);
