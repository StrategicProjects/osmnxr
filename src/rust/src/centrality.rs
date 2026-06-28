//! Node centrality measures on a weighted [`Graph`].

use crate::graph::Graph;
use crate::routing::dijkstra;
use std::cmp::Ordering;
use std::collections::BinaryHeap;

const EPS: f64 = 1e-9;

/// Min-heap entry by ascending distance.
struct Entry {
    dist: f64,
    node: usize,
}
impl PartialEq for Entry {
    fn eq(&self, other: &Self) -> bool {
        self.dist == other.dist
    }
}
impl Eq for Entry {}
impl PartialOrd for Entry {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}
impl Ord for Entry {
    fn cmp(&self, other: &Self) -> Ordering {
        other.dist.partial_cmp(&self.dist).unwrap_or(Ordering::Equal)
    }
}

/// Closeness centrality for every node. For node `v` with reachable set of size
/// `r` and total distance `s`, closeness is `(r - 1) / s`. When `normalized`,
/// it is scaled by `(r - 1) / (n - 1)` (Wasserman--Faust) to compare nodes in
/// disconnected graphs. Isolated nodes get `0`.
pub fn closeness_centrality(graph: &Graph, normalized: bool) -> Vec<f64> {
    let n = graph.n_nodes;
    let mut out = vec![0.0; n];
    for v in 0..n {
        let dist = dijkstra(graph, v);
        let mut sum = 0.0;
        let mut reach = 0usize;
        for &d in dist.iter() {
            if d.is_finite() && d > 0.0 {
                sum += d;
                reach += 1;
            }
        }
        if sum > 0.0 && reach > 0 {
            let mut c = reach as f64 / sum;
            if normalized && n > 1 {
                c *= reach as f64 / (n as f64 - 1.0);
            }
            out[v] = c;
        }
    }
    out
}

/// Betweenness centrality via Brandes' algorithm for weighted graphs. When
/// `normalized`, scores are divided by `(n - 1)(n - 2)` (directed graphs).
pub fn betweenness_centrality(graph: &Graph, normalized: bool) -> Vec<f64> {
    let n = graph.n_nodes;
    let mut bc = vec![0.0f64; n];

    for s in 0..n {
        let mut dist = vec![f64::INFINITY; n];
        let mut sigma = vec![0.0f64; n];
        let mut preds: Vec<Vec<usize>> = vec![Vec::new(); n];
        let mut done = vec![false; n];
        let mut stack: Vec<usize> = Vec::new();

        dist[s] = 0.0;
        sigma[s] = 1.0;
        let mut heap = BinaryHeap::new();
        heap.push(Entry { dist: 0.0, node: s });

        while let Some(Entry { dist: d, node: v }) = heap.pop() {
            if done[v] {
                continue;
            }
            done[v] = true;
            stack.push(v);
            for (w, c) in graph.neighbors(v) {
                let nd = d + c;
                if nd < dist[w] - EPS {
                    dist[w] = nd;
                    sigma[w] = sigma[v];
                    preds[w].clear();
                    preds[w].push(v);
                    heap.push(Entry { dist: nd, node: w });
                } else if (nd - dist[w]).abs() <= EPS {
                    sigma[w] += sigma[v];
                    preds[w].push(v);
                }
            }
        }

        let mut delta = vec![0.0f64; n];
        while let Some(w) = stack.pop() {
            let coeff = (1.0 + delta[w]) / sigma[w];
            for &v in &preds[w] {
                delta[v] += sigma[v] * coeff;
            }
            if w != s {
                bc[w] += delta[w];
            }
        }
    }

    if normalized && n > 2 {
        let scale = 1.0 / ((n as f64 - 1.0) * (n as f64 - 2.0));
        for x in bc.iter_mut() {
            *x *= scale;
        }
    }
    bc
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn betweenness_of_a_path_peaks_in_the_middle() {
        // Directed line 0->1->2->3->4 (and reverse) : node 2 most central.
        let from = vec![0, 1, 2, 3, 1, 2, 3, 4];
        let to = vec![1, 2, 3, 4, 0, 1, 2, 3];
        let w = vec![1.0; 8];
        let g = Graph::from_edges(&from, &to, &w, 5);
        let bc = betweenness_centrality(&g, false);
        assert!(bc[2] > bc[1]);
        assert!(bc[1] > bc[0]);
        assert_eq!(bc[0], 0.0); // endpoints lie on no shortest path
    }

    #[test]
    fn closeness_center_beats_leaf() {
        // Star: 0 in the middle connected to 1,2,3 (bidirectional).
        let from = vec![0, 1, 0, 2, 0, 3];
        let to = vec![1, 0, 2, 0, 3, 0];
        let w = vec![1.0; 6];
        let g = Graph::from_edges(&from, &to, &w, 4);
        let cc = closeness_centrality(&g, false);
        assert!(cc[0] > cc[1]);
    }
}
