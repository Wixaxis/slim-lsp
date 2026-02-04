import { sortTailwindClasses } from "@herb-tools/tailwind-class-sorter";
import process from "node:process";

const readStdin = async () => {
  let data = "";
  for await (const chunk of process.stdin) {
    data += chunk;
  }
  return data.trim();
};

const main = async () => {
  const input = await readStdin();
  if (!input) {
    process.stdout.write(JSON.stringify({ classes: "" }));
    return;
  }

  const payload = JSON.parse(input);
  const options = {
    tailwindConfig: payload.tailwindConfig || undefined,
    tailwindStylesheet: payload.tailwindStylesheet || undefined,
    tailwindPreserveDuplicates: payload.tailwindPreserveDuplicates ?? false,
    tailwindPreserveWhitespace: payload.tailwindPreserveWhitespace ?? true,
    baseDir: payload.baseDir || undefined
  };

  const sorted = await sortTailwindClasses(payload.classes || "", options);
  process.stdout.write(JSON.stringify({ classes: sorted }));
};

main().catch((error) => {
  process.stderr.write(`${error.message}\n`);
  process.exit(1);
});
