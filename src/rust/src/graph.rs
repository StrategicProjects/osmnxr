//! Compressed-sparse-row (CSR) directed graph built from edge lists.
//!
//! Node identifiers are 0-based contiguous indices; the R layer is responsible
//! for mapping OSM node ids to and from these indices.

/// A directed, weighted graph in CSR form.
pub struct Graph {
    /// `offsets[i] .. offsets[i + 1]` is the slice of out-edges of node `i`.
    pub offsets: Vec<usize>,
    /// Destination node of each out-edge, grouped by source node.
    pub targets: Vec<usize>,
    /// Weight (e.g. length or travel time) of each out-edge.
    pub weights: Vec<f64>,
    /// Number of nodes.
    pub n_nodes: usize,
}

impl Graph {
    /// Build a CSR graph from parallel `from`/`to`/`weight` edge vectors.
    ///
    /// `n_nodes` is the number of distinct node indices; every value in
    /// `from`/`to` must be in `0 .. n_nodes`.
    pub fn from_edges(from: &[usize], to: &[usize], weight: &[f64], n_nodes: usize) -> Self {
        let m = from.len();
        let mut degree = vec![0usize; n_nodes + 1];
        for &u in from {
            degree[u + 1] += 1;
        }
        for i in 0..n_nodes {
            degree[i + 1] += degree[i];
        }
        let offsets = degree; // now a prefix-sum offset array
        let mut targets = vec![0usize; m];
        let mut weights = vec![0.0f64; m];
        let mut cursor = offsets.clone();
        for e in 0..m {
            let u = from[e];
            let pos = cursor[u];
            targets[pos] = to[e];
            weights[pos] = weight[e];
            cursor[u] += 1;
        }
        Graph { offsets, targets, weights, n_nodes }
    }

    /// Out-edges of `node` as `(target, weight)` pairs.
    pub fn neighbors(&self, node: usize) -> impl Iterator<Item = (usize, f64)> + '_ {
        let start = self.offsets[node];
        let end = self.offsets[node + 1];
        (start..end).map(move |e| (self.targets[e], self.weights[e]))
    }

    #[allow(dead_code)] // part of the public graph API; used by upcoming metrics
    pub fn n_edges(&self) -> usize {
        self.targets.len()
    }
}
