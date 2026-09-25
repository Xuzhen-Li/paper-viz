# 40 nodes, about 90 edges, four communities. Weights are correlations.
set.seed(308)

n <- 40L
comm <- sample(c("C1", "C2", "C3", "C4"), n, replace = TRUE, prob = c(0.3, 0.28, 0.22, 0.2))
nodes <- sprintf("N%02d", 1:n)
edges <- list()
for (i in 1:(n - 1L)) {
  for (j in (i + 1L):n) {
    same <- comm[i] == comm[j]
    p <- if (same) 0.22 else 0.025
    if (runif(1) < p) {
      w <- if (same) rbeta(1, 6, 2) else rbeta(1, 2, 6)
      # keep a little noise so within-community weights are not a hard floor
      w <- min(0.95, max(0.08, w + rnorm(1, 0, 0.04)))
      edges[[length(edges) + 1L]] <- data.frame(
        from = nodes[i], to = nodes[j], weight = round(w, 3),
        community = comm[i], stringsAsFactors = FALSE
      )
    }
  }
}
el <- do.call(rbind, edges)
# trim or top up toward 90 edges, preferring stronger within-community links
if (nrow(el) > 90L) {
  el <- el[order(-el$weight), , drop = FALSE]
  el <- el[seq_len(90L), , drop = FALSE]
}
# every node should appear at least once
seen <- unique(c(el$from, el$to))
miss <- setdiff(nodes, seen)
for (m in miss) {
  i <- match(m, nodes)
  j <- sample(setdiff(which(comm == comm[i]), i), 1L)
  el <- rbind(el, data.frame(
    from = nodes[i], to = nodes[j], weight = round(runif(1, 0.35, 0.7), 3),
    community = comm[i], stringsAsFactors = FALSE
  ))
}
# node community lookup is the community of `from`; add a zero-weight note? 
# store each node's community on a column that plot can recover:
# duplicate community of `to` by adding rows is unnecessary if we write node table
# into the same file via a convention. Keep community as the `from` node's group,
# and also write the `to` node group by ensuring a matching from-row exists.
node_comm <- setNames(comm, nodes)
el$community <- node_comm[el$from]
utils::write.csv(el, "data.csv", row.names = FALSE)
utils::write.csv(
  data.frame(node = nodes, community = comm, stringsAsFactors = FALSE),
  "data_nodes.csv",
  row.names = FALSE
)
