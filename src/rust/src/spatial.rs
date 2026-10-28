//! Planar point-to-polyline snapping over a uniform grid index.
//!
//! Edges arrive as flattened vertex arrays plus per-edge offsets (the R layer
//! passes `sf::st_coordinates()` output). Coordinates are treated as planar;
//! the R layer owns CRS semantics.

use std::collections::HashMap;

/// One polyline segment with its owning edge and the cumulative planar
/// length of the polyline before this segment.
struct Seg {
    x1: f64,
    y1: f64,
    x2: f64,
    y2: f64,
    edge: u32,
    pos0: f64,
}

/// The nearest location on the edge set to a query point.
pub struct Snap {
    /// 0-based edge index.
    pub edge: usize,
    /// Planar distance from the query point to the snapped location.
    pub dist: f64,
    /// Snapped coordinates (on the edge polyline).
    pub x: f64,
    pub y: f64,
    /// Planar distance along the edge polyline from its first vertex.
    pub pos: f64,
}

/// A uniform grid over the segments of a set of polylines, sized for about
/// one segment per cell. Street-network segments are short relative to the
/// extent, so each occupies a handful of cells; the few that span many cells
/// go into an `oversize` list scanned on every query.
pub struct SegmentIndex {
    segs: Vec<Seg>,
    grid: HashMap<(i64, i64), Vec<u32>>,
    oversize: Vec<u32>,
    cell: f64,
    minx: f64,
    miny: f64,
    maxx: f64,
    maxy: f64,
}

/// Squared distance from `(px, py)` to the segment, the clamped projection
/// parameter `t`, the projected point, and the segment length.
fn project(px: f64, py: f64, s: &Seg) -> (f64, f64, f64, f64, f64) {
    let dx = s.x2 - s.x1;
    let dy = s.y2 - s.y1;
    let len2 = dx * dx + dy * dy;
    let t = if len2 > 0.0 {
        (((px - s.x1) * dx + (py - s.y1) * dy) / len2).clamp(0.0, 1.0)
    } else {
        0.0
    };
    let x = s.x1 + t * dx;
    let y = s.y1 + t * dy;
    let d2 = (px - x) * (px - x) + (py - y) * (py - y);
    (d2, t, x, y, len2.sqrt())
}

impl SegmentIndex {
    pub fn build(vx: &[f64], vy: &[f64], offsets: &[usize]) -> Self {
        let n_edges = offsets.len().saturating_sub(1);
        let mut segs: Vec<Seg> = Vec::new();
        let (mut minx, mut miny) = (f64::INFINITY, f64::INFINITY);
        let (mut maxx, mut maxy) = (f64::NEG_INFINITY, f64::NEG_INFINITY);
        for e in 0..n_edges {
            let mut pos0 = 0.0;
            let hi = offsets[e + 1];
            for i in offsets[e]..hi.saturating_sub(1) {
                let (x1, y1, x2, y2) = (vx[i], vy[i], vx[i + 1], vy[i + 1]);
                minx = minx.min(x1.min(x2));
                miny = miny.min(y1.min(y2));
                maxx = maxx.max(x1.max(x2));
                maxy = maxy.max(y1.max(y2));
                let len = ((x2 - x1).powi(2) + (y2 - y1).powi(2)).sqrt();
                segs.push(Seg { x1, y1, x2, y2, edge: e as u32, pos0 });
                pos0 += len;
            }
        }

        let w = (maxx - minx).max(0.0);
        let h = (maxy - miny).max(0.0);
        let m = segs.len().max(1) as f64;
        let mut cell = (w * h / m).sqrt();
        if !cell.is_finite() || cell <= 0.0 {
            cell = w.max(h) / m.sqrt(); // degenerate (collinear) extents
        }
        if !cell.is_finite() || cell <= 0.0 {
            cell = 1.0; // single location or empty
        }

        let mut grid: HashMap<(i64, i64), Vec<u32>> = HashMap::new();
        let mut oversize: Vec<u32> = Vec::new();
        for (i, s) in segs.iter().enumerate() {
            let ix0 = (s.x1.min(s.x2) / cell).floor() as i64;
            let ix1 = (s.x1.max(s.x2) / cell).floor() as i64;
            let iy0 = (s.y1.min(s.y2) / cell).floor() as i64;
            let iy1 = (s.y1.max(s.y2) / cell).floor() as i64;
            let n_cells = (ix1 - ix0 + 1).saturating_mul(iy1 - iy0 + 1);
            if n_cells > 1024 {
                oversize.push(i as u32);
                continue;
            }
            for ix in ix0..=ix1 {
                for iy in iy0..=iy1 {
                    grid.entry((ix, iy)).or_default().push(i as u32);
                }
            }
        }
        SegmentIndex { segs, grid, oversize, cell, minx, miny, maxx, maxy }
    }

    #[cfg(test)]
    pub fn is_empty(&self) -> bool {
        self.segs.is_empty()
    }

    /// Nearest edge location to `(px, py)` within `tolerance` (pass
    /// `f64::INFINITY` for unlimited). Ties resolve to the lowest segment
    /// index, so results are deterministic.
    pub fn nearest(&self, px: f64, py: f64, tolerance: f64) -> Option<Snap> {
        if self.segs.is_empty() {
            return None;
        }
        // best = (d2, seg index, t, x, y)
        let mut best: Option<(f64, u32, f64, f64, f64)> = None;
        let consider = |si: u32, best: &mut Option<(f64, u32, f64, f64, f64)>| {
            let s = &self.segs[si as usize];
            let (d2, t, x, y, _) = project(px, py, s);
            let better = match best {
                None => true,
                Some((bd2, bsi, ..)) => d2 < *bd2 || (d2 == *bd2 && si < *bsi),
            };
            if better {
                *best = Some((d2, si, t, x, y));
            }
        };
        for &si in &self.oversize {
            consider(si, &mut best);
        }

        let cell = self.cell;
        // Ring-search around the query cell, clamped per axis into the range
        // of occupied cells: clamping can only shrink the per-axis cell
        // distance to any occupied cell, so the (r - 1) * cell ring lower
        // bound below stays valid, while far-away points (think wrong CRS)
        // cost a bounded number of rings instead of one per cell of distance.
        let lo_x = (self.minx / cell).floor() as i64;
        let hi_x = (self.maxx / cell).floor() as i64;
        let lo_y = (self.miny / cell).floor() as i64;
        let hi_y = (self.maxy / cell).floor() as i64;
        let cx = ((px / cell).floor() as i64).clamp(lo_x, hi_x);
        let cy = ((py / cell).floor() as i64).clamp(lo_y, hi_y);
        // Rings beyond this cover every cell the data occupies.
        let max_ring = (hi_x - lo_x).max(hi_y - lo_y) + 1;

        for r in 0..=max_ring {
            // No cell at Chebyshev ring r can hold anything closer than this.
            let bound = if r <= 1 { 0.0 } else { (r - 1) as f64 * cell };
            if let Some((bd2, ..)) = best {
                if bd2 <= bound * bound {
                    break;
                }
            }
            if bound > tolerance {
                break;
            }
            let scan = |ix: i64, iy: i64, best: &mut Option<(f64, u32, f64, f64, f64)>| {
                if let Some(cellv) = self.grid.get(&(ix, iy)) {
                    for &si in cellv {
                        consider(si, best);
                    }
                }
            };
            if r == 0 {
                scan(cx, cy, &mut best);
            } else {
                for ix in (cx - r)..=(cx + r) {
                    scan(ix, cy - r, &mut best);
                    scan(ix, cy + r, &mut best);
                }
                for iy in (cy - r + 1)..=(cy + r - 1) {
                    scan(cx - r, iy, &mut best);
                    scan(cx + r, iy, &mut best);
                }
            }
        }

        best.and_then(|(d2, si, t, x, y)| {
            let dist = d2.sqrt();
            if dist > tolerance {
                return None;
            }
            let s = &self.segs[si as usize];
            let seg_len = ((s.x2 - s.x1).powi(2) + (s.y2 - s.y1).powi(2)).sqrt();
            Some(Snap {
                edge: s.edge as usize,
                dist,
                x,
                y,
                pos: s.pos0 + t * seg_len,
            })
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Brute-force nearest over all segments, mirroring `nearest`'s
    /// tie-breaking (lowest segment index).
    fn brute(vx: &[f64], vy: &[f64], offsets: &[usize], px: f64, py: f64) -> (usize, f64, f64) {
        let mut best: Option<(f64, usize, f64)> = None; // d2, edge, pos
        for e in 0..offsets.len() - 1 {
            let mut pos0 = 0.0;
            for i in offsets[e]..offsets[e + 1] - 1 {
                let s = Seg {
                    x1: vx[i],
                    y1: vy[i],
                    x2: vx[i + 1],
                    y2: vy[i + 1],
                    edge: e as u32,
                    pos0,
                };
                let (d2, t, _, _, seg_len) = project(px, py, &s);
                if best.map_or(true, |(bd2, ..)| d2 < bd2) {
                    best = Some((d2, e, pos0 + t * seg_len));
                }
                pos0 += seg_len;
            }
        }
        let (d2, e, pos) = best.unwrap();
        (e, d2.sqrt(), pos)
    }

    /// Tiny deterministic xorshift64 RNG (same as routing's).
    struct Rng(u64);
    impl Rng {
        fn next(&mut self) -> u64 {
            let mut x = self.0;
            x ^= x << 13;
            x ^= x >> 7;
            x ^= x << 17;
            self.0 = x;
            x
        }
        fn unif(&mut self) -> f64 {
            (self.next() % 1_000_000) as f64 / 1_000_000.0
        }
    }

    #[test]
    fn snaps_to_the_interior_of_a_segment() {
        // One horizontal edge from (0,0) to (10,0).
        let vx = vec![0.0, 10.0];
        let vy = vec![0.0, 0.0];
        let idx = SegmentIndex::build(&vx, &vy, &[0, 2]);
        let s = idx.nearest(3.0, 4.0, f64::INFINITY).unwrap();
        assert_eq!(s.edge, 0);
        assert!((s.dist - 4.0).abs() < 1e-12);
        assert!((s.x - 3.0).abs() < 1e-12 && s.y.abs() < 1e-12);
        assert!((s.pos - 3.0).abs() < 1e-12);
    }

    #[test]
    fn clamps_beyond_the_ends() {
        let vx = vec![0.0, 10.0];
        let vy = vec![0.0, 0.0];
        let idx = SegmentIndex::build(&vx, &vy, &[0, 2]);
        let s = idx.nearest(-5.0, 1.0, f64::INFINITY).unwrap();
        assert!((s.pos - 0.0).abs() < 1e-12);
        let s = idx.nearest(15.0, -1.0, f64::INFINITY).unwrap();
        assert!((s.pos - 10.0).abs() < 1e-12);
    }

    #[test]
    fn respects_the_tolerance() {
        let vx = vec![0.0, 10.0];
        let vy = vec![0.0, 0.0];
        let idx = SegmentIndex::build(&vx, &vy, &[0, 2]);
        assert!(idx.nearest(5.0, 3.0, 2.0).is_none());
        assert!(idx.nearest(5.0, 3.0, 3.0).is_some());
    }

    #[test]
    fn position_accumulates_over_polyline_vertices() {
        // L-shaped edge: (0,0) -> (10,0) -> (10,10).
        let vx = vec![0.0, 10.0, 10.0];
        let vy = vec![0.0, 0.0, 10.0];
        let idx = SegmentIndex::build(&vx, &vy, &[0, 3]);
        let s = idx.nearest(12.0, 4.0, f64::INFINITY).unwrap();
        assert_eq!(s.edge, 0);
        assert!((s.pos - 14.0).abs() < 1e-12);
        assert!((s.x - 10.0).abs() < 1e-12 && (s.y - 4.0).abs() < 1e-12);
    }

    #[test]
    fn empty_index_returns_none() {
        let idx = SegmentIndex::build(&[], &[], &[0]);
        assert!(idx.is_empty());
        assert!(idx.nearest(0.0, 0.0, f64::INFINITY).is_none());
    }

    #[test]
    fn matches_brute_force_on_random_networks() {
        let mut rng = Rng(42);
        for _ in 0..5 {
            // ~80 random 2- to 4-vertex polylines in the unit square.
            let n_edges = 80;
            let mut vx = Vec::new();
            let mut vy = Vec::new();
            let mut offsets = vec![0usize];
            for _ in 0..n_edges {
                let nv = 2 + (rng.next() % 3) as usize;
                for _ in 0..nv {
                    vx.push(rng.unif());
                    vy.push(rng.unif());
                }
                offsets.push(vx.len());
            }
            let idx = SegmentIndex::build(&vx, &vy, &offsets);
            for _ in 0..200 {
                // include points outside the extent
                let px = rng.unif() * 1.6 - 0.3;
                let py = rng.unif() * 1.6 - 0.3;
                let got = idx.nearest(px, py, f64::INFINITY).unwrap();
                let (we, wd, wp) = brute(&vx, &vy, &offsets, px, py);
                assert!(
                    (got.dist - wd).abs() < 1e-12,
                    "dist mismatch at ({px}, {py}): got {} want {wd}",
                    got.dist
                );
                // Equidistant snaps may differ in edge; the distance must not.
                if got.edge == we {
                    assert!((got.pos - wp).abs() < 1e-9);
                }
            }
        }
    }
}
