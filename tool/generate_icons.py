#!/usr/bin/env python3
"""Generate auto_env desktop and tray icons.

The icon uses the same visual language as the app: Apple-light surfaces,
system blue as the primary action color, and system green for the active
environment. The desktop icon keeps a configuration-card metaphor, while the
tray icon is reduced to a compact switch mark for 16px readability.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]

MAC_ICON_DIR = ROOT / "macos/Runner/Assets.xcassets/AppIcon.appiconset"
WINDOWS_ICON = ROOT / "windows/runner/resources/app_icon.ico"
TRAY_DIR = ROOT / "assets/tray"
SOURCE_DIR = ROOT / "assets/icon_sources"

APP_ICON_SIZES = (16, 32, 64, 128, 256, 512, 1024)
WINDOWS_ICON_SIZES = (16, 24, 32, 48, 64, 128, 256)

SYSTEM_BLUE = (0, 122, 255, 255)
SYSTEM_BLUE_DARK = (0, 80, 180, 255)
SYSTEM_GREEN = (52, 199, 89, 255)
TEXT_PRIMARY = (28, 28, 30, 255)
TEXT_SECONDARY = (108, 108, 112, 255)
BORDER = (229, 229, 234, 255)


def lerp(a: int, b: int, t: float) -> int:
    return round(a + (b - a) * t)


def vertical_gradient(size: tuple[int, int], top: tuple[int, ...], bottom: tuple[int, ...]) -> Image.Image:
    width, height = size
    img = Image.new("RGBA", size)
    px = img.load()
    for y in range(height):
        t = y / max(1, height - 1)
        color = tuple(lerp(top[i], bottom[i], t) for i in range(4))
        for x in range(width):
            px[x, y] = color
    return img


def rounded_gradient(
    base: Image.Image,
    box: tuple[int, int, int, int],
    radius: int,
    top: tuple[int, ...],
    bottom: tuple[int, ...],
    outline: tuple[int, ...] | None = None,
    outline_width: int = 1,
) -> None:
    x0, y0, x1, y1 = box
    width = x1 - x0
    height = y1 - y0
    mask = Image.new("L", (width, height), 0)
    md = ImageDraw.Draw(mask)
    md.rounded_rectangle((0, 0, width - 1, height - 1), radius=radius, fill=255)
    grad = vertical_gradient((width, height), top, bottom)
    base.paste(grad, (x0, y0), mask)

    if outline:
        draw = ImageDraw.Draw(base)
        inset = outline_width // 2
        draw.rounded_rectangle(
            (x0 + inset, y0 + inset, x1 - inset - 1, y1 - inset - 1),
            radius=radius,
            outline=outline,
            width=outline_width,
        )


def shadow(
    base: Image.Image,
    box: tuple[int, int, int, int],
    radius: int,
    offset: tuple[int, int],
    blur: int,
    color: tuple[int, int, int, int],
) -> None:
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    ox, oy = offset
    shifted = (box[0] + ox, box[1] + oy, box[2] + ox, box[3] + oy)
    draw.rounded_rectangle(shifted, radius=radius, fill=color)
    layer = layer.filter(ImageFilter.GaussianBlur(blur))
    base.alpha_composite(layer)


def draw_soft_line(
    draw: ImageDraw.ImageDraw,
    start: tuple[int, int],
    end: tuple[int, int],
    width: int,
    fill: tuple[int, int, int, int],
) -> None:
    draw.line((*start, *end), fill=fill, width=width)
    r = width // 2
    draw.ellipse((start[0] - r, start[1] - r, start[0] + r, start[1] + r), fill=fill)
    draw.ellipse((end[0] - r, end[1] - r, end[0] + r, end[1] + r), fill=fill)


def draw_horizontal_arrow(
    layer: Image.Image,
    y: int,
    x0: int,
    x1: int,
    width: int,
    color: tuple[int, int, int, int],
    direction: str,
) -> None:
    draw = ImageDraw.Draw(layer)
    head = round(width * 1.28)
    half = round(width * 0.74)

    if direction == "right":
        line_start = (x0, y)
        line_end = (x1 - head, y)
        tip = (x1, y)
        tri = [(x1 - head, y - half), tip, (x1 - head, y + half)]
    else:
        line_start = (x1, y)
        line_end = (x0 + head, y)
        tip = (x0, y)
        tri = [(x0 + head, y - half), tip, (x0 + head, y + half)]

    draw_soft_line(draw, line_start, line_end, width, color)
    draw.polygon(tri, fill=color)


def render_app_icon(size: int) -> Image.Image:
    aa = 4
    w = size * aa
    s = w / 1024

    def p(value: float) -> int:
        return round(value * s)

    img = Image.new("RGBA", (w, w), (0, 0, 0, 0))

    tile = (p(84), p(68), p(940), p(948))
    shadow(img, tile, p(218), (0, p(30)), p(42), (17, 28, 52, 42))
    shadow(img, tile, p(218), (0, p(5)), p(10), (17, 28, 52, 18))
    rounded_gradient(
        img,
        tile,
        p(218),
        (255, 255, 255, 255),
        (242, 247, 255, 255),
        outline=(215, 226, 238, 255),
        outline_width=max(1, p(2)),
    )

    card = (p(208), p(214), p(816), p(810))
    shadow(img, card, p(78), (0, p(24)), p(34), (24, 38, 62, 32))
    rounded_gradient(
        img,
        card,
        p(78),
        (255, 255, 255, 255),
        (248, 251, 255, 255),
        outline=(222, 231, 242, 255),
        outline_width=max(1, p(2)),
    )

    draw = ImageDraw.Draw(img)
    title_bar = (card[0], card[1], card[2], p(315))
    draw.rounded_rectangle(title_bar, radius=p(78), fill=(239, 245, 252, 255))
    draw.rectangle((card[0], p(260), card[2], p(315)), fill=(239, 245, 252, 255))
    for idx, color in enumerate(((255, 95, 86, 255), (255, 189, 46, 255), (39, 201, 63, 255))):
        cx = p(280 + idx * 42)
        cy = p(266)
        r = p(10)
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=color)

    # Configuration rows: hosts/env entries rendered as compact data rails.
    rows = [
        (p(365), SYSTEM_BLUE, p(470), p(676)),
        (p(470), SYSTEM_GREEN, p(522), p(724)),
        (p(575), TEXT_SECONDARY, p(448), p(640)),
        (p(680), (175, 184, 194, 255), p(504), p(714)),
    ]
    for y, accent, x_mid, x_end in rows:
        r = p(12)
        draw.ellipse((p(278) - r, y - r, p(278) + r, y + r), fill=accent)
        draw.rounded_rectangle((p(322), y - p(12), x_mid, y + p(12)), radius=p(12), fill=(64, 78, 95, 210))
        draw.rounded_rectangle((x_mid + p(36), y - p(12), x_end, y + p(12)), radius=p(12), fill=(186, 196, 207, 230))
        draw.rounded_rectangle((p(714), y - p(14), p(748), y + p(14)), radius=p(14), fill=(224, 232, 241, 255))

    # White separator under the switch mark keeps the symbol crisp over rows.
    switch_back = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw_horizontal_arrow(switch_back, p(430), p(282), p(756), p(88), (255, 255, 255, 238), "right")
    draw_horizontal_arrow(switch_back, p(618), p(268), p(742), p(88), (255, 255, 255, 238), "left")
    img.alpha_composite(switch_back)

    switch = Image.new("RGBA", img.size, (0, 0, 0, 0))
    shadow(switch, (p(290), p(390), p(756), p(666)), p(60), (0, p(15)), p(22), (0, 75, 170, 42))
    draw_horizontal_arrow(switch, p(430), p(300), p(748), p(62), SYSTEM_BLUE, "right")
    draw_horizontal_arrow(switch, p(618), p(276), p(724), p(62), SYSTEM_GREEN, "left")
    img.alpha_composite(switch)

    # A small active-state node gives the icon a product-specific "applied
    # profile" cue without relying on text.
    node = Image.new("RGBA", img.size, (0, 0, 0, 0))
    nd = ImageDraw.Draw(node)
    cx, cy = p(760), p(686)
    shadow(node, (cx - p(58), cy - p(58), cx + p(58), cy + p(58)), p(58), (0, p(8)), p(12), (10, 80, 40, 35))
    nd.ellipse((cx - p(46), cy - p(46), cx + p(46), cy + p(46)), fill=(255, 255, 255, 255))
    nd.ellipse((cx - p(34), cy - p(34), cx + p(34), cy + p(34)), fill=SYSTEM_GREEN)
    nd.line((cx - p(16), cy, cx - p(4), cy + p(13), cx + p(19), cy - p(17)), fill=(255, 255, 255, 255), width=p(8), joint="curve")
    img.alpha_composite(node)

    return img.resize((size, size), Image.Resampling.LANCZOS)


def draw_tray_switch(size: int, colored: bool) -> Image.Image:
    aa = 4
    w = size * aa
    s = w / 32

    def p(value: float) -> int:
        return round(value * s)

    img = Image.new("RGBA", (w, w), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    if colored:
        top = SYSTEM_BLUE
        bottom = SYSTEM_GREEN
    else:
        top = bottom = (0, 0, 0, 235)

    stroke = max(2, p(3.0))
    head = max(3, p(4.8))
    half = max(2, p(3.8))

    def mini_arrow(y: int, x0: int, x1: int, color: tuple[int, int, int, int], direction: str) -> None:
        if direction == "right":
            draw.line((x0, y, x1 - head, y), fill=color, width=stroke)
            draw.polygon([(x1 - head, y - half), (x1, y), (x1 - head, y + half)], fill=color)
            draw.ellipse((x0 - stroke // 2, y - stroke // 2, x0 + stroke // 2, y + stroke // 2), fill=color)
        else:
            draw.line((x1, y, x0 + head, y), fill=color, width=stroke)
            draw.polygon([(x0 + head, y - half), (x0, y), (x0 + head, y + half)], fill=color)
            draw.ellipse((x1 - stroke // 2, y - stroke // 2, x1 + stroke // 2, y + stroke // 2), fill=color)

    mini_arrow(p(10), p(6), p(25), top, "right")
    mini_arrow(p(22), p(7), p(26), bottom, "left")

    # Tiny row ticks make the mark read as environment/config switching, not a
    # generic refresh symbol.
    tick_color = (0, 0, 0, 170) if not colored else (82, 92, 105, 220)
    draw.rounded_rectangle((p(7), p(15), p(14), p(17)), radius=p(1), fill=tick_color)
    draw.rounded_rectangle((p(18), p(15), p(25), p(17)), radius=p(1), fill=tick_color)

    return img.resize((size, size), Image.Resampling.LANCZOS)


def write_png(path: Path, image: Image.Image) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path)


def write_tray_preview(template: Image.Image, colored: Image.Image) -> None:
    preview = Image.new("RGBA", (220, 92), (0, 0, 0, 0))
    draw = ImageDraw.Draw(preview)
    draw.rounded_rectangle(
        (0, 0, 103, 91),
        radius=12,
        fill=(246, 247, 249, 255),
        outline=(210, 215, 222, 255),
    )
    draw.rounded_rectangle(
        (117, 0, 219, 91),
        radius=12,
        fill=(28, 28, 30, 255),
        outline=(64, 64, 68, 255),
    )

    colored_32 = colored.resize((32, 32), Image.Resampling.LANCZOS)
    white_template = Image.new("RGBA", template.size, (255, 255, 255, 0))
    white_template.putalpha(template.getchannel("A"))

    preview.alpha_composite(template, (20, 14))
    preview.alpha_composite(colored_32, (58, 14))
    preview.alpha_composite(white_template, (137, 14))
    preview.alpha_composite(colored_32, (175, 14))
    write_png(SOURCE_DIR / "tray_preview.png", preview)


def main() -> None:
    SOURCE_DIR.mkdir(parents=True, exist_ok=True)

    app_icons = {size: render_app_icon(size) for size in APP_ICON_SIZES}
    for size, image in app_icons.items():
        write_png(MAC_ICON_DIR / f"app_icon_{size}.png", image)
    write_png(SOURCE_DIR / "app_icon_1024.png", app_icons[1024])

    app_icons[256].save(
        WINDOWS_ICON,
        format="ICO",
        sizes=[(size, size) for size in WINDOWS_ICON_SIZES],
    )

    tray_template_16 = draw_tray_switch(16, colored=False)
    tray_template_32 = draw_tray_switch(32, colored=False)
    tray_color_256 = draw_tray_switch(256, colored=True)

    write_png(TRAY_DIR / "icon.png", tray_template_16)
    write_png(TRAY_DIR / "icon@2x.png", tray_template_32)
    write_png(SOURCE_DIR / "tray_template_32.png", tray_template_32)
    write_png(SOURCE_DIR / "tray_windows_256.png", tray_color_256)
    write_tray_preview(tray_template_32, tray_color_256)
    tray_color_256.save(
        TRAY_DIR / "icon.ico",
        format="ICO",
        sizes=[(16, 16), (32, 32), (48, 48), (256, 256)],
    )


if __name__ == "__main__":
    main()
