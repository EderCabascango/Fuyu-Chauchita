"""Recorta el logo oficial de Chauchita en piezas con fondo transparente.

Uso: python tool/recortar_logo.py <logo.png>
Genera assets/marca/*.png y assets/icono/{icono,frente}.png (ícono de la app).
"""
import sys
from PIL import Image

FONDO_ICONO = (255, 255, 255, 255)


def sin_fondo(im: Image.Image) -> Image.Image:
    """Vuelve transparente solo el fondo claro conectado al borde (no el blanco
    de adentro del logo), con bordes suavizados."""
    from collections import deque

    im = im.convert("RGBA")
    px = im.load()
    w, h = im.size
    visto = bytearray(w * h)
    cola = deque((x, y) for x in range(w) for y in (0, h - 1))
    cola.extend((x, y) for y in range(h) for x in (0, w - 1))
    while cola:
        x, y = cola.popleft()
        i = y * w + x
        if visto[i]:
            continue
        visto[i] = 1
        r, g, b, _ = px[x, y]
        claridad = min(r, g, b)
        if claridad < 200:
            continue  # llegó al dibujo
        alfa = 0 if claridad >= 240 else int(255 * (240 - claridad) / 40)
        px[x, y] = (r, g, b, alfa)
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h and not visto[ny * w + nx]:
                cola.append((nx, ny))
    return im


def recorte(im: Image.Image, y0: int, y1: int) -> Image.Image:
    banda = im.crop((0, y0, im.width, y1))
    caja = banda.getchannel("A").point(lambda a: 255 if a > 60 else 0).getbbox()
    return banda.crop(caja)


def cuadrado(pieza: Image.Image, lado: int, ocupa: float, fondo=(0, 0, 0, 0)) -> Image.Image:
    lienzo = Image.new("RGBA", (lado, lado), fondo)
    escala = ocupa * lado / max(pieza.size)
    p = pieza.resize((round(pieza.width * escala), round(pieza.height * escala)), Image.LANCZOS)
    lienzo.alpha_composite(p, ((lado - p.width) // 2, (lado - p.height) // 2))
    return lienzo


def main(origen: str) -> None:
    im = sin_fondo(Image.open(origen))
    pin = recorte(im, 100, 465)
    nombre = recorte(im, 468, 580)
    fuyu = recorte(im, 660, 750)
    completo = recorte(im, 100, 580)

    pin.save("assets/marca/pin.png")
    nombre.save("assets/marca/chauchita.png")
    fuyu.save("assets/marca/fuyu.png")
    completo.save("assets/marca/logo.png")

    # Ícono de la app: pin sobre fondo blanco; el adaptable deja margen de seguridad.
    cuadrado(pin, 1024, 0.78, FONDO_ICONO).convert("RGB").save("assets/icono/icono.png")
    cuadrado(pin, 1024, 0.58).save("assets/icono/frente.png")


if __name__ == "__main__":
    main(sys.argv[1])
