import tkinter as tk
from tkinter import filedialog, ttk, messagebox
from PIL import Image, ImageTk
import os
import time
import sys

#Constantes
TARGET_SIZE = (500, 500)  # Todas las imágenes se redimensionan a este tamaño para estandarizar
BIN_IMAGE_SIZE = (70, 70)  # Cada cuadrante se reduce a este tamaño antes de guardar
NUM_QUADRANTS = 16  # Se divide la imagen en 4x4 = 16 cuadrantes
QUADRANT_ROWS = 4 #Filas
QUADRANT_COLS = 4 #Columnas
PROJECT_DIR = os.path.dirname(os.path.abspath(__file__))  # Directorio donde está el script .py
ENCRYPTION_KEY = 0x5A  # Clave XOR usada para cifrar el contenido del archivo binario

def save_quadrant_to_bin(image, quadrant_num, bin_path):
    img = image.resize(TARGET_SIZE).convert("L")  # Convierte a blanco y negro y redimensiona a 500x500

    # Se calcula el ancho y alto de cada cuadrante
    quadrant_w = img.width // QUADRANT_COLS
    quadrant_h = img.height // QUADRANT_ROWS

    # A partir del número de cuadrante (1 a 16), se calcula su posición fila/columna
    row = (quadrant_num - 1) // QUADRANT_COLS
    col = (quadrant_num - 1) % QUADRANT_COLS

    # Coordenadas del área del cuadrante dentro de la imagen redimensionada
    box = (
        col * quadrant_w,
        row * quadrant_h,
        (col + 1) * quadrant_w,
        (row + 1) * quadrant_h
    )

    cropped = img.crop(box).resize(BIN_IMAGE_SIZE)  # Se extrae y redimensiona a 70x70
    pixel_data = cropped.tobytes()  # Se convierte en arreglo de bytes (4900 bytes)

    # Se cifra el contenido aplicando XOR a cada byte
    encrypted = bytes([b ^ ENCRYPTION_KEY for b in pixel_data])

    # Se escribe el binario: primero el número de cuadrante sin cifrar, luego los 4900 bytes cifrados
    with open(bin_path, "wb") as f:
        f.write(bytes([quadrant_num]))
        f.write(encrypted)

class ImageQuadrantApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Selector de Cuadrante de Imagen")

        self.image = None  # Imagen cargada por el usuario

        # Etiqueta inicial (antes de cargar imagen)
        self.image_label = tk.Label(root, text="No se ha cargado imagen")
        self.image_label.pack(pady=10)

        # Botón para abrir el explorador de archivos y seleccionar una imagen
        self.select_btn = tk.Button(root, text="Seleccionar Imagen", command=self.load_image)
        self.select_btn.pack(pady=5)

        # Menú desplegable para elegir un cuadrante del 1 al 16
        self.quadrant_selector = ttk.Combobox(root, values=[str(i) for i in range(1, NUM_QUADRANTS + 1)])
        self.quadrant_selector.set("Seleccionar cuadrante")
        self.quadrant_selector.pack(pady=5)

        # Botón para ejecutar el guardado del cuadrante seleccionado
        self.generate_btn = tk.Button(root, text="Seleccionar", command=self.generate_and_save)
        self.generate_btn.pack(pady=5)

    def load_image(self):
        # Abre el diálogo para seleccionar una imagen
        path = filedialog.askopenfilename(filetypes=[("Imágenes", "*.png;*.jpg;*.jpeg")])
        if path:
            self.image = Image.open(path).resize(TARGET_SIZE)  # Carga y redimensiona

            # Prepara la imagen para mostrarla en Tkinter
            photo = ImageTk.PhotoImage(self.image)
            self.image_label.configure(image=photo)
            self.image_label.image = photo  # Guarda la referencia para que no se borre

            # También guarda la imagen redimensionada como "imagen.png" en el directorio del proyecto
            resized_image_path = os.path.join(PROJECT_DIR, "imagen.png")
            self.image.save(resized_image_path)
            print(f"Imagen guardada en: {resized_image_path}")

    def generate_and_save(self):
        if not self.image:
            messagebox.showerror("Error", "Primero selecciona una imagen.")
            return
        try:
            # Convierte la selección del usuario en número entero
            quadrant = int(self.quadrant_selector.get())
            bin_filename = "cuadrante.bin"
            bin_path = os.path.join(PROJECT_DIR, bin_filename)

            # Llama a la función para crear y guardar el binario
            save_quadrant_to_bin(self.image, quadrant, bin_path)
            messagebox.showinfo("Éxito")  # Aviso de éxito
            time.sleep(2)
            sys.exit()  # Cierra el programa tras guardar

        except ValueError:
            messagebox.showerror("Error", "Selecciona un número de cuadrante válido.")

#Generacion interfaz 
if __name__ == "__main__":
    root = tk.Tk()
    app = ImageQuadrantApp(root)
    root.mainloop()
