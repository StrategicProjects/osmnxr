//! Shortest-path routing over a [`Graph`].

use crate::graph::Graph;
use std::cmp::Ordering;
use std::collections::BinaryHeap;

/// Min-heap entry ordered by ascending distance.
struct State {
    dist: f64,
    node: usize,
}

impl PartialEq for State {
    fn eq(&self, other: &Self) -> bool {
        self.dist == other.dist
    }
}
impl Eq for State {}
impl PartialOrd for State {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}
impl Ord for State {
    fn cmp(&self, other: &Self) -> Ordering {
        // Reverse so `BinaryHeap` (a max-heap) yields the smallest distance.
        other.dist.partial_cmp(&self.dist).unwrap_or(Ordering::Equal)
    }
}

/// Dijkstra single-source shortest distances. Returns a vector of length
/// `n_nodes`; unreachable nodes are `f64::INFINITY`.
pub fn dijkstra(graph: &Graph, source: usize) -> Vec<f64> {
    let mut dist = vec![f64::INFINITY; graph.n_nodes];
    dist[source] = 0.0;
    let mut heap = BinaryHeap::new();
    heap.push(State { dist: 0.0, node: source });
    while let Some(State { dist: d, node }) = heap.pop() {
        if d > dist[node] {
            continue;
        }
        for (next, w) in graph.neighbors(node) {
            let nd = d + w;
            if nd < dist[next] {
                dist[next] = nd;
                heap.push(State { dist: nd, node: next });
            }
        }
    }
    dist
}

/// Dijkstra with predecessor tracking, returning the shortest path from
/// `source` to `target` as a sequence of node indices (empty if unreachable).
pub fn shortest_path(graph: &Graph, source: usize, target: usize) -> Vec<usize> {
    let mut dist = vec![f64::INFINITY; graph.n_nodes];
    let mut prev = vec![usize::MAX; graph.n_nodes];
    dist[source] = 0.0;
    let mut heap = BinaryHeap::new();
    heap.push(State { dist: 0.0, node: source });
    while let Some(State { dist: d, node }) = heap.pop() {
        if node == target {
            break;
        }
        if d > dist[node] {
            continue;
        }
        for (next, w) in graph.neighbors(node) {
            let nd = d + w;
            if nd < dist[next] {
                dist[next] = nd;
                prev[next] = node;
                heap.push(State { dist: nd, node: next });
            }
        }
    }
    if dist[target].is_infinite() {
        return Vec::new();
    }
    let mut path = vec![target];
    let mut cur = target;
    while cur != source {
        cur = prev[cur];
        path.push(cur);
    }
    path.reverse();
    path
}

#[cfg(test)]
mod tests {
    use super::*;

    fn line_graph() -> Graph {
        // 0 -1-> 1 -1-> 2 -1-> 3, plus a shortcut 0 -10-> 3
        Graph::from_edges(&[0, 1, 2, 0], &[1, 2, 3, 3], &[1.0, 1.0, 1.0, 10.0], 4)
    }

    #[test]
    fn dijkstra_distances() {
        let g = line_graph();
        let d = dijkstra(&g, 0);
        assert_eq!(d, vec![0.0, 1.0, 2.0, 3.0]);
    }

    #[test]
    fn path_prefers_shorter_route() {
        let g = line_graph();
        assert_eq!(shortest_path(&g, 0, 3), vec![0, 1, 2, 3]);
    }

    #[test]
    fn unreachable_is_empty() {
        let g = Graph::from_edges(&[0], &[1], &[1.0], 3);
        assert!(shortest_path(&g, 0, 2).is_empty());
    }
}
