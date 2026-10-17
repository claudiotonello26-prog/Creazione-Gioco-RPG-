// Carica il bundle compilato (funzioni globali, come in Nakama) in un contesto
// isolato per i test.
const fs = require('fs');
const path = require('path');
const vm = require('vm');

function loadModule() {
  const code = fs.readFileSync(path.join(__dirname, '..', 'build', 'index.js'), 'utf8');
  const ctx = vm.createContext({ console, Math, JSON, Object, Array, String, Number });
  vm.runInContext(code + '\n;this.__exports = { ARENA_OP, ARENA_CHALLENGES, ARENA_TICK_RATE, ARENA_COUNTDOWN_TICKS };', ctx);
  return ctx;
}

/** Scheletro con il solo braccio sinistro piegato di [angle] gradi. */
function armPose(angle) {
  const k = [];
  for (let i = 0; i < 13; i++) k.push([0, 0, 0]);
  const rad = (angle * Math.PI) / 180;
  k[1] = [0.5, 0.3, 0.99];
  k[3] = [0.5, 0.4, 0.99];
  k[5] = [0.5 + 0.1 * Math.sin(rad), 0.4 - 0.1 * Math.cos(rad), 0.99];
  return k;
}

/** Plank: spalla, anca e caviglia allineate (o piegate se [aligned] è false). */
function plankPose(aligned) {
  const k = [];
  for (let i = 0; i < 13; i++) k.push([0, 0, 0]);
  k[1] = [0.2, 0.5, 0.99];
  k[7] = [0.5, aligned ? 0.5 : 0.3, 0.99];
  k[11] = [0.8, 0.5, 0.99];
  return k;
}

module.exports = { loadModule, armPose, plankPose };
