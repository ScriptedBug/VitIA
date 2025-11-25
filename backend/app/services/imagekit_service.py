# backend/app/services/imagekit_service.py
from imagekitio import ImageKit
from imagekitio.models.UploadFileRequestOptions import UploadFileRequestOptions
import os
from dotenv import load_dotenv

load_dotenv()

# Inicializa ImageKit con tus variables de entorno
imagekit = ImageKit(
    private_key=os.getenv('IMAGEKIT_PRIVATE_KEY'),
    public_key=os.getenv('IMAGEKIT_PUBLIC_KEY'),
    url_endpoint=os.getenv('IMAGEKIT_URL_ENDPOINT')
)

def upload_image_to_imagekit(file_bytes, file_name: str) -> str:
    """
    Sube una imagen (bytes) a ImageKit y devuelve la URL.
    """
    try:
        upload_response = imagekit.upload_file(
            file=file_bytes,
            file_name=file_name,
            options=UploadFileRequestOptions(
                folder="/coleccion_usuarios", # Puedes organizar carpetas
                is_private_file=False
            )
        )
        # Devolvemos la URL accesible
        return upload_response.url
    except Exception as e:
        print(f"Error subiendo a ImageKit: {e}")
        raise e