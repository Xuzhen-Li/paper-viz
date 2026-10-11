# Layout of the example: a generic genotype x environment prediction pipeline.
# Coordinates are in SVG px on a 1300 x 712 canvas (see helpers.W, helpers.H).
BLUE,RED,TEAL,PURPLE,GREEN='#1F72AE','#CC312C','#2aa198','#9a5bd1','#2e7d32'
# ---- zones
R(8,8,250,696,'#f2f4f7','#c9ced6',8,1)
R(266,8,300,696,'#eef1f5','#c9ced6',8,1)
R(574,8,330,696,'#f2f4f7','#c9ced6',8,1)
R(912,8,190,696,'#eef1f5','#c9ced6',8,1)
R(1110,8,184,696,'#e8f3ea','#b9d3bf',8,1)
T(133,32,'Input data',14,'bold'); T(416,32,'Encoders',14,'bold'); T(739,32,'Fusion',14,'bold')
T(1007,32,'Prediction',14,'bold'); T(1202,32,'Evaluation',14,'bold')

# ---- inputs: phenotype records
R(22,56,222,144,'#fff','#555',6)
T(34,76,'Phenotype records',11,'bold','start')
axes(42,88,184,52)
hist=[3,7,13,19,22,17,11,6,3]
for k,v in enumerate(hist):
    a(f'<rect x="{48+k*19.5:.1f}" y="{140-v*2.2:.1f}" width="16" height="{v*2.2:.1f}" fill="#62B4E7" stroke="#1F72AE" stroke-width="0.8"/>')
T(133,164,'yield, flowering date',10)
M(133,190,'y ∈ ℝ^n',11,tex=r'y \in \mathbb{R}^{n}')
# genotype matrix
R(22,216,222,236,'#fff','#555',6)
T(34,236,'Genotype matrix (SNPs)',11,'bold','start'); ICON('database',224,244,26)
pal={0:'#DEE4F0',1:'#8EBDDA',2:'#1D7CBB'}
for i in range(8):
    for j in range(12):
        v=int(rng.integers(0,3)); a(f'<rect x="{40+j*13.5:.1f}" y="{262+i*14:.1f}" width="12.5" height="13" fill="{pal[v]}"/>')
T(133,392,'0 / 1 / 2 copies of the minor allele',9)
M(133,428,'G ∈ {0,1,2}^(n×p)',11,tex=r'G \in \{0,1,2\}^{n \times p}')
# environment covariates
R(22,468,222,224,'#fff','#555',6)
T(34,488,'Environment covariates',11,'bold','start')
ICON('flame',202,484,15); ICON('snowflake',228,486,20)
axes(42,506,184,96)
xs=np.linspace(46,222,80); curve(xs,560-30*np.sin((xs-46)/176*math.pi),RED,1.4)
xs2=np.linspace(46,222,40); curve(xs2,578-9*np.abs(np.sin((xs2-46)/9)),BLUE,1.1)
T(50,520,'temperature',9,anchor='start',fill=RED); T(50,596,'rainfall',9,anchor='start',fill=BLUE)
M(133,640,'E ∈ ℝ^(n×t×c)',11,tex=r'E \in \mathbb{R}^{n \times t \times c}')
T(133,672,'daily weather and soil per site-year',9)

# ---- encoders
R(280,56,272,134,'#fff','#555',6)
T(416,78,'Quality control & imputation',11,'bold')
T(416,104,'minor allele frequency ≥ 0.05',10); T(416,124,'call rate ≥ 0.9',10); T(416,144,'missing calls imputed',10)
T(416,172,'markers kept: p',10,style='italic')
L([(244,300),(262,300),(262,123),(278,123)])
R(280,206,272,246,'#e3f4f1',TEAL,6,1.6)
T(416,226,'Genotype branch',11,'bold')
L([(300,190),(300,238)])
R(296,240,240,52,'#fde8d4','#e08a3a',5,1.4); T(416,260,'SNP embedding',11,'bold'); M(416,283,'e_j = W g_j + p_j',10,tex=r'e_{j} = W g_{j} + p_{j}')
L([(416,292),(416,304)])
R(296,306,240,52,'#a9d8d0',TEAL,5,1.4); T(416,326,'Convolution blocks ×3',11,'bold'); T(416,347,'(kernel 9, dilation 1–4)',10)
L([(416,358),(416,370)])
R(296,372,240,52,'#a9d8d0',TEAL,5,1.4); T(416,392,'Global pooling',11,'bold'); M(416,414,'h_g ∈ ℝ^d',10,tex=r'h_{g} \in \mathbb{R}^{d}')
R(280,468,272,224,'#efe3f7',PURPLE,6,1.6)
T(416,488,'Environment branch',11,'bold')
L([(244,523),(294,523)])
R(296,500,240,46,'#d8c3ef',PURPLE,5,1.4); T(416,518,'Daily series encoder',11,'bold'); T(416,538,'(temporal convolution)',10)
L([(416,546),(416,558)])
R(296,560,240,46,'#d8c3ef',PURPLE,5,1.4); T(416,578,'Season summary',11,'bold'); T(416,598,'(means, extremes, totals)',10)
L([(416,606),(416,618)])
R(296,620,240,46,'#d8c3ef',PURPLE,5,1.4); T(416,638,'Projection',11,'bold'); M(416,659,'h_e ∈ ℝ^d',10,tex=r'h_{e} \in \mathbb{R}^{d}')

# ---- fusion
R(590,56,298,250,'#fff','#555',6)
T(739,76,'Cross-attention fusion',11,'bold')
T(739,96,'environment state queries SNP tokens',9)
tok=[(612+k*31,116) for k in range(9)]; al=[0.05,0.1,0.35,0.9,0.4,0.12,0.6,0.2,0.08]
for (x_,y_),w_ in zip(tok,al):
    a(f'<line x1="{x_+9}" y1="{y_+18}" x2="739" y2="182" stroke="{TEAL}" stroke-width="{0.6+3.4*w_:.2f}" stroke-opacity="{0.25+0.75*w_:.2f}" stroke-linecap="round"/>')
for x_,y_ in tok: a(f'<rect x="{x_}" y="{y_}" width="18" height="18" rx="3" fill="#a9d8d0" stroke="{TEAL}" stroke-width="1.2"/>')
a(f'<circle cx="739" cy="186" r="9" fill="#d8c3ef" stroke="{PURPLE}" stroke-width="2"/>')
T(760,190,'q',10,anchor='start',style='italic')
M(739,236,'α_k = softmax_k(qᵀk_k / √d)',10,tex=r'\alpha_{k} = \mathrm{softmax}_{k}\!\left(q^{\top} k_{k} / \sqrt{d}\right)')
M(739,278,'z_a = Σ_k α_k v_k',10,tex=r'z_{a} = \sum_{k} \alpha_{k} v_{k}')
L([(536,398),(566,398),(566,262),(588,262)],TEAL,1.6)
L([(536,643),(570,643),(570,214),(588,214)],PURPLE,1.6)
L([(739,306),(739,320)])
R(590,322,298,130,'#fde8d4','#e08a3a',5,1.4)
T(739,344,'Genotype × environment interaction',11,'bold')
M(739,382,'z = [z_a; h_g; h_g ⊙ h_e]',10,tex=r'z = \left[\, z_{a};\ h_{g};\ h_{g} \odot h_{e} \,\right]')
T(739,420,'concatenated, then layer normalisation',9)
R(590,468,298,110,'#e8f3ea',GREEN,5,1.4)
T(739,490,'Site and year effects',11,'bold')
M(739,526,'u ~ N(0, σ_u² I)',10,tex=r'u \sim \mathcal{N}(0,\ \sigma_{u}^{2} I)')
T(739,556,'random intercepts, shared across folds',9)
# legend
L([(600,618),(640,618)],'#444',1.4); T(648,622,'forward pass',9,anchor='start')
L([(600,646),(640,646)],'#6b7686',1.2,True,'5,4'); T(648,650,'labels to the loss',9,anchor='start')
a(f'<rect x="602" y="666" width="30" height="12" rx="3" fill="#a9d8d0" stroke="{TEAL}" stroke-width="1.2"/>'); T(648,676,'trainable module',9,anchor='start')

# ---- prediction
R(926,56,162,170,'#fff','#555',6)
T(1007,76,'Training loss',11,'bold')
M(1007,114,'L = 1/n Σ_i (y_i − ŷ_i)²',8.5,tex=r'\mathcal{L} = \frac{1}{n}\sum_{i}(y_{i} - \hat{y}_{i})^{2}')
M(1007,150,'+ λ‖θ‖²',9,tex=r'+\ \lambda \Vert\theta\Vert_{2}^{2}')
T(1007,182,'mean squared error',9); T(1007,198,'plus weight decay',9)
L([(244,92),(258,92),(258,46),(950,46),(950,54)],'#6b7686',1.2,True,'5,4')
L([(888,387),(924,387)])
R(926,300,162,190,'#fff',GREEN,6,1.6)
T(1007,320,'Prediction head',11,'bold'); T(1007,337,'MLP 256 – 64 – 1',9)
lay=[(950,[360,385,410,435]),(985,[355,375,395,415,435]),(1020,[370,395,420]),(1055,[395])]
for (x1,ys1),(x2,ys2) in zip(lay,lay[1:]):
    for y1 in ys1:
        for y2 in ys2: a(f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="#5b6878" stroke-width="1"/>')
for x_,ys_ in lay:
    for y_ in ys_: a(f'<circle cx="{x_}" cy="{y_}" r="5.5" fill="url(#nodeg)" stroke="#26323f" stroke-width="1.6"/>')
M(1007,474,'ŷ = f_θ(z) + u',10,tex=r'\hat{y} = f_{\theta}(z) + u')
L([(1007,300),(1007,228)])
L([(888,523),(1007,523),(1007,492)],GREEN,1.4)
R(926,540,162,152,'#fff','#666',6,1.2,'5,4')
T(1007,560,'Prediction interval',11,'bold')
axes(944,574,130,72); xs=np.linspace(948,1070,30); yy=630-0.32*(xs-948)
band=' '.join(f'{x:.1f},{y-8:.1f}' for x,y in zip(xs,yy))+' '+' '.join(f'{x:.1f},{y+8:.1f}' for x,y in zip(xs[::-1],yy[::-1]))
a(f'<polygon points="{band}" fill="#5a63b8" fill-opacity="0.22" stroke="none"/>'); curve(xs,yy,'#3a3f8f',1.4)
M(1007,676,'ŷ ± 1.96 σ̂',10,tex=r'\hat{y} \pm 1.96\,\hat{\sigma}')

# ---- evaluation
R(1124,56,156,250,'#fff','#555',6)
T(1202,76,'Observed vs predicted',11,'bold')
axes(1144,92,120,112)
L([(1146,202),(1262,92)],'#888',1,False,'4,3')
for k in range(26):
    t_=k/25; x_=1150+108*t_; y_=198-104*t_+float(rng.normal(0,9))
    a(f'<circle cx="{x_:.1f}" cy="{y_:.1f}" r="2.6" fill="#62B4E7" stroke="#1F72AE" stroke-width="0.7"/>')
T(1204,224,'predicted ŷ',9); 
M(1202,256,'r = cor(y, ŷ)',10,tex=r'r = \mathrm{cor}(y,\ \hat{y})')
T(1202,284,'computed per environment',9)
L([(1088,395),(1106,395),(1106,180),(1122,180)])
L([(1202,306),(1202,320)])
R(1124,322,156,170,'#fff','#666',6,1)
T(1202,342,'Prediction accuracy',11,'bold')
ICON('gauge',1202,394,66)
M(1202,452,'r ∈ [−1, 1]',10,tex=r'r \in [-1,\ 1]')
T(1202,476,'on held-out sites',9)
R(1124,508,156,184,'#e8f3ea',GREEN,6,1.6)
T(1202,528,'Cross-validation',11,'bold')
for f in range(5):
    for s_ in range(5):
        fill='#F77E12' if s_==f else '#BFBFBF'
        a(f'<rect x="{1142+s_*24}" y="{546+f*20}" width="20" height="14" rx="2" fill="{fill}"/>')
T(1202,660,'leave one site out',10); T(1202,678,'test site in orange',9)
