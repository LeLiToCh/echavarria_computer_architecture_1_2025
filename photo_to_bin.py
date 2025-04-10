import tkinter as tk
from tkinter import filedialog, ttk, messagebox
from PIL import Image, ImageTk
import os
import time
import sys
# Constantes
TARGET_SIZE = (500, 500)
BIN_IMAGE_SIZE = (70, 70)  # Este será el tamaño para guardar el .bin
NUM_QUADRANTS = 16
QUADRANT_ROWS = 4
QUADRANT_COLS = 4
PROJECT_DIR = "/home/emmanuel/Documents/isa/arm/proyecto_1_arqui_I"
ENCRYPTION_KEY = 0x5A  # Clave para XOR

# Guardar archivo .bin con encriptación
def save_quadrant_to_bin(image, quadrant_num, bin_path):
    img = image.resize(TARGET_SIZE).convert("L")  # Escala de grises
    quadrant_w = img.width // QUADRANT_COLS
    quadrant_h = img.height // QUADRANT_ROWS

    row = (quadrant_num - 1) // QUADRANT_COLS
    col = (quadrant_num - 1) % QUADRANT_COLS
    box = (
        col * quadrant_w,
        row * quadrant_h,
        (col + 1) * quadrant_w,
        (row + 1) * quadrant_h
    )
    
    # ⬇️ Aquí está la clave: redimensionar el cuadrante a 20x20 para obtener 400 bytes
    cropped = img.crop(box).resize(BIN_IMAGE_SIZE)
    pixel_data = cropped.tobytes()

    encrypted = bytes([b ^ ENCRYPTION_KEY for b in pixel_data])

    with open(bin_path, "wb") as f:
        f.write(bytes([quadrant_num]))  # Flag de cuadrante (sin encriptar)
        f.write(encrypted)              # 400 bytes encriptados

# Interfaz
class ImageQuadrantApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Selector de Cuadrante de Imagen")

        self.image = None
        self.image_label = tk.Label(root, text="No se ha cargado imagen")
        self.image_label.pack(pady=10)

        self.select_btn = tk.Button(root, text="Seleccionar Imagen", command=self.load_image)
        self.select_btn.pack(pady=5)

        self.quadrant_selector = ttk.Combobox(root, values=[str(i) for i in range(1, NUM_QUADRANTS + 1)])
        self.quadrant_selector.set("Seleccionar cuadrante")
        self.quadrant_selector.pack(pady=5)

        self.generate_btn = tk.Button(root, text="Seleccionar", command=self.generate_and_save)
        self.generate_btn.pack(pady=5)

    def load_image(self):
        path = filedialog.askopenfilename(filetypes=[("Imágenes", "*.png;*.jpg;*.jpeg")])
        if path:
            self.image = Image.open(path).resize(TARGET_SIZE)
            photo = ImageTk.PhotoImage(self.image)
            self.image_label.configure(image=photo)
            self.image_label.image = photo

            # Guardar imagen redimensionada
            resized_image_path = os.path.join(PROJECT_DIR, "imagen.png")
            self.image.save(resized_image_path)
            print(f"Imagen guardada en: {resized_image_path}")

    def generate_and_save(self):
        if not self.image:
            messagebox.showerror("Error", "Primero selecciona una imagen.")
            return
        try:
            quadrant = int(self.quadrant_selector.get())
            bin_filename = f"cuadrante.bin"
            bin_path = os.path.join(PROJECT_DIR, bin_filename)
            save_quadrant_to_bin(self.image, quadrant, bin_path)
            messagebox.showinfo("Éxito")
            
        except ValueError:
            messagebox.showerror("Error", "Selecciona un número de cuadrante válido.")

# Ejecutar
if __name__ == "__main__":
    root = tk.Tk()
    app = ImageQuadrantApp(root)
    root.mainloop()
