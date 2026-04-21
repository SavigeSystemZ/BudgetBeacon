# Static Frontend Blueprint

Use this for no-framework sites, microsites, or dashboards where simplicity and portability matter more than a heavy toolchain.

## Expected repo shape

```
index.html          entry surface
assets/
  css/              stylesheets
  js/               JavaScript modules
  images/           local media
pages/              additional HTML pages (if site grows beyond one)
```

## Baseline stack

- HTML5 (semantic elements)
- CSS3 (custom properties for theming, flexbox/grid for layout)
- Vanilla JavaScript (ES modules)
- No build step required

## Validation commands

- Serve: `python3 -m http.server 8000 --bind 127.0.0.1`
- Smoke test: `curl -fsS http://127.0.0.1:8000/`
- Lint (optional): `npx htmlhint index.html` or `npx stylelint "assets/css/**/*.css"`

## Quality expectations

- Semantic HTML — use `nav`, `main`, `section`, `article`, `header`, `footer`, `button`, `label`. Not divs for everything.
- Intentional and responsive CSS — deliberate spacing, typography scale, and color palette. Layout works at mobile and desktop.
- JavaScript focused on clear state transitions — no framework-like complexity without framework discipline.
- Text contrast meets WCAG AA (4.5:1 for normal text, 3:1 for large text).
- Touch targets at least 44x44px for interactive elements.
- No horizontal scrolling at any viewport width.
- Pages load fast — minimal dependencies, optimized images, no unnecessary scripts.

## First milestone suggestion

1. Ship one polished static view with meaningful content or interactive behavior (filtering, toggling, data display).
2. Confirm `python3 -m http.server 8000 --bind 127.0.0.1` starts and `curl -fsS http://127.0.0.1:8000/` returns 200.
3. Confirm the page renders correctly at 360px and 1280px viewports.
4. Confirm text contrast meets WCAG AA using browser dev tools or contrast checker.
5. Record design direction, color palette, and typography choices in `DESIGN_NOTES.md`.
