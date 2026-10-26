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

/// Cost of the arc `i -> j` in a row-major `n x n` cost matrix.
#[inline]
fn arc(cost: &[f64], n: usize, i: usize, j: usize) -> f64 {
    cost[i * n + j]
}

/// Total cost of a tour over a row-major `n x n` cost matrix; the closing arc
/// back to the first stop is included when `closed`.
fn tour_cost(cost: &[f64], n: usize, tour: &[usize], closed: bool) -> f64 {
    let mut c = 0.0;
    for w in tour.windows(2) {
        c += arc(cost, n, w[0], w[1]);
    }
    if closed && tour.len() > 1 {
        c += arc(cost, n, tour[tour.len() - 1], tour[0]);
    }
    c
}

/// Nearest-neighbour tour construction from `start`. A fixed `end` (for an
/// open route) is reserved and appended last.
fn nearest_neighbor_tour(cost: &[f64], n: usize, start: usize, end: Option<usize>) -> Vec<usize> {
    let mut visited = vec![false; n];
    let mut tour = Vec::with_capacity(n);
    tour.push(start);
    visited[start] = true;
    let reserved = match end {
        Some(e) if e != start => {
            visited[e] = true;
            1
        }
        _ => 0,
    };
    while tour.len() < n - reserved {
        let last = *tour.last().unwrap();
        let mut best = usize::MAX;
        let mut best_cost = f64::INFINITY;
        for j in 0..n {
            if !visited[j] && (best == usize::MAX || arc(cost, n, last, j) < best_cost) {
                best = j;
                best_cost = arc(cost, n, last, j);
            }
        }
        visited[best] = true;
        tour.push(best);
    }
    if let Some(e) = end {
        if e != start {
            tour.push(e);
        }
    }
    tour
}

/// Local search over three move families, each evaluated by recomputing the
/// candidate's full tour cost, which keeps every move exact on asymmetric
/// matrices: or-opt (relocate a segment of 1..=3 stops, forward or reversed),
/// pairwise swaps, and 2-opt segment reversals. The first stop stays fixed
/// (and the last, when `fix_end`). Repeats until a full pass yields no strict
/// improvement; returns the final tour cost.
fn local_search(cost: &[f64], n: usize, tour: &mut Vec<usize>, closed: bool, fix_end: bool) -> f64 {
    let len = tour.len();
    let mut best_cost = tour_cost(cost, n, tour, closed);
    if len < 3 {
        return best_cost;
    }
    let tail = if fix_end { 1 } else { 0 };
    loop {
        let mut improved = false;
        // or-opt: relocate segments of 1..=3 stops, forward or reversed
        for seg_len in 1..=3usize.min(len - 2) {
            if 1 + seg_len + tail > len {
                break;
            }
            for i in 1..=(len - seg_len - tail) {
                let segment: Vec<usize> = tour[i..i + seg_len].to_vec();
                let mut rest: Vec<usize> = Vec::with_capacity(len - seg_len);
                rest.extend_from_slice(&tour[..i]);
                rest.extend_from_slice(&tour[i + seg_len..]);
                let last_slot = rest.len() - tail;
                for j in 1..=last_slot {
                    for reversed in [false, true] {
                        if reversed && seg_len == 1 {
                            continue;
                        }
                        let mut cand = Vec::with_capacity(len);
                        cand.extend_from_slice(&rest[..j]);
                        if reversed {
                            cand.extend(segment.iter().rev());
                        } else {
                            cand.extend_from_slice(&segment);
                        }
                        cand.extend_from_slice(&rest[j..]);
                        let c = tour_cost(cost, n, &cand, closed);
                        if c < best_cost {
                            best_cost = c;
                            *tour = cand;
                            improved = true;
                        }
                    }
                }
            }
        }
        // swaps and 2-opt reversals over movable positions
        let hi = len - tail;
        for i in 1..hi {
            for j in (i + 1)..hi {
                let mut cand = tour.clone();
                cand.swap(i, j);
                let c = tour_cost(cost, n, &cand, closed);
                if c < best_cost {
                    best_cost = c;
                    *tour = cand;
                    improved = true;
                }
                let mut cand = tour.clone();
                cand[i..=j].reverse();
                let c = tour_cost(cost, n, &cand, closed);
                if c < best_cost {
                    best_cost = c;
                    *tour = cand;
                    improved = true;
                }
            }
        }
        if !improved {
            break;
        }
    }
    best_cost
}

/// Tiny deterministic xorshift64 RNG, so results are reproducible and the R
/// session's RNG stream is untouched.
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

    /// Uniform draw in `lo..hi` (hi exclusive).
    fn range(&mut self, lo: usize, hi: usize) -> usize {
        lo + (self.next() % (hi - lo) as u64) as usize
    }
}

/// Double-bridge perturbation: cuts the tour after the fixed first stop into
/// four consecutive parts A B C D and reassembles them as A C B D. Segment
/// orientation is preserved, so the kick is valid on asymmetric matrices, and
/// the first and last positions stay put.
fn double_bridge(rng: &mut Rng, tour: &[usize]) -> Vec<usize> {
    let len = tour.len();
    if len < 4 {
        return tour.to_vec();
    }
    let mut cuts = [
        rng.range(1, len),
        rng.range(1, len),
        rng.range(1, len),
    ];
    cuts.sort_unstable();
    let [a, b, c] = cuts;
    if a == b || b == c {
        return tour.to_vec();
    }
    let mut out = Vec::with_capacity(len);
    out.extend_from_slice(&tour[..a]);
    out.extend_from_slice(&tour[b..c]);
    out.extend_from_slice(&tour[a..b]);
    out.extend_from_slice(&tour[c..]);
    out
}

/// Heuristic travelling-salesman tour over a row-major `n x n` cost matrix.
/// Builds a nearest-neighbour tour and, when `improve`, polishes it with an
/// iterated local search: or-opt/swap/2-opt descent restarted from
/// double-bridge perturbations, keeping the best tour found. The tour starts
/// at `start`; when `closed` it returns there (and `end` is ignored),
/// otherwise a fixed `end` pins the final stop and `None` leaves it free.
/// Returns the visiting order as indices into the matrix.
pub fn tsp_tour(
    cost: &[f64],
    n: usize,
    start: usize,
    end: Option<usize>,
    closed: bool,
    improve: bool,
) -> Vec<usize> {
    if n == 0 {
        return Vec::new();
    }
    if n == 1 {
        return vec![start];
    }
    // Unreachable pairs come in as Inf; use a large finite penalty instead so
    // cost comparisons stay well-defined (the R layer rejects routes that
    // still contain such arcs).
    let cost: Vec<f64> = cost
        .iter()
        .map(|&c| if c.is_finite() { c } else { 1e15 })
        .collect();
    let end = if closed { None } else { end };
    let mut tour = nearest_neighbor_tour(&cost, n, start, end);
    if !improve {
        return tour;
    }
    let fix_end = end.is_some();
    let mut best_cost = local_search(&cost, n, &mut tour, closed, fix_end);

    // Iterated local search with a work budget that shrinks as the O(n^3)
    // descent grows, and an early stop after a stretch of fruitless kicks.
    let kicks = (100_000_000 / (n * n * n).max(1)).clamp(25, 400);
    let patience = (kicks / 4).max(20);
    let mut rng = Rng(0x9E3779B97F4A7C15);
    let mut since_improved = 0usize;
    for _ in 0..kicks {
        let mut cand = double_bridge(&mut rng, &tour);
        let c = local_search(&cost, n, &mut cand, closed, fix_end);
        if c < best_cost {
            best_cost = c;
            tour = cand;
            since_improved = 0;
        } else {
            since_improved += 1;
            if since_improved >= patience {
                break;
            }
        }
    }
    tour
}

/// A Pareto-optimal route found by [`pareto_paths`].
pub struct ParetoRoute {
    pub path: Vec<usize>,
    pub cost: f64,
    pub resource: f64,
}

/// A label in the bicriteria search: the node reached, and the arena index of
/// the predecessor label (`usize::MAX` for the source). The accumulated
/// cost/resource pair travels in the heap entry instead.
struct Label {
    node: usize,
    pred: usize,
}

/// Heap entry ordered lexicographically by ascending `(cost, resource)`.
struct BiState {
    cost: f64,
    resource: f64,
    label: usize,
}

impl PartialEq for BiState {
    fn eq(&self, other: &Self) -> bool {
        self.cost == other.cost && self.resource == other.resource
    }
}
impl Eq for BiState {}
impl PartialOrd for BiState {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}
impl Ord for BiState {
    fn cmp(&self, other: &Self) -> Ordering {
        // Reverse so `BinaryHeap` (a max-heap) yields the lex-smallest pair.
        other
            .cost
            .partial_cmp(&self.cost)
            .unwrap_or(Ordering::Equal)
            .then(other.resource.partial_cmp(&self.resource).unwrap_or(Ordering::Equal))
    }
}

/// Bicriteria shortest paths from `source` to `target` by label-setting
/// (Martins' algorithm): every edge carries a `(cost, resource)` pair and the
/// result is the Pareto front of nondominated `(cost, resource)` path values,
/// in increasing cost / decreasing resource order. With a finite `budget` the
/// front is restricted to paths with `resource <= budget`, so its first entry
/// solves the constrained shortest path problem exactly. `max_routes` caps the
/// number of routes returned (`usize::MAX` for the whole front).
///
/// Labels are popped lexicographically by `(cost, resource)`, which makes the
/// per-node dominance test a single comparison against the best resource seen
/// at that node. Reverse-Dijkstra lower bounds on the remaining resource prune
/// labels that cannot reach the target within budget, and labels whose
/// projected resource cannot improve on the target's front are dropped early.
/// Weights must be nonnegative; the search is exact.
pub fn pareto_paths(
    from: &[usize],
    to: &[usize],
    w_cost: &[f64],
    w_res: &[f64],
    n_nodes: usize,
    source: usize,
    target: usize,
    budget: f64,
    max_routes: usize,
) -> Vec<ParetoRoute> {
    if max_routes == 0 {
        return Vec::new();
    }
    if source == target {
        return vec![ParetoRoute { path: vec![source], cost: 0.0, resource: 0.0 }];
    }
    // Two CSR graphs over the same edge order, so slot `e` holds the same
    // edge in both and `(targets[e], cost.weights[e], res.weights[e])` is one
    // directed edge with its pair of weights.
    let g_cost = Graph::from_edges(from, to, w_cost, n_nodes);
    let g_res = Graph::from_edges(from, to, w_res, n_nodes);

    // Reverse-graph Dijkstra bounds: least possible remaining resource from
    // each node to the target (also detects nodes that cannot reach it).
    let rev_res = Graph::from_edges(to, from, w_res, n_nodes);
    let lb_res = dijkstra(&rev_res, target);

    let mut arena: Vec<Label> = Vec::new();
    let mut heap: BinaryHeap<BiState> = BinaryHeap::new();
    // Best (lowest) resource among labels made permanent at each node; pops
    // arrive in increasing cost, so a new label is dominated iff it cannot
    // strictly improve this.
    let mut min_res = vec![f64::INFINITY; n_nodes];
    let mut routes: Vec<ParetoRoute> = Vec::new();

    if lb_res[source].is_finite() && lb_res[source] <= budget {
        arena.push(Label { node: source, pred: usize::MAX });
        heap.push(BiState { cost: 0.0, resource: 0.0, label: 0 });
    }

    while let Some(BiState { cost, resource, label }) = heap.pop() {
        let node = arena[label].node;
        if min_res[node] <= resource {
            continue; // dominated by (or duplicating) a permanent label
        }
        min_res[node] = resource;
        if node == target {
            let mut path = Vec::new();
            let mut cur = label;
            while cur != usize::MAX {
                path.push(arena[cur].node);
                cur = arena[cur].pred;
            }
            path.reverse();
            routes.push(ParetoRoute { path, cost, resource });
            if routes.len() >= max_routes {
                break;
            }
            continue;
        }
        let start = g_cost.offsets[node];
        let end = g_cost.offsets[node + 1];
        for e in start..end {
            let next = g_cost.targets[e];
            let nc = cost + g_cost.weights[e];
            let nr = resource + g_res.weights[e];
            // Within budget even in the best case, able to improve the next
            // node's front, and able to improve the target's front.
            if !lb_res[next].is_finite()
                || nr + lb_res[next] > budget
                || min_res[next] <= nr
                || min_res[target] <= nr + lb_res[next]
            {
                continue;
            }
            arena.push(Label { node: next, pred: label });
            heap.push(BiState { cost: nc, resource: nr, label: arena.len() - 1 });
        }
    }
    routes
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

    /// 4 stops on a line at x = 0, 1, 2, 10 with symmetric |xi - xj| costs.
    fn line_costs() -> Vec<f64> {
        let xs: [f64; 4] = [0.0, 1.0, 2.0, 10.0];
        let mut c = Vec::with_capacity(16);
        for i in 0..4 {
            for j in 0..4 {
                c.push((xs[i] - xs[j]).abs());
            }
        }
        c
    }

    #[test]
    fn tsp_closed_tour_is_a_permutation_returning_home() {
        let c = line_costs();
        let tour = tsp_tour(&c, 4, 0, None, true, true);
        let mut sorted = tour.clone();
        sorted.sort_unstable();
        assert_eq!(sorted, vec![0, 1, 2, 3]);
        assert_eq!(tour[0], 0);
        // Optimal closed tour on a line sweeps out and back: cost 2 * 10.
        assert!((tour_cost(&c, 4, &tour, true) - 20.0).abs() < 1e-9);
    }

    #[test]
    fn tsp_open_route_respects_fixed_end() {
        let c = line_costs();
        let tour = tsp_tour(&c, 4, 3, Some(0), false, true);
        assert_eq!(tour[0], 3);
        assert_eq!(tour[3], 0);
        // Optimal open route 3 -> 2 -> 1 -> 0 costs 10.
        assert!((tour_cost(&c, 4, &tour, false) - 10.0).abs() < 1e-9);
    }

    #[test]
    fn or_opt_fixes_a_greedy_mistake() {
        // Open free-end route from 0. Greedy takes the cheap bait arc 0 -> 1,
        // then 1 -> 3, and is forced onto 3 -> 2 (cost 100): 1 + 2 + 100 = 103.
        // The optimum is 0 -> 2 -> 3 -> 1: 2 + 1 + 3 = 6, which or-opt reaches
        // by relocating the segment [1, 3] reversed.
        let c = vec![
            0.0, 1.0, 2.0, 50.0, //
            1.0, 0.0, 100.0, 2.0, //
            2.0, 100.0, 0.0, 1.0, //
            50.0, 3.0, 100.0, 0.0,
        ];
        let nn = tsp_tour(&c, 4, 0, None, false, false);
        let improved = tsp_tour(&c, 4, 0, None, false, true);
        assert_eq!(nn, vec![0, 1, 3, 2]);
        assert!((tour_cost(&c, 4, &nn, false) - 103.0).abs() < 1e-9);
        assert_eq!(improved, vec![0, 2, 3, 1]);
        assert!((tour_cost(&c, 4, &improved, false) - 6.0).abs() < 1e-9);
    }

    #[test]
    fn tsp_handles_asymmetric_costs() {
        // Cheap arcs only along the directed cycle 0 -> 1 -> 2 -> 0 (cost 1
        // each); every other arc costs 10. Closed tour 0 -> 1 -> 2 costs 3,
        // the reverse costs 30, so the solver must respect arc direction.
        let c = vec![0.0, 1.0, 10.0, 10.0, 0.0, 1.0, 1.0, 10.0, 0.0];
        let tour = tsp_tour(&c, 3, 0, None, true, true);
        assert_eq!(tour, vec![0, 1, 2]);
    }

    /// Minimum tour cost by brute force over all orders of stops 1..n, with
    /// stop 0 fixed first (and the closing arc added when `closed`).
    fn brute_force(cost: &[f64], n: usize, closed: bool) -> f64 {
        fn go(cost: &[f64], n: usize, tour: &mut Vec<usize>, rest: &mut Vec<usize>, closed: bool, best: &mut f64) {
            if rest.is_empty() {
                let c = tour_cost(cost, n, tour, closed);
                if c < *best {
                    *best = c;
                }
                return;
            }
            for i in 0..rest.len() {
                let x = rest.remove(i);
                tour.push(x);
                go(cost, n, tour, rest, closed, best);
                tour.pop();
                rest.insert(i, x);
            }
        }
        let mut best = f64::INFINITY;
        let mut tour = vec![0usize];
        let mut rest: Vec<usize> = (1..n).collect();
        go(cost, n, &mut tour, &mut rest, closed, &mut best);
        best
    }

    #[test]
    fn ils_matches_brute_force_on_random_asymmetric_instances() {
        let n = 7;
        for seed in 1..=8u64 {
            let mut rng = Rng(seed);
            let mut cost = vec![0.0; n * n];
            for i in 0..n {
                for j in 0..n {
                    if i != j {
                        cost[i * n + j] = (rng.next() % 1000) as f64 + 1.0;
                    }
                }
            }
            for closed in [true, false] {
                let tour = tsp_tour(&cost, n, 0, None, closed, true);
                let got = tour_cost(&cost, n, &tour, closed);
                let best = brute_force(&cost, n, closed);
                assert!(
                    (got - best).abs() < 1e-9,
                    "seed {seed} closed {closed}: got {got}, optimum {best}"
                );
            }
        }
    }

    #[test]
    fn ils_improves_on_nearest_neighbor_at_fifty_stops() {
        let n = 50;
        let mut rng = Rng(7);
        let mut cost = vec![0.0; n * n];
        for i in 0..n {
            for j in 0..n {
                if i != j {
                    cost[i * n + j] = (rng.next() % 1000) as f64 + 1.0;
                }
            }
        }
        let nn = tsp_tour(&cost, n, 0, None, true, false);
        let ils = tsp_tour(&cost, n, 0, None, true, true);
        assert!(tour_cost(&cost, n, &ils, true) < tour_cost(&cost, n, &nn, true));
    }

    /// Diamond with a cheap high-resource route, an expensive zero-resource
    /// route and a dominated direct edge.
    fn diamond() -> (Vec<usize>, Vec<usize>, Vec<f64>, Vec<f64>) {
        let from = vec![0, 1, 0, 2, 0];
        let to = vec![1, 3, 2, 3, 3];
        let cost = vec![1.0, 1.0, 3.0, 3.0, 10.0];
        let res = vec![5.0, 5.0, 0.0, 0.0, 2.0];
        (from, to, cost, res)
    }

    #[test]
    fn pareto_front_on_diamond() {
        let (from, to, cost, res) = diamond();
        let routes =
            pareto_paths(&from, &to, &cost, &res, 4, 0, 3, f64::INFINITY, usize::MAX);
        let vals: Vec<(f64, f64)> = routes.iter().map(|r| (r.cost, r.resource)).collect();
        assert_eq!(vals, vec![(2.0, 10.0), (6.0, 0.0)]);
        assert_eq!(routes[0].path, vec![0, 1, 3]);
        assert_eq!(routes[1].path, vec![0, 2, 3]);
    }

    #[test]
    fn budget_picks_the_cheapest_feasible_route() {
        let (from, to, cost, res) = diamond();
        // Budget 5 rules out the (2, 10) route; (6, 0) beats (10, 2).
        let routes = pareto_paths(&from, &to, &cost, &res, 4, 0, 3, 5.0, 1);
        assert_eq!(routes.len(), 1);
        assert_eq!(routes[0].path, vec![0, 2, 3]);
        // Budget 2 admits the dominated-direct edge as the only option left
        // besides (6, 0); the cheapest feasible is still (6, 0).
        let routes = pareto_paths(&from, &to, &cost, &res, 4, 0, 3, 2.0, usize::MAX);
        let vals: Vec<(f64, f64)> = routes.iter().map(|r| (r.cost, r.resource)).collect();
        assert_eq!(vals, vec![(6.0, 0.0)]);
    }

    #[test]
    fn infeasible_budget_and_unreachable_target_are_empty() {
        let (from, to, cost, res) = diamond();
        assert!(pareto_paths(&from, &to, &cost, &res, 4, 0, 3, -1.0, usize::MAX).is_empty());
        // Node 3 has no out-edges, so nothing reaches a 5th isolated node.
        assert!(pareto_paths(&from, &to, &cost, &res, 5, 0, 4, f64::INFINITY, usize::MAX)
            .is_empty());
    }

    #[test]
    fn pareto_trivial_and_capped() {
        let (from, to, cost, res) = diamond();
        let same = pareto_paths(&from, &to, &cost, &res, 4, 2, 2, f64::INFINITY, usize::MAX);
        assert_eq!(same.len(), 1);
        assert_eq!(same[0].path, vec![2]);
        let capped = pareto_paths(&from, &to, &cost, &res, 4, 0, 3, f64::INFINITY, 1);
        assert_eq!(capped.len(), 1);
        assert_eq!(capped[0].path, vec![0, 1, 3]);
    }

    /// All simple paths from `s` to `t` as `(cost, resource)` pairs.
    fn enumerate_values(
        from: &[usize],
        to: &[usize],
        cost: &[f64],
        res: &[f64],
        n: usize,
        s: usize,
        t: usize,
    ) -> Vec<(f64, f64)> {
        fn go(
            edges: &[(usize, usize, f64, f64)],
            t: usize,
            node: usize,
            seen: &mut Vec<bool>,
            c: f64,
            r: f64,
            out: &mut Vec<(f64, f64)>,
        ) {
            if node == t {
                out.push((c, r));
                return;
            }
            for &(u, v, wc, wr) in edges {
                if u == node && !seen[v] {
                    seen[v] = true;
                    go(edges, t, v, seen, c + wc, r + wr, out);
                    seen[v] = false;
                }
            }
        }
        let edges: Vec<(usize, usize, f64, f64)> = (0..from.len())
            .map(|i| (from[i], to[i], cost[i], res[i]))
            .collect();
        let mut seen = vec![false; n];
        seen[s] = true;
        let mut out = Vec::new();
        go(&edges, t, s, &mut seen, 0.0, 0.0, &mut out);
        out
    }

    /// Nondominated subset of `(cost, resource)` values, deduplicated and
    /// sorted by increasing cost.
    fn pareto_filter(mut vals: Vec<(f64, f64)>) -> Vec<(f64, f64)> {
        vals.sort_by(|a, b| {
            a.0.partial_cmp(&b.0).unwrap().then(a.1.partial_cmp(&b.1).unwrap())
        });
        let mut front: Vec<(f64, f64)> = Vec::new();
        for (c, r) in vals {
            if front.iter().all(|&(fc, fr)| !(fc <= c && fr <= r)) {
                front.push((c, r));
            }
        }
        front
    }

    #[test]
    fn pareto_matches_brute_force_on_random_graphs() {
        for seed in 1..=12u64 {
            let mut rng = Rng(seed);
            let n = 6usize;
            let mut from = Vec::new();
            let mut to = Vec::new();
            let mut cost = Vec::new();
            let mut res = Vec::new();
            for u in 0..n {
                for v in 0..n {
                    if u != v && rng.next() % 100 < 45 {
                        from.push(u);
                        to.push(v);
                        cost.push((rng.next() % 20) as f64 + 1.0);
                        // About half the edges consume no resource at all.
                        res.push(if rng.next() % 2 == 0 { 0.0 } else { (rng.next() % 10) as f64 });
                    }
                }
            }
            let all = enumerate_values(&from, &to, &cost, &res, n, 0, n - 1);
            let want = pareto_filter(all.clone());
            let got: Vec<(f64, f64)> =
                pareto_paths(&from, &to, &cost, &res, n, 0, n - 1, f64::INFINITY, usize::MAX)
                    .iter()
                    .map(|r| (r.cost, r.resource))
                    .collect();
            assert_eq!(got, want, "seed {seed}: front mismatch");

            // Constrained answers agree with brute force for several budgets.
            for budget in [0.0, 3.0, 7.0, 15.0] {
                let best = all
                    .iter()
                    .filter(|&&(_, r)| r <= budget)
                    .map(|&(c, _)| c)
                    .fold(f64::INFINITY, f64::min);
                let solved =
                    pareto_paths(&from, &to, &cost, &res, n, 0, n - 1, budget, 1);
                match solved.first() {
                    Some(r) => {
                        assert!(
                            (r.cost - best).abs() < 1e-9 && r.resource <= budget,
                            "seed {seed} budget {budget}: got ({}, {}), optimum {best}",
                            r.cost,
                            r.resource
                        );
                    }
                    None => assert!(
                        best.is_infinite(),
                        "seed {seed} budget {budget}: solver found nothing, optimum {best}"
                    ),
                }
            }
        }
    }

    #[test]
    fn pareto_paths_are_consistent_with_their_values() {
        let (from, to, cost, res) = diamond();
        let wc = edge_weight_map(&from, &to, &cost);
        for r in pareto_paths(&from, &to, &cost, &res, 4, 0, 3, f64::INFINITY, usize::MAX) {
            assert!((path_cost(&r.path, &wc) - r.cost).abs() < 1e-9);
        }
    }

    #[test]
    fn tsp_trivial_sizes() {
        assert_eq!(tsp_tour(&[0.0], 1, 0, None, true, true), vec![0]);
        let c = vec![0.0, 2.0, 3.0, 0.0];
        assert_eq!(tsp_tour(&c, 2, 1, None, false, true), vec![1, 0]);
    }
}
