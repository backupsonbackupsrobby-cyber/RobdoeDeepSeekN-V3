import math
import time
import torch
import torch.nn as nn
from typing import Optional

class PhotonicPhaseCoupler:
    """
    Offline Photonic Dispersion & Diurnal Phase Coupler.
    Attaches to live HuggingFace / PyTorch transformer layers and MoE routing gates via forward hooks.
    """
    def __init__(self, base_freq: float = 0.05208333, c_eff: float = 0.98, arcseconds_full: float = 1296000.0):
        self.base_freq = base_freq
        self.c_eff = c_eff
        self.arcseconds_full = arcseconds_full

    def compute_diurnal_phase(self) -> float:
        """Calculates current UTC diurnal phase angle in radians."""
        now_sec = time.time() % 86400.0
        current_arc = (now_sec * 15.0) % self.arcseconds_full
        return (current_arc / self.arcseconds_full) * 2.0 * math.pi

    def create_layer_pre_hook(self, layer_idx: int):
        """
        Creates a PyTorch forward pre-hook for transformer decoder layers.
        Modulates input hidden_states with spatial-temporal wave phase before attention/FFN computation.
        """
        def hook(module: nn.Module, args: tuple) -> Optional[tuple]:
            if not args:
                return args
            
            hidden_states = args[0]
            if not isinstance(hidden_states, torch.Tensor):
                return args

            phase_angle = self.compute_diurnal_phase()
            seq_len = hidden_states.size(1)
            device = hidden_states.device
            dtype = hidden_states.dtype

            # Spatial position wave vector: k = omega / c_eff
            positions = torch.arange(seq_len, device=device, dtype=torch.float32)
            k_vector = (2.0 * math.pi * self.base_freq) / self.c_eff
            
            # Phase field dispersion: phi(x, t) = phase_angle - (x * k)
            wave_phase = phase_angle - (positions * k_vector)
            field = torch.sin(wave_phase).to(dtype=dtype).unsqueeze(-1)  # [seq_len, 1]

            # Apply additive phase modulation directly to incoming tensor
            modulated_states = hidden_states + (field * 0.01)
            
            # Return modified args tuple matching layer signature
            return (modulated_states,) + args[1:]

        return hook

    def patch_moe_gate(self, gate_module: nn.Module):
        """
        Monkey-patches an MoE routing gate forward method.
        Injects photonic wave interference into raw routing logits prior to top-k expert selection.
        """
        original_forward = gate_module.forward

        def patched_forward(hidden_states: torch.Tensor, *args, **kwargs):
            phase_angle = self.compute_diurnal_phase()
            
            # Call original gate pass to retrieve unscaled logits
            logits = original_forward(hidden_states, *args, **kwargs)
            
            # Generate phase offset matrix matching expert count
            num_experts = logits.size(-1)
            expert_phases = torch.linspace(0, 2 * math.pi, num_experts, device=logits.device, dtype=logits.dtype)
            interference = torch.cos(phase_angle - expert_phases) * 0.05
            
            # Inject photonic phase alignment into router logits
            if isinstance(logits, tuple):
                return (logits[0] + interference,) + logits[1:]
            return logits + interference

        gate_module.forward = patched_forward


def apply_photonic_coupling(model: nn.Module) -> nn.Module:
    """
    Scans a local PyTorch / HuggingFace model and attaches hooks to decoder layers and MoE gates.
    Pass your initialized model instance into this function before running model.generate() or forward().
    """
    coupler = PhotonicPhaseCoupler()
    hook_count = 0
    gate_count = 0

    # Locate transformer decoder layers
    layers = getattr(model, "layers", None)
    if layers is None and hasattr(model, "model"):
        layers = getattr(model.model, "layers", None)

    if layers is not None:
        for idx, layer in enumerate(layers):
            layer.register_forward_pre_hook(coupler.create_layer_pre_hook(idx))
            hook_count += 1
            
            # Check for MoE gating modules inside layer
            for name, submodule in layer.named_modules():
                if "gate" in name.lower() or "router" in name.lower():
                    coupler.patch_moe_gate(submodule)
                    gate_count += 1

    print(f"[✓] Attached Photonic Pre-Hooks to {hook_count} Transformer Layers.")
    print(f"[✓] Patched Photonic Phase Bias onto {gate_count} MoE Router Gates.")
    return model
