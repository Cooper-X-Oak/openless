# Windows Capsule Contract Lab

This folder preserves the withdrawn Windows capsule contract work as fork-only
research material. It is not an upstream PR proposal unless we decide to revive
it later.

## Context

The original Windows issue was not only a gray edge around the capsule. The
deeper contract question was:

- the DOM pill should own the visible capsule surface;
- the native Windows HWND should only be a transparent carrier/input envelope;
- transparent host margins should pass clicks through;
- visible capsule surfaces should still consume input;
- macOS vibrancy/backdrop behavior should remain separate from Windows.

The withdrawn PR was:

- upstream PR: `Open-Less/openless#499`
- issue: `Open-Less/openless#498`
- implementation commit: `74e4631c0298e78df53cc3c85c79648699ca587e`

The PR was closed because upstream maintainers preferred their own direction,
but the evidence and approach are valuable enough to keep in this fork.

## Preserved Evidence

Recording capsule HITL:

- `recording-hit-test.json`
- `recording-capsule-host-crop.png`
- `recording-capsule-printwindow.png`
- `recording-screen-green-bg.png`

Translation badge capsule HITL:

- `translation-hit-test.json`
- `translation-capsule-host-crop.png`
- `translation-capsule-printwindow.png`
- `translation-screen-green-bg.png`

Comparison:

- `accepted-recording-translation-comparison.png`

## Gate Summary

Recording capsule:

- DPI: `120`
- scale: `1.25`
- expected logical size: `220x84`
- observed physical size: `275x105`
- transparent top-left, left-middle, and bottom-right hit-test points passed through
- pill center hit `OpenLess Capsule`
- `allPassed = true`

Translation capsule:

- DPI: `120`
- scale: `1.25`
- expected logical size: `220x118`
- observed physical size: `275x148`
- transparent top-left, left-middle, and bottom-right hit-test points passed through
- pill center hit `OpenLess Capsule`
- badge center hit `OpenLess Capsule`
- `allPassed = true`

## Design Notes

The lab branch removes native Acrylic/Mica/DWM material from the Windows capsule
host and uses a rounded native `SetWindowRgn` envelope for the visible pill and
translation badge. This avoids making the transparent host rectangle visible on
Windows while preserving click-through behavior outside the visible capsule
surface.

Keep this material in the fork as a reference for future Windows capsule work.
