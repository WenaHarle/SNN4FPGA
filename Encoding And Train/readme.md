# Encoding & Training Guide

## Overview

This directory contains the complete pipeline for data preparation, signal encoding, and SNN model training with FPGA quantization.

## 📋 Notebooks Overview

### 1. Generate Data.ipynb
**Purpose**: Generate synthetic ECG dataset with multiple cardiac conditions

**Key Features**:
- Generates ECG signals for different classes (Normal, Arrhythmia, Q-wave, etc.)
- Implements Gaussian-based signal morphology synthesis
- Adds realistic artifact noise, especially around QRS complexes
- Creates balanced train/test splits
- Outputs datasets ready for encoding stage

**Output**: `spikes_sampler_centered_var/` - Organized dataset structure

**Key Parameters**:
- Sampling rate: Configurable (typically 1000 Hz)
- Signal duration: Configurable per heartbeat
- Noise levels: Different levels for each class
- Artifact magnitude: Especially QRS corruption for 'unknown' class

---

### 2. Encoding Normal.ipynb
**Purpose**: Implement spike encoding methods to convert continuous signals to spike trains

**Supported Encoding Methods**:

#### A. Delta Modulation (DM)
```
- dm_up[n]   = 1 if x[n] - y[n-1] > delta
- dm_down[n] = 1 if x[n] - y[n-1] < -delta
```
Where `y[n]` is the reconstructed signal.

**Use Case**: Efficient encoding with adaptive step size

#### B. Level Crossing (LC) - 2 Channel
```
- Quantize signal to index: idx[n] = floor(x[n] / step_mv)
- LC_up[n]   = 1 if idx[n] > idx[n-1]    (crossing up)
- LC_down[n] = 1 if idx[n] < idx[n-1]    (crossing down)
```

**Use Case**: Robust to amplitude variations, time-efficient

#### C. Threshold-Based Encoding
Direct comparison against threshold levels.

**Use Case**: Simplest implementation, minimal computation

**Output**: Spike matrices for each encoding method
- `spikes_F.mem` - Spikes from encoding F
- `spikes_Q.mem` - Spikes from encoding Q
- `spikes_S.mem` - Spikes from encoding S
- `spikes.mem` - Main spike training data

---

### 3. Sampling Point Encoding.ipynb
**Purpose**: Alternative encoding using strategic sampling points

**Key Concept**:
- Select representative time points from each cycle
- Encode spike presence/absence at these points
- Reduces computation while preserving information

**Use Case**: Resource-constrained FPGA implementations

---

### 4. Train_FPGA_Fix.ipynb
**Purpose**: Train Spiking Neural Network with fixed-point quantization for FPGA

**Architecture**:
- **Input Layer**: Spike encoded signals
- **Hidden Layers**: Leaky Integrate-and-Fire (LIF) neurons with quantization
- **Output Layer**: Classification neurons

**Quantization Scheme - Q8.4**:
- **8-bit signed integer** representation
- **4 fractional bits**
- **Range**: [-128, 127] integer ↔ [-8.0, 7.9375] float
- **Step size**: 1/16 = 0.0625

**Training Configuration**:
```python
Q_BITS  = 8
Q_FRAC  = 4
Q_SCALE = 2^4 = 16
Q_MIN   = -128
Q_MAX   = 127
```

**Training Process**:
1. Initialize LIF neuron parameters
2. Forward pass with spike inputs
3. Compute loss with quantization constraints
4. Backward pass with surrogate gradients
5. Update weights and export to FPGA format

**Output Files**:
- Trained weight matrices (quantized)
- `fc1_w_q44_int8.mem` - Layer 1 weights
- `fc2_w_q44_int8.mem` - Layer 2 weights
- `fc3_w_q44_int8.mem` - Layer 3 weights
- Model checkpoints and training logs

**Performance Metrics**:
- Accuracy on test set
- Confusion matrix analysis
- Precision, Recall, F1-score per class
- Hardware-Software equivalence verification

---

## 🔄 Workflow

```
1. Generate Data.ipynb
   └─→ Creates synthetic ECG dataset
       └─→ spikes_sampler_centered_var/

2. Encoding Normal.ipynb
   └─→ Encodes signals to spike trains
       └─→ spikes*.mem files

3. Train_FPGA_Fix.ipynb
   └─→ Trains quantized SNN
       └─→ fc*_w_q44_int8.mem (weights)
           └─→ Ready for FPGA deployment
```

---

## 💾 Data Format

### Spike Memory Files (*.mem)
Binary spike representations ready for FPGA:
- **Format**: One value per line
- **Values**: 0 (no spike) or 1 (spike)
- **Order**: Sequential spike indices

### Weight Memory Files (fc*_w_q44_int8.mem)
Quantized network weights for FPGA:
- **Format**: Fixed-point Q4.4 in 8-bit signed integer
- **Range**: [-128, 127]
- **Conversion**: `fixed_value = round(float_value * 16)`

---

## 🛠️ Key Parameters & Configuration

### Signal Generation
- **Sampling Rate**: fs = 1000 Hz (configurable)
- **Signal Duration**: 1-5 seconds per sample
- **Noise Level**: 0.1-0.5 (varies by class)

### Encoding
- **Delta Modulation Step**: 0.05 (configurable)
- **Level Crossing Step**: 0.1 mV (configurable)

### Training
- **Epochs**: 100 (with early stopping)
- **Warmup Epochs**: 15
- **Batch Size**: 32
- **Learning Rate**: Scheduled decay
- **Optimizer**: Adam with quantization constraints

---

## 📊 Expected Performance

| Metric | Value |
|--------|-------|
| Training Accuracy | >95% |
| Test Accuracy | >90% |
| Quantization Loss | <2% |
| FPGA Latency | <10ms per sample |
| Power Consumption | <100mW (FPGA) |

---

## 🔍 Troubleshooting

### Low Encoding Accuracy
- Check delta modulation step size
- Verify signal normalization
- Increase level crossing grid resolution

### Training Divergence
- Reduce learning rate
- Increase warmup epochs
- Check for NaN in quantized values

### FPGA Mismatch
- Verify weight export format
- Check fixed-point quantization
- Run comprehensive testbench

---

## 📝 Dependencies

```
Python: 3.8+
PyTorch: 1.9+
SNNTorch: 0.9+
NumPy: 1.19+
Matplotlib: 3.3+
scikit-learn: 0.24+
Jupyter: 1.0+
```

Install all dependencies:
```bash
pip install torch snntorch numpy matplotlib scikit-learn jupyter
```

---

## 📚 Advanced Topics

### Custom Encoding Methods
Extend `encode_*` functions in Encoding Normal.ipynb with your own spike generation logic.

### Quantization Tuning
Modify `Q_BITS` and `Q_FRAC` in Train_FPGA_Fix.ipynb to optimize accuracy vs. resource usage.

### Layer Configuration
Adjust hidden layer sizes, neuron counts, and time constants for different hardware targets.

---

**Last Updated**: May 2026  
**Maintainer**: SNN4FPGA Team
