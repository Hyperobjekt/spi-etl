import { readFileSync, writeFileSync } from "fs";
import { csvParse, autoType } from "d3-dsv";

/**
 * Handles reading csv input and writing output
 */
export function io({ process, parser = autoType, filename, output }) {
  filename = filename || process.argv[2];
  output = output || process.argv[3];
  const _data = readFileSync(filename, { encoding: "utf8", flag: "r" });
  const data = csvParse(_data, parser);
  const write = output
    ? (value) => writeFileSync(output, value)
    : (value) => process.stdout.write(value);
  return { data, write, _: { filename, output, data: _data } };
}
