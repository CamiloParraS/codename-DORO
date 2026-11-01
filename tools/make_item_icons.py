"""Draws the pixel icons from their grids: the Scanner's (assets/ui/icons/scanner.svg) and the two things a questioned
guard drops (assets/items/letter.svg, doc.png). Run: python tools/make_item_icons.py"""
import math
from PIL import Image

W, H = 30, 41


def scanner_cells() -> set:
    on = set()

    def rect(c0, c1, r0, r1):
        on.update((c, r) for c in range(c0, c1 + 1) for r in range(r0, r1 + 1))
    rect(14, 14, 3, 8)                                   # antenna
    rect(3, 11, 9, 9); rect(13, 15, 9, 9); on.discard((4, 9))
    rect(3, 15, 10, 10); rect(3, 15, 11, 11)
    rect(3, 10, 12, 14); rect(14, 14, 12, 12)
    cx, cy, r = 9, 20, 5.3                               # the eye: a blue disk in a white ring
    for rr in range(15, 27):
        for c in range(3, 16):
            if math.hypot(c - cx, rr - cy) > r and (c <= 5 or c >= 13 or rr >= 25 or rr <= 15 or c <= 7):
                if c <= 4 or (c >= 13 and 16 <= rr <= 23) or rr >= 25 or (rr <= 15 and c <= 7) or (rr <= 16 and c >= 11 and c <= 12):
                    on.add((c, rr))
    rect(3, 3, 15, 25)
    on -= {(c, rr) for c in range(W) for rr in range(15, 26) if math.hypot(c - cx, rr - cy) <= r}
    on |= {(9, 19), (8, 20), (10, 20), (9, 21)}          # crosshair
    rect(11, 12, 15, 15); rect(13, 13, 16, 16)
    rect(15, 23, 18, 18); rect(15, 22, 19, 19); rect(15, 18, 20, 20)    # the beam
    rect(26, 26, 18, 18); rect(25, 26, 19, 19); rect(24, 26, 20, 20)
    rect(14, 15, 21, 23); rect(16, 16, 23, 23); rect(13, 13, 26, 26)
    rect(3, 11, 25, 27); rect(3, 5, 27, 29); on.discard((4, 28))
    rect(7, 10, 28, 29); rect(8, 10, 30, 31); rect(9, 10, 32, 32)
    rect(8, 9, 33, 36); rect(10, 10, 35, 35)
    rect(9, 10, 37, 38); rect(8, 10, 39, 40)
    return on


def write_scanner_svg(path: str) -> None:
    k = 1.75  # drawn at 52.5 x 71.75, the height the old 80 x 72 icon had
    d = ""
    for r in range(H):
        run = None
        for c in range(W + 1):
            if (c, r) in scanner_cells() if c < W else False:
                run = (c, 1) if run is None else (run[0], run[1] + 1)
            elif run:
                d += f"M{run[0]} {r}h{run[1]}v1h-{run[1]}z"
                run = None
    with open(path, "w") as f:
        f.write(f'<svg xmlns="http://www.w3.org/2000/svg" width="{W * k}" height="{H * k}" viewBox="0 0 {W} {H}" shape-rendering="crispEdges"><path fill="#fff" d="{d}"/></svg>')


INK = (96, 96, 96, 255)
WHITE = (255, 255, 255, 255)
EDGE = (12, 12, 12, 255)


def write_svg(im: Image.Image, path: str) -> None:
    """The sprite as crisp one-pixel rects, a run of one colour per rect."""
    rects = ""
    for y in range(im.height):
        x = 0
        while x < im.width:
            px = im.getpixel((x, y))
            if px[3] == 0:
                x += 1
                continue
            x2 = x
            while x2 + 1 < im.width and im.getpixel((x2 + 1, y)) == px:
                x2 += 1
            rects += f'<rect x="{x}" y="{y}" width="{x2 - x + 1}" height="1" fill="#{px[0]:02x}{px[1]:02x}{px[2]:02x}"/>'
            x = x2 + 1
    with open(path, "w") as f:
        f.write(f'<svg xmlns="http://www.w3.org/2000/svg" width="{im.width}" height="{im.height}" viewBox="0 0 {im.width} {im.height}" shape-rendering="crispEdges">{rects}</svg>')


def outline(im: Image.Image) -> Image.Image:
    out = Image.new("RGBA", (im.width + 2, im.height + 2), (0, 0, 0, 0))
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            if px[x, y][3]:
                for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                    if out.getpixel((x + 1 + dx, y + 1 + dy))[3] == 0:
                        out.putpixel((x + 1 + dx, y + 1 + dy), EDGE)
    for y in range(im.height):
        for x in range(im.width):
            if px[x, y][3]:
                out.putpixel((x + 1, y + 1), px[x, y])
    return out


def letter(path: str) -> None:
    im = Image.new("RGBA", (12, 15), (0, 0, 0, 0))
    for y in range(15):
        for x in range(12):
            if not ((x + y) % 7 == 0 and y in (0, 14)):   # a chipped, crumpled edge
                im.putpixel((x, y), WHITE)
    for y in (3, 6, 9, 12):                                # lines of writing, in dashes
        for x in range(2, 10):
            if (x + y) % 4 != 0:
                im.putpixel((x, y), INK)
    im = im.rotate(-12, resample=Image.NEAREST, expand=True)
    write_svg(outline(im), path)


def doc(path: str) -> None:
    im = Image.new("RGBA", (12, 17), (0, 0, 0, 0))
    for x in range(0, 12, 2):                              # the dotted top edge: sheets sticking out
        im.putpixel((x, 0), WHITE)
    for y in range(1, 17):
        for x in range(12):
            im.putpixel((x, y), WHITE)
    for x in (2, 5, 8):                                    # slots down the cover
        for y in range(5, 15):
            im.putpixel((x, y), INK)
    for x in range(1, 11):
        im.putpixel((x, 3), INK if x % 2 else WHITE)       # the stamp
    im = im.rotate(8, resample=Image.NEAREST, expand=True)
    write_svg(outline(im), path)


write_scanner_svg("assets/ui/icons/scanner.svg")
letter("assets/items/letter.svg")
doc("assets/items/doc.svg")
