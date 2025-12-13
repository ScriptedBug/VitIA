from ultralytics import YOLO
import os

MODEL_PATH = os.path.join(os.path.dirname(__file__), "best2.pt")

print(f"Loading YOLO model from {MODEL_PATH}...")
# load once
model = YOLO(MODEL_PATH)

print("YOLO model loaded.")
