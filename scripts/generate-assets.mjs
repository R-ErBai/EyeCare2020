import { mkdirSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { deflateSync } from "node:zlib";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const resources = join(root, "EyeCare2020", "Resources");
const appIcon = join(root, "EyeCare2020", "Assets.xcassets", "AppIcon.appiconset");

mkdirSync(resources, { recursive: true });
mkdirSync(appIcon, { recursive: true });

const width = 1024;
const height = 1024;
const pixels = new Uint8Array(width * height * 4);

function mix(a, b, t) {
  return Math.round(a + (b - a) * t);
}

function setPixel(x, y, color) {
  if (x < 0 || y < 0 || x >= width || y >= height) return;
  const offset = (Math.floor(y) * width + Math.floor(x)) * 4;
  pixels[offset] = color[0];
  pixels[offset + 1] = color[1];
  pixels[offset + 2] = color[2];
  pixels[offset + 3] = color[3] ?? 255;
}

function blendPixel(x, y, color, alpha = 1) {
  if (x < 0 || y < 0 || x >= width || y >= height) return;
  const offset = (Math.floor(y) * width + Math.floor(x)) * 4;
  const sourceAlpha = (color[3] ?? 255) / 255 * alpha;
  pixels[offset] = Math.round(pixels[offset] * (1 - sourceAlpha) + color[0] * sourceAlpha);
  pixels[offset + 1] = Math.round(
    pixels[offset + 1] * (1 - sourceAlpha) + color[1] * sourceAlpha,
  );
  pixels[offset + 2] = Math.round(
    pixels[offset + 2] * (1 - sourceAlpha) + color[2] * sourceAlpha,
  );
  pixels[offset + 3] = 255;
}

function drawDisc(cx, cy, radius, color) {
  const minX = Math.max(0, Math.floor(cx - radius));
  const maxX = Math.min(width - 1, Math.ceil(cx + radius));
  const minY = Math.max(0, Math.floor(cy - radius));
  const maxY = Math.min(height - 1, Math.ceil(cy + radius));
  const radiusSquared = radius * radius;

  for (let y = minY; y <= maxY; y += 1) {
    for (let x = minX; x <= maxX; x += 1) {
      const dx = x - cx;
      const dy = y - cy;
      if (dx * dx + dy * dy <= radiusSquared) {
        setPixel(x, y, color);
      }
    }
  }
}

function drawRing(cx, cy, radius, thickness, color) {
  const inner = radius - thickness / 2;
  const outer = radius + thickness / 2;
  const minX = Math.max(0, Math.floor(cx - outer));
  const maxX = Math.min(width - 1, Math.ceil(cx + outer));
  const minY = Math.max(0, Math.floor(cy - outer));
  const maxY = Math.min(height - 1, Math.ceil(cy + outer));

  for (let y = minY; y <= maxY; y += 1) {
    for (let x = minX; x <= maxX; x += 1) {
      const distance = Math.hypot(x - cx, y - cy);
      if (distance >= inner && distance <= outer) {
        blendPixel(x, y, color, 0.95);
      }
    }
  }
}

function drawLine(x1, y1, x2, y2, thickness, color) {
  const half = thickness / 2;
  const minX = Math.max(0, Math.floor(Math.min(x1, x2) - half - 1));
  const maxX = Math.min(width - 1, Math.ceil(Math.max(x1, x2) + half + 1));
  const minY = Math.max(0, Math.floor(Math.min(y1, y2) - half - 1));
  const maxY = Math.min(height - 1, Math.ceil(Math.max(y1, y2) + half + 1));
  const vx = x2 - x1;
  const vy = y2 - y1;
  const lengthSquared = vx * vx + vy * vy;

  for (let y = minY; y <= maxY; y += 1) {
    for (let x = minX; x <= maxX; x += 1) {
      const t = Math.max(
        0,
        Math.min(1, ((x - x1) * vx + (y - y1) * vy) / lengthSquared),
      );
      const nearestX = x1 + t * vx;
      const nearestY = y1 + t * vy;
      if (Math.hypot(x - nearestX, y - nearestY) <= half) {
        setPixel(x, y, color);
      }
    }
  }
}

function quadraticPoint(start, control, end, t) {
  const oneMinusT = 1 - t;
  return [
    oneMinusT * oneMinusT * start[0] +
      2 * oneMinusT * t * control[0] +
      t * t * end[0],
    oneMinusT * oneMinusT * start[1] +
      2 * oneMinusT * t * control[1] +
      t * t * end[1],
  ];
}

function drawCurve(start, control, end, thickness, color) {
  let previous = start;
  for (let step = 1; step <= 80; step += 1) {
    const point = quadraticPoint(start, control, end, step / 80);
    drawLine(previous[0], previous[1], point[0], point[1], thickness, color);
    previous = point;
  }
}

const top = [5, 28, 23];
const bottom = [17, 70, 53];
for (let y = 0; y < height; y += 1) {
  for (let x = 0; x < width; x += 1) {
    const diagonal = (x + y) / (width + height);
    setPixel(x, y, [
      mix(top[0], bottom[0], diagonal),
      mix(top[1], bottom[1], diagonal),
      mix(top[2], bottom[2], diagonal),
      255,
    ]);
  }
}

const mint = [159, 229, 189, 255];
const amber = [245, 178, 98, 255];
const paper = [232, 247, 235, 255];
const forest = [8, 38, 30, 255];
const center = 512;

for (let index = 0; index < 20; index += 1) {
  const angle = (index / 20) * Math.PI * 2 - Math.PI / 2;
  const innerRadius = 365;
  const outerRadius = 425;
  const x1 = center + Math.cos(angle) * innerRadius;
  const y1 = center + Math.sin(angle) * innerRadius;
  const x2 = center + Math.cos(angle) * outerRadius;
  const y2 = center + Math.sin(angle) * outerRadius;
  drawLine(x1, y1, x2, y2, 11, index % 5 === 0 ? paper : mint);
}

drawCurve([232, 512], [512, 310], [792, 512], 24, paper);
drawCurve([232, 512], [512, 714], [792, 512], 24, paper);
drawDisc(512, 512, 120, amber);
drawDisc(512, 512, 56, forest);
drawDisc(548, 478, 18, paper);
drawRing(512, 512, 214, 4, mint);

function crc32(buffer) {
  let crc = 0xffffffff;
  for (const byte of buffer) {
    crc ^= byte;
    for (let bit = 0; bit < 8; bit += 1) {
      crc = (crc >>> 1) ^ (0xedb88320 & -(crc & 1));
    }
  }
  return (crc ^ 0xffffffff) >>> 0;
}

function pngChunk(type, data) {
  const typeBuffer = Buffer.from(type, "ascii");
  const chunk = Buffer.alloc(12 + data.length);
  chunk.writeUInt32BE(data.length, 0);
  typeBuffer.copy(chunk, 4);
  data.copy(chunk, 8);
  chunk.writeUInt32BE(crc32(Buffer.concat([typeBuffer, data])), 8 + data.length);
  return chunk;
}

const scanlines = Buffer.alloc((width * 4 + 1) * height);
for (let y = 0; y < height; y += 1) {
  const rowOffset = y * (width * 4 + 1);
  scanlines[rowOffset] = 0;
  Buffer.from(pixels.buffer, y * width * 4, width * 4).copy(scanlines, rowOffset + 1);
}

const ihdr = Buffer.alloc(13);
ihdr.writeUInt32BE(width, 0);
ihdr.writeUInt32BE(height, 4);
ihdr[8] = 8;
ihdr[9] = 6;
const png = Buffer.concat([
  Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
  pngChunk("IHDR", ihdr),
  pngChunk("IDAT", deflateSync(scanlines, { level: 9 })),
  pngChunk("IEND", Buffer.alloc(0)),
]);
writeFileSync(join(appIcon, "AppIcon-1024.png"), png);

const sampleRate = 44100;
const channels = 1;
const bitsPerSample = 16;
const dataSize = sampleRate * channels * (bitsPerSample / 8);
const wav = Buffer.alloc(44 + dataSize);
wav.write("RIFF", 0);
wav.writeUInt32LE(36 + dataSize, 4);
wav.write("WAVE", 8);
wav.write("fmt ", 12);
wav.writeUInt32LE(16, 16);
wav.writeUInt16LE(1, 20);
wav.writeUInt16LE(channels, 22);
wav.writeUInt32LE(sampleRate, 24);
wav.writeUInt32LE(sampleRate * channels * (bitsPerSample / 8), 28);
wav.writeUInt16LE(channels * (bitsPerSample / 8), 32);
wav.writeUInt16LE(bitsPerSample, 34);
wav.write("data", 36);
wav.writeUInt32LE(dataSize, 40);
writeFileSync(join(resources, "silence.wav"), wav);

console.log("Generated AppIcon-1024.png and silence.wav");
