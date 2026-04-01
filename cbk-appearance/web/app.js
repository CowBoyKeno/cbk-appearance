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
  { id: '1', label: 'Facial Hair', styleOptions: [] },
  { id: '2', label: 'Eyebrows', styleOptions: [] },
  { id: '4', label: 'Makeup', styleOptions: [] },
  { id: '5', label: 'Blush', styleOptions: [] },
  { id: '8', label: 'Lipstick', styleOptions: [] }
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
  { id: '3', label: 'Torso', drawableOptions: [], textureMaxByDrawable: {}, maxTexture: 63 },
  { id: '4', label: 'Legs', drawableOptions: [], textureMaxByDrawable: {}, maxTexture: 63 },
  { id: '6', label: 'Shoes', drawableOptions: [], textureMaxByDrawable: {}, maxTexture: 63 },
  { id: '8', label: 'Undershirt', drawableOptions: [], textureMaxByDrawable: {}, maxTexture: 63 },
  { id: '11', label: 'Top', drawableOptions: [], textureMaxByDrawable: {}, maxTexture: 63 }
];

const defaultPropControls = [
  { id: '0', label: 'Hat', drawableOptions: [{ value: -1, label: 'None' }], textureMaxByDrawable: {}, maxTexture: 63 },
  { id: '1', label: 'Glasses', drawableOptions: [{ value: -1, label: 'None' }], textureMaxByDrawable: {}, maxTexture: 63 }
];

function deepClone(v) {
  return JSON.parse(JSON.stringify(v));
}

function titleize(value) {
  return String(value || '')
    .replace(/_/g, ' ')
    .replace(/\b\w/g, (char) => char.toUpperCase());
}

function clampNumber(value, min, max) {
  const numeric = Number(value);
  if (!Number.isFinite(numeric)) return min;
  return Math.min(max, Math.max(min, numeric));
}

function valueMatches(a, b) {
  return String(a) === String(b);
}

function parseInteger(value, fallback = 0) {
  const parsed = parseInt(value, 10);
  return Number.isNaN(parsed) ? fallback : parsed;
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

function getHeritageOptions() {
  if (Array.isArray(state.config?.heritageOptions) && state.config.heritageOptions.length) {
    return state.config.heritageOptions;
  }

  return Array.from({ length: 46 }, (_, index) => ({
    value: index,
    label: `Parent ${index}`
  }));
}

function getHairColorOptions() {
  if (Array.isArray(state.config?.hairColorOptions) && state.config.hairColorOptions.length) {
    return state.config.hairColorOptions;
  }

  return Array.from({ length: 64 }, (_, index) => ({
    value: index,
    label: `Hair Color ${index}`
  }));
}

function getEyeColorOptions() {
  if (Array.isArray(state.config?.eyeColorOptions) && state.config.eyeColorOptions.length) {
    return state.config.eyeColorOptions;
  }

  return Array.from({ length: 32 }, (_, index) => ({
    value: index,
    label: `Eye Color ${index}`
  }));
}

function getActiveProfile() {
  const profiles = state.config?.profiles;
  if (!profiles || !state.appearance?.model) {
    return null;
  }

  return profiles[state.appearance.model] || null;
}

function buildIndexedOptions(maxValue, prefix, includeNone = false) {
  const safeMax = Math.max(0, Number(maxValue) || 0);
  const options = [];

  if (includeNone) {
    options.push({ value: -1, label: 'None' });
  }

  for (let index = 0; index <= safeMax; index += 1) {
    options.push({
      value: index,
      label: `${prefix} ${index}`
    });
  }

  return options;
}

function buildTextureOptions(maxTexture) {
  return buildIndexedOptions(Math.max(0, Number(maxTexture) || 0), 'Texture');
}

function getHairStyleOptions() {
  const profile = getActiveProfile();
  if (Array.isArray(profile?.hairStyleOptions) && profile.hairStyleOptions.length) {
    return profile.hairStyleOptions;
  }

  return buildIndexedOptions(255, 'Hair Style');
}

function getComponentControls() {
  const profile = getActiveProfile();
  if (Array.isArray(profile?.componentControls) && profile.componentControls.length) {
    return profile.componentControls;
  }

  return defaultComponentControls.map((control) => ({
    ...control,
    drawableOptions: buildIndexedOptions(255, control.label),
    textureMaxByDrawable: {}
  }));
}

function getPropControls() {
  const profile = getActiveProfile();
  if (Array.isArray(profile?.propControls) && profile.propControls.length) {
    return profile.propControls;
  }

  return defaultPropControls.map((control) => ({
    ...control,
    drawableOptions: buildIndexedOptions(63, control.label, true),
    textureMaxByDrawable: {}
  }));
}

function getTextureMax(control, drawable) {
  const raw = control?.textureMaxByDrawable?.[String(drawable)];
  if (Number.isFinite(raw)) {
    return raw;
  }

  return parseInteger(raw, Number(control?.maxTexture) || 0);
}

function getMaxOptionValue(options, fallback = 0) {
  if (!Array.isArray(options) || !options.length) {
    return fallback;
  }

  return options.reduce((max, option) => {
    const value = Number(option.value);
    return Number.isFinite(value) ? Math.max(max, value) : max;
  }, fallback);
}

function findOption(options, value) {
  return (options || []).find((option) => valueMatches(option.value, value)) || null;
}

function clampAppearanceForCurrentProfile() {
  if (!state.appearance) return;

  const hairOptions = getHairStyleOptions();
  state.appearance.hair.style = clampNumber(state.appearance.hair.style, 0, getMaxOptionValue(hairOptions, 0));

  getComponentControls().forEach((control) => {
    const slot = String(control.id);
    state.appearance.components[slot] = state.appearance.components[slot] || { drawable: 0, texture: 0 };
    const component = state.appearance.components[slot];
    component.drawable = clampNumber(component.drawable, 0, getMaxOptionValue(control.drawableOptions, 0));
    component.texture = clampNumber(component.texture, 0, getTextureMax(control, component.drawable));
  });

  getPropControls().forEach((control) => {
    const slot = String(control.id);
    state.appearance.props[slot] = state.appearance.props[slot] || { drawable: -1, texture: 0 };
    const prop = state.appearance.props[slot];
    prop.drawable = clampNumber(prop.drawable, -1, getMaxOptionValue(control.drawableOptions, -1));
    if (prop.drawable === -1) {
      prop.texture = 0;
    } else {
      prop.texture = clampNumber(prop.texture, 0, getTextureMax(control, prop.drawable));
    }
  });
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

function selectControl(label, options, value, onInput, extra = {}) {
  const wrapper = document.createElement('div');
  const meta = document.createElement('div');
  meta.className = 'meta';

  const selectedLabel = document.createElement('span');
  const selectedValue = document.createElement('span');
  meta.appendChild(selectedLabel);
  meta.appendChild(selectedValue);
  wrapper.appendChild(meta);

  const previewRow = document.createElement('div');
  previewRow.className = 'choice-preview hidden';

  const swatch = document.createElement('span');
  swatch.className = 'swatch';
  const hint = document.createElement('span');
  hint.className = 'hint';
  previewRow.appendChild(swatch);
  previewRow.appendChild(hint);
  wrapper.appendChild(previewRow);

  const select = document.createElement('select');
  (options || []).forEach((opt) => {
    const option = document.createElement('option');
    option.value = opt.value;
    option.textContent = opt.label;
    if (valueMatches(opt.value, value)) option.selected = true;
    select.appendChild(option);
  });

  const syncDisplay = (rawValue) => {
    const current = findOption(options, rawValue);
    selectedLabel.textContent = current?.label || extra.fallbackLabel || String(rawValue);
    selectedValue.textContent = typeof extra.valueText === 'function' ? extra.valueText(rawValue, current) : '';

    const swatchHex = typeof extra.getSwatch === 'function' ? extra.getSwatch(current, rawValue) : '';
    const hintText = typeof extra.getHint === 'function' ? extra.getHint(current, rawValue) : '';
    previewRow.classList.toggle('hidden', !swatchHex && !hintText);

    if (swatchHex) {
      swatch.style.background = swatchHex;
      swatch.classList.remove('hidden');
    } else {
      swatch.classList.add('hidden');
    }

    hint.textContent = hintText || '';
  };

  syncDisplay(value);

  select.onchange = (e) => {
    const parsedValue = typeof extra.parseValue === 'function'
      ? extra.parseValue(e.target.value)
      : e.target.value;
    syncDisplay(parsedValue);
    onInput(parsedValue);
  };

  wrapper.appendChild(select);
  return controlWrapper(label, wrapper);
}

function namedNumberSelect(label, options, value, onInput, extra = {}) {
  return selectControl(label, options, value, onInput, {
    parseValue: (raw) => parseInteger(raw, 0),
    valueText: (raw) => raw === -1 ? 'Clear' : `#${raw}`,
    ...extra
  });
}

function colorSelect(label, options, value, onInput) {
  return selectControl(label, options, value, onInput, {
    parseValue: (raw) => parseInteger(raw, 0),
    valueText: (raw) => `#${raw}`,
    getSwatch: (current) => current?.hex || '',
    getHint: (current) => current?.hex || ''
  });
}

function renderIdentity(container) {
  container.appendChild(selectControl('Model', getModelOptions(), state.appearance.model, (v) => {
    state.appearance.model = v;
    clampAppearanceForCurrentProfile();
    render();
    preview();
  }));

  const heritageOptions = getHeritageOptions();
  ['shapeFirst', 'shapeSecond', 'skinFirst', 'skinSecond'].forEach((key) => {
    container.appendChild(namedNumberSelect(heritageLabels[key] || key, heritageOptions, state.appearance.heritage[key], (v) => {
      state.appearance.heritage[key] = v;
      preview();
    }));
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
  for (let i = 0; i < state.appearance.faceFeatures.length; i += 1) {
    const label = faceFeatureLabels[i] || `Feature ${i + 1}`;
    container.appendChild(rangeControl(label, -1, 1, 0.01, state.appearance.faceFeatures[i], (v) => {
      state.appearance.faceFeatures[i] = v;
      preview();
    }));
  }
}

function renderHair(container) {
  container.appendChild(namedNumberSelect('Hair Style', getHairStyleOptions(), state.appearance.hair.style, (v) => {
    state.appearance.hair.style = v;
    preview();
  }));

  container.appendChild(colorSelect('Hair Color', getHairColorOptions(), state.appearance.hair.color, (v) => {
    state.appearance.hair.color = v;
    preview();
  }));

  container.appendChild(colorSelect('Hair Highlight', getHairColorOptions(), state.appearance.hair.highlight, (v) => {
    state.appearance.hair.highlight = v;
    preview();
  }));

  container.appendChild(colorSelect('Eye Color', getEyeColorOptions(), state.appearance.eyes.color, (v) => {
    state.appearance.eyes.color = v;
    preview();
  }));
}

function renderOverlays(container) {
  const hairColors = getHairColorOptions();

  getOverlayControls().forEach((control) => {
    const id = String(control.id);
    const label = control.label || titleize(id);
    state.appearance.headOverlays[id] = state.appearance.headOverlays[id] || { style: 0, opacity: 0, color: 0, secondColor: 0 };
    const overlay = state.appearance.headOverlays[id];
    const styleOptions = Array.isArray(control.styleOptions) && control.styleOptions.length
      ? control.styleOptions
      : buildIndexedOptions(255, `${label} Style`);

    container.appendChild(namedNumberSelect(`${label} Style`, styleOptions, overlay.style, (v) => {
      overlay.style = v;
      preview();
    }));

    container.appendChild(rangeControl(`${label} Opacity`, 0, 1, 0.01, overlay.opacity, (v) => {
      overlay.opacity = v;
      preview();
    }));

    if ((control.colorType || 0) > 0) {
      container.appendChild(colorSelect(`${label} Color`, hairColors, overlay.color, (v) => {
        overlay.color = v;
        preview();
      }));
    }
  });
}

function renderClothing(container) {
  getComponentControls().forEach((control) => {
    const slot = String(control.id);
    state.appearance.components[slot] = state.appearance.components[slot] || { drawable: 0, texture: 0 };
    const component = state.appearance.components[slot];
    const label = control.label || `Component ${slot}`;

    container.appendChild(namedNumberSelect(`${label} Item`, control.drawableOptions, component.drawable, (v) => {
      component.drawable = v;
      component.texture = Math.min(component.texture, getTextureMax(control, v));
      render();
      preview();
    }));

    container.appendChild(namedNumberSelect(`${label} Texture`, buildTextureOptions(getTextureMax(control, component.drawable)), component.texture, (v) => {
      component.texture = v;
      preview();
    }, {
      fallbackLabel: 'Texture',
      valueText: (raw) => `#${raw}`
    }));
  });

  getPropControls().forEach((control) => {
    const slot = String(control.id);
    state.appearance.props[slot] = state.appearance.props[slot] || { drawable: -1, texture: 0 };
    const prop = state.appearance.props[slot];
    const label = control.label || `Prop ${slot}`;

    container.appendChild(namedNumberSelect(`${label} Item`, control.drawableOptions, prop.drawable, (v) => {
      prop.drawable = v;
      prop.texture = v === -1 ? 0 : Math.min(prop.texture, getTextureMax(control, v));
      render();
      preview();
    }, {
      valueText: (raw) => raw === -1 ? 'Clear' : `#${raw}`
    }));

    container.appendChild(namedNumberSelect(`${label} Texture`, buildTextureOptions(prop.drawable === -1 ? 0 : getTextureMax(control, prop.drawable)), prop.texture, (v) => {
      prop.texture = v;
      preview();
    }, {
      fallbackLabel: 'Texture',
      valueText: (raw) => `#${raw}`
    }));
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
    clampAppearanceForCurrentProfile();
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
