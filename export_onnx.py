from onnx_modules import export_onnx
import os

if __name__ == "__main__":
    export_path = "Elysia_145000"
    model_path = "dataset/Elysia/models/G_145000.pth"
    config_path = "dataset/Elysia/config.json"
    novq = False
    dev = False
    if not os.path.exists("onnx"):
        os.makedirs("onnx")
    if not os.path.exists(f"onnx/{export_path}"):
        os.makedirs(f"onnx/{export_path}")
    export_onnx(export_path, model_path, config_path, novq, dev, "chinese")
