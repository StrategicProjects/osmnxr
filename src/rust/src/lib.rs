use extendr_api::prelude::*;

mod graph;
mod metrics;
mod routing;

use graph::Graph;

/// Convert a 0-based R integer vector to `Vec<usize>`.
fn as_idx(v: &[i32]) -> Vec<usize> {
    v.iter().map(|&x| x as usize).collect()
}

/// Basic network statistics from edge endpoints (0-based) and weights.
/// @keywords internal
#[extendr]
fn rs_basic_stats(from: Vec<i32>, to: Vec<i32>, weight: Vec<f64>, n_nodes: i32) -> List {
    let s = metrics::basic_stats(&as_idx(&from), &as_idx(&to), &weight, n_nodes as usize);
    list!(
        n_nodes = s.n_nodes as i32,
        n_edges = s.n_edges as i32,
        total_length = s.total_length,
        mean_length = s.mean_length,
        mean_out_degree = s.mean_out_degree,
        self_loops = s.self_loops as i32
    )
}

/// Shortest path (0-based node indices) between `source` and `target`.
/// Returns an empty vector when the target is unreachable.
/// @keywords internal
#[extendr]
fn rs_shortest_path(
    from: Vec<i32>,
    to: Vec<i32>,
    weight: Vec<f64>,
    n_nodes: i32,
    source: i32,
    target: i32,
) -> Vec<i32> {
    let g = Graph::from_edges(&as_idx(&from), &as_idx(&to), &weight, n_nodes as usize);
    routing::shortest_path(&g, source as usize, target as usize)
        .into_iter()
        .map(|x| x as i32)
        .collect()
}

/// Single-source shortest distances (length `n_nodes`); `Inf` if unreachable.
/// @keywords internal
#[extendr]
fn rs_dijkstra(
    from: Vec<i32>,
    to: Vec<i32>,
    weight: Vec<f64>,
    n_nodes: i32,
    source: i32,
) -> Vec<f64> {
    let g = Graph::from_edges(&as_idx(&from), &as_idx(&to), &weight, n_nodes as usize);
    routing::dijkstra(&g, source as usize)
}

/// Shannon entropy of binned edge bearings (degrees).
/// @keywords internal
#[extendr]
fn rs_orientation_entropy(bearings: Vec<f64>, num_bins: i32) -> f64 {
    metrics::orientation_entropy(&bearings, num_bins as usize)
}

/// Initial compass bearings (degrees) for parallel coordinate vectors.
/// @keywords internal
#[extendr]
fn rs_bearings(lat1: Vec<f64>, lon1: Vec<f64>, lat2: Vec<f64>, lon2: Vec<f64>) -> Vec<f64> {
    (0..lat1.len())
        .map(|i| metrics::bearing(lat1[i], lon1[i], lat2[i], lon2[i]))
        .collect()
}

// Macro to generate exports.
// This ensures exported functions are registered with R.
// See corresponding C code in `entrypoint.c`.
extendr_module! {
    mod osmnxr;
    fn rs_basic_stats;
    fn rs_shortest_path;
    fn rs_dijkstra;
    fn rs_orientation_entropy;
    fn rs_bearings;
}
