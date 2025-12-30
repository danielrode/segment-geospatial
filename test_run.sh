#!/usr/bin/env bash
# author: Daniel Rode


# Runs a test segmentation on a CHM tile


# Documentation
# https://samgeo.gishub.org/examples/sam2_text_prompts/
# https://samgeo.gishub.org/samgeo/


cd "$(dirname "$0")"
podman build -t samgeo .

# cp CHM_TIFF_SRC ./chm.tif

podman run --rm --interactive \
    --volume ./:/dropper:z \
    --entrypoint python3 \
    localhost/samgeo:latest \
<<EOF
from pathlib import Path
from samgeo import SamGeo
import rasterio
import numpy as np

chm_path = Path('/dropper/chm.tif')
rgb_chm_path = Path(chm_path.parent, chm_path.stem + '_rgb.tif')

if not Path(rgb_chm_path).exists():
    with rasterio.open(chm_path) as src:
        data = src.read(1)
        meta = src.meta.copy()

        # Replace NaNs with 0
        data = np.nan_to_num(data, nan=0.0)

        # Drop pixels below 1.37 m
        data[data < 1.37] = 0

        # Scale to 0-255 (Simple Min-Max scaling)
        data_scaled = (
            ((data - data.min()) / (data.max() - data.min()) * 255)
            .astype(np.uint8)
        )

        # Update metadata to 3-band RGB for SAM
        meta.update(dtype=rasterio.uint8, count=3, nodata=None)

        # Write converted raster to file
        with rasterio.open(rgb_chm_path, 'w', **meta) as dst:
            # Write the same scaled data to all three bands (Grayscale RGB)
            for i in range(1, 4):
                dst.write(data_scaled, i)

image = rgb_chm_path

sam = SamGeo(
    model_type="vit_h",
    checkpoint="sam_vit_h_4b8939.pth",
    sam_kwargs=None,
)

mask = Path(chm_path.parent, chm_path.stem + "_segment.tif")
sam.generate(
    str(image),
    str(mask),
    batch=True,
    foreground=True,
    # erosion_kernel=(3, 3),
    erosion_kernel=(5, 5),
    mask_multiplier=255,
    min_size=2,
    max_size=100,
)

vector = Path(chm_path.parent, chm_path.stem + "_segment.gpkg")
sam.tiff_to_gpkg(str(mask), str(vector), simplify_tolerance=None)
EOF
