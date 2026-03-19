const resource = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'cbk-appearance';

const state = {
  open: false,
  appearance: null,
  config: null,
  section: 'identity',
  saving: false,
  saveMessage: '',
  error: '',
  activeCamera: 'full'
};

const cameraInputState = {
  dragging: false,
  lastMouseX: 0,
  rotate: 0,
  zoom: 0,
  raf: 0
};

const sections = [
  { key: 'identity', title: 'Identity & Heritage' },
  { key: 'face', title: 'Face Features' },
  { key: 'hair', title: 'Hair & Eyes' },
  { key: 'overlays', title: 'Overlays' },
  { key: 'clothing', title: 'Clothing' }
];

const defaultOverlayControls = [
  { id: '1', label: 'Facial Hair', maxStyle: 28, colorType: 1 },
  { id: '2', label: 'Eyebrows', maxStyle: 33, colorType: 1 },
  { id: '4', label: 'Makeup', maxStyle: 74, colorType: 2 },
  { id: '5', label: 'Blush', maxStyle: 6, colorType: 2 },
  { id: '8', label: 'Lipstick', maxStyle: 9, colorType: 2 }
];

const heritageLabels = {
  shapeFirst: 'Parent 1 Face',
  shapeSecond: 'Parent 2 Face',
  skinFirst: 'Parent 1 Skin Tone',
  skinSecond: 'Parent 2 Skin Tone'
};

const faceFeatureLabels = [
  'Nose Width',
  'Nose Peak Height',
  'Nose Peak Length',
  'Nose Bone Height',
  'Nose Tip Lowering',
  'Nose Bone Twist',
  'Eyebrow Height',
  'Eyebrow Depth',
  'Cheekbone Height',
  'Cheekbone Width',
  'Cheeks Width',
  'Eyes Opening',
  'Lips Thickness',
  'Jaw Width',
  'Jaw Shape',
  'Chin Lowering',
  'Chin Length',
  'Chin Shape',
  'Chin Cleft',
  'Neck Thickness'
];

const defaultModelOptions = [
  { value: 'mp_m_freemode_01', label: 'Male Freemode' },
  { value: 'mp_f_freemode_01', label: 'Female Freemode' }
];

const defaultComponentControls = [
  { id: '3', label: 'Torso', maxDrawable: 255, maxTexture: 63 },
  { id: '4', label: 'Legs', maxDrawable: 255, maxTexture: 63 },
  { id: '6', label: 'Shoes', maxDrawable: 255, maxTexture: 63 },
  { id: '8', label: 'Undershirt', maxDrawable: 255, maxTexture: 63 },
  { id: '11', label: 'Top', maxDrawable: 255, maxTexture: 63 }
];

const defaultPropControls = [
  { id: '0', label: 'Hat', maxDrawable: 63, maxTexture: 63 },
  { id: '1', label: 'Glasses', maxDrawable: 63, maxTexture: 63 }
];

function deepClone(v) {
  return JSON.parse(JSON.stringify(v));
}

function titleize(value) {
  return String(value || '')
    .replace(/_/g, ' ')
    .replace(/\b\w/g, (char) => char.toUpperCase());
}

function getModelOptions() {
  if (Array.isArray(state.config?.modelOptions) && state.config.modelOptions.length) {
    return state.config.modelOptions;
  }

  return defaultModelOptions;
}

function getOverlayControls() {
  if (Array.isArray(state.config?.overlayControls) && state.config.overlayControls.length) {
    return state.config.overlayControls;
  }

  return defaultOverlayControls;
}

function getComponentControls() {
  if (Array.isArray(state.config?.componentControls) && state.config.componentControls.length) {
    return state.config.componentControls;
  }

  return defaultComponentControls;
}

function getPropControls() {
  if (Array.isArray(state.config?.propControls) && state.config.propControls.length) {
    return state.config.propControls;
  }

  return defaultPropControls;
}

async function nui(name, data = {}) {
  const res = await fetch(`https://${resource}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data)
  });
  return res.json();
}

function setOpen(flag) {
  document.getElementById('app').classList.toggle('hidden', !flag);
}

function setStatus(message = '', error = '') {
  state.saveMessage = message;
  state.error = error;
  const status = document.getElementById('status');
  status.textContent = error || message || 'Thanks For Using CBK!';
  status.className = `status ${error ? 'error' : ''}`;
}

function isFormTarget(target) {
  return !!(target && target.closest && target.closest('input, select, textarea, button, label'));
}

function isInsideControls(target) {
  return !!(target && target.closest && target.closest('#controls'));
}

function queueCameraInput(rotateDelta = 0, zoomDelta = 0) {
  cameraInputState.rotate += rotateDelta;
  cameraInputState.zoom += zoomDelta;

  if (cameraInputState.raf) {
    return;
  }

  cameraInputState.raf = window.requestAnimationFrame(() => {
    const payload = {
      rotate: cameraInputState.rotate,
      zoom: cameraInputState.zoom
    };

    cameraInputState.rotate = 0;
    cameraInputState.zoom = 0;
    cameraInputState.raf = 0;

    if (!state.open || (payload.rotate === 0 && payload.zoom === 0)) {
      return;
    }

    nui('cameraInput', payload);
  });
}

function resetCameraPointerState() {
  cameraInputState.dragging = false;
  cameraInputState.lastMouseX = 0;
}

function bindCameraMouseControls() {
  window.addEventListener('mousedown', (event) => {
    if (!state.open) return;
    if (event.button !== 0 && event.button !== 2) return;
    if (isFormTarget(event.target)) return;

    cameraInputState.dragging = true;
    cameraInputState.lastMouseX = event.clientX;
    event.preventDefault();
  });

  window.addEventListener('mousemove', (event) => {
    if (!state.open || !cameraInputState.dragging) return;

    const deltaX = event.clientX - cameraInputState.lastMouseX;
    cameraInputState.lastMouseX = event.clientX;

    if (Math.abs(deltaX) < 1) {
      return;
    }

    queueCameraInput(deltaX * 0.35, 0);
  });

  window.addEventListener('mouseup', resetCameraPointerState);
  window.addEventListener('mouseleave', resetCameraPointerState);
  window.addEventListener('blur', resetCameraPointerState);
  window.addEventListener('contextmenu', (event) => {
    if (state.open && cameraInputState.dragging) {
      event.preventDefault();
    }
  });

  window.addEventListener('wheel', (event) => {
    if (!state.open) return;
    if (isFormTarget(event.target) || isInsideControls(event.target)) return;

    event.preventDefault();
    const zoomDelta = event.deltaY > 0 ? 0.12 : -0.12;
    queueCameraInput(0, zoomDelta);
  }, { passive: false });
}

function renderSteps() {
  const el = document.getElementById('steps');
  el.innerHTML = '';
  sections.forEach(section => {
    const btn = document.createElement('button');
    btn.className = `step ${state.section === section.key ? 'active' : ''}`;
    btn.textContent = section.title;
    btn.onclick = () => {
      state.section = section.key;
      autoCameraForSection();
      render();
    };
    el.appendChild(btn);
  });
}

function renderCameraButtons() {
  document.querySelectorAll('[data-camera]').forEach((button) => {
    const mode = button.getAttribute('data-camera');
    button.classList.toggle('active', state.activeCamera === mode);
  });
}

function controlWrapper(label, inner) {
  const card = document.createElement('div');
  card.className = 'control';
  card.innerHTML = `<label>${label}</label>`;
  card.appendChild(inner);
  return card;
}

function rangeControl(label, min, max, step, value, onInput) {
  const wrapper = document.createElement('div');
  wrapper.innerHTML = `
    <div class="meta"><span>${label}</span><span>${Number(value).toFixed(2)}</span></div>
    <input type="range" min="${min}" max="${max}" step="${step}" value="${value}" />
  `;
  const input = wrapper.querySelector('input');
  input.oninput = (e) => {
    wrapper.querySelector('.meta span:last-child').textContent = Number(e.target.value).toFixed(2);
    onInput(parseFloat(e.target.value));
  };
  return controlWrapper(label, wrapper);
}

function numberControl(label, value, onInput, min = 0, max = 255) {
  const wrapper = document.createElement('div');
  wrapper.innerHTML = `<input type="number" min="${min}" max="${max}" value="${value}" />`;
  wrapper.querySelector('input').oninput = (e) => onInput(parseInt(e.target.value || '0', 10));
  return controlWrapper(label, wrapper);
}

function selectControl(label, options, value, onInput) {
  const wrapper = document.createElement('div');
  const select = document.createElement('select');
  options.forEach(opt => {
    const option = document.createElement('option');
    option.value = opt.value;
    option.textContent = opt.label;
    if (String(opt.value) === String(value)) option.selected = true;
    select.appendChild(option);
  });
  select.onchange = (e) => onInput(e.target.value);
  wrapper.appendChild(select);
  return controlWrapper(label, wrapper);
}

function renderIdentity(container) {
  container.appendChild(selectControl('Model', getModelOptions(), state.appearance.model, (v) => {
    state.appearance.model = v;
    preview();
  }));

  ['shapeFirst', 'shapeSecond', 'skinFirst', 'skinSecond'].forEach((key) => {
    container.appendChild(numberControl(heritageLabels[key] || key, state.appearance.heritage[key], (v) => {
      state.appearance.heritage[key] = v;
      preview();
    }, 0, 45));
  });

  container.appendChild(rangeControl('Resemblance', 0, 1, 0.01, state.appearance.heritage.shapeMix, (v) => {
    state.appearance.heritage.shapeMix = v;
    preview();
  }));
  container.appendChild(rangeControl('Skin Tone Mix', 0, 1, 0.01, state.appearance.heritage.skinMix, (v) => {
    state.appearance.heritage.skinMix = v;
    preview();
  }));
}

function renderFace(container) {
  for (let i = 0; i < state.appearance.faceFeatures.length; i++) {
    const label = faceFeatureLabels[i] || `Feature ${i + 1}`;
    container.appendChild(rangeControl(label, -1, 1, 0.01, state.appearance.faceFeatures[i], (v) => {
      state.appearance.faceFeatures[i] = v;
      preview();
    }));
  }
}

function renderHair(container) {
  const maxHairColor = Number.isFinite(state.config?.maxHairColor) ? state.config.maxHairColor : 63;
  const maxEyeColor = Number.isFinite(state.config?.maxEyeColor) ? state.config.maxEyeColor : 31;

  container.appendChild(numberControl('Hair Style', state.appearance.hair.style, (v) => {
    state.appearance.hair.style = v;
    preview();
  }));
  container.appendChild(numberControl('Hair Color', state.appearance.hair.color, (v) => {
    state.appearance.hair.color = v;
    preview();
  }, 0, maxHairColor));
  container.appendChild(numberControl('Hair Highlight', state.appearance.hair.highlight, (v) => {
    state.appearance.hair.highlight = v;
    preview();
  }, 0, maxHairColor));
  container.appendChild(numberControl('Eye Color', state.appearance.eyes.color, (v) => {
    state.appearance.eyes.color = v;
    preview();
  }, 0, maxEyeColor));
}

function renderOverlays(container) {
  const maxHairColor = Number.isFinite(state.config?.maxHairColor) ? state.config.maxHairColor : 63;

  getOverlayControls().forEach((control) => {
    const id = String(control.id);
    const label = control.label || titleize(id);
    state.appearance.headOverlays[id] = state.appearance.headOverlays[id] || { style: 0, opacity: 0, color: 0, secondColor: 0 };
    const overlay = state.appearance.headOverlays[id];
    container.appendChild(numberControl(`${label} Style`, overlay.style, (v) => {
      overlay.style = v;
      preview();
    }, 0, Number.isFinite(control.maxStyle) ? control.maxStyle : 255));
    container.appendChild(rangeControl(`${label} Opacity`, 0, 1, 0.01, overlay.opacity, (v) => {
      overlay.opacity = v;
      preview();
    }));

    if ((control.colorType || 0) > 0) {
      container.appendChild(numberControl(`${label} Color`, overlay.color, (v) => {
        overlay.color = v;
        preview();
      }, 0, maxHairColor));
    }
  });
}

function renderClothing(container) {
  getComponentControls().forEach((control) => {
    const slot = String(control.id);
    state.appearance.components[slot] = state.appearance.components[slot] || { drawable: 0, texture: 0 };
    const c = state.appearance.components[slot];
    const label = control.label || `Component ${slot}`;
    container.appendChild(numberControl(`${label} Drawable`, c.drawable, (v) => {
      c.drawable = v;
      preview();
    }, 0, Number.isFinite(control.maxDrawable) ? control.maxDrawable : 255));
    container.appendChild(numberControl(`${label} Texture`, c.texture, (v) => {
      c.texture = v;
      preview();
    }, 0, Number.isFinite(control.maxTexture) ? control.maxTexture : 63));
  });

  getPropControls().forEach((control) => {
    const slot = String(control.id);
    state.appearance.props[slot] = state.appearance.props[slot] || { drawable: -1, texture: 0 };
    const p = state.appearance.props[slot];
    const label = control.label || `Prop ${slot}`;
    container.appendChild(numberControl(`${label} Drawable (-1 clears)`, p.drawable, (v) => {
      p.drawable = v;
      preview();
    }, -1, Number.isFinite(control.maxDrawable) ? control.maxDrawable : 63));
    container.appendChild(numberControl(`${label} Texture`, p.texture, (v) => {
      p.texture = v;
      preview();
    }, 0, Number.isFinite(control.maxTexture) ? control.maxTexture : 63));
  });
}

function autoCameraForSection() {
  let mode = 'full';
  if (state.section === 'face' || state.section === 'overlays') mode = 'head';
  if (state.section === 'hair') mode = 'head';
  if (state.section === 'clothing') mode = 'torso';
  state.activeCamera = mode;
  nui('camera', { mode });
  renderCameraButtons();
}

function render() {
  renderSteps();
  renderCameraButtons();
  document.getElementById('sectionEyebrow').textContent = 'Creator';
  const current = sections.find((s) => s.key === state.section);
  document.getElementById('sectionTitle').textContent = current.title;
  document.getElementById('saveBtn').disabled = state.saving;
  document.getElementById('saveBtn').textContent = state.saving ? 'Saving...' : 'Save';

  const controls = document.getElementById('controls');
  controls.innerHTML = '';

  switch (state.section) {
    case 'identity': renderIdentity(controls); break;
    case 'face': renderFace(controls); break;
    case 'hair': renderHair(controls); break;
    case 'overlays': renderOverlays(controls); break;
    case 'clothing': renderClothing(controls); break;
  }
}

let previewTimer = null;
function preview() {
  clearTimeout(previewTimer);
  previewTimer = setTimeout(() => {
    nui('preview', { appearance: state.appearance }).then((response) => {
      if (response?.ok && response.appearance) {
        state.appearance = response.appearance;
      }
    });
  }, 40);
}

window.addEventListener('message', (event) => {
  const data = event.data;
  if (data.action === 'open') {
    state.open = true;
    state.appearance = deepClone(data.appearance);
    state.config = data.config || {};
    state.section = 'identity';
    state.saving = false;
    state.activeCamera = 'full';
    setOpen(true);
    setStatus();
    render();
    autoCameraForSection();
  } else if (data.action === 'close') {
    state.open = false;
    state.saving = false;
    setOpen(false);
  } else if (data.action === 'saveState') {
    state.saving = !!data.saving;
    if (data.error) {
      setStatus('', data.message || data.error);
    } else {
      setStatus(data.message || '');
    }
    render();
  }
});

document.getElementById('saveBtn').onclick = async () => {
  if (state.saving) return;
  state.saving = true;
  setStatus('Saving appearance...');
  render();

  const response = await nui('save', { appearance: state.appearance });
  if (!response.ok) {
    state.saving = false;
    setStatus('', response.error || 'Save failed.');
    render();
  }
};

document.getElementById('cancelBtn').onclick = () => nui('close');
document.getElementById('rotateLeft').onclick = () => nui('rotate', { direction: -20.0 });
document.getElementById('rotateRight').onclick = () => nui('rotate', { direction: 20.0 });
document.getElementById('zoomIn').onclick = () => nui('zoom', { delta: -0.08 });
document.getElementById('zoomOut').onclick = () => nui('zoom', { delta: 0.08 });

document.querySelectorAll('[data-camera]').forEach((button) => {
  button.onclick = () => {
    state.activeCamera = button.getAttribute('data-camera');
    renderCameraButtons();
    nui('camera', { mode: state.activeCamera });
  };
});

bindCameraMouseControls();
nui('ready');
