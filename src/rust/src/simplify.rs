//! Topology simplification and intersection consolidation primitives.
//!
//! These functions work purely on graph topology (node indices); the R layer
//! is responsible for rebuilding `sf` geometry from the returned node chains
//! and component labels.

use std::collections::HashSet;

/// Distinct-neighbour undirected adjacency. Self-loops are ignored.
fn undirected_adjacency(from: &[usize], to: &[usize], n_nodes: usize) -> Vec<Vec<usize>> {
    let mut sets: Vec<HashSet<usize>> = vec![HashSet::new(); n_nodes];
    for i in 0..from.len() {
        if from[i] != to[i] {
            sets[from[i]].insert(to[i]);
            sets[to[i]].insert(from[i]);
        }
    }
    sets.into_iter()
        .map(|s| {
            let mut v: Vec<usize> = s.into_iter().collect();
            v.sort_unstable();
            v
        })
        .collect()
}

/// A node is a topological endpoint (kept after simplification) when it does
/// not have exactly two distinct neighbours, i.e. it is a dead-end, an
/// intersection, or isolated.
fn is_endpoint(adj: &[Vec<usize>], node: usize) -> bool {
    adj[node].len() != 2
}

/// Find simplified chains: every maximal path of interstitial (degree-2) nodes
/// between two endpoints. Each chain is returned once as an ordered vector of
/// node indices `[endpoint, ..interstitial.., endpoint]`.
pub fn simplify_paths(from: &[usize], to: &[usize], n_nodes: usize) -> Vec<Vec<usize>> {
    let adj = undirected_adjacency(from, to, n_nodes);
    let mut paths: Vec<Vec<usize>> = Vec::new();
    // Directed first-steps already consumed, to record each chain only once.
    let mut seen: HashSet<(usize, usize)> = HashSet::new();

    for u in 0..n_nodes {
        if !is_endpoint(&adj, u) {
            continue;
        }
        for &start in &adj[u] {
            if seen.contains(&(u, start)) {
                continue;
            }
            let mut path = vec![u];
            let mut prev = u;
            let mut cur = start;
            loop {
                path.push(cur);
                if is_endpoint(&adj, cur) || cur == u {
                    break;
                }
                let nbrs = &adj[cur];
                let next = if nbrs[0] == prev { nbrs[1] } else { nbrs[0] };
                prev = cur;
                cur = next;
            }
            let last = path[path.len() - 1];
            let before_last = path[path.len() - 2];
            seen.insert((u, start));
            seen.insert((last, before_last));
            paths.push(path);
        }
    }
    paths
}

/// Union-find root of `x` with path compression.
fn find(parent: &mut [usize], x: usize) -> usize {
    let mut root = x;
    while parent[root] != root {
        root = parent[root];
    }
    let mut cur = x;
    while parent[cur] != root {
        let next = parent[cur];
        parent[cur] = root;
        cur = next;
    }
    root
}

/// Connected-component label (the 0-based root node index) for each of `n`
/// nodes, given undirected `a`--`b` adjacency pairs.
pub fn connected_components(a: &[usize], b: &[usize], n: usize) -> Vec<i32> {
    let mut parent: Vec<usize> = (0..n).collect();
    for i in 0..a.len() {
        let ra = find(&mut parent, a[i]);
        let rb = find(&mut parent, b[i]);
        if ra != rb {
            parent[ra] = rb;
        }
    }
    (0..n).map(|i| find(&mut parent, i) as i32).collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn collapses_degree_two_chain() {
        // 0 -- 1 -- 2 -- 3 with 1,2 interstitial: one chain [0,1,2,3].
        let from = vec![0, 1, 2];
        let to = vec![1, 2, 3];
        let paths = simplify_paths(&from, &to, 4);
        assert_eq!(paths.len(), 1);
        assert_eq!(paths[0], vec![0, 1, 2, 3]);
    }

    #[test]
    fn keeps_intersection_nodes() {
        // A plus/cross: node 0 connects to 1,2,3,4 (all dead-ends).
        let from = vec![0, 0, 0, 0];
        let to = vec![1, 2, 3, 4];
        let paths = simplify_paths(&from, &to, 5);
        // four chains, each of length 2
        assert_eq!(paths.len(), 4);
        assert!(paths.iter().all(|p| p.len() == 2));
    }

    #[test]
    fn components_group_connected_nodes() {
        // pairs (0,1) and (2,3); 4 alone -> 3 components
        let comp = connected_components(&[0, 2], &[1, 3], 5);
        assert_eq!(comp[0], comp[1]);
        assert_eq!(comp[2], comp[3]);
        assert_ne!(comp[0], comp[2]);
        assert_ne!(comp[4], comp[0]);
    }
}
