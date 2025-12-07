from fastapi.testclient import TestClient 
from app.main import app
import os

client = TestClient(app)

def test_predict_image_ok(monkeypatch):
    """
    Caso de aceptación:
    Dada una imagen válida,
    cuando se envía al endpoint /ia/predict,
    entonces se devuelve una lista de predicciones
    con variedad y confianza.
    """

    # MOCK del modelo YOLO
    class FakeBox:
        def __init__(self):
            self.cls = 0
            self.conf = 0.85

    class FakeResult:
        def __init__(self):
            self.boxes = [FakeBox()]

    class FakeModel:
        names = {0: "Tempranillo"}

        def predict(self, image, save=False, verbose=False):
            print("➡️  MODELO FAKE: procesando imagen...")  # 👈 MOSTRAR EN TERMINAL
            return [FakeResult()]

    # PATCH al modelo real
    monkeypatch.setattr(
        "app.ia.model_loader.model",
        FakeModel()
    )

    # Imagen de prueba
    sample_path = os.path.join(
        os.path.dirname(__file__),
        "samples",
        "descarga(1).jpg"
    )
    assert os.path.exists(sample_path)

    with open(sample_path, "rb") as f:
        files = {"file": ("descarga(1).jpg", f, "image/jpeg")}
        response = client.post("/ia/predict", files=files)

    assert response.status_code == 200

    body = response.json()

    # 🔵 IMPRIMIMOS EN TERMINAL LO QUE LA API "DETECTÓ"
    print("\n📸 RESULTADO DE LA DETECCIÓN:")
    for pred in body["predicciones"]:
        print(f" - Variedad detectada: {pred['variedad']}")
        print(f" - Confianza: {pred['confianza']}%")

    # VALIDACIONES
    assert "predicciones" in body
    assert isinstance(body["predicciones"], list)
    assert len(body["predicciones"]) > 0

    pred = body["predicciones"][0]
    assert "variedad" in pred
    assert "confianza" in pred
    assert 0.0 <= pred["confianza"] <= 100.0

