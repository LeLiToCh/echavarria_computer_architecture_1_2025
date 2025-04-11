import numpy as np
import matplotlib.pyplot as plt
from PIL import Image, ImageDraw
import os

# Ruta base del proyecto (misma carpeta donde está este script)
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# Archivos necesarios
interpolado_path = os.path.join(BASE_DIR, "interpolado.bin")
cuadrante_path = os.path.join(BASE_DIR, "cuadrante.bin")
imagen_original_path = os.path.join(BASE_DIR, "imagen.png")

# Verifica que todos los archivos requeridos existan
if not all(map(os.path.exists, [interpolado_path, cuadrante_path, imagen_original_path])):
    print("Uno o más archivos no existen. Verifica las rutas.")
    exit(1)

# Carga del archivo .bin que contiene la imagen interpolada (escala de grises)
data_interpolado = np.fromfile(interpolado_path, dtype=np.uint8)
if data_interpolado.size == 0:
    print("El archivo interpolado.bin está vacío.")
    exit(1)

# Se asume que la imagen es cuadrada, se calcula el tamaño
size_interpolado = int(np.sqrt(data_interpolado.size))
image_interpolada = data_interpolado[:size_interpolado**2].reshape((size_interpolado, size_interpolado))

# Carga de la imagen original en formato RGB
try:
    imagen_original = Image.open(imagen_original_path).convert("RGB")
except Exception as e:
    print(f"Error cargando la imagen original: {e}")
    exit(1)

original_np = np.array(imagen_original)  # Se convierte a arreglo NumPy para obtener dimensiones
h, w, _ = original_np.shape  # Alto, ancho y canales

# Carga del número de cuadrante desde el archivo binario
cuadrante_data = np.fromfile(cuadrante_path, dtype=np.uint8)
if cuadrante_data.size == 0:
    print("El archivo cuadrante.bin está vacío. Se usará el valor 1 por defecto.")
    cuadrante_value = 1
else:
    cuadrante_value = int(cuadrante_data[0])
    if not (1 <= cuadrante_value <= 16):
        print(f"Valor de cuadrante inválido: {cuadrante_value}. Se usará el valor 1.")
        cuadrante_value = 1

cuadrante_16 = cuadrante_value  # Valor final del cuadrante a usar

# Cálculo de coordenadas del cuadrante dentro de la imagen original (4x4)
rows, cols = 4, 4
cell_w, cell_h = int(w // cols), int(h // rows)
row = int((cuadrante_16 - 1) // cols)
col = int((cuadrante_16 - 1) % cols)

# Coordenadas del rectángulo del cuadrante
x1 = int(col * cell_w)
y1 = int(row * cell_h)
x2 = int(x1 + cell_w)
y2 = int(y1 + cell_h)

# Se convierte la imagen original en editable y se crea una capa de transparencia
imagen_editable = Image.fromarray(original_np).convert("RGBA")
overlay = Image.new("RGBA", imagen_editable.size, (255, 0, 0, 0))
draw_overlay = ImageDraw.Draw(overlay)

# Se dibuja un rectángulo rojo semitransparente sobre el cuadrante
try:
    draw_overlay.rectangle([x1, y1, x2, y2], outline="red", fill=(255, 0, 0, 60), width=4)
except Exception as e:
    print(f"Error al dibujar el rectángulo: {e}")
    exit(1)

# Se combina la imagen original con la superposición
imagen_final = Image.alpha_composite(imagen_editable, overlay).convert("RGB")

# Visualización: imagen original con cuadrante marcado + imagen interpolada en escala de grises
fig, axs = plt.subplots(1, 2, figsize=(10, 5))
axs[0].imshow(imagen_final)
axs[0].set_title(f"Imagen original (Cuadrante 4x4: {cuadrante_16})")
axs[0].axis("off")

axs[1].imshow(image_interpolada, cmap='gray')
axs[1].set_title("Imagen interpolada")
axs[1].axis("off")

plt.tight_layout()
plt.show()
