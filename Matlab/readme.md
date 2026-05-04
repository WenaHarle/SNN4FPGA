# MATLAB Reference Models

Reference implementations and analysis models in MATLAB for ECG signal processing and SNN verification.

## 📋 Files Overview

### 1. simul.m
**Purpose**: MATLAB simulation and analysis of ECG signals

**Key Functions**:
- Signal generation and visualization
- Spike encoding simulations
- Neural response verification
- Data analysis and statistics

**Usage**:
```matlab
>> simul
```

**Output**:
- Plots of ECG waveforms
- Spike train visualizations
- Performance analysis charts

---

### 2. Karakteristik.m
**Purpose**: Comprehensive signal characteristics analysis

**Analysis Includes**:
- **Frequency Domain**: FFT, power spectral density
- **Time Domain**: Signal statistics, peak detection
- **Morphological Features**:
  - QRS complex detection
  - P-wave and T-wave characteristics
  - RR interval analysis
- **Classification Metrics**:
  - Signal-to-noise ratio (SNR)
  - Classification performance indicators
  - Feature extraction for ML models

**Key Functions**:
- `analyze_qrs()` - QRS complex detection and measurement
- `extract_features()` - Feature extraction for classification
- `plot_characteristics()` - Visualization of signal properties
- `compute_snr()` - Signal-to-noise ratio calculation

**Usage**:
```matlab
>> Karakteristik
```

**Output**:
- Characteristic plots
- Feature vectors
- Quality metrics

---

### 3. SNN.slx
**Purpose**: Simulink model for system-level simulation

**Model Architecture**:
- ECG signal source
- Preprocessing blocks
- Spike encoding module
- Neural network simulation
- Output classification

**Features**:
- Block-based system design
- Real-time simulation capability
- Hardware co-simulation support
- Documentation of signal flow

**Usage**:
```matlab
>> open('SNN.slx')
>> sim('SNN.slx')
```

**Parameters** (configurable in model):
- Sampling rate
- Threshold levels
- Network weights
- Time constants

---

## 🔄 Workflow

```
Signal Generation
       ↓
Charakteristik.m (Analysis)
       ↓
simul.m (Simulation)
       ↓
SNN.slx (System Model)
       ↓
Compare with Python results
```

---

## 🛠️ Configuration

### Signal Parameters
```matlab
Fs = 1000;           % Sampling frequency (Hz)
Duration = 5;        % Signal duration (seconds)
Classes = 4;         % Number of cardiac classes
NoiseLevel = 0.1;    % Baseline noise standard deviation
```

### Encoding Parameters
```matlab
DeltaModThreshold = 0.05;    % Delta modulation step
LCGridStep = 0.1;             % Level crossing grid step
EncodingMethod = 'LC';         % 'DM' or 'LC'
```

### Neural Network Parameters
```matlab
NumHiddenNeurons = [64, 32];   % Layer sizes
TimeConstant = 0.01;           % LIF time constant (seconds)
Threshold = 1.0;               % Spike threshold
```

---

## 📊 Analysis Capabilities

### Frequency Analysis
- FFT computation and visualization
- Power spectral density estimation
- Frequency band analysis (0.5-100 Hz for ECG)

### Time Domain Analysis
- RR interval computation
- Heart rate variability (HRV)
- Signal statistics (mean, std, skewness, kurtosis)

### Morphological Analysis
- QRS complex detection (>100ms typical)
- P-wave detection
- T-wave analysis
- PR and QT intervals

### Classification Features
- Temporal features: RR intervals, QRS width
- Spectral features: Dominant frequencies
- Morphological features: Wave amplitudes
- Statistical features: Signal moments

---

## 🔄 Integration with Python Pipeline

### Export to Python
Use MATLAB to export analyzed signals:
```matlab
% Save to .mat file
save('analyzed_signals.mat', 'signals', 'features', 'labels')

% Or convert to CSV
writetable(table(features, labels), 'features.csv')
```

### Import from Python
Load Python-generated data:
```matlab
% From .csv
data = readtable('python_output.csv');

% From .mat
load('python_data.mat')

% From numpy (if saved as CSV or HDF5)
```

---

## 📈 Expected Analysis Results

| Metric | Typical Value |
|--------|---------------|
| Normal Heart Rate | 60-100 bpm |
| QRS Width | 80-120 ms |
| PR Interval | 120-200 ms |
| QT Interval | 350-450 ms |
| SNR (Clean Signal) | >20 dB |
| SNR (Noisy Signal) | 5-15 dB |

---

## 🔍 Signal Classes

### Typical ECG Classifications
1. **Normal (N)**: Regular sinus rhythm
2. **Arrhythmia (A)**: Irregular heartbeat
3. **Left Bundle Branch Block (L)**: Abnormal conduction
4. **Right Bundle Branch Block (R)**: Abnormal conduction
5. **Paced (P)**: Artificially paced beats
6. **Unknown (U)**: Unclassifiable signals

---

## 🛠️ Common Tasks

### Run Complete Analysis
```matlab
% Load signal
signal = load_ecg_signal('sample.mat');

% Run characteristics analysis
Karakteristik

% Run simulation
simul

% Open Simulink model
open SNN.slx
```

### Extract Features for ML Training
```matlab
features = extract_features(signals);
save('ml_features.mat', 'features', 'labels')
```

### Verify Against Python Results
```matlab
% Load both datasets
python_results = readtable('python_classification.csv');
matlab_results = readtable('matlab_classification.csv');

% Compare
comparison = compare_results(python_results, matlab_results);
```

---

## 📚 Dependencies

- MATLAB R2019b or later
- Signal Processing Toolbox
- (Optional) Deep Learning Toolbox for NN integration
- (Optional) Simulink and Stateflow

---

## 💡 Tips & Best Practices

1. **Always verify signal preprocessing** - Check for NaN, Inf, or outliers
2. **Use appropriate sampling rates** - At least 2x highest frequency (Nyquist)
3. **Normalize signals** - Zero-mean, unit variance for consistency
4. **Document parameters** - Keep track of all signal processing settings
5. **Compare with Python** - Validate results across implementations

---

## 🔗 References

- **ECG Analysis**: MIT-BIH Arrhythmia Database format
- **Signal Processing**: [MathWorks Documentation](https://www.mathworks.com/help/)
- **SNN Theory**: Leaky Integrate-and-Fire neuron models
- **FPGA Integration**: See [FSM/](../FSM/) for hardware models

---

**Last Updated**: May 2026  
**Purpose**: Reference and validation models for SNN4FPGA project
