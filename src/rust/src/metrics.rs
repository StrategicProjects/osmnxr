//! Urban / network metrics computed on the Rust side.

use std::f64::consts::PI;

/// Summary statistics for a set of weighted edges.
pub struct BasicStats {
    pub n_nodes: usize,
    pub n_edges: usize,
    pub total_length: f64,
    pub mean_length: f64,
    pub mean_out_degree: f64,
    pub self_loops: usize,
}

/// Compute basic network statistics from edge endpoints and weights.
pub fn basic_stats(from: &[usize], to: &[usize], weight: &[f64], n_nodes: usize) -> BasicStats {
    let n_edges = from.len();
    let total_length: f64 = weight.iter().sum();
    let mean_length = if n_edges > 0 { total_length / n_edges as f64 } else { 0.0 };
    let mean_out_degree = if n_nodes > 0 { n_edges as f64 / n_nodes as f64 } else { 0.0 };
    let self_loops = from.iter().zip(to).filter(|(u, v)| u == v).count();
    BasicStats { n_nodes, n_edges, total_length, mean_length, mean_out_degree, self_loops }
}

/// Shannon entropy (in nats) of edge compass bearings, binned into `num_bins`
/// equal sectors over `[0, 360)`. Higher entropy = more disordered (organic)
/// street grid; lower = more ordered (gridiron). Bearings are in degrees.
pub fn orientation_entropy(bearings: &[f64], num_bins: usize) -> f64 {
    if bearings.is_empty() || num_bins == 0 {
        return 0.0;
    }
    let mut counts = vec![0.0f64; num_bins];
    let bin_width = 360.0 / num_bins as f64;
    for &b in bearings {
        let bb = b.rem_euclid(360.0);
        let mut idx = (bb / bin_width).floor() as usize;
        if idx >= num_bins {
            idx = num_bins - 1;
        }
        counts[idx] += 1.0;
    }
    let total: f64 = counts.iter().sum();
    let mut h = 0.0;
    for c in counts {
        if c > 0.0 {
            let p = c / total;
            h -= p * p.ln();
        }
    }
    h
}

/// Initial compass bearing (degrees, clockwise from north) from point
/// `(lat1, lon1)` to `(lat2, lon2)`, both in decimal degrees.
pub fn bearing(lat1: f64, lon1: f64, lat2: f64, lon2: f64) -> f64 {
    let (phi1, phi2) = (lat1.to_radians(), lat2.to_radians());
    let dlon = (lon2 - lon1).to_radians();
    let y = dlon.sin() * phi2.cos();
    let x = phi1.cos() * phi2.sin() - phi1.sin() * phi2.cos() * dlon.cos();
    let theta = y.atan2(x);
    (theta * 180.0 / PI).rem_euclid(360.0)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn perfect_grid_has_low_entropy() {
        // Two orientations only (E-W and N-S): low entropy.
        let grid = vec![0.0, 90.0, 180.0, 270.0, 0.0, 90.0, 180.0, 270.0];
        let uniform = vec![0.0, 45.0, 90.0, 135.0, 180.0, 225.0, 270.0, 315.0];
        let h_grid = orientation_entropy(&grid, 8);
        let h_uniform = orientation_entropy(&uniform, 8);
        assert!(h_grid < h_uniform);
    }

    #[test]
    fn bearing_due_east_is_90() {
        let b = bearing(0.0, 0.0, 0.0, 1.0);
        assert!((b - 90.0).abs() < 1e-6);
    }
}
