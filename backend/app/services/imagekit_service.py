import base64
from imagekitio import ImageKit
from imagekitio.models.UploadFileRequestOptions import UploadFileRequestOptions
from datetime import datetime
import os
from dotenv import load_dotenv

load_dotenv()

# Inicialización del cliente
imagekit = ImageKit(
    private_key=os.getenv("IMAGEKIT_PRIVATE_KEY"),
    public_key=os.getenv("IMAGEKIT_PUBLIC_KEY"),
    url_endpoint=os.getenv("IMAGEKIT_URL_ENDPOINT")
)

def upload_image_to_imagekit(file_bytes: bytes, filename: str) -> str:
    try:
        encoded_string = base64.b64encode(file_bytes).decode("utf-8")

        ext = os.path.splitext(filename)[1].lower()
        mime = "image/jpeg"
        if ext == ".png":
            mime = "image/png"

        unique_filename = f"{datetime.utcnow().timestamp()}_{filename}"

        # Realizamos la subida
        upload = imagekit.upload_file(
            file=encoded_string,
            file_name=unique_filename,
            options=UploadFileRequestOptions(
                folder="/vitia",
                is_private_file=False, # Asegúrate de que sea pública
                use_unique_file_name=True,
                tags=["vitia-app"]
            )
        )

        print("IMAGEKIT RESPONSE:", upload)

        # --- CORRECCIÓN CRÍTICA AQUÍ ---
        # Accedemos a la propiedad .url directamente (es un objeto, no un diccionario)
        image_url = upload.url 
        # -------------------------------

        if not image_url:
            raise Exception("La respuesta de ImageKit no contiene URL")

        return image_url

    except Exception as e:
        print("EXCEPCIÓN EN IMAGEKIT:", str(e))
        raise