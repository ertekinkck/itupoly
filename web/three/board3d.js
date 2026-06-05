// İTÜpoly — gerçek 3B tahta (three.js / WebGL).
// Flutter tarafından HtmlElementView içine mount edilir; state Dart'tan
// setState(json) ile gelir, tile tıklaması window.itupolyOnTapTile(index) ile
// Dart'a döner.
import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';

const TILE = 1.0;       // kare boyutu (dünya birimi)
const TH = 0.22;        // kare yüksekliği
const GRID = 11;
const HALF = (GRID - 1) / 2;

// index -> (row,col) (Flutter ile aynı: 0 sağ-alt, ters saat yönü)
function cell(i) {
  if (i <= 10) return [10, 10 - i];
  if (i <= 20) return [20 - i, 0];
  if (i <= 30) return [0, i - 20];
  return [i - 30, 10];
}
function cellToWorld(row, col) {
  return [(col - HALF) * TILE, (row - HALF) * TILE];
}
function tileWorld(i) { const [r, c] = cell(i); return cellToWorld(r, c); }

const state = {
  renderer: null, scene: null, camera: null, controls: null,
  raf: null, tiles: [], buildings: {}, tokens: {}, host: null,
  followTarget: new THREE.Vector3(0, 0, 0),
  ro: null, lastDown: null,
};

function makeRenderer(host) {
  const r = new THREE.WebGLRenderer({ antialias: true, alpha: true });
  r.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
  r.shadowMap.enabled = true;
  r.shadowMap.type = THREE.PCFSoftShadowMap;
  r.outputColorSpace = THREE.SRGBColorSpace;
  host.appendChild(r.domElement);
  r.domElement.style.width = '100%';
  r.domElement.style.height = '100%';
  r.domElement.style.display = 'block';
  r.domElement.style.touchAction = 'none';
  return r;
}

function tileColorFor(t) {
  // t: {k: kind, g: groupColor, o: owner, h: houses, m: mortgaged}
  if (t.m) return 0x223047;
  if (t.g != null) return t.g;
  switch (t.k) {
    case 'ring': return 0x8390a0;
    case 'utility': return 0xc9a23a;
    case 'tax': return 0x7a3340;
    case 'card': return 0x3a6b5a;
    case 'corner': return 0x2a3550;
    default: return 0x3a4660;
  }
}

function buildBoard(tiles) {
  const g = state.scene;
  // Masa zemini.
  const baseGeo = new THREE.BoxGeometry(GRID + 1.2, 0.5, GRID + 1.2);
  const baseMat = new THREE.MeshStandardMaterial({ color: 0x0c1424, roughness: 0.9, metalness: 0.1 });
  const base = new THREE.Mesh(baseGeo, baseMat);
  base.position.y = -0.25;
  base.receiveShadow = true;
  g.add(base);

  // İç oyun alanı (hafif yükseltili panel).
  const innerGeo = new THREE.BoxGeometry(GRID - 1.6, 0.05, GRID - 1.6);
  const innerMat = new THREE.MeshStandardMaterial({ color: 0x101a30, roughness: 0.8 });
  const inner = new THREE.Mesh(innerGeo, innerMat);
  inner.position.y = 0.02;
  inner.receiveShadow = true;
  g.add(inner);

  state.tiles = [];
  for (let i = 0; i < 40; i++) {
    const [x, z] = tileWorld(i);
    const corner = i % 10 === 0;
    const w = TILE * (corner ? 0.98 : 0.92);
    const geo = new THREE.BoxGeometry(w, TH, w);
    const mat = new THREE.MeshStandardMaterial({
      color: 0x0e1830, roughness: 0.6, metalness: 0.1,
    });
    const mesh = new THREE.Mesh(geo, mat);
    mesh.position.set(x, TH / 2, z);
    mesh.castShadow = true;
    mesh.receiveShadow = true;
    mesh.userData.index = i;
    g.add(mesh);
    state.tiles.push(mesh);
  }
  // Merkez amblem (altın halka).
  const ring = new THREE.Mesh(
    new THREE.TorusGeometry(1.1, 0.16, 16, 60),
    new THREE.MeshStandardMaterial({ color: 0xE8B53A, metalness: 0.85, roughness: 0.25, emissive: 0x3a2a08 }),
  );
  ring.rotation.x = Math.PI / 2;
  ring.position.y = 0.45;
  ring.castShadow = true;
  g.add(ring);
  state.ring = ring;
}

// ---- Kare üstü doku (isim + fiyat + ikon + grup şeridi) ----
function hexColor(v) { return '#' + (v & 0xffffff).toString(16).padStart(6, '0'); }

function sideColorForKind(k) {
  switch (k) {
    case 'ring': return '#8390a0';
    case 'utility': return '#c9a23a';
    case 'tax': return '#b04a58';
    case 'card': return '#3a8b73';
    case 'corner': return '#E8B53A';
    default: return '#46506a';
  }
}

function wrapText(ctx, text, cx, y, maxW, lh) {
  const words = text.split(' ');
  let line = '';
  const lines = [];
  for (const w of words) {
    const test = line ? line + ' ' + w : w;
    if (ctx.measureText(test).width > maxW && line) { lines.push(line); line = w; }
    else line = test;
  }
  if (line) lines.push(line);
  const start = y - ((lines.length - 1) * lh) / 2;
  lines.forEach((l, i) => ctx.fillText(l, cx, start + i * lh));
}

function rotForIndex(i) {
  const [r, c] = cell(i);
  if (r === 10) return 0;            // alt sıra
  if (c === 0) return Math.PI / 2;   // sol sütun
  if (r === 0) return Math.PI;       // üst sıra
  return -Math.PI / 2;               // sağ sütun
}

function topTexture(t, index) {
  const cv = document.createElement('canvas');
  cv.width = 256; cv.height = 256;
  const x = cv.getContext('2d');
  x.fillStyle = '#0e1830';
  x.fillRect(0, 0, 256, 256);
  // grup / tür şeridi (üstte)
  x.fillStyle = t.g != null ? hexColor(t.g) : sideColorForKind(t.k);
  x.fillRect(0, 0, 256, 60);
  // ikon
  x.textAlign = 'center';
  x.textBaseline = 'middle';
  x.font = '96px serif';
  x.fillText(t.ic || '', 128, 130);
  // isim
  x.fillStyle = '#eef1f8';
  x.font = 'bold 26px sans-serif';
  wrapText(x, t.n || '', 128, 196, 232, 28);
  // fiyat
  if (t.p) {
    x.fillStyle = '#ffd98a';
    x.font = 'bold 30px sans-serif';
    x.fillText(t.p + '₭', 128, 240);
  }
  const tex = new THREE.CanvasTexture(cv);
  tex.colorSpace = THREE.SRGBColorSpace;
  tex.anisotropy = 8;
  tex.center.set(0.5, 0.5);
  tex.rotation = rotForIndex(index);
  return tex;
}

function textureTile(mesh, t) {
  const dark = new THREE.MeshStandardMaterial({ color: 0x0e1830, roughness: 0.6, metalness: 0.1 });
  const top = new THREE.MeshStandardMaterial({
    map: topTexture(t, mesh.userData.index), roughness: 0.5, metalness: 0.1,
  });
  // BoxGeometry yüz sırası: +x,-x,+y,-y,+z,-z → üst = index 2
  mesh.material = [dark, dark, top, dark, dark, dark];
  mesh.userData.mats = [dark, top];
  mesh.userData.textured = true;
}

function tokenMesh(color) {
  const grp = new THREE.Group();
  const mat = new THREE.MeshStandardMaterial({ color, metalness: 0.7, roughness: 0.3 });
  const base = new THREE.Mesh(new THREE.CylinderGeometry(0.22, 0.28, 0.12, 24), mat);
  base.position.y = 0.06;
  const body = new THREE.Mesh(new THREE.CylinderGeometry(0.1, 0.2, 0.4, 24), mat);
  body.position.y = 0.34;
  const head = new THREE.Mesh(new THREE.SphereGeometry(0.18, 24, 16), mat);
  head.position.y = 0.64;
  for (const m of [base, body, head]) { m.castShadow = true; grp.add(m); }
  return grp;
}

function setState(json) {
  let data;
  try { data = typeof json === 'string' ? JSON.parse(json) : json; }
  catch (e) { console.error('itupoly3d setState parse', e); return; }
  if (!state.scene) return;

  // Kareler: doku (bir kez) + sahiplik vurgusu + ipotek alçalması.
  for (let i = 0; i < 40 && i < (data.tiles || []).length; i++) {
    const t = data.tiles[i];
    const m = state.tiles[i];
    if (!m) continue;
    if (!m.userData.textured && t.n != null) textureTile(m, t);
    const mats = m.userData.mats || [m.material];
    for (const mat of mats) {
      if (t.o != null) {
        mat.emissive.setHex(t.o);
        mat.emissiveIntensity = 0.45;
      } else {
        mat.emissiveIntensity = 0.0;
      }
    }
    m.position.y = t.m ? TH * 0.35 : TH / 2;
    updateBuildings(i, t);
  }
  state.currentId = data.cur;

  // Token'lar.
  const present = new Set();
  for (const p of (data.players || [])) {
    if (p.b) { removeToken(p.id); continue; }
    present.add(p.id);
    let tk = state.tokens[p.id];
    if (!tk) {
      tk = tokenMesh(p.c);
      tk.userData = { idx: p.pos, queue: [], seg: null, offset: clusterOffset(p.id) };
      const [x, z] = tileWorld(p.pos);
      tk.position.set(x + tk.userData.offset.x, TH, z + tk.userData.offset.z);
      state.scene.add(tk);
      state.tokens[p.id] = tk;
    }
    tk.userData.offset = clusterOffset(p.id);
    // Hedef indeks değiştiyse yol noktaları kuyruğu (kare kare hop).
    if (tk.userData.idx !== p.pos) {
      tk.userData.queue.push(...pathCells(tk.userData.idx, p.pos));
      tk.userData.idx = p.pos;
    }
  }
  for (const id of Object.keys(state.tokens)) {
    if (!present.has(Number(id))) removeToken(Number(id));
  }

  // Kamera takip hedefi (aktif oyuncu).
  if (data.current != null) {
    const [x, z] = tileWorld(data.current);
    state.followTarget.set(x, 0.3, z);
  }
}

function clusterOffset(id) {
  const col = (id % 3) - 1;
  const row = Math.floor(id / 3) - 0.5;
  return new THREE.Vector3(col * 0.22, 0, row * 0.22);
}

function pathCells(from, to) {
  const fwd = ((to - from) % 40 + 40) % 40;
  const step = fwd <= 20 ? 1 : -1;
  const n = step === 1 ? fwd : 40 - fwd;
  const cells = [];
  let cur = from;
  for (let k = 0; k < n; k++) {
    cur = ((cur + step) % 40 + 40) % 40;
    cells.push(cur);
  }
  return cells;
}

function removeToken(id) {
  const tk = state.tokens[id];
  if (tk) { state.scene.remove(tk); delete state.tokens[id]; }
}

function updateBuildings(i, t) {
  const key = String(i);
  if (state.buildings[key]) { state.scene.remove(state.buildings[key]); delete state.buildings[key]; }
  const h = t.h || 0;
  if (h <= 0) return;
  const [x, z] = tileWorld(i);
  const grp = new THREE.Group();
  if (h === 5) {
    const hotel = new THREE.Mesh(
      new THREE.BoxGeometry(0.34, 0.5, 0.34),
      new THREE.MeshStandardMaterial({ color: 0xE8B53A, metalness: 0.6, roughness: 0.3, emissive: 0x2a1d05 }),
    );
    hotel.position.set(x, TH + 0.25, z);
    hotel.castShadow = true;
    grp.add(hotel);
  } else {
    for (let k = 0; k < h; k++) {
      const house = new THREE.Mesh(
        new THREE.BoxGeometry(0.16, 0.22, 0.16),
        new THREE.MeshStandardMaterial({ color: 0x2DD4A7, roughness: 0.5 }),
      );
      house.position.set(x - 0.22 + k * 0.15, TH + 0.11, z - 0.28);
      house.castShadow = true;
      grp.add(house);
    }
  }
  state.scene.add(grp);
  state.buildings[key] = grp;
}

function animate() {
  state.raf = requestAnimationFrame(animate);
  const dt = 0.016;
  const time = performance.now() * 0.001;
  if (state.ring) state.ring.rotation.z += 0.005; // yavaş dönüş
  for (const id of Object.keys(state.tokens)) {
    const tk = state.tokens[id];
    const off = tk.userData.offset || new THREE.Vector3();

    // Yeni segment başlat.
    if (!tk.userData.seg && tk.userData.queue.length) {
      const next = tk.userData.queue.shift();
      const [tx, tz] = tileWorld(next);
      tk.userData.seg = {
        fromX: tk.position.x, fromZ: tk.position.z,
        toX: tx + off.x, toZ: tz + off.z, t: 0,
      };
    }

    const seg = tk.userData.seg;
    if (seg) {
      seg.t = Math.min(1, seg.t + dt * 6.0); // ~1 kare/0.17s
      const e = seg.t;
      tk.position.x = seg.fromX + (seg.toX - seg.fromX) * e;
      tk.position.z = seg.fromZ + (seg.toZ - seg.fromZ) * e;
      tk.position.y = TH + Math.sin(e * Math.PI) * 0.4; // hop yayı
      if (seg.t >= 1) {
        tk.position.y = TH;
        tk.userData.seg = null;
      }
    } else {
      // Dinlenirken hedef kareye otur; aktif token hafif nefes alır.
      const [tx, tz] = tileWorld(tk.userData.idx);
      tk.position.x += (tx + off.x - tk.position.x) * 0.2;
      tk.position.z += (tz + off.z - tk.position.z) * 0.2;
      const bob = Number(id) === state.currentId
        ? Math.abs(Math.sin(time * 2.5)) * 0.09
        : 0;
      tk.position.y += (TH + bob - tk.position.y) * 0.25;
    }
  }

  if (state.controls) {
    state.controls.target.lerp(state.followTarget, 0.06);
    state.controls.update();
  }
  state.renderer.render(state.scene, state.camera);
}

function attach(hostOrId) {
  // Flutter platform view'ı shadow DOM içinde olabildiğinden eleman
  // referansını doğrudan alırız; string verilirse id ile ararız.
  const host = (hostOrId && hostOrId.nodeType === 1)
    ? hostOrId
    : document.getElementById(hostOrId);
  if (!host) { console.error('itupoly3d host yok:', hostOrId); return; }
  if (state.host) dispose();
  state.host = host;

  const scene = new THREE.Scene();
  state.scene = scene;

  const w = host.clientWidth || 600;
  const h = host.clientHeight || 600;
  const cam = new THREE.PerspectiveCamera(42, w / h, 0.1, 100);
  cam.position.set(0, 11, 12.5);
  state.camera = cam;

  state.renderer = makeRenderer(host);
  state.renderer.setSize(w, h, false);

  // Işıklar.
  scene.add(new THREE.HemisphereLight(0xbcd0ff, 0x0b1220, 0.9));
  const key = new THREE.DirectionalLight(0xfff2d0, 1.25);
  key.position.set(6, 14, 6);
  key.castShadow = true;
  key.shadow.mapSize.set(2048, 2048);
  key.shadow.camera.near = 1; key.shadow.camera.far = 50;
  key.shadow.camera.left = -10; key.shadow.camera.right = 10;
  key.shadow.camera.top = 10; key.shadow.camera.bottom = -10;
  scene.add(key);
  const fill = new THREE.DirectionalLight(0x8ab4ff, 0.4);
  fill.position.set(-8, 6, -4);
  scene.add(fill);

  const controls = new OrbitControls(cam, state.renderer.domElement);
  controls.enableDamping = true;
  controls.dampingFactor = 0.08;
  controls.minDistance = 6;
  controls.maxDistance = 26;
  controls.maxPolarAngle = Math.PI * 0.46; // çok yatay olmasın
  controls.target.set(0, 0, 0);
  state.controls = controls;

  buildBoard(null);

  // Merkez İTÜpoly amblemi (Flutter bundled asset).
  new THREE.TextureLoader().load(
    'assets/assets/images/emblem.png',
    (tex) => {
      tex.colorSpace = THREE.SRGBColorSpace;
      const plane = new THREE.Mesh(
        new THREE.PlaneGeometry(2.6, 2.6),
        new THREE.MeshBasicMaterial({ map: tex, transparent: true }),
      );
      plane.rotation.x = -Math.PI / 2;
      plane.position.y = 0.08;
      scene.add(plane);
      state.logo = plane;
    },
    undefined,
    () => { /* asset yoksa altın halka yeterli */ },
  );

  if (window.__itupolyPendingState) {
    setState(window.__itupolyPendingState);
    window.__itupolyPendingState = null;
  }

  // Tap raycast (sürükleme değilse).
  const ray = new THREE.Raycaster();
  const ndc = new THREE.Vector2();
  const dom = state.renderer.domElement;
  dom.addEventListener('pointerdown', (e) => {
    state.lastDown = { x: e.clientX, y: e.clientY, t: performance.now() };
  });
  dom.addEventListener('pointerup', (e) => {
    const d = state.lastDown;
    if (!d) return;
    const moved = Math.hypot(e.clientX - d.x, e.clientY - d.y);
    if (moved > 8 || performance.now() - d.t > 500) return; // sürükleme
    const rect = dom.getBoundingClientRect();
    ndc.x = ((e.clientX - rect.left) / rect.width) * 2 - 1;
    ndc.y = -((e.clientY - rect.top) / rect.height) * 2 + 1;
    ray.setFromCamera(ndc, state.camera);
    const hits = ray.intersectObjects(state.tiles, false);
    if (hits.length && window.itupolyOnTapTile) {
      window.itupolyOnTapTile(hits[0].object.userData.index);
    }
  });

  // Yeniden boyutlandırma.
  state.ro = new ResizeObserver(() => {
    const nw = host.clientWidth, nh = host.clientHeight;
    if (nw && nh) {
      state.camera.aspect = nw / nh;
      state.camera.updateProjectionMatrix();
      state.renderer.setSize(nw, nh, false);
    }
  });
  state.ro.observe(host);

  animate();
  console.log('itupoly3d attached', w, h);
}

function dispose() {
  if (state.raf) cancelAnimationFrame(state.raf);
  if (state.ro) state.ro.disconnect();
  if (state.renderer) {
    state.renderer.dispose();
    if (state.renderer.domElement && state.renderer.domElement.parentNode) {
      state.renderer.domElement.parentNode.removeChild(state.renderer.domElement);
    }
  }
  state.renderer = null; state.scene = null; state.camera = null;
  state.controls = null; state.tiles = []; state.tokens = {}; state.buildings = {};
  state.host = null;
}

window.Itupoly3D = {
  attach,
  dispose,
  setState: (json) => {
    if (!state.scene) { window.__itupolyPendingState = json; return; }
    setState(json);
  },
};
