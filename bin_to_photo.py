import numpy as np
import matplotlib.pyplot as plt
from PIL import Image, ImageDraw
import os
import os

# Obtener la ruta de la carpeta donde está el script actual
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# Rutas relativas al proyecto
interpolado_path = os.path.join(BASE_DIR, "interpolado.bin")
cuadrante_path = os.path.join(BASE_DIR, "cuadrante.bin")
imagen_original_path = os.path.join(BASE_DIR, "imagen.png")


# Verificar existencia de archivos
if not all(map(os.path.exists, [interpolado_path, cuadrante_path, imagen_original_path])):
    print("Uno o más archivos no existen. Verifica las rutas.")
    exit(1)

# Cargar imagen interpolada desde .bin
data_interpolado = np.fromfile(interpolado_path, dtype=np.uint8)
if data_interpolado.size == 0:
    print("El archivo interpolado.bin está vacío.")
    exit(1)

size_interpolado = int(np.sqrt(data_interpolado.size))
image_interpolada = data_interpolado[:size_interpolado**2].reshape((size_interpolado, size_interpolado))

# Cargar imagen original
try:
    imagen_original = Image.open(imagen_original_path).convert("RGB")
except Exception as e:
    print(f"Error cargando la imagen original: {e}")
    exit(1)

original_np = np.array(imagen_original)

# Dimensiones
h, w, _ = original_np.shape

# Cargar el valor del cuadrante
cuadrante_data = np.fromfile(cuadrante_path, dtype=np.uint8)
if cuadrante_data.size == 0:
    print("El archivo cuadrante.bin está vacío. Se usará el valor 1 por defecto.")
    cuadrante_value = 1
else:
    cuadrante_value = int(cuadrante_data[0])
    if not (1 <= cuadrante_value <= 16):
        print(f"Valor de cuadrante inválido: {cuadrante_value}. Se usará el valor 1.")
        cuadrante_value = 1

cuadrante_16 = cuadrante_value

# Calcular coordenadas del cuadrante (4x4)
rows, cols = 4, 4
cell_w, cell_h = int(w // cols), int(h // rows)
row = int((cuadrante_16 - 1) // cols)
col = int((cuadrante_16 - 1) % cols)

x1 = int(col * cell_w)
y1 = int(row * cell_h)
x2 = int(x1 + cell_w)
y2 = int(y1 + cell_h)

# Dibujar rectángulo rojo sobre la imagen original
imagen_editable = Image.fromarray(original_np).convert("RGBA")
overlay = Image.new("RGBA", imagen_editable.size, (255, 0, 0, 0))
draw_overlay = ImageDraw.Draw(overlay)

try:
    draw_overlay.rectangle([x1, y1, x2, y2], outline="red", fill=(255, 0, 0, 60), width=4)
except Exception as e:
    print(f"Error al dibujar el rectángulo: {e}")
    exit(1)

imagen_final = Image.alpha_composite(imagen_editable, overlay).convert("RGB")

# Mostrar imágenes
fig, axs = plt.subplots(1, 2, figsize=(10, 5))
axs[0].imshow(imagen_final)
axs[0].set_title(f"Imagen original (Cuadrante 4x4: {cuadrante_16})")
axs[0].axis("off")
axs[1].imshow(image_interpolada, cmap='gray')
axs[1].set_title("Imagen interpolada")
axs[1].axis("off")
plt.tight_layout()
plt.show()
