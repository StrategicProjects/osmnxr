//! Shortest-path routing over a [`Graph`].

use crate::graph::Graph;
use std::cmp::Ordering;
use std::collections::{BinaryHeap, HashMap, HashSet};

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

/// Dijkstra from `source` to `target` that ignores `blocked_nodes` and the
/// directed edges in `blocked_edges`. Returns `(path, cost)`; an empty path and
/// `f64::INFINITY` when the target is unreachable. Used by Yen's algorithm.
fn shortest_path_blocked(
    graph: &Graph,
    source: usize,
    target: usize,
    blocked_nodes: &HashSet<usize>,
    blocked_edges: &HashSet<(usize, usize)>,
) -> (Vec<usize>, f64) {
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
            if blocked_nodes.contains(&next) || blocked_edges.contains(&(node, next)) {
                continue;
            }
            let nd = d + w;
            if nd < dist[next] {
                dist[next] = nd;
                prev[next] = node;
                heap.push(State { dist: nd, node: next });
            }
        }
    }
    if dist[target].is_infinite() {
        return (Vec::new(), f64::INFINITY);
    }
    let mut path = vec![target];
    let mut cur = target;
    while cur != source {
        cur = prev[cur];
        path.push(cur);
    }
    path.reverse();
    (path, dist[target])
}

/// Minimum directed edge weight for each `(u, v)` pair, for scoring paths.
fn edge_weight_map(from: &[usize], to: &[usize], weight: &[f64]) -> HashMap<(usize, usize), f64> {
    let mut m: HashMap<(usize, usize), f64> = HashMap::new();
    for i in 0..from.len() {
        let key = (from[i], to[i]);
        let e = m.entry(key).or_insert(f64::INFINITY);
        if weight[i] < *e {
            *e = weight[i];
        }
    }
    m
}

fn path_cost(path: &[usize], wmap: &HashMap<(usize, usize), f64>) -> f64 {
    let mut c = 0.0;
    for w in path.windows(2) {
        c += wmap.get(&(w[0], w[1])).copied().unwrap_or(f64::INFINITY);
    }
    c
}

/// Yen's algorithm for the `k` loopless shortest paths from `source` to
/// `target`. Returns up to `k` `(path, cost)` pairs in increasing cost order.
pub fn k_shortest_paths(
    graph: &Graph,
    from: &[usize],
    to: &[usize],
    weight: &[f64],
    source: usize,
    target: usize,
    k: usize,
) -> Vec<(Vec<usize>, f64)> {
    let wmap = edge_weight_map(from, to, weight);
    let empty_n: HashSet<usize> = HashSet::new();
    let empty_e: HashSet<(usize, usize)> = HashSet::new();

    let mut accepted: Vec<(Vec<usize>, f64)> = Vec::new();
    let (first, first_cost) = shortest_path_blocked(graph, source, target, &empty_n, &empty_e);
    if first.is_empty() {
        return accepted;
    }
    accepted.push((first, first_cost));

    let mut candidates: Vec<(Vec<usize>, f64)> = Vec::new();
    while accepted.len() < k {
        let last = &accepted[accepted.len() - 1].0;
        for i in 0..last.len() - 1 {
            let spur_node = last[i];
            let root_path = &last[0..=i];

            let mut blocked_edges: HashSet<(usize, usize)> = HashSet::new();
            for (p, _) in &accepted {
                if p.len() > i && &p[0..=i] == root_path {
                    blocked_edges.insert((p[i], p[i + 1]));
                }
            }
            let mut blocked_nodes: HashSet<usize> = HashSet::new();
            for &n in &root_path[0..root_path.len() - 1] {
                blocked_nodes.insert(n);
            }

            let (spur, _) =
                shortest_path_blocked(graph, spur_node, target, &blocked_nodes, &blocked_edges);
            if spur.is_empty() {
                continue;
            }
            let mut total = root_path[0..root_path.len() - 1].to_vec();
            total.extend_from_slice(&spur);
            let cost = path_cost(&total, &wmap);
            if !candidates.iter().any(|(p, _)| *p == total)
                && !accepted.iter().any(|(p, _)| *p == total)
            {
                candidates.push((total, cost));
            }
        }
        if candidates.is_empty() {
            break;
        }
        candidates.sort_by(|a, b| a.1.partial_cmp(&b.1).unwrap_or(Ordering::Equal));
        accepted.push(candidates.remove(0));
    }
    accepted
}

/// Row-major shortest-distance matrix from each source to each target.
pub fn distance_matrix(graph: &Graph, sources: &[usize], targets: &[usize]) -> Vec<f64> {
    let mut out = Vec::with_capacity(sources.len() * targets.len());
    for &s in sources {
        let dist = dijkstra(graph, s);
        for &t in targets {
            out.push(dist[t]);
        }
    }
    out
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

    #[test]
    fn yen_finds_two_distinct_paths() {
        // 0->1->3 (cost 2) and 0->2->3 (cost 4)
        let from = vec![0, 1, 0, 2];
        let to = vec![1, 3, 2, 3];
        let w = vec![1.0, 1.0, 2.0, 2.0];
        let g = Graph::from_edges(&from, &to, &w, 4);
        let paths = k_shortest_paths(&g, &from, &to, &w, 0, 3, 2);
        assert_eq!(paths.len(), 2);
        assert_eq!(paths[0].0, vec![0, 1, 3]);
        assert!((paths[0].1 - 2.0).abs() < 1e-9);
        assert_eq!(paths[1].0, vec![0, 2, 3]);
        assert!((paths[1].1 - 4.0).abs() < 1e-9);
    }

    #[test]
    fn yen_caps_at_available_paths() {
        let from = vec![0, 1];
        let to = vec![1, 2];
        let w = vec![1.0, 1.0];
        let g = Graph::from_edges(&from, &to, &w, 3);
        let paths = k_shortest_paths(&g, &from, &to, &w, 0, 2, 5);
        assert_eq!(paths.len(), 1);
    }

    #[test]
    fn distance_matrix_shape_and_values() {
        let g = line_graph();
        let dm = distance_matrix(&g, &[0, 1], &[2, 3]);
        assert_eq!(dm, vec![2.0, 3.0, 1.0, 2.0]);
    }
}
