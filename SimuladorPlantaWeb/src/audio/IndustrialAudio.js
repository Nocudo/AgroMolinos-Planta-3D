/**
 * IndustrialAudio.js - Motor de Audio Procedural Industrial con Web Audio API.
 * Síntesis procedural en tiempo real (cero dependencias de archivos de audio externos):
 * 1. Zumbido electromagnético del motor de inducción (fundamental 60 Hz + armónicos 120 Hz, 180 Hz).
 * 2. Silbido de conmutación PWM del inversor VFD a 4 kHz (IGBT carrier frequency).
 * 3. Ruido mecánico de molienda de martillos y cereal con ruido blanco filtrado.
 * 4. Sirena de alarma industrial ISA 18.2 modulada en frecuencia para parada de emergencia.
 * 5. Chasquido de contactor / seccionador electromecánico.
 */
export class IndustrialAudio {
  constructor(eventBus) {
    this.eventBus = eventBus;
    this.ctx = null;
    this.isMuted = false;
    this.initialized = false;

    // Nodos de audio del motor
    this.motorHumOsc = null;
    this.motorHumHarmonic = null;
    this.motorHumGain = null;

    // Nodo PWM VFD
    this.vfdCarrierOsc = null;
    this.vfdCarrierGain = null;

    // Nodo Ruido Molino
    this.grindNoiseNode = null;
    this.grindFilter = null;
    this.grindGain = null;

    // Sirena E-Stop
    this.alarmOsc = null;
    this.alarmGain = null;
    this.alarmTimer = null;

    this.setupUserUnlock();
    this.setupListeners();
  }

  setupUserUnlock() {
    // Inicializar AudioContext tras la primera interacción del usuario
    const unlock = () => {
      if (!this.initialized) {
        this.initAudioContext();
        window.removeEventListener('click', unlock);
        window.removeEventListener('keydown', unlock);
      }
    };
    window.addEventListener('click', unlock);
    window.addEventListener('keydown', unlock);
  }

  initAudioContext() {
    try {
      const AudioCtx = window.AudioContext || window.webkitAudioContext;
      this.ctx = new AudioCtx();

      // Master Gain
      this.masterGain = this.ctx.createGain();
      this.masterGain.gain.setValueAtTime(0.35, this.ctx.currentTime);
      this.masterGain.connect(this.ctx.destination);

      this.createMotorHumSynthesizer();
      this.createVFDCarrrierSynthesizer();
      this.createGrindingNoiseSynthesizer();
      this.createAlarmSynthesizer();

      this.initialized = true;
    } catch (e) {
      console.warn('[IndustrialAudio] Web Audio API no soportada o bloqueada:', e);
    }
  }

  createMotorHumSynthesizer() {
    // Oscilador fundamental
    this.motorHumOsc = this.ctx.createOscillator();
    this.motorHumOsc.type = 'sawtooth';
    this.motorHumOsc.frequency.setValueAtTime(60.0, this.ctx.currentTime);

    // Armónico par a 120 Hz
    this.motorHumHarmonic = this.ctx.createOscillator();
    this.motorHumHarmonic.type = 'triangle';
    this.motorHumHarmonic.frequency.setValueAtTime(120.0, this.ctx.currentTime);

    const humFilter = this.ctx.createBiquadFilter();
    humFilter.type = 'lowpass';
    humFilter.frequency.setValueAtTime(320.0, this.ctx.currentTime);

    this.motorHumGain = this.ctx.createGain();
    this.motorHumGain.gain.setValueAtTime(0.0, this.ctx.currentTime);

    this.motorHumOsc.connect(humFilter);
    this.motorHumHarmonic.connect(humFilter);
    humFilter.connect(this.motorHumGain);
    this.motorHumGain.connect(this.masterGain);

    this.motorHumOsc.start();
    this.motorHumHarmonic.start();
  }

  createVFDCarrrierSynthesizer() {
    // Silbido agudo de conmutación IGBT a 4 kHz
    this.vfdCarrierOsc = this.ctx.createOscillator();
    this.vfdCarrierOsc.type = 'sine';
    this.vfdCarrierOsc.frequency.setValueAtTime(4000.0, this.ctx.currentTime);

    this.vfdCarrierGain = this.ctx.createGain();
    this.vfdCarrierGain.gain.setValueAtTime(0.0, this.ctx.currentTime);

    this.vfdCarrierOsc.connect(this.vfdCarrierGain);
    this.vfdCarrierGain.connect(this.masterGain);
    this.vfdCarrierOsc.start();
  }

  createGrindingNoiseSynthesizer() {
    // Generador de ruido blanco mediante AudioBuffer para la fricción de martillos y cereal
    const bufferSize = this.ctx.sampleRate * 2;
    const noiseBuffer = this.ctx.createBuffer(1, bufferSize, this.ctx.sampleRate);
    const output = noiseBuffer.getChannelData(0);
    for (let i = 0; i < bufferSize; i++) {
      output[i] = Math.random() * 2 - 1;
    }

    const whiteNoise = this.ctx.createBufferSource();
    whiteNoise.buffer = noiseBuffer;
    whiteNoise.loop = true;

    this.grindFilter = this.ctx.createBiquadFilter();
    this.grindFilter.type = 'bandpass';
    this.grindFilter.frequency.setValueAtTime(450.0, this.ctx.currentTime);
    this.grindFilter.Q.setValueAtTime(1.5, this.ctx.currentTime);

    this.grindGain = this.ctx.createGain();
    this.grindGain.gain.setValueAtTime(0.0, this.ctx.currentTime);

    whiteNoise.connect(this.grindFilter);
    this.grindFilter.connect(this.grindGain);
    this.grindGain.connect(this.masterGain);

    whiteNoise.start();
  }

  createAlarmSynthesizer() {
    // Sirena de emergencia modulada
    this.alarmOsc = this.ctx.createOscillator();
    this.alarmOsc.type = 'sawtooth';
    this.alarmOsc.frequency.setValueAtTime(800.0, this.ctx.currentTime);

    this.alarmGain = this.ctx.createGain();
    this.alarmGain.gain.setValueAtTime(0.0, this.ctx.currentTime);

    this.alarmOsc.connect(this.alarmGain);
    this.alarmGain.connect(this.masterGain);
    this.alarmOsc.start();
  }

  setupListeners() {
    this.eventBus.on('safety:eStop', (data) => {
      if (data.engaged) {
        this.playContactorClick();
        this.startAlarmSound();
      } else {
        this.stopAlarmSound();
      }
    });

    this.eventBus.on('vfd:command', (data) => {
      if (data.action === 'start' || data.action === 'stop') {
        this.playContactorClick();
      }
    });
  }

  playContactorClick() {
    if (!this.initialized || !this.ctx) return;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();
    osc.type = 'square';
    osc.frequency.setValueAtTime(150.0, this.ctx.currentTime);
    osc.frequency.exponentialRampToValueAtTime(30.0, this.ctx.currentTime + 0.08);

    gain.gain.setValueAtTime(0.4, this.ctx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.001, this.ctx.currentTime + 0.08);

    osc.connect(gain);
    gain.connect(this.masterGain);
    osc.start();
    osc.stop(this.ctx.currentTime + 0.09);
  }

  startAlarmSound() {
    if (!this.initialized || !this.ctx) return;
    this.alarmGain.gain.setTargetAtTime(0.25, this.ctx.currentTime, 0.05);

    // Modulación periódica de sirena 800 Hz a 1200 Hz
    let toggle = false;
    if (this.alarmTimer) clearInterval(this.alarmTimer);
    this.alarmTimer = setInterval(() => {
      if (this.alarmOsc && this.ctx) {
        toggle = !toggle;
        this.alarmOsc.frequency.setTargetAtTime(toggle ? 1150.0 : 800.0, this.ctx.currentTime, 0.08);
      }
    }, 400);
  }

  stopAlarmSound() {
    if (!this.initialized || !this.ctx) return;
    this.alarmGain.gain.setTargetAtTime(0.0, this.ctx.currentTime, 0.05);
    if (this.alarmTimer) {
      clearInterval(this.alarmTimer);
      this.alarmTimer = null;
    }
  }

  /**
   * Modula en tiempo real la síntesis de audio según las variables de la máquina.
   * @param {number} motorRPM 
   * @param {number} frequencyHz 
   * @param {number} currentRMS 
   * @param {boolean} faultPhaseLoss 
   * @param {number} feedRate 
   */
  update(motorRPM, frequencyHz, currentRMS, faultPhaseLoss, feedRate) {
    if (!this.initialized || !this.ctx) return;

    const t = this.ctx.currentTime;

    // 1. Modulación del zumbido del motor
    if (frequencyHz > 0.5 && motorRPM > 20.0) {
      const baseFreq = Math.max(10.0, frequencyHz);
      this.motorHumOsc.frequency.setTargetAtTime(baseFreq, t, 0.05);
      this.motorHumHarmonic.frequency.setTargetAtTime(baseFreq * 2.0, t, 0.05);

      // Si hay pérdida de fase, el zumbido de 120 Hz se eleva dramáticamente
      const targetHumVolume = faultPhaseLoss ? 0.35 : Math.min(0.2, (currentRMS / 20.0) * 0.15);
      this.motorHumGain.gain.setTargetAtTime(targetHumVolume, t, 0.05);

      // 2. Modulación del silbido PWM del VFD
      const targetPwmVolume = Math.min(0.08, (frequencyHz / 60.0) * 0.06);
      this.vfdCarrierGain.gain.setTargetAtTime(targetPwmVolume, t, 0.05);

      // 3. Modulación de molienda de martillos
      const targetGrindVol = Math.min(0.28, (motorRPM / 1750.0) * (0.05 + 0.2 * (feedRate / 100.0)));
      this.grindGain.gain.setTargetAtTime(targetGrindVol, t, 0.08);
      this.grindFilter.frequency.setTargetAtTime(300.0 + (motorRPM / 1750.0) * 600.0, t, 0.08);
    } else {
      this.motorHumGain.gain.setTargetAtTime(0.0, t, 0.1);
      this.vfdCarrierGain.gain.setTargetAtTime(0.0, t, 0.1);
      this.grindGain.gain.setTargetAtTime(0.0, t, 0.1);
    }
  }
}
export default IndustrialAudio;
