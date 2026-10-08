# Italian archive interface

Native Godot controls use reusable nine-patch SVG artwork, defined in `Scripts/ArchiveTheme.gd`. No HTML or browser UI is involved.

- Walnut wood frames, inset brass rules, and small palmette / scroll corner inlays inspired by Italian domestic furniture.
- Parchment interiors and a lightly marked plaster background.
- Bundled DejaVu Serif regular and bold fonts; license in `Fonts/LICENSE.txt`.
- Wood buttons have normal, hovered, selected, disabled, and keyboard-focus states.
- Persistent clock module groups the date and household purse above play, pause, and `x1`–`x5` preset buttons. The gold line tracks progress through the current month. Existing speed durations are preserved; tooltips state seconds per month. These labels indicate speed presets rather than literal multipliers.
- Family, house, finance, chronicle, person, career, and menu surfaces share the same frame system.

The SVGs are project-native vector assets and can be edited without image generation. Nine-patch texture margins preserve their corners as windows resize. The theme is inherited by dynamically added people and controls.

To capture actual Godot rendering:

```bash
godot --path . --script Tools/PreviewInterface.gd --windowed --resolution 1920x1080 -- --person
```

This exports `interface-preview.png` and `person-window-preview.png` here and closes automatically.

The finance page uses five horizontal summary cards and side-by-side household earnings and monthly accounts. `Icons/` contains matching SVG icons; hover explanations retain the full monthly breakdown, currency rules, and funding warnings. Amounts use `L.` for lire and `Fl.` for fiorini.

Capture it with `--finances`; add `--accounts` to preview twelve settled months. The image is written to `finances-preview.png`.
