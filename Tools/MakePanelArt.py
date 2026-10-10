"""Draws the AHOS options window art into media/panel/ (run from the addon folder).

    python Tools/MakePanelArt.py

The window's look is a keyboard: surfaces are keycaps, with a face and a darker lip
under it, the way the AHOS logo is drawn. Every file is white on transparent and is
tinted in game from the palette in options/Look.lua, so one set of shapes serves
every theme. Shapes are drawn at 4x and scaled down for smooth edges. The rounded
shapes are made for Texture:SetTextureSliceMargins: corners keep their shape at any
size and the middle stretches. Requires Pillow.
"""
import os

from PIL import Image, ImageDraw, ImageFilter

OUT = os.path.join("media", "panel")
SS = 4  # supersampling
RADII = (3, 4, 6, 8, 10)


def canvas(w, h):
    return Image.new("L", (w * SS, h * SS), 0)


def save(mask, name, w, h):
    mask = mask.resize((w, h), Image.LANCZOS)
    img = Image.new("RGBA", (w, h), (255, 255, 255, 0))
    img.putalpha(mask)
    img.save(os.path.join(OUT, name + ".tga"))


def rounded(size, radius, inset=(0.0, 0.0, 0.0, 0.0)):
    left, top, right, bottom = inset
    m = canvas(size, size)
    ImageDraw.Draw(m).rounded_rectangle(
        [left * SS, top * SS, size * SS - 1 - right * SS, size * SS - 1 - bottom * SS],
        radius=radius * SS, fill=255)
    return m


def cut(outer, inner):
    return Image.composite(Image.new("L", outer.size, 0), outer, inner)


def circle(size, inset=0.0):
    m = canvas(size, size)
    i = inset * SS
    ImageDraw.Draw(m).ellipse([i, i, size * SS - 1 - i, size * SS - 1 - i], fill=255)
    return m


def glyph(name, draw, size=32):
    m = canvas(size, size)
    draw(ImageDraw.Draw(m), SS)
    save(m, "glyph-" + name, size, size)


def line(d, s, pts, w):
    d.line([(x * s, y * s) for x, y in pts], fill=255, width=int(w * s), joint="curve")
    for x, y in (pts[0], pts[-1]):
        r = w * s / 2
        d.ellipse([x * s - r, y * s - r, x * s + r, y * s + r], fill=255)


def box(d, s, x0, y0, x1, y1, r, w=None):
    if w:
        d.rounded_rectangle([x0 * s, y0 * s, x1 * s, y1 * s], radius=r * s, outline=255, width=int(w * s))
    else:
        d.rounded_rectangle([x0 * s, y0 * s, x1 * s, y1 * s], radius=r * s, fill=255)


def main():
    os.makedirs(OUT, exist_ok=True)

    # Surfaces, 64x64; slice margin = radius + 2.
    #   round<r>-fill   the whole shape
    #   round<r>-edge   a 1.25px outline; -edge2 a 2px one
    #   round<r>-face   the keycap's face: the shape lifted 3px off its bottom edge,
    #                   drawn over -fill so the strip left below it reads as the lip
    for r in RADII:
        fill = rounded(64, r)
        save(fill, "round%d-fill" % r, 64, 64)
        save(cut(fill, rounded(64, max(0, r - 1.25), (1.25,) * 4)), "round%d-edge" % r, 64, 64)
        save(cut(fill, rounded(64, max(0, r - 2), (2.0,) * 4)), "round%d-edge2" % r, 64, 64)
        save(rounded(64, r, (0, 0, 0, 3)), "round%d-face" % r, 64, 64)

    save(circle(64), "circle-fill", 64, 64)
    save(cut(circle(64), circle(64, 2.0)), "circle-ring", 64, 64)

    # A soft shadow under the window; slice margin 40
    m = canvas(128, 128)
    ImageDraw.Draw(m).rounded_rectangle([28 * SS, 30 * SS, 100 * SS, 102 * SS], radius=10 * SS, fill=160)
    save(m.filter(ImageFilter.GaussianBlur(10 * SS)), "shadow", 128, 128)

    # A vertical glow for the selected page: bright at the top, fading out
    m = Image.new("L", (8 * SS, 64 * SS), 0)
    d = ImageDraw.Draw(m)
    for y in range(64 * SS):
        d.line([(0, y), (8 * SS, y)], fill=int(255 * (1 - y / (64 * SS)) ** 1.6))
    save(m, "fade-v", 8, 64)

    # Control glyphs, 32x32
    glyph("cross", lambda d, s: (line(d, s, [(10, 10), (22, 22)], 2.6), line(d, s, [(22, 10), (10, 22)], 2.6)))
    glyph("check", lambda d, s: line(d, s, [(8, 16.5), (13.5, 22), (24, 10.5)], 2.8))
    glyph("chevron", lambda d, s: line(d, s, [(10, 13), (16, 19), (22, 13)], 2.6))
    glyph("plus", lambda d, s: (line(d, s, [(16, 9), (16, 23)], 2.6), line(d, s, [(9, 16), (23, 16)], 2.6)))
    glyph("search", lambda d, s: (d.ellipse([7 * s, 7 * s, 20 * s, 20 * s], outline=255, width=int(2.4 * s)),
                                  line(d, s, [(19, 19), (24.5, 24.5)], 2.8)))

    def grip(d, s):
        # three steps of a key's corner, for the resize handle
        for i, (x, y) in enumerate(((24, 12), (24, 18), (18, 18), (24, 24), (18, 24), (12, 24))):
            d.rounded_rectangle([(x - 2) * s, (y - 2) * s, (x + 2) * s, (y + 2) * s], radius=1 * s, fill=255)
    glyph("grip", grip)

    def undo(d, s):
        d.arc([8 * s, 9 * s, 24 * s, 25 * s], start=200, end=90, fill=255, width=int(2.6 * s))
        d.polygon([(5 * s, 13 * s), (12.5 * s, 8.5 * s), (12.5 * s, 17.5 * s)], fill=255)
    glyph("undo", undo)

    # The "changed from default" mark: a tiny keycap seen from above
    def changed(d, s):
        box(d, s, 6, 6, 26, 26, 5)
    glyph("changed", changed)

    # Page icons, 32x32, a line drawing on an implied key
    def overview(d, s):  # a gauge
        d.arc([5 * s, 7 * s, 27 * s, 29 * s], start=180, end=360, fill=255, width=int(2.4 * s))
        line(d, s, [(16, 18), (22, 11)], 2.4)
        d.ellipse([13.5 * s, 15.5 * s, 18.5 * s, 20.5 * s], fill=255)
    glyph("page-overview", overview)

    def display(d, s):  # a key with text in its corner
        box(d, s, 5, 5, 27, 27, 5, 2.2)
        box(d, s, 15, 9, 23, 13, 1)
    glyph("page-display", display)

    def keybinds(d, s):  # a key
        d.ellipse([4 * s, 9 * s, 16 * s, 21 * s], outline=255, width=int(2.4 * s))
        line(d, s, [(16, 15), (28, 15)], 2.4)
        line(d, s, [(23, 15), (23, 20)], 2.4)
        line(d, s, [(27, 15), (27, 19)], 2.4)
    glyph("page-keybinds", keybinds)

    def abbreviations(d, s):  # a long label shortened: a wide bar becoming a short one
        box(d, s, 4, 8, 28, 14, 2)
        line(d, s, [(9, 19), (9, 25)], 2)
        box(d, s, 13, 19, 23, 25, 2)
    glyph("page-abbreviations", abbreviations)

    def profiles(d, s):  # stacked keys
        box(d, s, 9, 4, 27, 20, 4, 2.2)
        box(d, s, 5, 11, 23, 27, 4)
    glyph("page-profiles", profiles)

    def compatibility(d, s):  # two keys side by side, linked
        box(d, s, 3, 9, 14, 23, 3, 2.2)
        box(d, s, 18, 9, 29, 23, 3, 2.2)
        line(d, s, [(14, 16), (18, 16)], 2.2)
    glyph("page-compatibility", compatibility)

    def debug(d, s):  # a magnifier over a key corner
        box(d, s, 4, 4, 20, 20, 3, 2.2)
        d.ellipse([13 * s, 13 * s, 25 * s, 25 * s], outline=255, width=int(2.4 * s))
        line(d, s, [(24, 24), (28, 28)], 2.6)
    glyph("page-debug", debug)

    def about(d, s):  # an i on a key
        box(d, s, 5, 5, 27, 27, 5, 2.2)
        d.ellipse([14.3 * s, 9 * s, 17.7 * s, 12.4 * s], fill=255)
        line(d, s, [(16, 15.5), (16, 22.5)], 2.6)
    glyph("page-about", about)

    def window(d, s):  # sliders
        for x, knob in ((9, 12), (16, 20), (23, 14)):
            line(d, s, [(x, 6), (x, 26)], 1.6)
            d.ellipse([(x - 3) * s, (knob - 3) * s, (x + 3) * s, (knob + 3) * s], fill=255)
    glyph("page-window", window)

    print("wrote", len(os.listdir(OUT)), "files to", OUT)


if __name__ == "__main__":
    main()
