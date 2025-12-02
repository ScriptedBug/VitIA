import base64
from imagekitio import ImageKit
from imagekitio.models.UploadFileRequestOptions import UploadFileRequestOptions
from datetime import datetime
import os

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

        upload = imagekit.upload_file(
            file=encoded_string,
            file_name=unique_filename,
            options={
                "folder": "/vitia",
                "use_unique_file_name": True,
                "overwrite_file": False,
                "mime": mime
            }
        )

        print("IMAGEKIT RESPONSE:", upload)

        image_url = upload.get("url")
        if not image_url:
            raise Exception("Error subiendo imagen a ImageKit")

        return image_url

    except Exception as e:
        print("EXCEPCIÓN EN IMAGEKIT:", str(e))
        raise


