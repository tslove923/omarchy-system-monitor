// Human-readable formatting helpers for the system monitor plugin.
.pragma library

// 0..1 ratio -> "NN%"
function pct01(v) {
  return Math.round((v || 0) * 100) + "%"
}

// KB -> "N.N GB"
function gb(kb) {
  return (kb / (1024 * 1024)).toFixed(1) + " GB"
}

// MHz -> "NNNN MHz"
function mhz(m) {
  return (m || 0) + " MHz"
}
