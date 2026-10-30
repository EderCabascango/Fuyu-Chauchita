"""Genera el ícono de la app: casa blanca con una llave de herramientas, fondo morado."""
import sys
from PIL import Image, ImageDraw

VERDE = (106, 63, 216, 255)  # morado de la app
BLANCO = (255, 255, 255, 255)
S = 1024


def glifo(escala: float) -> Image.Image:
    """Casa + llave centradas, ocupando `escala` del lienzo."""
    capa = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(capa)
    c = S / 2
    w = S * escala  # ancho total de la casa

    # Casa: techo triangular + cuerpo
    techo_alto = w * 0.42
    cuerpo_alto = w * 0.50
    top = c - (techo_alto + cuerpo_alto) / 2
    d.polygon([(c, top), (c + w / 2, top + techo_alto), (c - w / 2, top + techo_alto)], fill=BLANCO)
    cx0, cx1 = c - w * 0.38, c + w * 0.38
    d.rounded_rectangle([cx0, top + techo_alto - 2, cx1, top + techo_alto + cuerpo_alto],
                        radius=w * 0.05, fill=BLANCO)

    # Llave (en verde, recortada sobre la casa), dibujada horizontal y luego rotada
    llave = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    k = ImageDraw.Draw(llave)
    L = w * 0.62           # largo total
    g = w * 0.075          # grosor del mango
    r = w * 0.13           # radio de la cabeza
    y = c
    x0 = c - L / 2
    k.rounded_rectangle([x0 + r, y - g, c + L / 2, y + g], radius=g, fill=VERDE)
    k.ellipse([x0, y - r, x0 + 2 * r, y + r], fill=VERDE)
    # boca de la llave
    k.rectangle([x0 - 1, y - r * 0.38, x0 + r * 0.9, y + r * 0.38], fill=(0, 0, 0, 0))
    llave = llave.rotate(45, resample=Image.BICUBIC, center=(c, c))
    desplazada = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    desplazada.paste(llave, (0, int(w * 0.12)), llave)

    capa.alpha_composite(desplazada)
    return capa


def main(destino: str) -> None:
    completo = Image.new("RGBA", (S, S), VERDE)
    completo.alpha_composite(glifo(0.62))
    completo.convert("RGB").save(f"{destino}/icono.png")

    # Primer plano del ícono adaptable de Android: dentro de la zona segura (~66 %)
    glifo(0.46).save(f"{destino}/frente.png")


if __name__ == "__main__":
    main(sys.argv[1])
