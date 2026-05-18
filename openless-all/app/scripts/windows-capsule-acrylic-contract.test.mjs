import { readFile } from 'node:fs/promises';

function assertMatch(source, pattern, name) {
  if (!pattern.test(source)) {
    throw new Error(`${name}: pattern ${pattern} not found`);
  }
}

const libRs = await readFile(new URL('../src-tauri/src/lib.rs', import.meta.url), 'utf-8');
const capsuleTsx = await readFile(new URL('../src/components/Capsule.tsx', import.meta.url), 'utf-8');
const capsuleLayoutTs = await readFile(new URL('../src/lib/capsuleLayout.ts', import.meta.url), 'utf-8');

if (/apply_acrylic\(&capsule/.test(libRs)) {
  throw new Error(
    'windows capsule must not apply Acrylic to the whole native host; it paints transparent shadow/badge margins gray',
  );
}

assertMatch(
  libRs,
  /apply_acrylic\(&qa,\s*Some\(\(30,\s*32,\s*38,\s*140\)\)\)/,
  'windows QA window may keep Acrylic because its panel fills the native host',
);

assertMatch(
  capsuleLayoutTs,
  /const horizontalInset = 12;[\s\S]*?width: pill\.width \+ horizontalInset \* 2,[\s\S]*?height: translationActive \? 118 : 84,[\s\S]*?bottomInset: 12,/,
  'windows capsule host must keep transparent margins for shadow, badge, and animation room',
);

assertMatch(
  capsuleTsx,
  /const useBackdrop = os !== 'win';/,
  'windows capsule pill should not depend on WebView2 backdrop-filter inside a transparent native window',
);

assertMatch(
  capsuleTsx,
  /background: os === 'win' \? 'rgba\(255, 255, 255, 0\.96\)' : 'rgba\(255, 255, 255, 0\.85\)'/,
  'windows capsule pill should carry an opaque enough DOM surface after removing host Acrylic',
);

assertMatch(
  capsuleTsx,
  /return\s*\(\s*<div\s*style=\{\{[\s\S]*?width:\s*'100%',[\s\S]*?height:\s*'100%',[\s\S]*?paddingLeft:\s*hostMetrics\.horizontalInset,[\s\S]*?paddingRight:\s*hostMetrics\.horizontalInset,[\s\S]*?background:\s*'transparent'/,
  'capsule host should remain transparent outside the visible pill',
);
