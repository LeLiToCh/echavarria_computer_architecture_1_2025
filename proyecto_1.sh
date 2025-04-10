#!/bin/bash

echo "Ejecutando photo_to_bin.py..."
python3 photo_to_bin.py

echo "Compilando y ejecutando interpolacion.s (ARM)..."
arm-linux-gnueabi-as interpolacion.s -o interpolacion.o
arm-linux-gnueabi-ld interpolacion.o -o interpolacion
./interpolacion                                # Ejecuta el binario ARM

echo "Ejecutando bin_to_photo.py..."
python3 bin_to_photo.py

echo "Todo ejecutado correctamente."
