# openless-pr497-evidence-upload

Archived human-in-the-loop (HITL) evidence for OpenLess PR #497
(`fix(windows): restore capsule transparent host boundary`).

## What this is

A standalone evidence bundle, not runnable code. The artifacts under
`pr497-capsule-hitl/` document the manual visual gate that verified the
Windows capsule renders over a solid background with transparent native
host margins (no host-sized gray rectangle).

## Contents

- `pr497-capsule-hitl/README.md` — evidence summary and gate result (PASS).
- `pr497-capsule-hitl/meta.json` — pixel-sample measurements and rects.
- `pr497-capsule-hitl/screen-green-bg-hitl.png` — full screenshot.
- `pr497-capsule-hitl/capsule-host-crop-hitl.png` — cropped capsule region.

## How to view

Open the PNGs directly and read `meta.json` for the pixel-sample data.
No build or run step is required.
