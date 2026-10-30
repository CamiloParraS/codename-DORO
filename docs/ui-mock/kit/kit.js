// Shared mock behaviour: stage fit, language swap, replay, dial emblem, UI ticks.
(function () {
  const stage = document.getElementById('stage');
  const BAR = 44;
  function fit() { stage.style.transform = `translate(-50%, -50%) scale(${Math.min(innerWidth / 1920, (innerHeight - BAR) / 1080)})`; }
  addEventListener('resize', fit); fit();

  // dial: segmented rings around the Metis emblem, drawn from circles with dash patterns
  const ring = (r, w, dash, extra = '') => `<circle r="${r}" fill="none" stroke="currentColor" stroke-width="${w}" stroke-dasharray="${dash}" ${extra}/>`;
  const seg = (r, n, gap) => { const c = 2 * Math.PI * r, s = c / n; return `${(s - gap).toFixed(1)} ${gap}`; };
  document.querySelectorAll('[data-dial]').forEach(el => {
    const emblem = el.dataset.dial !== 'plain';
    el.innerHTML = `<svg viewBox="-500 -500 1000 1000">
      <g class="spin rev">${ring(486, 10, '2 17.5', 'opacity=".55"')}${ring(458, 2, 'none', 'opacity=".5"')}</g>
      <g class="spin">${ring(420, 46, seg(420, 18, 26), 'opacity=".42"')}</g>
      <g class="spin rev">${ring(366, 6, seg(366, 36, 14), 'opacity=".6"')}${ring(346, 2, '8 6', 'opacity=".4"')}</g>
      <g>${ring(300, 3, 'none', 'opacity=".7"')}</g>
      ${emblem ? '<use href="#emblem" x="-170" y="-170" width="340" height="340"/>' : ''}
    </svg>`;
  });

  // language swap on [data-es]
  let es = false;
  function lang(on) {
    es = on;
    document.querySelectorAll('[data-es]').forEach(el => {
      if (el.dataset.en === undefined) el.dataset.en = el.innerHTML;
      el.innerHTML = on ? el.dataset.es : el.dataset.en;
    });
    const b = document.getElementById('t-lang'); if (b) b.setAttribute('aria-pressed', on);
    document.documentElement.lang = on ? 'es' : 'en';
  }
  window.GL = { lang, get es() { return es; }, stage };
  const lb = document.getElementById('t-lang'); if (lb) lb.addEventListener('click', () => { lang(!es); if (window.onLang) window.onLang(es); });

  // replay entrance
  function play() { stage.classList.remove('in'); void stage.offsetWidth; stage.classList.add('in'); if (window.onPlay) window.onPlay(); }
  window.GL.play = play;
  const rb = document.getElementById('t-replay'); if (rb) rb.addEventListener('click', play);
  play();

  // audio: square-wave UI ticks (stand-in for Mixer SFX)
  let ac;
  function tone(f, ms, vol = .04, type = 'square') {
    try {
      ac = ac || new (window.AudioContext || window.webkitAudioContext)();
      if (ac.state === 'suspended') ac.resume();
      const o = ac.createOscillator(), g = ac.createGain(), t = ac.currentTime;
      o.type = type; o.frequency.value = f; g.gain.setValueAtTime(vol, t); g.gain.setValueAtTime(0, t + ms / 1000);
      o.connect(g); g.connect(ac.destination); o.start(t); o.stop(t + ms / 1000);
    } catch (e) { /* no audio before a gesture */ }
  }
  Object.assign(window.GL, { tone, tick: () => tone(1900, 22), beep: () => tone(1250, 90, .05), thump: () => tone(70, 220, .16, 'sine') });
  document.addEventListener('mouseover', e => { const r = e.target.closest && e.target.closest('.row'); if (r && !r.classList.contains('locked') && r !== document._lastRow) GL.tick(); document._lastRow = r; });
  addEventListener('keydown', e => { if (/^(Arrow(Up|Down|Left|Right)|[wasd])$/i.test(e.key)) GL.tick(); });
})();
