import torch
from transformers import AutoModelForCausalLM
from photonic_model_patch import apply_photonic_coupling

model = AutoModelForCausalLM.from_pretrained(
    "C:/RobdoeDeepSeekN-V3/model_weights",
    torch_dtype="auto",
    device_map="auto"
)

model = apply_photonic_coupling(model)
print("[✓] Local model initialized and photonic phase coupled.")