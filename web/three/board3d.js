// İTÜpoly — gerçek 3B tahta (three.js / WebGL).
// Flutter tarafından HtmlElementView içine mount edilir; state Dart'tan
// setState(json) ile gelir, tile tıklaması window.itupolyOnTapTile(index) ile
// Dart'a döner.
import * as THREE from 'three';

const TILE = 1.0;       // kare boyutu (dünya birimi)
const TH = 0.22;        // kare yüksekliği
const GRID = 11;
const HALF = (GRID - 1) / 2;

// index -> (row,col)
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

function clusterOffset(playerId) {
  const idx = (playerId || 0) % 6;
  const r = 0.38;
  const angle = (idx * Math.PI * 2) / 6;
  return new THREE.Vector3(Math.cos(angle) * r, 0, Math.sin(angle) * r);
}

const state = {
  renderer: null, scene: null, camera: null,
  raf: null, tiles: [], buildings: {}, tokens: {}, host: null,
  followTarget: new THREE.Vector3(0, 0, 0),
  cameraTarget: new THREE.Vector3(0, 0, 0), // 100% programmatic target
  ro: null, lastDown: null, currentId: null, currentTileIndex: 0,
  actionIndicator: null,
  currentIndicatorType: null,
  introTime: 2.8,
  
  // Custom 3D Dice states
  dice1: null, dice2: null,
  diceRolling: false,
  diceRollTime: 0,
  diceLandingHoldTime: 0.0,
  diceData: { d1: 1, d2: 1, lastRn: -1 },
  wasAnimating: false, // Sahne hareketten durağana geçişi izler → 'idle' sinyali
  dicePos1: new THREE.Vector3(-0.6, 0.16, 0),
  dicePos2: new THREE.Vector3(0.6, 0.16, 0),
  diceVel1: new THREE.Vector3(),
  diceVel2: new THREE.Vector3(),
  diceRot1: new THREE.Euler(),
  diceRot2: new THREE.Euler(),
  diceAng1: new THREE.Vector3(),
  diceAng2: new THREE.Vector3(),

  // Building drop animations and particles
  buildingAnimData: {}, // i -> {targetH, currentH, posY, velY, elasticBounce}
  particles: [], // list of {mesh, vel, life, maxLife}

  // Cash transfer animations
  cashBills: [], // list of {mesh, fromPos, toPos, t}

  // Camera effects
  shakeTime: 0,
  shakeIntensity: 0,

  // Victory Gold Rain
  victoryRain: false,
  coins: [], // list of {mesh, vel, spin}
  
  // Flash lights for jail
  jailFlashing: false,
  jailFlashTimer: 0,
  keyLight: null,
  fillLight: null,
  ambientLight: null,
  originalLights: {}
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

// Generate rounded canvas texture for dice faces
function createDiceTexture(pips) {
  const canvas = document.createElement('canvas');
  canvas.width = 128;
  canvas.height = 128;
  const ctx = canvas.getContext('2d');

  // Background (Soft White / Cream / Golden border)
  ctx.fillStyle = '#fffdf6';
  ctx.fillRect(0, 0, 128, 128);

  ctx.strokeStyle = '#d4af37'; // Golden border
  ctx.lineWidth = 6;
  ctx.strokeRect(3, 3, 122, 122);

  // Draw pips (Black circles)
  ctx.fillStyle = '#231f20';
  const radius = 10;
  const positions = {
    1: [[64, 64]],
    2: [[34, 34], [94, 94]],
    3: [[34, 34], [64, 64], [94, 94]],
    4: [[34, 34], [94, 34], [34, 94], [94, 94]],
    5: [[34, 34], [94, 34], [64, 64], [34, 94], [94, 94]],
    6: [[34, 34], [94, 34], [34, 64], [94, 64], [34, 94], [94, 94]],
  };

  const p = positions[pips] || [];
  for (const pos of p) {
    ctx.beginPath();
    ctx.arc(pos[0], pos[1], radius, 0, Math.PI * 2);
    ctx.fill();
  }

  const tex = new THREE.CanvasTexture(canvas);
  tex.colorSpace = THREE.SRGBColorSpace;
  return tex;
}

function createDieMaterial() {
  const mats = [];
  const faceValues = [4, 3, 1, 6, 2, 5];
  for (let i = 0; i < 6; i++) {
    mats.push(new THREE.MeshStandardMaterial({
      map: createDiceTexture(faceValues[i]),
      roughness: 0.1,
      metalness: 0.1,
    }));
  }
  return mats;
}

function buildBoard(tiles) {
  const g = state.scene;
  // Masa zemini.
  const baseGeo = new THREE.BoxGeometry(GRID + 1.2, 0.5, GRID + 1.2);
  const baseMat = new THREE.MeshStandardMaterial({ color: 0xe0e4eb, roughness: 0.85, metalness: 0.1 });
  const base = new THREE.Mesh(baseGeo, baseMat);
  base.position.y = -0.25;
  base.receiveShadow = true;
  g.add(base);

  // İç oyun alanı panel.
  const innerGeo = new THREE.BoxGeometry(GRID - 1.6, 0.05, GRID - 1.6);
  const innerMat = new THREE.MeshStandardMaterial({ color: 0xe9ebf0, roughness: 0.9 });
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
      color: 0xffffff, roughness: 0.6, metalness: 0.1,
    });
    const mesh = new THREE.Mesh(geo, mat);
    mesh.position.set(x, TH / 2, z);
    mesh.castShadow = true;
    mesh.receiveShadow = true;
    mesh.userData.index = i;
    g.add(mesh);
    state.tiles.push(mesh);
  }

  // --- Çimenlik Merkez Yerleşke Tasarımı ---
  const lawnGeo = new THREE.BoxGeometry(3.6, 0.02, 3.6);
  const lawnMat = new THREE.MeshStandardMaterial({ color: 0x1f5c22, roughness: 0.95 });
  const lawn = new THREE.Mesh(lawnGeo, lawnMat);
  lawn.position.set(0, 0.03, 0);
  lawn.receiveShadow = true;
  g.add(lawn);

  // 3B Zarlar
  const dieGeo = new THREE.BoxGeometry(0.32, 0.32, 0.32);
  const dieMat = createDieMaterial();
  
  state.dice1 = new THREE.Mesh(dieGeo, dieMat);
  state.dice1.castShadow = true;
  state.dice1.position.copy(state.dicePos1);
  state.dice1.visible = false;
  g.add(state.dice1);

  state.dice2 = new THREE.Mesh(dieGeo, dieMat);
  state.dice2.castShadow = true;
  state.dice2.position.copy(state.dicePos2);
  state.dice2.visible = false;
  g.add(state.dice2);
}

// ---- Kare üstü doku ----
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
  x.fillStyle = '#ffffff';
  x.fillRect(0, 0, 256, 256);
  // grup / tür şeridi (üstte)
  x.fillStyle = t.g != null ? hexColor(t.g) : sideColorForKind(t.k);
  x.fillRect(0, 0, 256, 60);
  // ikon
  x.textAlign = 'center';
  x.textBaseline = 'middle';
  x.fillStyle = '#1a202c';
  x.font = '84px MaterialIcons';
  x.fillText(t.ic || '', 128, 130);
  // isim
  x.fillStyle = '#0b1220';
  x.font = 'bold 26px sans-serif';
  wrapText(x, t.n || '', 128, 196, 232, 28);
  // fiyat
  if (t.p) {
    x.fillStyle = '#2d3748';
    x.font = 'bold 30px sans-serif';
    x.fillText(t.p + '₺', 128, 240);
  }
  const tex = new THREE.CanvasTexture(cv);
  tex.colorSpace = THREE.SRGBColorSpace;
  tex.anisotropy = 8;
  tex.center.set(0.5, 0.5);
  tex.rotation = rotForIndex(index);
  return tex;
}

function textureTile(mesh, t) {
  const dark = new THREE.MeshStandardMaterial({ color: 0xffffff, roughness: 0.6, metalness: 0.1 });
  const top = new THREE.MeshStandardMaterial({
    map: topTexture(t, mesh.userData.index), roughness: 0.5, metalness: 0.1,
  });
  mesh.material = [dark, dark, top, dark, dark, dark];
  mesh.userData.mats = [dark, top];
  mesh.userData.textured = true;
}

// Procedural İTÜ Custom Pawns / Tokens
function createCustomPawn(type, color) {
  const grp = new THREE.Group();
  
  // Common metallic base
  const baseMat = new THREE.MeshStandardMaterial({ color, metalness: 0.8, roughness: 0.2 });
  const base = new THREE.Mesh(new THREE.CylinderGeometry(0.18, 0.22, 0.05, 16), baseMat);
  base.position.y = 0.025;
  base.castShadow = true;
  base.receiveShadow = true;
  grp.add(base);

  const mat = new THREE.MeshStandardMaterial({ color, metalness: 0.85, roughness: 0.15 });

  if (type === 'ari') {
    // 🐝 İTÜ Arısı
    const bee = new THREE.Group();
    bee.position.y = 0.24;
    
    const body = new THREE.Mesh(new THREE.SphereGeometry(0.14, 16, 16), mat);
    body.scale.set(1, 1, 1.4);
    body.castShadow = true;
    bee.add(body);
    
    const stripeMat = new THREE.MeshStandardMaterial({ color: 0x111111, metalness: 0.5, roughness: 0.3 });
    const s1 = new THREE.Mesh(new THREE.CylinderGeometry(0.142, 0.142, 0.04, 12), stripeMat);
    s1.rotation.x = Math.PI / 2;
    s1.position.z = 0.05;
    const s2 = s1.clone();
    s2.position.z = -0.05;
    bee.add(s1);
    bee.add(s2);

    const wingMat = new THREE.MeshStandardMaterial({ color: 0xffffff, transparent: true, opacity: 0.7, roughness: 0.1 });
    const w1 = new THREE.Mesh(new THREE.SphereGeometry(0.06, 12, 12), wingMat);
    w1.scale.set(1.5, 0.2, 0.8);
    w1.position.set(0.12, 0.1, 0);
    w1.rotation.z = Math.PI / 6;
    const w2 = w1.clone();
    w2.position.x = -0.12;
    w2.rotation.z = -Math.PI / 6;
    bee.add(w1);
    bee.add(w2);

    const head = new THREE.Mesh(new THREE.SphereGeometry(0.08, 12, 12), mat);
    head.position.set(0, 0.05, 0.18);
    bee.add(head);

    grp.add(bee);

  } else if (type === 'pergel') {
    // 🎓 Kep
    const cap = new THREE.Group();
    cap.position.y = 0.05;

    const skull = new THREE.Mesh(new THREE.CylinderGeometry(0.13, 0.13, 0.14, 16), mat);
    skull.position.y = 0.07;
    skull.castShadow = true;
    cap.add(skull);

    const board = new THREE.Mesh(new THREE.BoxGeometry(0.32, 0.02, 0.32), mat);
    board.position.y = 0.15;
    board.rotation.y = Math.PI / 4;
    board.castShadow = true;
    cap.add(board);

    const tasselMat = new THREE.MeshStandardMaterial({ color: 0xffd700, metalness: 0.9, roughness: 0.1 });
    const tassel = new THREE.Mesh(new THREE.BoxGeometry(0.02, 0.1, 0.02), tasselMat);
    tassel.position.set(0.12, 0.1, 0.1);
    cap.add(tassel);

    grp.add(cap);

  } else if (type === 'baret') {
    // 🪖 Baret
    const helmet = new THREE.Group();
    helmet.position.y = 0.05;

    const helmetMat = new THREE.MeshStandardMaterial({ color: 0xffcc00, metalness: 0.6, roughness: 0.2 });
    const dome = new THREE.Mesh(new THREE.SphereGeometry(0.15, 16, 12, 0, Math.PI * 2, 0, Math.PI / 2), helmetMat);
    dome.position.y = 0.02;
    dome.castShadow = true;
    helmet.add(dome);

    const brim = new THREE.Mesh(new THREE.CylinderGeometry(0.18, 0.18, 0.015, 16), helmetMat);
    brim.scale.set(1.0, 1.0, 1.25);
    brim.position.y = 0.01;
    helmet.add(brim);

    grp.add(helmet);

  } else if (type === 'kahve') {
    // ☕ Çay Bardağı
    const cup = new THREE.Group();
    cup.position.y = 0.05;

    const saucer = new THREE.Mesh(new THREE.CylinderGeometry(0.2, 0.16, 0.03, 16), new THREE.MeshStandardMaterial({ color: 0xffffff, roughness: 0.3 }));
    saucer.position.y = 0.015;
    saucer.castShadow = true;
    cup.add(saucer);

    const glassMat = new THREE.MeshStandardMaterial({
      color: 0xffffff, transparent: true, opacity: 0.35, metalness: 0.9, roughness: 0.1
    });
    const glass = new THREE.Mesh(new THREE.CylinderGeometry(0.14, 0.09, 0.28, 16), glassMat);
    glass.position.y = 0.155;
    glass.castShadow = true;
    cup.add(glass);

    const teaMat = new THREE.MeshStandardMaterial({ color: 0x8a1309, roughness: 0.2, metalness: 0.1 });
    const tea = new THREE.Mesh(new THREE.CylinderGeometry(0.11, 0.08, 0.18, 16), teaMat);
    tea.position.y = 0.11;
    cup.add(tea);

    grp.add(cup);

  } else if (type === 'hesapMakinesi') {
    // 🧮 Hesap Makinesi
    const calc = new THREE.Group();
    calc.position.y = 0.05;

    const bodyMat = new THREE.MeshStandardMaterial({ color: 0x555555, roughness: 0.5, metalness: 0.2 });
    const body = new THREE.Mesh(new THREE.BoxGeometry(0.18, 0.28, 0.05), bodyMat);
    body.rotation.x = -Math.PI / 4;
    body.position.y = 0.11;
    body.castShadow = true;
    calc.add(body);

    const screenMat = new THREE.MeshStandardMaterial({ color: 0xaaffbb, emissive: 0x22aa33, emissiveIntensity: 0.4, roughness: 0.1 });
    const screen = new THREE.Mesh(new THREE.BoxGeometry(0.14, 0.06, 0.01), screenMat);
    screen.position.set(0, 0.17, 0.06);
    screen.rotation.x = -Math.PI / 4;
    calc.add(screen);

    grp.add(calc);

  } else if (type === 'devreKarti') {
    // 💳 İstanbulkart
    const card = new THREE.Group();
    card.position.y = 0.05;

    const holder = new THREE.Mesh(new THREE.BoxGeometry(0.15, 0.03, 0.08), new THREE.MeshStandardMaterial({ color: 0x222222 }));
    holder.position.y = 0.015;
    card.add(holder);

    const cardMat = new THREE.MeshStandardMaterial({ color: 0x1060b0, roughness: 0.4, metalness: 0.1 });
    const cMesh = new THREE.Mesh(new THREE.BoxGeometry(0.18, 0.26, 0.015), cardMat);
    cMesh.position.set(0, 0.14, 0);
    cMesh.rotation.y = Math.PI / 12;
    cMesh.castShadow = true;
    card.add(cMesh);

    const logoMat = new THREE.MeshStandardMaterial({ color: 0xffd700, roughness: 0.3 });
    const logo = new THREE.Mesh(new THREE.BoxGeometry(0.12, 0.04, 0.005), logoMat);
    logo.position.set(-0.02, 0.18, 0.01);
    logo.rotation.y = Math.PI / 12;
    card.add(logo);

    grp.add(card);

  } else {
    const fallback = tokenMesh(color);
    grp.add(fallback);
  }

  return grp;
}

// Fallback tokenMesh
function tokenMesh(color) {
  const grp = new THREE.Group();
  const mat = new THREE.MeshStandardMaterial({ color, metalness: 0.7, roughness: 0.3 });
  const base = new THREE.Mesh(new THREE.CylinderGeometry(0.16, 0.20, 0.08, 16), mat);
  base.position.y = 0.04;
  const body = new THREE.Mesh(new THREE.CylinderGeometry(0.08, 0.16, 0.3, 16), mat);
  body.position.y = 0.23;
  const head = new THREE.Mesh(new THREE.SphereGeometry(0.13, 16, 12), mat);
  head.position.y = 0.45;
  for (const m of [base, body, head]) { m.castShadow = true; grp.add(m); }
  return grp;
}

function spawnDust(x, y, z) {
  const pCount = 12;
  const leavesMat = new THREE.MeshStandardMaterial({
    color: 0xdddddd, transparent: true, opacity: 0.8, roughness: 0.9
  });
  for (let i = 0; i < pCount; i++) {
    const geo = new THREE.BoxGeometry(0.04 + Math.random() * 0.04, 0.04 + Math.random() * 0.04, 0.04 + Math.random() * 0.04);
    const m = new THREE.Mesh(geo, leavesMat);
    m.position.set(x + (Math.random() - 0.5) * 0.4, y, z + (Math.random() - 0.5) * 0.4);
    state.scene.add(m);
    
    state.particles.push({
      mesh: m,
      vel: new THREE.Vector3((Math.random() - 0.5) * 1.5, 0.5 + Math.random() * 1.5, (Math.random() - 0.5) * 1.5),
      life: 0,
      maxLife: 30 + Math.floor(Math.random() * 20)
    });
  }
}

function spawnCashBills(fromPos, toPos) {
  const billCount = 8;
  const billMat = new THREE.MeshStandardMaterial({ color: 0x4caf50, roughness: 0.5, side: THREE.DoubleSide });
  const billGeo = new THREE.BoxGeometry(0.16, 0.01, 0.08);

  for (let i = 0; i < billCount; i++) {
    const mesh = new THREE.Mesh(billGeo, billMat);
    mesh.position.copy(fromPos);
    mesh.rotation.set(Math.random() * Math.PI, Math.random() * Math.PI, 0);
    state.scene.add(mesh);

    state.cashBills.push({
      mesh: mesh,
      from: fromPos.clone(),
      to: toPos.clone(),
      t: -i * 0.12,
      rotSpeed: new THREE.Vector3(Math.random() * 5, Math.random() * 5, 0)
    });
  }
}

function triggerScreenShake(intensity = 0.15) {
  state.shakeTime = 30;
  state.shakeIntensity = intensity;
}

function triggerVictoryRain() {
  state.victoryRain = true;
}

function spawnVictoryCoin() {
  const coinMat = new THREE.MeshStandardMaterial({ color: 0xffd700, metalness: 0.9, roughness: 0.1 });
  const coinGeo = new THREE.CylinderGeometry(0.08, 0.08, 0.02, 12);
  const mesh = new THREE.Mesh(coinGeo, coinMat);
  mesh.castShadow = true;
  
  const rx = (Math.random() - 0.5) * 8.0;
  const rz = (Math.random() - 0.5) * 8.0;
  mesh.position.set(rx, 6.0, rz);
  state.scene.add(mesh);
  
  state.coins.push({
    mesh: mesh,
    vel: new THREE.Vector3((Math.random() - 0.5) * 0.5, -3.0 - Math.random() * 3.0, (Math.random() - 0.5) * 0.5),
    spin: new THREE.Vector3(Math.random() * 4, Math.random() * 4, Math.random() * 4)
  });
}

function createJailCage(x, z) {
  const cage = new THREE.Group();
  const mat = new THREE.MeshStandardMaterial({ color: 0x333333, metalness: 0.9, roughness: 0.2 });
  
  const barGeo = new THREE.CylinderGeometry(0.02, 0.02, 0.6, 8);
  const positions = [
    [-0.2, -0.2], [0.2, -0.2], [-0.2, 0.2], [0.2, 0.2]
  ];
  for (const p of positions) {
    const bar = new THREE.Mesh(barGeo, mat);
    bar.position.set(x + p[0], TH + 0.3, z + p[1]);
    bar.castShadow = true;
    cage.add(bar);
  }
  
  const capGeo = new THREE.BoxGeometry(0.44, 0.03, 0.44);
  const capTop = new THREE.Mesh(capGeo, mat);
  capTop.position.set(x, TH + 0.6, z);
  capTop.castShadow = true;
  cage.add(capTop);

  return cage;
}

function rollDice(d1, d2) {
  state.diceData.d1 = d1;
  state.diceData.d2 = d2;
  state.diceRolling = true;
  state.diceRollTime = 0;
  state.diceLandingHoldTime = 0.0;

  state.dice1.visible = true;
  state.dice2.visible = true;

  state.dice1.position.set(-0.5 + (Math.random() - 0.5) * 0.4, 6.0, 0.3 + (Math.random() - 0.5) * 0.4);
  state.dice2.position.set(0.5 + (Math.random() - 0.5) * 0.4, 6.5, -0.3 + (Math.random() - 0.5) * 0.4);

  state.diceVel1.set((Math.random() - 0.5) * 3.0, -3.5, (Math.random() - 0.5) * 3.0);
  state.diceVel2.set((Math.random() - 0.5) * 3.0, -3.0, (Math.random() - 0.5) * 3.0);

  state.diceAng1.set(22 + Math.random() * 32, 22 + Math.random() * 32, 22 + Math.random() * 32);
  state.diceAng2.set(22 + Math.random() * 32, 22 + Math.random() * 32, 22 + Math.random() * 32);
}

function getTargetRotation(val) {
  switch (val) {
    case 1: return new THREE.Euler(0, 0, 0);
    case 6: return new THREE.Euler(Math.PI, 0, 0);
    case 2: return new THREE.Euler(-Math.PI / 2, 0, 0);
    case 5: return new THREE.Euler(Math.PI / 2, 0, 0);
    case 3: return new THREE.Euler(0, 0, Math.PI / 2);
    case 4: return new THREE.Euler(0, 0, -Math.PI / 2);
    default: return new THREE.Euler(0, 0, 0);
  }
}

function isAnyTokenMoving() {
  for (const id of Object.keys(state.tokens)) {
    const tk = state.tokens[id];
    if (tk && (tk.userData.seg || (tk.userData.queue && tk.userData.queue.length > 0))) {
      return true;
    }
  }
  return false;
}

function getIndicatorType(data) {
  const phase = data.phase;
  const currentTileIdx = data.current;
  if (currentTileIdx == null) return null;
  const tile = data.tiles[currentTileIdx];
  if (!tile) return null;

  if (phase === 'awaitBuyDecision') {
    return 'buy';
  }
  if (phase === 'mustLiquidate') {
    return 'rent';
  }
  if (phase === 'awaitRoll' || phase === 'inDisiplin') {
    return 'roll';
  }
  
  if (phase === 'endTurn') {
    if (tile.k === 'card') return 'card';
    if (tile.k === 'tax') return 'rent';
    if (tile.k === 'corner') {
      if (tile.n && tile.n.includes('Başla')) return 'go';
      if (tile.n && (tile.n.includes('Disiplin') || tile.n.includes('Sevk'))) return 'jail';
      if (tile.n && tile.n.includes('Çim')) return 'parking';
    }
    // If the landed tile is owned by someone else, show rent/tax (red arrow)
    if (tile.o != null && tile.o !== 0x000000) {
      const curPlayer = data.players.find(p => p.id === data.cur);
      if (curPlayer && tile.o !== curPlayer.c) {
        return 'rent';
      }
    }
  }
  return null;
}

function buildIndicatorMesh(type, group) {
  if (type === 'buy') {
    const coinMat = new THREE.MeshStandardMaterial({ color: 0xffd700, metalness: 0.9, roughness: 0.1, emissive: 0x3a2c00 });
    const coin = new THREE.Mesh(new THREE.CylinderGeometry(0.12, 0.12, 0.03, 16), coinMat);
    coin.rotation.x = Math.PI / 2;
    coin.castShadow = true;
    group.add(coin);
  } else if (type === 'rent') {
    const arrowMat = new THREE.MeshStandardMaterial({ color: 0xff3333, metalness: 0.5, roughness: 0.2, emissive: 0x440000 });
    const shaft = new THREE.Mesh(new THREE.CylinderGeometry(0.03, 0.03, 0.12, 10), arrowMat);
    shaft.position.y = 0.06;
    shaft.castShadow = true;
    const head = new THREE.Mesh(new THREE.ConeGeometry(0.08, 0.1, 10), arrowMat);
    head.position.y = -0.04;
    head.rotation.x = Math.PI; // point down
    head.castShadow = true;
    group.add(shaft);
    group.add(head);
  } else if (type === 'card') {
    const cardMat = new THREE.MeshStandardMaterial({ color: 0x00d2ff, metalness: 0.6, roughness: 0.2, emissive: 0x002e3b });
    const cardMesh = new THREE.Mesh(new THREE.BoxGeometry(0.14, 0.22, 0.012), cardMat);
    cardMesh.rotation.x = -Math.PI / 6;
    cardMesh.castShadow = true;
    group.add(cardMesh);
  } else if (type === 'jail') {
    const baseMat = new THREE.MeshStandardMaterial({ color: 0x222222, metalness: 0.8 });
    const domeMat = new THREE.MeshStandardMaterial({ color: 0xff0000, roughness: 0.1, metalness: 0.1, emissive: 0xff0000, emissiveIntensity: 0.5 });
    const sirenBase = new THREE.Mesh(new THREE.CylinderGeometry(0.08, 0.08, 0.02, 12), baseMat);
    sirenBase.castShadow = true;
    const sirenDome = new THREE.Mesh(new THREE.SphereGeometry(0.06, 12, 10, 0, Math.PI * 2, 0, Math.PI / 2), domeMat);
    sirenDome.position.y = 0.01;
    sirenDome.castShadow = true;
    group.add(sirenBase);
    group.add(sirenDome);
  } else if (type === 'roll') {
    const dieMat = new THREE.MeshStandardMaterial({ color: 0xffffff, roughness: 0.2, metalness: 0.05 });
    const d1 = new THREE.Mesh(new THREE.BoxGeometry(0.08, 0.08, 0.08), dieMat);
    const d2 = new THREE.Mesh(new THREE.BoxGeometry(0.08, 0.08, 0.08), dieMat);
    d1.position.set(-0.06, 0, 0);
    d2.position.set(0.06, 0.04, 0);
    d1.rotation.set(0.5, 0.5, 0);
    d2.rotation.set(-0.5, 0, 0.5);
    d1.castShadow = true;
    d2.castShadow = true;
    group.add(d1);
    group.add(d2);
  } else if (type === 'go') {
    const starMat = new THREE.MeshStandardMaterial({ color: 0xffd700, metalness: 0.8, roughness: 0.1, emissive: 0x3a2c00 });
    const pyramidGeo = new THREE.ConeGeometry(0.1, 0.18, 4);
    const p1 = new THREE.Mesh(pyramidGeo, starMat);
    const p2 = p1.clone();
    p2.rotation.x = Math.PI;
    p1.castShadow = true;
    p2.castShadow = true;
    group.add(p1);
    group.add(p2);
  } else if (type === 'parking') {
    const parkMat = new THREE.MeshStandardMaterial({ color: 0x1f8f30, roughness: 0.8, metalness: 0.05 });
    const t1 = new THREE.Mesh(new THREE.ConeGeometry(0.1, 0.16, 6), parkMat);
    t1.position.y = 0.05;
    t1.castShadow = true;
    const t2 = new THREE.Mesh(new THREE.ConeGeometry(0.08, 0.12, 6), parkMat);
    t2.position.y = 0.13;
    t2.castShadow = true;
    group.add(t1);
    group.add(t2);
  }
}

function setState(json) {
  let data;
  try { data = typeof json === 'string' ? JSON.parse(json) : json; }
  catch (e) { console.error('itupoly3d setState parse', e); return; }
  if (!state.scene) return;

  // Check if dice rolled
  if (data.rn != null && data.rn !== state.diceData.lastRn) {
    state.diceData.lastRn = data.rn;
    if (data.d1 > 0 && data.d2 > 0) {
      rollDice(data.d1, data.d2);
    }
  }

  // Detect bankruptcy screen shake
  let prevActiveCount = 0;
  for (const id of Object.keys(state.tokens)) prevActiveCount++;
  
  let currentActiveCount = 0;
  for (const p of (data.players || [])) {
    if (!p.b) currentActiveCount++;
  }
  if (prevActiveCount > 0 && currentActiveCount < prevActiveCount) {
    triggerScreenShake(0.24);
  }

  // Kareler: doku + sahiplik kaydı
  for (let i = 0; i < 40 && i < (data.tiles || []).length; i++) {
    const t = data.tiles[i];
    const m = state.tiles[i];
    if (!m) continue;
    m.userData.tileData = t; // Save tile data for redraw on font load
    if (!m.userData.textured && t.n != null) textureTile(m, t);
    
    // Save owner info for animate loop
    if (t.o != null) {
      m.userData.ownerEmissiveColor = t.o;
      m.userData.ownerEmissiveIntensity = 0.45;
    } else {
      m.userData.ownerEmissiveColor = 0x000000;
      m.userData.ownerEmissiveIntensity = 0.0;
    }
    m.userData.mortgaged = t.m;
    updateBuildings(i, t);
  }
  state.currentId = data.cur;

  // Token'lar.
  const present = new Set();
  let anyJailed = false;
  
  for (const p of (data.players || [])) {
    if (p.b) { removeToken(p.id); continue; }
    present.add(p.id);
    let tk = state.tokens[p.id];
    
    // Cash transfer
    if (tk && tk.userData.lastCash != null && tk.userData.lastCash !== p.cash) {
      const delta = p.cash - tk.userData.lastCash;
      tk.userData.lastCash = p.cash;
      if (delta < 0 && state.currentId === p.id) {
        const centerPos = new THREE.Vector3(0, TH, 0);
        spawnCashBills(tk.position, centerPos);
      }
    }
    
    if (!tk) {
      tk = createCustomPawn(p.t, p.c);
      tk.userData = { idx: p.pos, targetIdx: p.pos, queue: [], seg: null, offset: clusterOffset(p.id), lastCash: p.cash };
      const [x, z] = tileWorld(p.pos);
      tk.position.set(x + tk.userData.offset.x, TH, z + tk.userData.offset.z);
      state.scene.add(tk);
      state.tokens[p.id] = tk;
    }
    
    // Jail bars
    if (p.j) {
      anyJailed = true;
      if (!tk.userData.jailCage) {
        const [x, z] = tileWorld(p.pos);
        tk.userData.jailCage = createJailCage(x, z);
        state.scene.add(tk.userData.jailCage);
        state.jailFlashing = true;
      }
    } else {
      if (tk.userData.jailCage) {
        state.scene.remove(tk.userData.jailCage);
        tk.userData.jailCage = null;
      }
    }

    tk.userData.offset = clusterOffset(p.id);
    if (tk.userData.targetIdx === undefined) {
      tk.userData.targetIdx = tk.userData.idx || p.pos;
    }
    if (tk.userData.targetIdx !== p.pos) {
      const startFrom = tk.userData.targetIdx;
      tk.userData.queue.push(...pathCells(startFrom, p.pos));
      tk.userData.targetIdx = p.pos;
    }
  }
  
  for (const id of Object.keys(state.tokens)) {
    if (!present.has(Number(id))) removeToken(Number(id));
  }
  
  state.jailFlashing = anyJailed;

  // Takip hedefi
  if (data.current != null) {
    const [x, z] = tileWorld(data.current);
    state.followTarget.set(x, 0.3, z);
    state.currentTileIndex = data.current; // Save current index
  }

  if (data.winnerId != null) {
    triggerVictoryRain();
  }

  // Update current action indicator type
  const indicatorType = getIndicatorType(data);
  if (indicatorType !== state.currentIndicatorType) {
    state.currentIndicatorType = indicatorType;
    if (state.actionIndicator) {
      // Clear old children
      while (state.actionIndicator.children.length > 0) {
        state.actionIndicator.remove(state.actionIndicator.children[0]);
      }
      
      if (indicatorType) {
        buildIndicatorMesh(indicatorType, state.actionIndicator);
      }
    }
  }
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
  if (tk) {
    if (tk.userData.jailCage) state.scene.remove(tk.userData.jailCage);
    state.scene.remove(tk);
    delete state.tokens[id];
  }
}

function updateBuildings(i, t) {
  const key = String(i);
  const h = t.h || 0;
  
  const anim = state.buildingAnimData[key];
  const targetH = h;
  const currentH = anim ? anim.targetH : 0;

  if (targetH !== currentH) {
    if (state.buildings[key]) {
      state.scene.remove(state.buildings[key]);
      delete state.buildings[key];
    }
    
    if (targetH > 0) {
      const [x, z] = tileWorld(i);
      const grp = new THREE.Group();
      
      if (targetH === 5) {
        // Hotel model
        const hotel = new THREE.Group();
        const bodyMat = new THREE.MeshStandardMaterial({ color: 0xffd700, metalness: 0.7, roughness: 0.2, emissive: 0x3a2503 });
        const body = new THREE.Mesh(new THREE.BoxGeometry(0.34, 0.45, 0.34), bodyMat);
        body.position.y = 0.225;
        body.castShadow = true;
        hotel.add(body);
        
        const roofMat = new THREE.MeshStandardMaterial({ color: 0x203560, roughness: 0.3 });
        const roof = new THREE.Mesh(new THREE.CylinderGeometry(0.18, 0.18, 0.08, 16), roofMat);
        roof.position.y = 0.465;
        roof.rotation.x = Math.PI / 2;
        hotel.add(roof);

        grp.add(hotel);
      } else {
        // Houses model
        const houseMat = new THREE.MeshStandardMaterial({ color: 0x2dd4a7, roughness: 0.4, metalness: 0.1 });
        const roofMat = new THREE.MeshStandardMaterial({ color: 0x902230, roughness: 0.6 });
        
        for (let k = 0; k < targetH; k++) {
          const house = new THREE.Group();
          
          const body = new THREE.Mesh(new THREE.BoxGeometry(0.16, 0.18, 0.16), houseMat);
          body.position.y = 0.09;
          body.castShadow = true;
          house.add(body);
          
          const roof = new THREE.Mesh(new THREE.ConeGeometry(0.12, 0.08, 4), roofMat);
          roof.position.y = 0.22;
          roof.rotation.y = Math.PI / 4;
          roof.castShadow = true;
          house.add(roof);

          house.position.set(x - 0.22 + k * 0.15, 0, z - 0.26);
          grp.add(house);
        }
      }

      state.scene.add(grp);
      state.buildings[key] = grp;

      state.buildingAnimData[key] = {
        targetH: targetH,
        posY: TH + 2.5,
        velY: -4.0,
        elasticBounce: 2,
        x: x, z: z
      };
      
      const [wx, wz] = tileWorld(i);
      spawnDust(wx, TH, wz);
    } else {
      delete state.buildingAnimData[key];
    }
  }
}

function animate() {
  state.raf = requestAnimationFrame(animate);
  const dt = 0.016;
  const time = performance.now() * 0.001;


  // --- 3D Physics Dice Animation Loop ---
  if (state.diceRolling) {
    state.diceRollTime += dt;
    const g = -9.8;
    const lawnHeight = 0.16;

    state.diceVel1.y += g * dt;
    state.dice1.position.addScaledVector(state.diceVel1, dt);
    state.dice1.rotation.x += state.diceAng1.x * dt;
    state.dice1.rotation.y += state.diceAng1.y * dt;
    state.dice1.rotation.z += state.diceAng1.z * dt;

    if (state.dice1.position.y < lawnHeight) {
      state.dice1.position.y = lawnHeight;
      state.diceVel1.y = -state.diceVel1.y * 0.45;
      state.diceVel1.x *= 0.5;
      state.diceVel1.z *= 0.5;
      state.diceAng1.multiplyScalar(0.45);
    }

    state.diceVel2.y += g * dt;
    state.dice2.position.addScaledVector(state.diceVel2, dt);
    state.dice2.rotation.x += state.diceAng2.x * dt;
    state.dice2.rotation.y += state.diceAng2.y * dt;
    state.dice2.rotation.z += state.diceAng2.z * dt;

    if (state.dice2.position.y < lawnHeight) {
      state.dice2.position.y = lawnHeight;
      state.diceVel2.y = -state.diceVel2.y * 0.45;
      state.diceVel2.x *= 0.5;
      state.diceVel2.z *= 0.5;
      state.diceAng2.multiplyScalar(0.45);
    }

    if (state.diceRollTime > 1.4) {
      const e = Math.min(1.0, (state.diceRollTime - 1.4) * 1.4);
      const tPos1 = new THREE.Vector3(-0.5, lawnHeight, 0.1);
      const tPos2 = new THREE.Vector3(0.5, lawnHeight, -0.1);

      state.dice1.position.lerp(tPos1, e);
      state.dice2.position.lerp(tPos2, e);

      const qTarget1 = new THREE.Quaternion().setFromEuler(getTargetRotation(state.diceData.d1));
      const qTarget2 = new THREE.Quaternion().setFromEuler(getTargetRotation(state.diceData.d2));

      state.dice1.quaternion.slerp(qTarget1, e);
      state.dice2.quaternion.slerp(qTarget2, e);

      if (e >= 1.0) {
        state.diceRolling = false;
        state.diceLandingHoldTime = 1.2; // Zarlar oturdu — yakın kamera ile yüzleri göster
        // Zarlar oturdu — Dart tarafına bildir (çift göstergesi için).
        if (window.itupolyOnAnimEvent) window.itupolyOnAnimEvent('diceSettled');
      }
    }
  }

  // --- Building Drop Animation ---
  for (const [key, anim] of Object.entries(state.buildingAnimData)) {
    const mesh = state.buildings[key];
    if (!mesh) continue;

    anim.velY += -12.0 * dt;
    anim.posY += anim.velY * dt;

    if (anim.posY < TH) {
      anim.posY = TH;
      if (anim.elasticBounce > 0) {
        anim.velY = -anim.velY * 0.35;
        anim.elasticBounce--;
      } else {
        anim.velY = 0;
      }
    }
    mesh.position.y = anim.posY;

    if (anim.posY === TH && Math.abs(anim.velY) > 0.1) {
      mesh.scale.set(1.18, 0.82, 1.18);
    } else {
      mesh.scale.lerp(new THREE.Vector3(1, 1, 1), 0.15);
    }
  }

  // --- Particles Loop ---
  for (let i = state.particles.length - 1; i >= 0; i--) {
    const p = state.particles[i];
    p.life++;
    p.mesh.position.addScaledVector(p.vel, dt);
    p.vel.y += -2.5 * dt;
    p.mesh.scale.multiplyScalar(0.95);
    
    if (p.mesh.material) {
      p.mesh.material.opacity = Math.max(0, 1 - p.life / p.maxLife);
    }

    if (p.life >= p.maxLife) {
      state.scene.remove(p.mesh);
      state.particles.splice(i, 1);
    }
  }

  // Victory Gold Rain
  if (state.victoryRain && Math.random() < 0.18) {
    spawnVictoryCoin();
  }

  for (let i = state.coins.length - 1; i >= 0; i--) {
    const c = state.coins[i];
    c.mesh.position.addScaledVector(c.vel, dt);
    
    c.mesh.rotation.x += c.spin.x * dt;
    c.mesh.rotation.y += c.spin.y * dt;
    c.mesh.rotation.z += c.spin.z * dt;

    if (c.mesh.position.y < 0.02) {
      c.mesh.position.y = 0.02;
      c.vel.y = -c.vel.y * 0.4;
      c.vel.x += (Math.random() - 0.5) * 1.0;
      c.vel.z += (Math.random() - 0.5) * 1.0;
      c.spin.multiplyScalar(0.5);
    }

    if (c.mesh.position.y < -0.5 || Math.abs(c.mesh.position.x) > 8.0) {
      state.scene.remove(c.mesh);
      state.coins.splice(i, 1);
    }
  }

  // --- Cash Bills Loop ---
  for (let i = state.cashBills.length - 1; i >= 0; i--) {
    const bill = state.cashBills[i];
    bill.t += dt * 1.8;
    if (bill.t > 0) {
      const e = Math.min(1.0, bill.t);
      const currentPos = new THREE.Vector3().lerpVectors(bill.from, bill.to, e);
      currentPos.y += Math.sin(e * Math.PI) * 0.8;
      bill.mesh.position.copy(currentPos);
      
      bill.mesh.rotation.x += bill.rotSpeed.x * dt;
      bill.mesh.rotation.y += bill.rotSpeed.y * dt;

      if (e >= 1.0) {
        state.scene.remove(bill.mesh);
        state.cashBills.splice(i, 1);
      }
    }
  }

  // --- Jail Light Flashing ---
  if (state.jailFlashing) {
    state.jailFlashTimer += dt * 8.0;
    const blue = Math.sin(state.jailFlashTimer) > 0;
    if (state.keyLight && state.fillLight) {
      state.keyLight.color.setHex(blue ? 0x0000ff : 0xff0000);
      state.fillLight.color.setHex(blue ? 0x0000bb : 0xbb0000);
      state.keyLight.intensity = 1.8;
      state.fillLight.intensity = 0.8;
    }
  } else {
    if (state.keyLight && state.keyLight.color.getHex() !== 0xfff2d0) {
      state.keyLight.color.setHex(0xfff2d0);
      state.keyLight.intensity = 1.25;
    }
    if (state.fillLight && state.fillLight.color.getHex() !== 0x8ab4ff) {
      state.fillLight.color.setHex(0x8ab4ff);
      state.fillLight.intensity = 0.4;
    }
  }

  // --- Dice Landing Hold Time Decr ---
  if (state.diceLandingHoldTime > 0) {
    state.diceLandingHoldTime -= dt;
  }

  // --- Pawn Jumping & Breathing ---
  let anyTokenMoving = false;
  for (const id of Object.keys(state.tokens)) {
    const tk = state.tokens[id];
    const off = tk.userData.offset || new THREE.Vector3();

    if (!state.diceRolling && state.diceLandingHoldTime <= 0 && !tk.userData.seg && tk.userData.queue.length) {
      const next = tk.userData.queue.shift();
      const [tx, tz] = tileWorld(next);
      tk.userData.seg = {
        fromX: tk.position.x, fromZ: tk.position.z,
        toX: tx + off.x, toZ: tz + off.z, t: 0,
        toIdx: next
      };
    }

    const seg = tk.userData.seg;
    if (seg) {
      anyTokenMoving = true;
      seg.t = Math.min(1, seg.t + dt * 3.6);
      const e = seg.t;
      tk.position.x = seg.fromX + (seg.toX - seg.fromX) * e;
      tk.position.z = seg.fromZ + (seg.toZ - seg.fromZ) * e;
      tk.position.y = TH + Math.sin(e * Math.PI) * 0.42;
      
      tk.scale.set(0.85, 1.25, 0.85);

      if (seg.t >= 1) {
        tk.position.y = TH;
        tk.userData.idx = seg.toIdx; // Landed logically, update now
        tk.userData.seg = null;
        spawnDust(tk.position.x, TH, tk.position.z);
      }
    } else {
      tk.scale.lerp(new THREE.Vector3(1, 1, 1), 0.2);
      
      const [tx, tz] = tileWorld(tk.userData.idx);
      tk.position.x += (tx + off.x - tk.position.x) * 0.2;
      tk.position.z += (tz + off.z - tk.position.z) * 0.2;
      const bob = Number(id) === state.currentId
        ? Math.abs(Math.sin(time * 2.8)) * 0.08
        : 0;
    }
  }

  // --- Real-time Active Pawn Tracking ---
  const activeToken = state.tokens[state.currentId];
  if (activeToken) {
    state.followTarget.set(activeToken.position.x, TH + 0.1, activeToken.position.z);
  }

  // --- Dynamic Tile Highlighting & Elevation (Pulsing in Top View) ---
  const activeAnim = isAnyTokenMoving() || state.diceRolling;
  for (let i = 0; i < 40; i++) {
    const m = state.tiles[i];
    if (!m) continue;
    const isCurrent = (i === state.currentTileIndex) && !activeAnim;
    
    let targetY = m.userData.mortgaged ? TH * 0.35 : TH / 2;
    if (isCurrent) {
      targetY = TH / 2 + 0.16; // Lift the active tile up
    }
    
    m.position.y += (targetY - m.position.y) * 0.12;

    const mats = m.userData.mats || [m.material];
    for (const mat of mats) {
      if (isCurrent) {
        mat.emissive.setHex(0xE8B53A); // Gold glow
        mat.emissiveIntensity = 0.35 + Math.sin(time * 6.5) * 0.25;
      } else {
        mat.emissiveIntensity = m.userData.ownerEmissiveIntensity || 0.0;
        mat.emissive.setHex(m.userData.ownerEmissiveColor || 0x000000);
      }
    }
  }

  // --- Programmatic Camera: Top View vs Cinematic View Transitions ---
  if (state.camera) {
    let targetDist = 14.5;
    let offset;

    if (state.introTime > 0) {
      state.introTime -= dt;
      // Close-up on Start tile (index 0) where tokens are selected/spawned
      const [sx, sz] = tileWorld(0);
      const startPos = new THREE.Vector3(sx, 0.3, sz);
      state.cameraTarget.lerp(startPos, 0.08);
      targetDist = 6.2;
      offset = new THREE.Vector3(0, targetDist * 0.75, targetDist * 0.9);
    } else if (state.diceRolling) {
      // 1a. Zarlar düşerken: neredeyse düz yukarıdan izle (yüzeyler görünsün)
      const center = new THREE.Vector3(0, 0.16, 0);
      state.cameraTarget.lerp(center, 0.12);
      targetDist = 5.5;
      offset = new THREE.Vector3(0, targetDist * 0.97, targetDist * 0.18);
    } else if (state.diceLandingHoldTime > 0) {
      // 1b. Zarlar durdu: çok yakın, düz yukarıdan — yüzler net okunur
      const center = new THREE.Vector3(0, 0.16, 0);
      state.cameraTarget.lerp(center, 0.15);
      targetDist = 2.8;
      offset = new THREE.Vector3(0, targetDist * 0.98, targetDist * 0.08);
    } else if (isAnyTokenMoving()) {
      // 2. Cinematic View: Zoom closer and track moving pawn
      state.cameraTarget.lerp(state.followTarget, 0.08);
      targetDist = 7.0;
      offset = new THREE.Vector3(0, targetDist * 0.75, targetDist * 0.9);
    } else {
      // 3. Top View: Return to board center and look straight down
      const center = new THREE.Vector3(0, 0, 0);
      state.cameraTarget.lerp(center, 0.06);
      targetDist = 14.5; // Pull back to show all tiles (prevent crop/cut-off)
      // Small 0.001 Z offset avoids camera gimbal lock/flipping looking straight down
      offset = new THREE.Vector3(0, targetDist, 0.001);
    }

    const targetCamPos = new THREE.Vector3().addVectors(state.cameraTarget, offset);
    state.camera.position.lerp(targetCamPos, 0.06);

    // Apply Screen Shake
    if (state.shakeTime > 0) {
      state.shakeTime--;
      const intensity = state.shakeIntensity * (state.shakeTime / 30.0);
      state.camera.position.x += (Math.random() - 0.5) * intensity;
      state.camera.position.y += (Math.random() - 0.5) * intensity;
      state.camera.position.z += (Math.random() - 0.5) * intensity;
    }

    state.camera.lookAt(state.cameraTarget);
  }

  // --- Action Indicator Animation ---
  if (state.actionIndicator) {
    const type = state.currentIndicatorType;
    if (type && !activeAnim) {
      const scaleVal = 1.0 + Math.sin(time * 3.5) * 0.08;
      state.actionIndicator.scale.lerp(new THREE.Vector3(scaleVal, scaleVal, scaleVal), 0.12);
      
      const [wx, wz] = tileWorld(state.currentTileIndex);
      const targetPos = new THREE.Vector3(wx, TH + 0.62 + Math.sin(time * 4.5) * 0.04, wz);
      state.actionIndicator.position.lerp(targetPos, 0.12);
      
      state.actionIndicator.rotation.y += dt * 1.5;
      
      if (type === 'jail') {
        const sirenDome = state.actionIndicator.children[1];
        if (sirenDome && sirenDome.material) {
          const blue = Math.sin(time * 12.0) > 0;
          sirenDome.material.color.setHex(blue ? 0x0000ff : 0xff0000);
          sirenDome.material.emissive.setHex(blue ? 0x000088 : 0x880000);
        }
      }
    } else {
      state.actionIndicator.scale.lerp(new THREE.Vector3(0, 0, 0), 0.18);
    }
  }

  // --- Sahne boşta kalma sinyali (piyon + zar animasyonları bitti) ---
  const animatingNow = state.diceRolling || state.diceLandingHoldTime > 0 || isAnyTokenMoving();
  if (state.wasAnimating && !animatingNow) {
    // Hareket → durağan geçişi: Dart'a 'idle' gönder (kart ve orta-overlay için).
    if (window.itupolyOnAnimEvent) window.itupolyOnAnimEvent('idle');
  }
  state.wasAnimating = animatingNow;

  state.renderer.render(state.scene, state.camera);
}

function attach(hostOrId) {
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
  cam.position.set(0, 14.5, 0.001); // Start in Top View looking straight down
  state.camera = cam;

  state.renderer = makeRenderer(host);
  state.renderer.setSize(w, h, false);

  scene.add(new THREE.HemisphereLight(0xffffff, 0xd8dde6, 1.1));
  
  const key = new THREE.DirectionalLight(0xfff2d0, 1.25);
  key.position.set(5, 12, 5);
  key.castShadow = true;
  key.shadow.mapSize.set(1024, 1024);
  key.shadow.camera.near = 1; key.shadow.camera.far = 40;
  key.shadow.camera.left = -8; key.shadow.camera.right = 8;
  key.shadow.camera.top = 8; key.shadow.camera.bottom = -8;
  key.shadow.bias = -0.0006;
  scene.add(key);
  state.keyLight = key;

  const fill = new THREE.DirectionalLight(0x8ab4ff, 0.4);
  fill.position.set(-6, 5, -3);
  scene.add(fill);
  state.fillLight = fill;

  // Initialize floating action indicator
  state.actionIndicator = new THREE.Group();
  state.actionIndicator.scale.set(0, 0, 0);
  // scene.add(state.actionIndicator); // Commented out to remove the rotating 3D action indicator
  state.currentIndicatorType = null;

  buildBoard(null);

  if (window.__itupolyPendingState) {
    setState(window.__itupolyPendingState);
    window.__itupolyPendingState = null;
  }

  // Tap raycast
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
    if (moved > 8 || performance.now() - d.t > 500) return;
    const rect = dom.getBoundingClientRect();
    ndc.x = ((e.clientX - rect.left) / rect.width) * 2 - 1;
    ndc.y = -((e.clientY - rect.top) / rect.height) * 2 + 1;
    ray.setFromCamera(ndc, state.camera);
    const hits = ray.intersectObjects(state.tiles, false);
    if (hits.length && window.itupolyOnTapTile) {
      window.itupolyOnTapTile(hits[0].object.userData.index);
    }
  });

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

  if (document.fonts) {
    const redrawTexturedTiles = () => {
      for (let i = 0; i < 40; i++) {
        const m = state.tiles[i];
        if (m && m.userData.textured && m.userData.tileData) {
          textureTile(m, m.userData.tileData);
        }
      }
    };
    document.fonts.ready.then(redrawTexturedTiles);
    document.fonts.addEventListener('loadingdone', redrawTexturedTiles);
  }

  console.log('itupoly3d attached (enhanced GDD version - cinematic transitions)', w, h);
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
  state.tiles = []; state.tokens = {}; state.buildings = {};
  state.actionIndicator = null;
  state.currentIndicatorType = null;
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
