# Inbox Classic logo

Rebuilt by hand from the Gemini concept (`source/*.jpeg`) as clean SVG on a grid, in the homepage colors:
indigo `#4C5CC5`, coral `#F8485E`, wordmark `#3F3A8F`. `source/gen.py` regenerates every SVG in `svg/`
(`python gen.py <out dir> <PT Sans Bold .ttf>`, needs fonttools and uharfbuzz).

The SVGs use only what simple renderers draw: no `clipPath` (the lines are cut to the envelope in `gen.py`), and every
stroked line carries its own `fill="none"`. Qt's SVG renderer, which Omarchy's app grid and dock use, supports neither
clipping nor every attribute inherited from a group, and drew the envelope's lines past its edges and filled black.

## Files

| File                                      | Use                                                                                                               |
| ----------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| `svg/app-icon.svg`                        | Square app icon, full bleed. Windows, Linux, web. Drop-in for `app/res/app-icon.svg`                              |
| `svg/app-icon-macos.svg`                  | macOS icon on Apple's grid (824 plate on a 1024 canvas)                                                           |
| `svg/favicon.svg`                         | Simplified icon for 16 to 32 px (frame and coral V only)                                                          |
| `svg/mark.svg`                            | The envelope mark on its own (landscape)                                                                          |
| `svg/mark-mono.svg`                       | One color outline envelope (symbolic icons, print, embossing)                                                     |
| `svg/logo-horizontal.svg`, `-on-dark.svg` | Mark plus "Inbox Classic" in PT Sans Bold, outlined                                                               |
| `web/`                                    | `favicon.ico` (16, 32, 48), `favicon.svg`, `apple-touch-icon.png`, `icon-192.png`, `icon-512.png`, `logo-512.png` |
| `windows/app.ico`                         | 16 to 256, the small sizes from the simplified icon                                                               |
| `mac/AppIcon.icns`                        | Built with iconutil from `AppIcon.iconset`                                                                        |
| `linux/hicolor/`                          | PNG sizes, scalable SVG and a `-symbolic` SVG, named `com.inboxclassic.InboxClassic`                              |
| `png/`                                    | Large PNGs for docs, stores and social                                                                            |

## Putting it in the repos

- **inboxclassic.com**: replace `favicon.svg`, `favicon.ico`, `apple-touch-icon.png`, `img/icon-192.png`, `img/logo-512.png` with the files in `web/`.
- **The app** uses copies of three of these: `app/res/app-icon.svg` (Windows, Linux, the scalable icon of the Linux packages), `app/res/app-icon-small.svg` (32 pixels and below, for `app.ico` and the Linux tray) and `app/res/app-icon-mac.svg` (the .icns, made by `scripts/mac-build.sh`). After changing them, run `scripts/build-icons.sh`, which rebuilds `app/res/app.ico` and `linux/data/tray`.

## Review of the Gemini images

- Flat and clean; the colors were close to the homepage's (sampled `#4054B0`, `#F74A5C`, `#35357F`) and are snapped to the exact values.
- Fixed in the rebuild: uneven line weights (the coral V was thinner than the white lines), lines that stopped short or overlapped at random, and the landscape-only shape. The icon now has one stroke width, parallel V and chevron, and diagonals that end under the coral V.
- The generated lettering was close to PT Sans but not it; the wordmark here is real PT Sans Bold, kerned and outlined, so no font is needed.
- The mark has too much detail for 16 px, hence `favicon.svg`.
