"""Draws the mouse icons hotkey text can show into media/glyphs/ (run from the addon folder).

    python Tools/MakeGlyphs.py

Every icon is white on transparent, 64x64, and is tinted to the text's colour by
the texture markup (Keybinds:GetMouseIcon), so one set serves every colour. The
button that is pressed is filled; the rest of the mouse is an outline. Shapes are
drawn at 4x and scaled down for smooth edges. Requires Pillow.
"""
import os

from PIL import Image, ImageDraw

OUT = os.path.join("media", "glyphs")
SIZE = 64
SS = 4
W = 5  # outline width at 64 px


def s(v):
    return int(round(v * SS))


def body(d):
    # the mouse: a rounded body, the split between the buttons, and the wheel slot
    d.rounded_rectangle([s(14), s(4), s(50), s(60)], radius=s(17), outline=255, width=s(W))
    d.line([s(32), s(5), s(32), s(26)], fill=255, width=s(W * 0.8))
    d.line([s(15), s(27), s(49), s(27)], fill=255, width=s(W * 0.8))


def fill_button(d, side):
    # the top half of the body on one side, inside the outline
    x0, x1 = (s(17), s(30)) if side == "left" else (s(34), s(47))
    mask = Image.new("L", (SIZE * SS, SIZE * SS), 0)
    m = ImageDraw.Draw(mask)
    m.rounded_rectangle([s(17), s(7), s(47), s(58)], radius=s(14), fill=255)
    clip = Image.new("L", (SIZE * SS, SIZE * SS), 0)
    ImageDraw.Draw(clip).rectangle([x0, s(7), x1, s(25)], fill=255)
    return mask, clip


def make(name, extra):
    img = Image.new("L", (SIZE * SS, SIZE * SS), 0)
    d = ImageDraw.Draw(img)
    body(d)
    extra(img, d)
    img = img.resize((SIZE, SIZE), Image.LANCZOS)
    out = Image.new("RGBA", (SIZE, SIZE), (255, 255, 255, 0))
    out.putalpha(img)
    out.save(os.path.join(OUT, name + ".tga"))


def pressed(side):
    def draw(img, d):
        mask, clip = fill_button(d, side)
        from PIL import ImageChops
        img.paste(255, (0, 0), ImageChops.multiply(mask, clip))
    return draw


def middle(img, d):
    d.rounded_rectangle([s(28), s(10), s(36), s(24)], radius=s(4), fill=255)


def side(img, d):
    # two side buttons on the left flank
    d.rounded_rectangle([s(6), s(30), s(12), s(38)], radius=s(2), fill=255)
    d.rounded_rectangle([s(6), s(41), s(12), s(49)], radius=s(2), fill=255)


def wheel(up):
    def draw(img, d):
        d.rounded_rectangle([s(29), s(11), s(35), s(23)], radius=s(3), fill=255)
        if up:
            d.polygon([(s(32), s(33)), (s(23), s(46)), (s(41), s(46))], fill=255)
        else:
            d.polygon([(s(32), s(50)), (s(23), s(37)), (s(41), s(37))], fill=255)
    return draw


def main():
    os.makedirs(OUT, exist_ok=True)
    make("mouse-left", pressed("left"))
    make("mouse-right", pressed("right"))
    make("mouse-middle", middle)
    make("mouse-side", side)
    make("mouse-wheelup", wheel(True))
    make("mouse-wheeldown", wheel(False))
    print("wrote 6 glyphs to", OUT)


if __name__ == "__main__":
    main()
