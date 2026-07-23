# Design and motion

Limiter uses a restrained native-editorial design: warm surfaces, one clear action per screen, compact information groups, system typography, SF Symbols, and motion that explains state changes.

## Product hierarchy

- The user's current intention is the primary content on Today.
- Daily outcomes are a compact factual summary, not a score or an estimate of “time saved.”
- Setup prioritizes likely distracting apps while preserving a complete searchable application list.
- The intervention keeps **Return to focus** immediately available, visually primary, and first in keyboard focus order.
- Empty states explain what will happen next without oversized illustration or decorative filler.

## Motion references

The project consulted these user-selected web references:

- [GSAP](https://github.com/greensock/GSAP) for purposeful sequencing, easing, and interruptible state transitions.
- [React Bits](https://github.com/DavidHDev/react-bits) for selected-state feedback, compact interactive components, and numeric/content transitions.
- [Lenis](https://github.com/darkroomengineering/lenis) for scroll-behavior principles.
- [ShaderGradient](https://github.com/ruucm/shadergradient) and [React Three Fiber](https://github.com/pmndrs/react-three-fiber) as references for projects that genuinely need expressive WebGL or 3D.

Limiter does not ship these JavaScript packages. It is a native SwiftUI application, so applicable ideas are implemented with native spring, opacity, offset, focus, and numeric transitions. Native macOS scrolling is preserved instead of being replaced, and GPU-heavy 3D decoration is intentionally omitted.

No source code or visual asset was copied from these repositories, so this design pass adds no runtime dependency or third-party license payload.

## Accessibility and restraint

- Interactive targets are at least 44 points where custom sizing is used.
- Keyboard focus is visible and follows the primary task.
- VoiceOver labels describe timers, duration menus, app rules, and icon-only actions.
- Reduced Motion replaces spatial transitions with opacity changes and disables press scaling.
- Light and dark palettes use independent semantic colors rather than simple inversion.
- Motion stays within the 180–260 ms token range and communicates selection, navigation, or value changes rather than running continuously.
