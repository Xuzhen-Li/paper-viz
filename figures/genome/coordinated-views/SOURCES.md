# coordinated-views v2 — sources and changes

Same simulated data (data.csv copied byte-for-byte from redraws/coordinated-views/) and same wording as v1. Layout idea and references as in meta.yaml; no journal images in this folder.

v2 changes (contrast ruling `status/primary_rulings_bio_novel_5_layout_20261113.md`):
- Text-only contrast fix: panel a label 'Cluster 2' #F77E12 -> #B95E0E and 'Cluster 6' #62B4E7 -> #437B9E (dark variants of the same swatch). Points, squares and heatmap keep the house palette.
- Heatmap: 0.3 pt white separators between cells (review ②-C4).
- Panel b spans the same height as a and c (review ②-C5); equal x/y scale kept by widening the y range evenly; scale bar and selection note keep their offsets from the frame. Layout frozen before saving so PDF/PNG/preview share one geometry.
- House import path resolves the worktree styles/python from redraws/; no pvr, no _apply_canvas. Data, wording, n from data.csv unchanged.

Built in `redraws/_staging/coordinated-views-v2/try3/` (see check.txt there).
