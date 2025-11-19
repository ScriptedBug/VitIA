from fastapi import APIRouter, UploadFile, File, HTTPException
from ..ia.model_loader import model
import io
from PIL import Image
from typing import List

router = APIRouter(prefix="/ia", tags=["ia"])

@router.post("/predict")
async def predict_image(file: UploadFile = File(...)):
    # Validación básica
    if file.content_type.split("/")[0] != "image":
        raise HTTPException(status_code=400, detail="File must be an image.")

    # Leer bytes (no guardamos si no es necesario)
    image_bytes = await file.read()
    try:
        image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Invalid image: {e}")

    # Run inference
    results = model.predict(image, save=False, verbose=False)  # list-like

    # Collect confidences per class
    class_confidences = {}
    for r in results:
        for box in r.boxes:
            cls_id = int(box.cls)
            conf = float(box.conf)
            cls_name = model.names[cls_id]
            class_confidences.setdefault(cls_name, []).append(conf)

    # compute average/confidence per class (in percentage)
    averaged = [{ "variedad": cls, "confianza": round((sum(confs)/len(confs))*100, 2)}
                for cls, confs in class_confidences.items()]

    # If you want include all classes with 0.0 for missing:
    '''for idx, name in model.names.items():
        if name not in [d["variedad"] for d in averaged]:
            averaged.append({"variedad": name, "confianza": 0.0})'''

    # sort by confianza desc
    averaged.sort(key=lambda x: x["confianza"], reverse=True)

    return {"predicciones": averaged}
