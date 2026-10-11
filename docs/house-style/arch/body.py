"""Layout of the example: a made-up genotype x environment prediction pipeline (1300 x 860 px canvas)."""
import math

import numpy as np

from helpers import PAL, FS, R, T, M, L, ICON, a, axes, curve, group

P = PAL
ZONE_Y0, ZONE_Y1 = 8, 812          # zones; the lane below (y about 836) carries the labels-to-loss line


def zone(gid, x, w, title, fill=None, stroke=None):
    R(x, ZONE_Y0, w, ZONE_Y1 - ZONE_Y0, fill or P['zone'], stroke or P['rule'], 'zone', gid=gid)
    T(x + w / 2, 34, title, 'zone')


def draw(rng):
    # ---- zones
    with group('zones'):
        zone('zone-input', 8, 250, 'Input data')
        zone('zone-encoders', 266, 300, 'Encoders', P['zone_alt'])
        zone('zone-fusion', 574, 330, 'Fusion')
        zone('zone-prediction', 912, 190, 'Prediction', P['zone_alt'])
        zone('zone-evaluation', 1110, 184, 'Evaluation', P['eval_light'], P['eval_rule'])

    # ---- input data
    with group('genotype-data'):
        R(22, 56, 222, 260, P['card'], P['grey'])
        T(34, 82, 'Genotype (SNPs)', 'title', anchor='start'); ICON('database', 220, 86, 34)
        fills = [P['input_light'], P['input_mid'], P['input']]
        for i in range(8):
            for j in range(12):
                a(f'<rect x="{40 + j * 13.5:.1f}" y="{112 + i * 14}" width="12.5" height="13" fill="{fills[int(rng.integers(0, 3))]}"/>')
        T(133, 250, 'minor-allele copies 0/1/2')
        M(133, 294, 'G ∈ {0,1,2}^(n×p)', r'G \in \{0,1,2\}^{n \times p}')
    with group('environment-data'):
        R(22, 332, 222, 296, P['card'], P['grey'])
        T(34, 358, 'Environment data', 'title', anchor='start')
        ICON('flame', 50, 386, 24); T(68, 392, 'heat days', anchor='start')
        ICON('snowflake', 164, 386, 30); T(184, 392, 'frost', anchor='start')
        axes(42, 414, 184, 96)
        xs = np.linspace(46, 222, 80); curve(xs, 474 - 28 * np.sin((xs - 46) / 176 * math.pi), P['heat'])
        xs2 = np.linspace(46, 222, 40); curve(xs2, 504 - 8 * np.abs(np.sin((xs2 - 46) / 9)), P['input'])
        T(42, 534, 'temperature', anchor='start', fill=P['heat']); T(226, 534, 'rainfall', anchor='end', fill=P['input'])
        M(133, 576, 'E ∈ ℝ^(n×t×c)', r'E \in \mathbb{R}^{n \times t \times c}')
        T(133, 610, 'daily, per site-year')
    with group('phenotype-data'):
        R(22, 644, 222, 160, P['card'], P['grey'])
        T(34, 670, 'Phenotype records', 'title', anchor='start')
        axes(42, 684, 184, 54)
        for k, v in enumerate([3, 7, 13, 19, 22, 17, 11, 6, 3]):
            a(f'<rect x="{48 + k * 19.5:.1f}" y="{738 - v * 2.2:.1f}" width="16" height="{v * 2.2:.1f}" fill="{P["input_mid"]}" stroke="{P["input"]}" stroke-width="1.25"/>')
        T(133, 764, 'yield, flowering date')
        M(133, 796, 'y ∈ ℝ^n', r'y \in \mathbb{R}^{n}')

    # ---- encoders
    with group('quality-control'):
        R(280, 56, 272, 160, P['card'], P['grey'])
        T(416, 82, 'Quality control', 'title')
        T(416, 110, 'allele frequency ≥ 0.05'); T(416, 134, 'call rate ≥ 0.9'); T(416, 158, 'missing calls imputed')
        T(416, 190, 'p markers kept', style='italic')
        L([(244, 136), (278, 136)])
    with group('genotype-branch'):
        R(280, 232, 272, 266, P['geno_light'], P['geno'], 'frame')
        T(416, 258, 'Genotype branch', 'title')
        L([(300, 216), (300, 266)])
        R(296, 268, 240, 62, P['fuse_light'], P['fuse']); T(416, 292, 'SNP embedding', 'title')
        M(416, 321, 'e_j = W g_j + p_j', r'e_{j} = W g_{j} + p_{j}')
        L([(416, 330), (416, 342)])
        R(296, 344, 240, 62, P['geno_mid'], P['geno']); T(416, 368, 'Convolution ×3', 'title'); T(416, 396, 'kernel 9, dilation 1–4')
        L([(416, 406), (416, 418)])
        R(296, 420, 240, 62, P['geno_mid'], P['geno']); T(416, 444, 'Global pooling', 'title')
        M(416, 473, 'h_g ∈ ℝ^d', r'h_{g} \in \mathbb{R}^{d}')
    with group('environment-branch'):
        R(280, 514, 272, 276, P['env_light'], P['env'], 'frame')
        T(416, 540, 'Environment branch', 'title')
        L([(244, 583), (294, 583)])
        R(296, 552, 240, 62, P['env_mid'], P['env']); T(416, 576, 'Series encoder', 'title'); T(416, 604, 'temporal convolution')
        L([(416, 614), (416, 626)])
        R(296, 628, 240, 62, P['env_mid'], P['env']); T(416, 652, 'Season summary', 'title'); T(416, 680, 'means, extremes, totals')
        L([(416, 690), (416, 702)])
        R(296, 704, 240, 62, P['env_mid'], P['env']); T(416, 728, 'Projection', 'title')
        M(416, 757, 'h_e ∈ ℝ^d', r'h_{e} \in \mathbb{R}^{d}')

    # ---- fusion
    with group('cross-attention'):
        R(590, 56, 298, 280, P['card'], P['grey'])
        T(739, 82, 'Cross-attention fusion', 'title')
        T(739, 108, 'environment queries SNP tokens')
        tok = [(612 + k * 31, 124) for k in range(9)]
        al = [0.05, 0.1, 0.35, 0.9, 0.4, 0.12, 0.6, 0.2, 0.08]
        for (x_, y_), w_ in zip(tok, al):
            a(f'<line x1="{x_ + 9}" y1="{y_ + 18}" x2="739" y2="190" stroke="{P["geno"]}" stroke-width="{1.25 + 3.0 * w_:.2f}"'
              f' stroke-opacity="{0.3 + 0.7 * w_:.2f}" stroke-linecap="round"/>')
        for x_, y_ in tok:
            a(f'<rect x="{x_}" y="{y_}" width="18" height="18" rx="3" fill="{P["geno_mid"]}" stroke="{P["geno"]}" stroke-width="1.25"/>')
        a(f'<circle cx="739" cy="196" r="9" fill="{P["env_mid"]}" stroke="{P["env"]}" stroke-width="2"/>')
        M(762, 202, 'q', r'q', anchor='start')
        M(739, 260, 'α_k = softmax_k(qᵀk_k / √d)', r'\alpha_{k} = \mathrm{softmax}_{k}(q^{\top} k_{k} / \sqrt{d})')
        M(739, 312, 'z_a = Σ_k α_k v_k', r'z_{a} = \sum_{k} \alpha_{k} v_{k}')
        L([(536, 451), (562, 451), (562, 290), (588, 290)], P['geno'])
        L([(536, 735), (570, 735), (570, 230), (588, 230)], P['env'])
    with group('interaction'):
        L([(739, 336), (739, 350)])
        R(590, 352, 298, 130, P['fuse_light'], P['fuse'])
        T(739, 378, 'G × E interaction', 'title')
        M(739, 422, 'z = [z_a; h_g; h_g ⊙ h_e]', r'z = [\, z_{a};\ h_{g};\ h_{g} \odot h_{e} \,]')
        T(739, 458, 'concatenated, layer-normalised')
    with group('site-year-effects'):
        R(590, 498, 298, 122, P['eval_light'], P['eval'])
        T(739, 524, 'Site and year effects', 'title')
        M(739, 566, 'u ~ N(0, σ_u² I)', r'u \sim \mathcal{N}(0,\ \sigma_{u}^{2} I)')
        T(739, 600, 'random intercepts')
    with group('legend'):
        L([(600, 666), (644, 666)]); T(656, 671, 'forward pass', anchor='start')
        L([(600, 700), (644, 700)], P['grey'], 'arrow_minor', dash='6,4'); T(656, 705, 'labels to the loss', anchor='start')
        a(f'<rect x="600" y="726" width="44" height="22" rx="5" fill="{P["card"]}" stroke="{P["grey"]}" stroke-width="2" stroke-dasharray="5,4"/>')
        T(656, 742, 'derived output', anchor='start')
        T(600, 780, 'card colour = branch or stage', anchor='start', fill=P['grey'])

    # ---- prediction
    with group('prediction-interval'):
        R(926, 56, 162, 182, P['card'], P['grey'], dash='6,4')
        T(1007, 82, 'Prediction', 'title'); T(1007, 102, 'interval', 'title')
        axes(944, 120, 126, 66)
        xs = np.linspace(948, 1066, 30); yy = 176 - 0.36 * (xs - 948)
        band = ' '.join(f'{x:.1f},{y - 8:.1f}' for x, y in zip(xs, yy)) + ' ' + ' '.join(f'{x:.1f},{y + 8:.1f}' for x, y in zip(xs[::-1], yy[::-1]))
        a(f'<polygon points="{band}" fill="{P["input"]}" fill-opacity="0.2" stroke="none"/>'); curve(xs, yy, P['input'])
        M(1007, 226, 'ŷ ± 1.96 σ̂', r'\hat{y} \pm 1.96\,\hat{\sigma}')
    with group('prediction-head'):
        R(926, 300, 162, 256, P['card'], P['eval'])
        T(1007, 326, 'Prediction', 'title'); T(1007, 346, 'head', 'title'); T(1007, 370, 'MLP 256–64–1')
        lay = [(950, [392, 417, 442, 467]), (985, [387, 407, 427, 447, 467]), (1020, [402, 427, 452]), (1055, [427])]
        for (x1, ys1), (x2, ys2) in zip(lay, lay[1:]):
            for y1 in ys1:
                for y2 in ys2:
                    a(f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{P["grey"]}" stroke-width="1.25"/>')
        for x_, ys_ in lay:
            for y_ in ys_:
                a(f'<circle cx="{x_}" cy="{y_}" r="5.5" fill="url(#nodeg)" stroke="{P['ink']}" stroke-width="1.6"/>')
        M(1007, 528, 'ŷ = f_θ(z) + u', r'\hat{y} = f_{\theta}(z) + u')
        L([(888, 417), (924, 417)])
        L([(888, 540), (924, 540)], P['eval'])
        L([(1007, 300), (1007, 240)])
    with group('training-loss'):
        L([(1007, 556), (1007, 598)])
        R(926, 600, 162, 204, P['card'], P['grey'])
        T(1007, 626, 'Training loss', 'title')
        M(1007, 666, 'L = mse(y, ŷ)', r'\mathcal{L} = \mathrm{mse}(y,\hat{y})')
        M(1007, 712, '+ λ‖θ‖²₂', r'+\ \lambda \Vert\theta\Vert_{2}^{2}')
        T(1007, 752, 'mean squared error'); T(1007, 780, '+ weight decay')
        L([(133, 804), (133, 836), (1050, 836), (1050, 806)], P['grey'], 'arrow_minor', dash='6,4')

    # ---- evaluation
    with group('observed-vs-predicted'):
        R(1124, 56, 156, 280, P['card'], P['grey'])
        T(1202, 82, 'Observed vs', 'title'); T(1202, 102, 'predicted', 'title')
        axes(1144, 120, 120, 112)
        L([(1146, 230), (1262, 120)], P['grey'], 'arrow_minor', arrow=False, dash='4,3')
        for k in range(26):
            t_ = k / 25; x_ = 1150 + 108 * t_; y_ = 226 - 104 * t_ + float(rng.normal(0, 9))
            a(f'<circle cx="{x_:.1f}" cy="{y_:.1f}" r="2.8" fill="{P["input_mid"]}" stroke="{P["input"]}" stroke-width="1.25"/>')
        T(1206, 256, 'predicted ŷ')
        M(1202, 296, 'r = cor(y, ŷ)', r'r = \mathrm{cor}(y,\ \hat{y})')
        T(1202, 324, 'per environment')
        L([(1088, 428), (1106, 428), (1106, 196), (1122, 196)])
    with group('accuracy'):
        L([(1202, 336), (1202, 350)])
        R(1124, 352, 156, 188, P['card'], P['grey'])
        T(1202, 378, 'Accuracy', 'title')
        ICON('gauge', 1202, 428, 72)
        M(1202, 498, 'r ∈ [−1, 1]', r'r \in [-1,\ 1]')
        T(1202, 526, 'held-out sites')
    with group('cross-validation'):
        R(1124, 556, 156, 248, P['eval_light'], P['eval'])
        T(1202, 582, 'Cross-', 'title'); T(1202, 602, 'validation', 'title')
        for f in range(5):
            for s_ in range(5):
                fill = P['fuse'] if s_ == f else P['off']
                a(f'<rect x="{1142 + s_ * 24}" y="{620 + f * 20}" width="20" height="14" rx="2" fill="{fill}"/>')
        T(1202, 746, 'leave one site out'); T(1202, 774, 'test fold: orange')
