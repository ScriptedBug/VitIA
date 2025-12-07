# backend/app/tests/test_identificacion.py
import pytest
import io
from PIL import Image
from fastapi.testclient import TestClient
from app.main import app

@pytest.fixture
def dummy_image_path(tmp_path):
    """
    Crea una imagen JPG real y válida de 100x100 píxeles (roja).
    """
    path = tmp_path / "test_image.jpg"
    img = Image.new('RGB', (100, 100), color = 'red')
    img.save(path, format='JPEG')
    return str(path)

def test_predict_image_ok(client, monkeypatch, dummy_image_path):
    """
    Caso de aceptación:
    Dada una imagen válida, se devuelve una predicción simulada.
    """
    
    # 1. Definimos el MOCK (Simulación)
    class FakeBox:
        def __init__(self):
            self.cls = 0
            self.conf = 0.85

    class FakeResult:
        def __init__(self):
            self.boxes = [FakeBox()]
            # Trucos para que parezca una lista iterable
            self.__len__ = lambda: 1
            self.__getitem__ = lambda s, i: FakeBox()

    class FakeModel:
        names = {0: "Tempranillo"}
        # Aceptamos cualquier argumento para que no falle
        def predict(self, source=None, save=False, verbose=False, **kwargs):
            return [FakeResult()]

    # --- AQUÍ ESTÁ EL CAMBIO CLAVE ---
    # En lugar de parchear 'app.ia.model_loader.model',
    # parcheamos 'app.routes.ml_routes.model' que es donde se ESTÁ USANDO.
    monkeypatch.setattr("app.routes.ml_routes.model", FakeModel())

    # 2. EJECUCIÓN
    with open(dummy_image_path, "rb") as f:
        response = client.post(
            "/ia/predict",
            files={"file": ("test_image.jpg", f, "image/jpeg")}
        )

    # 3. VERIFICACIÓN
    assert response.status_code == 200, f"Error: {response.text}"
    data = response.json()
    
    # Debug: Si falla, imprime qué devolvió para verlo en consola
    print(f"DEBUG DATA: {data}")
    
    assert "predicciones" in data
    assert len(data["predicciones"]) > 0
    assert data["predicciones"][0]["variedad"] == "Tempranillo"
    assert data["predicciones"][0]["confianza"] > 80