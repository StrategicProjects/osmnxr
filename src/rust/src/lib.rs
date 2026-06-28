use extendr_api::prelude::*;

mod graph;
mod metrics;
mod routing;
mod simplify;

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

/// Simplified node chains between topological endpoints. Returns a list of
/// 0-based node-index vectors, one per merged edge.
/// @keywords internal
#[extendr]
fn rs_simplify_paths(from: Vec<i32>, to: Vec<i32>, n_nodes: i32) -> List {
    let paths = simplify::simplify_paths(&as_idx(&from), &as_idx(&to), n_nodes as usize);
    List::from_values(
        paths
            .into_iter()
            .map(|p| p.into_iter().map(|x| x as i32).collect::<Vec<i32>>()),
    )
}

/// Connected-component label (0-based root index) for each node, given
/// undirected `a`--`b` adjacency pairs.
/// @keywords internal
#[extendr]
fn rs_connected_components(a: Vec<i32>, b: Vec<i32>, n_nodes: i32) -> Vec<i32> {
    simplify::connected_components(&as_idx(&a), &as_idx(&b), n_nodes as usize)
}

/// Yen's k loopless shortest paths. Returns a list with `paths` (a list of
/// 0-based node-index vectors) and `costs` (numeric).
/// @keywords internal
#[extendr]
fn rs_k_shortest_paths(
    from: Vec<i32>,
    to: Vec<i32>,
    weight: Vec<f64>,
    n_nodes: i32,
    source: i32,
    target: i32,
    k: i32,
) -> List {
    let g = Graph::from_edges(&as_idx(&from), &as_idx(&to), &weight, n_nodes as usize);
    let res = routing::k_shortest_paths(
        &g,
        &as_idx(&from),
        &as_idx(&to),
        &weight,
        source as usize,
        target as usize,
        k as usize,
    );
    let paths = List::from_values(
        res.iter()
            .map(|(p, _)| p.iter().map(|&x| x as i32).collect::<Vec<i32>>()),
    );
    let costs: Vec<f64> = res.iter().map(|(_, c)| *c).collect();
    list!(paths = paths, costs = costs)
}

/// Row-major shortest-distance matrix from each source to each target
/// (0-based indices). Length is `sources * targets`.
/// @keywords internal
#[extendr]
fn rs_distance_matrix(
    from: Vec<i32>,
    to: Vec<i32>,
    weight: Vec<f64>,
    n_nodes: i32,
    sources: Vec<i32>,
    targets: Vec<i32>,
) -> Vec<f64> {
    let g = Graph::from_edges(&as_idx(&from), &as_idx(&to), &weight, n_nodes as usize);
    routing::distance_matrix(&g, &as_idx(&sources), &as_idx(&targets))
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
    fn rs_simplify_paths;
    fn rs_connected_components;
    fn rs_k_shortest_paths;
    fn rs_distance_matrix;
}
