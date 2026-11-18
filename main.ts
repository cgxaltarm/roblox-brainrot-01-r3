// Brainrot Night Market: the entry program for roblox-brainrot-01.
// It hands the game in by copying the Rojo-built place, the Luau
// sources, the Studio screenshots and the play link into the output
// directory, then writing the dossier the judge reads, using the
// vendored make.fun library. Node 22, standard library only.
//
// Run it locally with:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

import { copyFileSync, cpSync, existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { basename, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

const here = fileURLToPath(new URL('.', import.meta.url));
const out = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';

// The grader refuses any output name starting with a dot, so skip
// dotted files and folders (.git, .DS_Store, .gitkeep) at every depth.
const notDotted = (path: string): boolean => !basename(path).startsWith('.');

mkdirSync(out, { recursive: true });
if (!existsSync(join(here, 'game.rbxl'))) {
  throw new Error('game.rbxl is missing: run `rojo build default.project.json --output game.rbxl` first.');
}
copyFileSync(join(here, 'game.rbxl'), join(out, 'game.rbxl'));
copyFileSync(join(here, 'PLAY.json'), join(out, 'PLAY.json'));
cpSync(join(here, 'src'), join(out, 'src'), { recursive: true, filter: notDotted });
mkdirSync(join(out, 'screenshots'), { recursive: true });
if (existsSync(join(here, 'screenshots'))) {
  cpSync(join(here, 'screenshots'), join(out, 'screenshots'), { recursive: true, filter: notDotted });
}

// Same caps the scorer enforces: at most 4 screenshots of 256 KiB,
// a place of at most 500,000 instances, scripts under 8 MiB total.
writeFileSync(
  join(out, 'dossier.json'),
  buildDossier(out, {
    text_max_bytes: 65536,
    screenshots: { max: 4, max_bytes: 262144 },
    max_instances: 500000,
    scripts_max_source_bytes: 8388608,
    scripts_max_path_chars: 1048576,
  }),
);
