# Phenotype-to-Single-Cell & Spatial Mapping Methods

A reference guide to published computational methods that connect **sample-level phenotypes** (clinical outcomes, treatment response, disease status, survival, etc.) to **single-cell** and/or **spatial** transcriptomics. Methods are grouped by primary data modality and integration strategy.

> **Scope note:** This list focuses on methods whose explicit goal is phenotype mapping or phenotype-associated cell/spot identification—not general cell typing, deconvolution-only tools, or spatial niche discovery without clinical linkage (unless they support phenotype transfer as a core feature). **Related methods** (within-cohort differential abundance, perturbation prioritization, drug-response transfer) and **out-of-scope adjacent tools** are included in separate sections at the end for completeness.

---

## Quick comparison

Sorted by **publication date** (newest first). Citation counts from [OpenAlex](https://openalex.org/) (retrieved 14 Jul 2026; stClinic refreshed when added). **Published** uses `YYYY-MM` of the cited reference: journal issue date for peer-reviewed papers; **latest bioRxiv version post date** for preprints (not the DOI prefix date when they differ).

| Published | Method | Citations | Journal / status | Modalities | Bulk? | Primary output | Lang | Code |
|-----------|--------|-----------|------------------|------------|-------|----------------|------|------|
| 2026-06 | **SP-printer** | 0 | *J. Translational Medicine* | ST + bulk | Yes | Stage/malignancy spot maps | — | Not public |
| 2026-05 | **SigBridgeR** | 0 | bioRxiv | sc + bulk | Yes | Unified screening + benchmarks | R | [WangLabCSU/SigBridgeR](https://github.com/WangLabCSU/SigBridgeR) |
| 2026-04 | **scSurvival** | 0 | *Cancer Discovery* | sc cohort + survival | No | Survival risk + cell attention | Py | [cliffren/scSurvival](https://github.com/cliffren/scSurvival) |
| 2026-04 | **SpaPheno** | 0 | *Genome Medicine* | ST + bulk + sc ref | Yes | Multi-scale spatial biomarkers | R | [Duan-Lab1/SpaPheno](https://github.com/Duan-Lab1/SpaPheno) |
| 2026-04 | **DEGAS spatial smoothing** | 0 | *Bioinformatics* | scSRT + bulk | Yes | High-risk cells/spots + SWiS maps | R | [DEGAS](https://github.com/tsteelejohnson91/DEGAS) + [spatial](https://github.com/dchatter04/DEGAS-Spatial-Smoothing) |
| 2026-03 | **PaSCient** | 1 | *Cell Systems* | sc cohort | No | Patient embeddings + cell/gene importance | Py | [Genentech/pascient](https://github.com/Genentech/pascient) |
| 2026-02 | **BiSCALE** | 0 | *Advanced Science* | WSI + ST + bulk | Yes | Predicted expression + phenotype niches | Py | [Hailong-Zheng/BiSCALE](https://github.com/Hailong-Zheng/BiSCALE) |
| 2026-02 | **TiRank** | 2 | *Genome Medicine* | sc/ST + bulk | Yes | TiRank+/− cells/spots | Py | [LenisLin/TiRank](https://github.com/LenisLin/TiRank) |
| 2026-01 | **ScPP** | 0 | *Interdisciplinary Sciences: Comp. Life Sciences* | sc + bulk | Yes | Phenotype+/−/background labels | R | [WangX-Lab/ScPP](https://github.com/WangX-Lab/ScPP) |
| 2026-01 | **scPhase** | 2 | *Genome Medicine* | sc cohort (sample labels) | No | Phenotype prediction + attention/gene attribution | Py | [wuqinhua/scPhase](https://github.com/wuqinhua/scPhase) |
| 2026-01 | **Shears** | 13 | *Cancer Cell* | sc + bulk | Yes | Cell coefficients + covariate-aware GLM | Py | [icbi-lab/shears](https://github.com/icbi-lab/shears) |
| 2026-01 | **stSurvTrans** | 0 | *IEEE TCBB* | ST + bulk survival | Yes | Prognosis-associated spatial patterns | Py | [Miaoyx323/stSurvTrans](https://github.com/Miaoyx323/stSurvTrans) |
| 2025-12 | **SpacePhenotyper** | 0 | bioRxiv | ST + bulk | Yes | Spot-level phenotype quantities | Py | [ncbi/SpacePhenotyper](https://github.com/ncbi/SpacePhenotyper) |
| 2025-12 | **SIDISH** | 5 | *Nature Communications* | sc + bulk (+ ST) | Yes | High-risk cells + in silico perturbation | Py | [mcgilldinglab/SIDISH](https://github.com/mcgilldinglab/SIDISH) |
| 2025-12 | **MultiMIL** | 19 | bioRxiv | sc/multi-omic cohort | No | Attention-based cell prioritization | Py | [theislab/multimil](https://github.com/theislab/multimil) |
| 2025-11 | **scSurv** | 0 | *Bioinformatics* | sc + bulk survival | Yes | Cell survival scores + spatial hazard maps | R | [3254c/scSurv](https://github.com/3254c/scSurv) |
| 2025-11 | **TinydenseR** | 0 | bioRxiv | sc/cytometry cohort | No | Sample-level phenotype-linked states | R | [Novartis/tinydenseR](https://github.com/Novartis/tinydenseR) |
| 2025-11 | **scPER** | 2 | *Advanced Science* | sc ref + bulk | Yes† | Cell proportions + phenotype subclusters | Py/R | [BrianLlll/scPER](https://github.com/BrianLlll/scPER) |
| 2025-11 | **DEGAS-ST** | 0 | *Genomics, Proteomics & Bioinformatics* | ST (Visium) + bulk | Yes | Prostate field-effect risk maps | R | [DEGAS](https://github.com/tsteelejohnson91/DEGAS) |
| 2025-09 | **CellPhenoX** | 3 | *Advanced Science* | sc cohort | No | Interpretable cell scores (SHAP) | Py | [fanzhanglab/pyCellPhenoX](https://github.com/fanzhanglab/pyCellPhenoX) |
| 2025-08 | **SCTP** | 2 | *iMeta* | bulk + sc + ST | Yes | Continuous malignancy scores (cells/spots) | R | [ztpub/SCTP](https://github.com/ztpub/SCTP) |
| 2025-08 | **scBGDL** | 6 | *Briefings in Bioinformatics* | sc + bulk | Yes‡ | Patient-level risk scores/subtypes | Py | [NEFLab/scBGDL](https://github.com/NEFLab/scBGDL) |
| 2025-08 | **ATSDP-NET** | 1 | *Frontiers in Medicine* | sc + bulk drug | Partial | Per-cell drug response predictions | Py | Not public |
| 2025-06 | **stClinic** | 15 | *Nature Communications* | ST multi-slice (+ multi-omics) + clinical | No | Clinically weighted niches / survival–metastasis maps | Py | [cmzuo11/stClinic](https://github.com/cmzuo11/stClinic) |
| 2025-06 | **SpaLinker** | 3 | *Cell Genomics* | ST + bulk | Yes | Phenotype-linked spatial TME features | R | [bm2-lab/SpaLinker](https://github.com/bm2-lab/SpaLinker) |
| 2025-04 | **scTransMIL** | 3 | bioRxiv | sc cohort | No | Sample/cell/gene-level cancer scores | — | Not publicly released |
| 2025-03 | **SSDA4Drug** | 13 | *Communications Biology* | sc + bulk drug | Yes | Drug-sensitive/resistant cell labels | Py | [hliulab/SSDA4Drug](https://github.com/hliulab/SSDA4Drug) |
| 2024-11 | **scPAS** | 7 | *Briefings in Bioinformatics* | sc + bulk | Yes | Risk scores + FDR per cell | R | [Zaoqu-Liu/scPAS](https://github.com/Zaoqu-Liu/scPAS) |
| 2024-08 | **SCellBOW** | 2 | *eLife* | sc + bulk survival | Partial | Cluster risk ranks (phenotype algebra) | Py | [cellsemantics/SCellBOW](https://github.com/cellsemantics/SCellBOW) |
| 2024-05 | **PIPET** | 6 | *Briefings in Bioinformatics* | sc + bulk | Yes | Phenotype-associated subpopulations | R | [ruan2ruan/PIPET](https://github.com/ruan2ruan/PIPET) |
| 2024-05 | **SCIPAC** | 9 | *Genome Biology* | sc + bulk | Yes | Continuous association + p-values per cell | R | [RavenGan/SCIPAC](https://github.com/RavenGan/SCIPAC) |
| 2024-04 | **scRANK** | 3 | *PLOS Computational Biology* | sc cohort + priors | No | Prior-knowledge cell cluster ranking | R | [aoulas/scRANK](https://github.com/aoulas/scRANK) |
| 2023-11 | **LP_SGL** | 5 | *Briefings in Bioinformatics* | sc + bulk | Yes | LP_SGL+/− cell labels | R | [hongmeizhanghm/LP_SGL](https://github.com/hongmeizhanghm/LP_SGL) |
| 2023-07 | **PACSI** | 12 | *BMC Biology* | sc + bulk + PPI | Yes | Network-proximity cell–phenotype links | R | [Chonghui-Liu/PACSI-project](https://github.com/Chonghui-Liu/PACSI-project) |
| 2023-05 | **Pencil** | 13 | *Nature Machine Intelligence* | sc (+ sample labels) | No* | Phenotype-associated cells + genes | Py | [cliffren/PENCIL](https://github.com/cliffren/PENCIL) |
| 2023-03 | **scRank-XMBD** | 7 | *Briefings in Bioinformatics* | sc + bulk survival | Yes | Prognostic cell subpopulation ranks | R | [xmuyulab/scRank-XMBD](https://github.com/xmuyulab/scRank-XMBD) |
| 2022-11 | **scAB** | 35 | *Nucleic Acids Research* | sc + bulk | Yes | Multiresolution phenotype-associated states | R | [jinworks/scAB](https://github.com/jinworks/scAB) |
| 2022-02 | **DEGAS** | 49 | *Genome Medicine* | sc + bulk | Yes | Cell-level disease impressions/scores | R | [tsteelejohnson91/DEGAS](https://github.com/tsteelejohnson91/DEGAS) |
| 2021-11 | **Scissor** | 520 | *Nature Biotechnology* | sc + bulk | Yes | Scissor+/− cell labels | R | [sunduanchen/Scissor](https://github.com/sunduanchen/Scissor) |
| 2020-08 | **scPrognosis** | 24 | *PLOS Computational Biology* | sc → bulk survival | Partial | sc-derived prognostic signatures | R | [XiaomeiLi1/scPrognosis](https://github.com/XiaomeiLi1/scPrognosis) |
| 2020-07 | **Augur** | 40 | *Nature Biotechnology* | sc cohort + condition | No | Cell-type prioritization for perturbation | R | [neurorestore/Augur](https://github.com/neurorestore/Augur) |
| — | **PhenoMapR** | — | In development | bulk / sc / ST | Ref sigs | Weighted prognostic scores | R | [brooksbenard/PhenoMapR](https://github.com/brooksbenard/PhenoMapR) |

\*Pencil uses **sample-level phenotype labels** on sc data, not bulk RNA-seq.  
†scPER requires bulk for phenotype-linked subcluster identification (deconvolution-first).  
‡scBGDL uses sc data to build sample-specific gene graphs but outputs **patient-level** risk scores, not per-cell labels.  
**Note:** **scSurv** (bulk+sc survival transfer) and **scSurvival** (sc cohort MIL Cox) are distinct methods with similar names.  
**DEGAS family:** **DEGAS** (2022) is the core bulk→sc framework (49 citations). **DEGAS-ST** (2025 GPB) is a separate prostate ST *application study* on Visium. **DEGAS spatial smoothing** (2026 *Bioinformatics*) is a separate *methods* paper adding SWiS smoothing for scSRT (Xenium/CosMx)—each has its own DOI and citation count.

---

## Citations by method

![Citations per method (OpenAlex, 14 Jul 2026)](phenotype-mapping-citations.png)

Scissor dominates citation counts among bulk→sc mapping methods, reflecting its status as the foundational approach (2021). **Augur** has a higher count but addresses within-cohort perturbation comparisons rather than bulk transfer. Most 2025–2026 methods have few or zero indexed citations yet.

---

## Publication timeline

![Publication timeline by method (2020–2026)](phenotype-mapping-timeline.png)

Methods color-coded by category: **bulk+sc integration** (blue), **sc cohort** (green), **spatial+bulk** (red), **related/adjacent** (purple), **meta-framework** (tan). Filled circles = peer-reviewed; diamonds = preprint (†). Sorted newest-first vertically; dates use the same `YYYY-MM` convention as the comparison table.

| Year | Methods published |
|------|-------------------|
| 2026 | SP-printer (06), SigBridgeR (05), scSurvival · SpaPheno · DEGAS spatial smoothing (04), PaSCient (03), BiSCALE · TiRank (02), ScPP · scPhase · Shears · stSurvTrans (01) |
| 2025 | SpacePhenotyper · SIDISH · MultiMIL (12), scSurv · TinydenseR · scPER · DEGAS-ST (11), CellPhenoX (09), SCTP · scBGDL · ATSDP-NET (08), stClinic · SpaLinker (06), scTransMIL (04), SSDA4Drug (03) |
| 2024 | scPAS (11), SCellBOW (08), PIPET · SCIPAC (05), scRANK (04) |
| 2023 | LP_SGL (11), PACSI (07), Pencil (05), scRank-XMBD (03) |
| 2022 | scAB (11), DEGAS (02) |
| 2021 | Scissor (11) |
| 2020 | scPrognosis (08), Augur (07) |

---

## Taxonomy of approaches

Methods grouped by **input data type** and **algorithmic family**. Pick your row first, then scan the method column.

### A. Bulk RNA-seq + single-cell reference → cell labels/scores

| Algorithm family | Methods | What they do |
|------------------|---------|--------------|
| Sparse / network regression | Scissor, Shears, scPAS, SCIPAC, scAB, **LP_SGL** | Regress or deconvolve bulk phenotypes onto individual cells |
| Network proximity (PPI) | **PACSI** | PPI network distance between cell signatures and bulk phenotype groups |
| REO + transfer learning | **scRank-XMBD**, TiRank | Rank-order gene pairs link bulk survival to prognostic cell subpopulations |
| Marker enrichment | ScPP, PIPET | Derive bulk marker sets, score cells (AUCell or vector similarity) |
| Deep transfer learning | DEGAS, SIDISH, **scSurv** | Neural nets transfer patient-level labels to cells (scSurv adds spatial hazard maps) |
| DEGAS ST extensions | **DEGAS-ST**, **DEGAS spatial smoothing** | Apply DEGAS to spatial data: prostate Visium application vs scSRT smoothing methods paper |
| Graph deep learning (patient output) | **scBGDL** | Sample-specific gene graphs for survival/subtype prediction (not per-cell labels) |
| sc-informed bulk prognosis | **scPrognosis** | Derive signatures from sc trajectories, validate on bulk survival |

### B. Multi-sample scRNA-seq cohort (sample labels, no bulk)

| Algorithm family | Methods | What they do |
|------------------|---------|--------------|
| MIL / attention | Pencil, scPhase, MultiMIL, PaSCient, scSurvival, scTransMIL | Treat each sample as a bag of cells; predict phenotype + rank cells |
| Sample-centric statistics | tinydenseR | Landmark density shifts linked to sample phenotypes |
| Explainable ML | CellPhenoX | SHAP-based interpretable scores from neighborhood embeddings |
| NLP / embedding | SCellBOW | Doc2vec clusters + bulk survival algebra for cluster risk |
| Perturbation prioritization | **Augur** | Rank cell types by response to experimental perturbation within sc cohort |
| Prior-knowledge ranking | **scRANK** | Map expert disease/drug priors to ranked cell clusters |

### C. Spatial transcriptomics + clinical / bulk data

| Algorithm family | Methods | What they do |
|------------------|---------|--------------|
| Bulk → spot transfer | SpacePhenotyper, TiRank, SpaPheno, **DEGAS-ST**, **stSurvTrans**, **SP-printer** | Transfer patient-level phenotype/survival models to spatial locations |
| Multi-slice ST + clinical graphs | **stClinic** | Dynamic graphs integrate multi-slice (multi-omics) ST; niche vectors predict survival/metastasis |
| scSRT (Xenium/CosMx) | **DEGAS spatial smoothing** | DEGAS + SWiS smoothing for single-cell spatial platforms |
| TME characterization + linking | SpaLinker | Characterize spatial TME features, link to bulk phenotypes |
| Multimodal deep fusion | SCTP | Joint bulk + sc + ST graphs for continuous phenotype scores |

### D. Other modalities

| Input | Methods | What they do |
|-------|---------|--------------|
| Histology (WSI) + RNA labels | BiSCALE | Predict bulk/spot expression from slides; link to phenotypes |
| sc reference + bulk (deconvolution) | scPER | Estimate cell proportions, then associate subclusters with phenotype |
| Prognostic signature databases | PhenoMapR | Score cells/spots/samples with pre-built prognostic gene sets |
| Bulk→sc drug response transfer | **SSDA4Drug**, **ATSDP-NET** | Transfer pharmacogenomic labels from bulk/cell lines to sc drug sensitivity |
| Meta-framework / benchmarking | **SigBridgeR** | Unified interface wrapping multiple bulk→sc screening methods |

---

## Bulk + single-cell integration methods

These methods leverage **large clinically annotated bulk cohorts** to label or score cells in a separate scRNA-seq reference.

### Scissor
**Single-Cell Identification of Subpopulations with bulk Sample phenotype coRrelation**

| | |
|---|---|
| **Publication** | Sun et al., 2021. *Nature Biotechnology* 40(4):527–538. [DOI: 10.1038/s41587-021-01091-3](https://doi.org/10.1038/s41587-021-01091-3) |
| **GitHub** | https://github.com/sunduanchen/Scissor |
| **Language** | R |

**Approach:** Computes cell–bulk correlation matrix, then fits a **graph-regularized sparse regression** (Lasso/elastic net with network penalty) linking bulk phenotypes to cells. No clustering required.

**Inputs:**
- scRNA-seq expression matrix
- Matched bulk expression matrix (same genes)
- Phenotype vector: continuous, binary, or Cox survival (`family = "gaussian"`, `"binomial"`, `"cox"`)

**Outputs:**
- `Scissor+` / `Scissor−` cell labels (direction depends on phenotype)
- Regression coefficients; reliability testing utilities

**Strengths:** Foundational method; simple API; supports survival.  
**Limitations:** Computationally expensive at atlas scale; no covariates; correlation-based design (addressed by Shears).

---

### LP_SGL
**Leiden partition + Sparse Group Lasso**

| | |
|---|---|
| **Publication** | Li et al., 2023-11. *Briefings in Bioinformatics* 25(1):bbad424. [DOI: 10.1093/bib/bbad424](https://doi.org/10.1093/bib/bbad424) · [OUP](https://academic.oup.com/bib/article/25/1/bbad424/7450935) |
| **GitHub** | https://github.com/hongmeizhanghm/LP_SGL |
| **Language** | R (Seurat, leidenAlg, SGL) |

**Approach:** Like Scissor, builds a cell–bulk **Pearson correlation matrix** from shared genes, then fits a **sparse group lasso (SGL)** regression with phenotype labels. The key extension is **Leiden community detection** on the scRNA-seq SNN graph: cells are grouped into communities, and SGL selects/shrinks at the **group level** (not just individual cells), encoding cell–cell interaction structure and improving robustness vs correlation-only methods.

**Inputs:**
- scRNA-seq expression (Seurat-preprocessed)
- Bulk expression matrix (same genes)
- Phenotype: binary diagnosis/response (logistic loss) or survival (Cox partial likelihood)

**Outputs:**
- `LP_SGL+` / `LP_SGL−` / Background cell labels (from regression coefficient signs)
- Group-aware regression coefficients

**Strengths:** Explicitly models cell communities; reported more robust than Scissor/scAB on incomplete gene sets; validated on LUAD, melanoma ICB, liver cancer survival + external cohorts.  
**Limitations:** Requires Leiden grouping step (resolution parameter γ); same bulk+sc integration setup as Scissor; also wrapped in SigBridgeR as `LPSGL`.

---

### Shears
**Shears are more powerful Scissors**

| | |
|---|---|
| **Publication** | Marteau et al., 2026. *Cancer Cell*. [DOI: 10.1016/j.ccell.2025.12.003](https://doi.org/10.1016/j.ccell.2025.12.003) |
| **GitHub** | https://github.com/icbi-lab/shears |
| **Language** | Python |

**Approach:** Two-step method: (1) Ridge regression deconvolves bulk into **weighted single-cell contributions** (not correlation); (2) per-cell linear models with **covariates** and biological replicates estimate phenotype association.

**Inputs:**
- scRNA-seq reference (AnnData)
- Bulk RNA-seq + phenotypes (survival, mutation, etc.)
- Optional covariates (tumor type, stage, dataset)

**Outputs:**
- Shears coefficients per cell
- Cell-type–aggregated association statistics
- UMAP overlays of phenotype-associated cells

**Strengths:** Scales to million-cell atlases; covariate-aware; faster than Scissor on large data.  
**Limitations:** Python/scverse ecosystem; newer with fewer independent benchmarks.

---

### scAB
**single-cell Analysis with Bulk data**

| | |
|---|---|
| **Publication** | Zhang et al., 2022. *Nucleic Acids Research* 50(21):12112–12130. [DOI: 10.1093/nar/gkac1109](https://doi.org/10.1093/nar/gkac1109) |
| **GitHub** | https://github.com/jinworks/scAB |
| **Language** | R |

**Approach:** **Knowledge- and graph-guided NMF** integrating sc + bulk + phenotype. Provides **multiresolution** (coarse and fine) phenotype-associated cell states.

**Inputs:** scRNA-seq, bulk RNA-seq, phenotype (binary/continuous/survival)

**Outputs:** Phenotype-associated factors at multiple resolutions; prognostic signatures

**Strengths:** Multiresolution view; works with scATAC in paper.  
**Limitations:** NMF-based; less interpretable than direct cell labels.

---

### SCIPAC
**Single-Cell and bulk data-based Identifier for Phenotype Associated Cells**

| | |
|---|---|
| **Publication** | Gan et al., 2024. *Genome Biology* 25:119. [DOI: 10.1186/s13059-024-03263-1](https://doi.org/10.1186/s13059-024-03263-1) |
| **GitHub** | https://github.com/RavenGan/SCIPAC |
| **Language** | R |

**Approach:** Quantifies **continuous association strength** between each cell and phenotype, with **per-cell p-values**. Supports binary, ordinal, continuous, and survival phenotypes.

**Inputs:** sc + bulk expression; phenotype

**Outputs:** Association score and p-value per cell

**Strengths:** First method with formal significance testing per cell; fast; minimal tuning.  
**Limitations:** Does not produce discrete +/- labels by default.

---

### scPAS
**Single-Cell Phenotype-Associated Subpopulation identifier**

| | |
|---|---|
| **Publication** | Xie et al., 2024. *Briefings in Bioinformatics* 26(1):bbae655. [DOI: 10.1093/bib/bbae655](https://doi.org/10.1093/bib/bbae655) |
| **GitHub** | https://github.com/Zaoqu-Liu/scPAS (also [aiminXie/scPAS](https://github.com/aiminXie/scPAS)) |
| **Language** | R |

**Approach:** **Network-regularized sparse regression** with gene-gene SNN from sc data. Permutation testing for significance.

**Inputs:** Bulk + sc expression; phenotype (gaussian/binomial/cox)

**Outputs:** `scPAS+/scPAS−/0` labels; risk scores; FDR

**Strengths:** Network regularization; parallelizable; spatial applications in paper.  
**Limitations:** Similar conceptual space to Scissor/scPAS family—method choice depends on benchmarks.

---

### PIPET
**Phenotypic Information based on bulk data Predicts relevant subpopulations in single cell data**

| | |
|---|---|
| **Publication** | Ruan et al., 2024. *Briefings in Bioinformatics* bbae260. [DOI: 10.1093/bib/bbae260](https://doi.org/10.1093/bib/bbae260) |
| **GitHub** | https://github.com/ruan2ruan/PIPET |
| **Language** | R |

**Approach:** Builds **phenotype feature vectors** from bulk DEGs, then scores sc cells by similarity to these vectors. Supports **multiclass** phenotypes.

**Inputs:** sc expression; bulk DEG-derived feature vectors (or auto-generated)

**Outputs:** Phenotype-associated cell subsets; visualization utilities

**Strengths:** Multiclass support; intuitive vector similarity framework.  
**Limitations:** Depends on bulk DEG quality.

---

### ScPP
**Single Cells' Phenotype Prediction**

| | |
|---|---|
| **Publication** | He et al., 2026-01. *Interdisciplinary Sciences: Computational Life Sciences*. [DOI: 10.1007/s12539-025-00803-6](https://link.springer.com/article/10.1007/s12539-025-00803-6) |
| **GitHub** | https://github.com/WangX-Lab/ScPP |
| **Language** | R |

**Approach:** Identifies phenotype-associated marker genes in bulk → **AUCell** enrichment in sc → intersects top/bottom α-ranked cells → assigns **phenotype+/−/background**.

**Inputs:** sc + bulk + phenotype (binary/continuous/survival)

**Outputs:** Three-way cell classification; ranked gene lists

**Strengths:** Fast; simple; competitive vs Scissor/scAB in benchmarks.  
**Limitations:** Threshold α requires tuning.

---

### DEGAS family overview

Three **separate peer-reviewed publications** extend the same software ([DEGAS](https://github.com/tsteelejohnson91/DEGAS)); each has its own DOI and OpenAlex citation count:

| Name in this doc | Publication | DOI | Citations | What it adds |
|------------------|-------------|-----|-----------|--------------|
| **DEGAS** | Johnson et al., 2022. *Genome Medicine* | [10.1186/s13073-022-01012-2](https://doi.org/10.1186/s13073-022-01012-2) | 49 | Core bulk→sc deep transfer learning framework |
| **DEGAS-ST** | Couetil et al., 2025. *Genomics, Proteomics & Bioinformatics* | [10.1093/gpbjnl/qzaf119](https://doi.org/10.1093/gpbjnl/qzaf119) | 0 | Prostate cancer **application** on Visium ST (field effect / benign glands) |
| **DEGAS spatial smoothing** | Chatterjee et al., 2026. *Bioinformatics* | [10.1093/bioinformatics/btag098](https://doi.org/10.1093/bioinformatics/btag098) | 0 | **Methods** extension: SWiS/FoVS smoothing for scSRT (Xenium, CosMx) |

Preprints (not counted in comparison table): DEGAS-ST bioRxiv [2023.04.21.537852](https://doi.org/10.1101/2023.04.21.537852) (11 citations); spatial smoothing bioRxiv [2025.01.30.635803](https://doi.org/10.1101/2025.01.30.635803) (4 citations).

---

### DEGAS
**Diagnostic Evidence GAuge of Single cells (core framework)**

| | |
|---|---|
| **Publication** | Johnson et al., 2022. *Genome Medicine* 14:11. [DOI: 10.1186/s13073-022-01012-2](https://doi.org/10.1186/s13073-022-01012-2) |
| **GitHub** | https://github.com/tsteelejohnson91/DEGAS |
| **Language** | R (TensorFlow backend) |

**Approach:** **Deep transfer learning** with coupled autoencoders. Trains on bulk labels, transfers "impressions" (disease attributes) to cells via domain adaptation.

**Inputs:**
- sc expression matrix (cells × genes)
- Bulk expression (samples × genes)
- One-hot patient labels (classification) or time/status (survival)
- Optional sc cell-type labels

**Outputs:** Cell-level disease impression scores; patient/cell prioritization

**Strengths:** Flexible deep architecture; multiple disease applications (GBM, AD, MM).  
**Limitations:** Requires matched gene space; deep learning setup overhead; does not include spatial smoothing (see **DEGAS spatial smoothing**) or ST-specific prostate validation (see **DEGAS-ST**).

---

### DEGAS spatial smoothing
**DEGAS with SWiS smoothing for scSRT** *(sometimes informally called DEGAS2)*

| | |
|---|---|
| **Publication** | Chatterjee et al., 2026-04. *Bioinformatics* btag098. [DOI: 10.1093/bioinformatics/btag098](https://doi.org/10.1093/bioinformatics/btag098) |
| **GitHub** | [DEGAS](https://github.com/tsteelejohnson91/DEGAS) + [DEGAS-Spatial-Smoothing](https://github.com/dchatter04/DEGAS-Spatial-Smoothing) |
| **Language** | R |

**Approach:** Separate **methods paper** extending core DEGAS with **spatial smoothing** (SWiS, FoVS) for **single-cell spatial platforms** (Xenium, CosMx). Validated in LIHC, SKCM, and Type II Diabetes Xenium data.

**Inputs:** scSRT data + bulk reference + clinical labels

**Outputs:** Smoothed high-risk cell/region maps on scSRT platforms

**Distinction from DEGAS-ST:** Targets subcellular-resolution scSRT with smoothing algorithms; not the same publication as the 2025 prostate Visium application study.

---

### DEGAS-ST
**Prostate spatial transcriptomics application (field effect study)**

| | |
|---|---|
| **Publication** | Couetil et al., 2025-11. *Genomics, Proteomics & Bioinformatics*. [DOI: 10.1093/gpbjnl/qzaf119](https://doi.org/10.1093/gpbjnl/qzaf119) · [GPB](https://academic.oup.com/gpb/article-lookup/doi/10.1093/gpbjnl/qzaf119) |
| **Preprint** | Couetil et al., 2023. bioRxiv. [DOI: 10.1101/2023.04.21.537852](https://doi.org/10.1101/2023.04.21.537852) |
| **GitHub** | https://github.com/tsteelejohnson91/DEGAS |
| **Language** | R |

**Approach:** Separate **application/biology study** applying core DEGAS to **Visium spatial transcriptomics** in prostate cancer. Identifies morphologically benign glands associated with progression (field effect); validates MSMB loss with IHC.

**Inputs:** Visium ST, bulk TCGA-PRAD RNA-seq with survival, sc reference for deconvolution

**Outputs:** Spot-level DEGAS risk scores; field-effect biomarker findings (MSMB, myeloid infiltration)

**Distinction from DEGAS spatial smoothing:** Visium spot-resolution prostate study—not the scSRT smoothing methods paper (2026 *Bioinformatics*).

---

### SIDISH
**Semi-supervised Iterative Deep Learning for Identifying Single-cell High-Risk Populations**

| | |
|---|---|
| **Publication** | Jolasun et al., 2025. *Nature Communications*. [DOI: 10.1038/s41467-025-66162-4](https://doi.org/10.1038/s41467-025-66162-4) |
| **GitHub** | https://github.com/mcgilldinglab/SIDISH |
| **Language** | Python |

**Approach:** Iterative feedback loop: **VAE** + **deep Cox regression** + transfer learning between bulk and sc. Includes **in silico gene knockout** for therapeutic prioritization. Extends to spatial.

**Inputs:** scRNA-seq, bulk RNA-seq, survival/phenotype labels

**Outputs:** High-risk cell labels; survival predictions; perturbation rankings; spatial maps

**Strengths:** Iterative refinement; therapeutic simulation; spatial compatible.  
**Limitations:** Complex multi-phase pipeline.

---

### scPER
**Proportions Estimated using single-cell RNA-seq Reference**

| | |
|---|---|
| **Publication** | 2025. *Advanced Science*. [DOI: 10.1002/advs.202514502](https://doi.org/10.1002/advs.202514502) |
| **GitHub** | https://github.com/BrianLlll/scPER |
| **Language** | Python + R |

**Approach:** **Adversarial autoencoder** + **XGBoost** for bulk deconvolution into sc-derived subclusters, then links subcluster proportions to clinical phenotypes.

**Inputs:** sc reference matrix + labels; bulk RNA-seq; optional clinical phenotypes

**Outputs:** Cell-type proportions; phenotype-associated subcluster associations

**Strengths:** Strong deconvolution accuracy; links phenotype via proportions rather than per-cell scoring.  
**Limitations:** Indirect single-cell mapping (via subcluster proportions).

---

### PACSI
**Phenotype-Associated Cell Subpopulation Identification**

| | |
|---|---|
| **Publication** | Liu et al., 2023-07. *BMC Biology* 21:158. [DOI: 10.1186/s12915-023-01658-3](https://doi.org/10.1186/s12915-023-01658-3) |
| **GitHub** | https://github.com/Chonghui-Liu/PACSI-project |
| **Language** | R (Seurat) |

**Approach:** Builds **cell and bulk gene signatures** (highly expressed genes), maps them onto a **PPI network**, and computes **network-based proximity** (average shortest path) between each cell and bulk samples with the phenotype of interest. Permutation testing assesses significance.

**Inputs:** scRNA-seq, bulk RNA-seq, phenotype labels, PPI network

**Outputs:** Phenotype-associated cell subpopulations with significance scores

**Strengths:** Network topology captures biological context beyond correlation; general-purpose across phenotypes.  
**Limitations:** Requires PPI network; computationally heavier than correlation-only methods.

---

### scRank-XMBD
**Prioritizing prognostic-associated subpopulations with bulk RNA-seq data**

| | |
|---|---|
| **Publication** | Yu et al., 2023-03. *Briefings in Bioinformatics* 24(2):bbad078. [DOI: 10.1093/bib/bbad078](https://doi.org/10.1093/bib/bbad078) |
| **GitHub** | https://github.com/xmuyulab/scRank-XMBD |
| **Language** | R |

**Approach:** Uses **Relative Expression Ordering (REO)** of gene pairs from bulk survival cohorts to identify prognostic gene signatures, then ranks sc subpopulations by how well their expression patterns match bulk prognostic profiles.

**Inputs:** scRNA-seq, bulk RNA-seq with survival data

**Outputs:** Ranked prognostic cell subpopulations; individualized risk assessment

**Strengths:** REO is robust to platform effects; links bulk survival directly to cell states.  
**Limitations:** Primarily survival-focused.

---

### scSurv
**Single-cell survival analysis via bulk–sc integration**

| | |
|---|---|
| **Publication** | 2025-11. *Bioinformatics* btaf646. [DOI: 10.1093/bioinformatics/btaf646](https://doi.org/10.1093/bioinformatics/btaf646) |
| **GitHub** | https://github.com/3254c/scSurv |
| **Language** | R |

**Approach:** **VAE** feature extraction + **deconvolution** + **Cox regression** to transfer bulk survival information to individual cells. Extends to **spatial hazard maps** on ST data.

**Inputs:** scRNA-seq reference, bulk RNA-seq with survival (time/status)

**Outputs:** Per-cell survival association scores; spatial hazard maps

**Strengths:** Direct bulk→sc survival transfer with spatial extension.  
**Limitations:** Distinct from **scSurvival** (2026, sc cohort MIL without bulk transfer).

---

### scPrognosis
**Single-cell informed breast cancer prognosis**

| | |
|---|---|
| **Publication** | Li et al., 2020-08. *PLOS Computational Biology* 16(8):e1008133. [DOI: 10.1371/journal.pcbi.1008133](https://doi.org/10.1371/journal.pcbi.1008133) |
| **GitHub** | https://github.com/XiaomeiLi1/scPrognosis |
| **Language** | R (+ MATLAB for some steps) |

**Approach:** Infers **EMT pseudotime** and a dynamic co-expression network from scRNA-seq, selects prognostic genes via an integrative ranking model, then builds a **bulk survival predictor** from the sc-derived signature.

**Inputs:** scRNA-seq (EMT or other biological process), bulk RNA-seq with survival for validation

**Outputs:** Prognostic gene signature; bulk survival model (indirect per-cell mapping)

**Strengths:** Early example of sc heterogeneity informing bulk prognosis; interpretable trajectory-based gene selection.  
**Limitations:** Indirect cell mapping; breast cancer/EMT focus in original paper.

---

### scBGDL
**Single-cell and bulk transcriptomic graph deep learning**

| | |
|---|---|
| **Publication** | 2025-08. *Briefings in Bioinformatics* bbaf467. [DOI: 10.1093/bib/bbaf467](https://doi.org/10.1093/bib/bbaf467) |
| **GitHub** | https://github.com/NEFLab/scBGDL |
| **Language** | Python |

**Approach:** Uses sc data to identify key genes, constructs **sample-specific gene graphs** (GAT + MinCutPool + Transformer), and trains graph deep learning for **survival prediction**, subtype classification, and treatment response across 16 TCGA cancer types.

**Inputs:** Bulk RNA-seq + survival/phenotype; scRNA-seq reference for gene selection

**Outputs:** Patient-level risk scores and subtype calls (not per-cell labels)

**Strengths:** Interpretable gene–gene edges; strong pan-cancer survival benchmarks.  
**Limitations:** Output is sample-level; sc data informs graph structure rather than direct cell scoring.

---

## Single-cell cohort methods (sample labels on sc data)

These methods use **multi-sample scRNA-seq** where each cell belongs to a patient/sample with a known phenotype. No bulk RNA-seq required.

### Pencil
**Supervised learning of high-confidence phenotypic subpopulations**

| | |
|---|---|
| **Publication** | Wu et al., 2023. *Nature Machine Intelligence* 5:521–532. [DOI: 10.1038/s42256-023-00656-y](https://doi.org/10.1038/s42256-023-00656-y) |
| **GitHub** | https://github.com/cliffren/PENCIL |
| **Language** | Python (PyTorch) |

**Approach:** **Learning with rejection** — simultaneously selects informative genes and identifies phenotype-associated subpopulations. Classification and regression modes; trajectory learning in regression mode.

**Inputs:** Expression matrix + per-cell or per-sample phenotype labels

**Outputs:** Phenotype-associated cells; selected gene sets; trajectory (regression mode)

**Strengths:** Scales to 1M cells; concurrent gene selection; GPU-accelerated.  
**Limitations:** Requires labels on sc samples; not bulk-transfer.

---

### scPhase
**phenotype prediction with attention mechanisms for single-cell exploring**

| | |
|---|---|
| **Publication** | Wu et al., 2026. *Genome Medicine*. [DOI: 10.1186/s13073-026-01598-x](https://doi.org/10.1186/s13073-026-01598-x) |
| **GitHub** | https://github.com/wuqinhua/scPhase |
| **Language** | Python |

**Approach:** **Attention-based MIL** with LinFormer attention, **Mixture-of-Experts** aggregation, and adversarial **domain adaptation** for batch correction. Integrated Gradients for gene attribution.

**Inputs:** AnnData (.h5ad) with sample IDs and phenotype labels per sample

**Outputs:** Sample-level phenotype predictions; cell attention weights; gene attributions

**Strengths:** No cell-type labels needed; cross-cohort generalization; multi-level interpretability.  
**Limitations:** Requires multi-sample sc cohort with labels.

---

### scTransMIL
**scRNA-seq Transformer-based Multi-Instance Learning**

| | |
|---|---|
| **Publication** | bioRxiv 2025. [DOI: 10.1101/2025.04.22.649948](https://doi.org/10.1101/2025.04.22.649948) |
| **GitHub** | Not publicly available (as of early 2026) |
| **Language** | — |

**Approach:** Transformer MIL over whole-genome context for cancer screening, single-cell disease scoring (validated on ~4M cells), and biomarker discovery.

**Inputs:** Multi-sample scRNA-seq with sample-level cancer/phenotype labels

**Outputs:** Sample classification; per-cell disease scores; gene-level biomarkers

**Strengths:** Whole-genome context; strong cancer screening benchmarks.  
**Limitations:** No public code yet; cancer-focused.

---

### MultiMIL
**Multimodal weakly supervised MIL**

| | |
|---|---|
| **Publication** | Litinetskaya et al., 2025-12. bioRxiv v2 (posted 16 Dec 2025). [DOI: 10.1101/2024.07.29.605625](https://doi.org/10.1101/2024.07.29.605625) |
| **GitHub** | https://github.com/theislab/multimil |
| **Language** | Python |

**Approach:** **Product-of-experts** multimodal integration + attention MIL for sample classification and disease-specific cell prioritization. Supports RNA + protein (IMC).

**Inputs:** Multi-sample sc/multi-omic data; sample-level disease labels

**Outputs:** Sample predictions; attention scores per cell; disease-associated gene discovery

**Strengths:** Multimodal; weakly supervised; atlas-scale.  
**Limitations:** Preprint; requires labeled sample cohort. (v1 posted July 2024; current version v2 posted December 2025.)

---

### PaSCient
**Patient-level representation from single-cell transcriptomics**

| | |
|---|---|
| **Publication** | Liu et al., 2026. *Cell Systems*. [DOI: S2405-4712(26)00052-9](https://www.cell.com/cell-systems/fulltext/S2405-4712(26)00052-9) |
| **GitHub** | https://github.com/Genentech/pascient |
| **Language** | Python |

**Approach:** Foundation-style **attention aggregation** (cells as bags) trained on 12.5M+ cells from 2,700+ patients. **Integrated gradients** for cell/gene importance.

**Inputs:** Multi-sample scRNA-seq; disease labels for training/fine-tuning

**Outputs:** Patient embeddings; cell/gene importance scores; disease classification

**Strengths:** Large-scale pretrained model; zero-shot potential; multi-level interpretability.  
**Limitations:** Pretrained weights available on request only.

---

### scSurvival
**Single-Cell Survival Analysis**

| | |
|---|---|
| **Publication** | Ren et al., 2026. *Cancer Discovery*. [DOI: 10.1158/2159-8290.CD-25-0965](https://doi.org/10.1158/2159-8290.CD-25-0965) |
| **GitHub** | https://github.com/cliffren/scSurvival |
| **Language** | Python |

**Approach:** **VAE feature extraction** + **multi-head attention MIL Cox regression**. Models each tumor as a bag of cells; identifies survival-associated subpopulations.

**Inputs:** AnnData with sample column, survival (time/status), optional covariates and batch key

**Outputs:** Patient survival predictions; cell-level attention/risk scores

**Strengths:** Direct survival modeling from sc cohorts; clinical covariate integration.  
**Limitations:** Requires sc cohort with survival annotations (still rare).

---

### CellPhenoX
**Explainable cell-specific phenotype prediction**

| | |
|---|---|
| **Publication** | Young et al., 2025. *Advanced Science*. [DOI: 10.1002/advs.202503289](https://doi.org/10.1002/advs.202503289) |
| **GitHub** | https://github.com/fanzhanglab/pyCellPhenoX |
| **Language** | Python |

**Approach:** Cell neighborhood **co-abundance embeddings** + XGBoost + **SHAP** with covariate/interaction terms for interpretable classification.

**Inputs:** Cell embedding features (Xi) per sample; clinical outcome Y; optional covariates

**Outputs:** Interpretable Scores per cell; SHAP values; phenotype predictions

**Strengths:** Handles confounders; multi-class; rare cell detection.  
**Limitations:** Requires pre-computed neighborhood embeddings.

---

### TinydenseR
**Sample-level modeling of single-cell data at scale**

| | |
|---|---|
| **Publication** | Milanez-Almeida et al., 2025. bioRxiv. [DOI: 10.1101/2025.11.26.690752](https://doi.org/10.1101/2025.11.26.690752) |
| **GitHub** | https://github.com/Novartis/tinydenseR |
| **Language** | R |

**Approach:** **Landmark-based** fuzzy density matrix (UMAP landmarks × samples). Clustering-independent; treats samples as replicates. Links cell-state density shifts to clinical/experimental outcomes.

**Inputs:** Multi-sample scRNA-seq or cytometry; sample-level phenotypes

**Outputs:** Differential cell-state densities; pePC embeddings; plsD feature programs; pseudobulk DE

**Strengths:** Atlas-scale; statistically principled; technology-agnostic.  
**Limitations:** Indirect cell-level mapping (via landmark densities); not bulk-transfer.

---

### SCellBOW
**Single Cell Bag of Words + Phenotype Algebra**

| | |
|---|---|
| **Publication** | Bhattacharya et al., 2025. *eLife*. [DOI: 10.7554/eLife.98469](https://doi.org/10.7554/eLife.98469) |
| **GitHub** | https://github.com/cellsemantics/SCellBOW |
| **Language** | Python |

**Approach:** NLP-inspired **Doc2vec** embeddings for sc clustering + **phenotype algebra**: vector subtraction on pseudo-bulk + bulk survival to rank cluster aggressiveness.

**Inputs:** Source scRNA-seq (pretrain); target scRNA-seq; bulk RNA-seq with survival (for algebra)

**Outputs:** Cell embeddings/clusters; relative aggressiveness scores per cluster

**Strengths:** Novel NLP framing; identifies high-risk clones (e.g., AR−/NElow in prostate).  
**Limitations:** Cluster-level (not single-cell) risk ranking; requires bulk survival for algebra.

---

## Spatial + clinical / bulk integration methods

### stClinic
**Spatially resolved Clinical niche dissection via dynamic graphs**

| | |
|---|---|
| **Publication** | Zuo et al., 2025-06. *Nature Communications* 16:5317. [DOI: 10.1038/s41467-025-60575-x](https://doi.org/10.1038/s41467-025-60575-x) |
| **GitHub** | https://github.com/cmzuo11/stClinic |
| **Zenodo** | https://zenodo.org/records/15246396 |
| **Language** | Python (PyTorch; Scanpy/AnnData; R helpers for some analyses) |

**Approach:** **Dynamic graph attention (VGAE)** integrates multi-slice spatial omics with a Mixture-of-Gaussians prior, iteratively pruning cross-slice edges between dissimilar niches. A supervised module then represents each slice as a **niche vector** (six attention-weighted geometric statistics relative to the population) and predicts clinical outcomes, yielding niche importance weights. Also supports **zero-shot label transfer** from a frozen encoder and multi-omics fusion via latent features from tools such as MultiVI/Seurat.

**Inputs:**
- Multi-slice spatial transcriptomics (or spatial multi-omics) with coordinates
- Slice-/patient-level clinical phenotypes (e.g., overall survival, primary vs metastasis)

**Outputs:**
- Batch-corrected niche embeddings and spatial domains across slices
- Niche weights for phenotype/survival prediction; malignancy and metastasis-linked niches
- Zero-shot transferred labels on query slices

**Strengths:** Direct niche↔clinical linkage without bulk RNA-seq transfer; multi-slice / multi-omics integration; zero-shot transfer; strong cancer applications (TNBC survival niches; CRC–liver metastasis niches).  
**Limitations:** Needs a multi-slice cohort with clinical labels (not a bulk→ST transfer tool); graph deep-learning setup; niche-level rather than per-spot continuous phenotype scores by default.

**Distinction from SpaLinker / SpacePhenotyper / stSurvTrans:** Operates on **spatial cohorts + clinical labels** via dynamic graphs, rather than transferring models from separate bulk expression cohorts.

---

### SpaLinker
**Spatial phenotype linker for TME**

| | |
|---|---|
| **Publication** | Cheng et al., 2025. *Cell Genomics* 5(7):100893. [DOI: 10.1016/j.xgen.2025.100893](https://doi.org/10.1016/j.xgen.2025.100893) |
| **GitHub** | https://github.com/bm2-lab/SpaLinker |
| **Language** | R |

**Approach:** Three modules: (1) TME molecular/cellular characterization, (2) spatial architecture recognition (TLS, tumor-normal interface), (3) **phenotype linking** via bulk RNA-seq integration.

**Inputs:** ST data; bulk RNA-seq with clinical phenotypes; optional sc reference

**Outputs:** Phenotype-associated spatial TME features; architecture calls; prognostic links

---

### SpaPheno
**Spatial phenotype linking with interpretable ML**

| | |
|---|---|
| **Publication** | Cheng et al., 2026. *Genome Medicine*. [DOI: 10.1186/s13073-026-01645-7](https://doi.org/10.1186/s13073-026-01645-7) |
| **GitHub** | https://github.com/Duan-Lab1/SpaPheno |
| **Language** | R |

**Approach:** **cell2location** deconvolution on bulk + ST → unified cell-type features → **Elastic Net** + **SHAP** for multi-scale interpretability (region, cell type, spot).

**Inputs:** ST, bulk RNA-seq with clinical labels, scRNA-seq reference

**Outputs:** Spatially resolved biomarkers; SHAP attributions at multiple scales

**Strengths:** Strong interpretability; validated across HCC, ccRCC, breast, melanoma.  
**Limitations:** Requires sc reference for deconvolution.

---

### SpacePhenotyper
**Eigen-Patient spatial phenotype transfer**

| | |
|---|---|
| **Publication** | bioRxiv 2025. [DOI: 10.64898/2025.12.12.693322](https://doi.org/10.64898/2025.12.12.693322) |
| **GitHub** | https://github.com/ncbi/SpacePhenotyper |
| **Language** | Python |

**Approach:** Algebraic spectral method: learns **Eigen-Gene** (patient-level phenotype predictor from bulk) → derives **Eigen-Patient** (gene-wise phenotype marker) → cosine similarity scores each spatial spot.

**Inputs:** Bulk expression + phenotype vector; ST expression + spot coordinates

**Outputs:** EigenPatient vector; per-spot phenotype quantity maps

**Strengths:** Simple, interpretable transfer; no sc reference needed.  
**Limitations:** Preprint; cosine similarity assumes linear gene-phenotype relationship.

---

### TiRank
**Phenotypic niche prioritization**

| | |
|---|---|
| **Publication** | 2026. *Genome Medicine*. [DOI: 10.1186/s13073-026-01604-2](https://doi.org/10.1186/s13073-026-01604-2) |
| **GitHub** | https://github.com/LenisLin/TiRank |
| **Docs** | https://tirank.readthedocs.io |
| **Language** | Python |

**Approach:** **Relative Expression Ordering (REO)** transform → **multitask transfer learning** aligning sc/ST/bulk into shared embedding → TiRank+/− labels.

**Inputs:** Bulk + clinical data; scRNA-seq or ST for inference

**Outputs:** `Rank_Label` (TiRank+/−) for cells or spots; survival/classification/regression modes

**Strengths:** Cross-modal; web GUI; pan-cancer benchmarks.  
**Limitations:** REO transformation may lose magnitude information.

---

### SCTP
**Single-Cell and Tissue Phenotype prediction**

| | |
|---|---|
| **Publication** | Zhu et al., 2025. *iMeta* 4(5):e70068. [DOI: 10.1002/imt2.70068](https://doi.org/10.1002/imt2.70068) |
| **GitHub** | https://github.com/ztpub/SCTP |
| **Language** | R |

**Approach:** **Graph attention (GAT)** deep multi-task fusion of bulk phenotype, sc composition, and ST spatial graphs. Pretrained **SCTP-CRC** model for colorectal malignancy.

**Inputs:** Bulk + sc + ST (or sc-only mode); Seurat objects

**Outputs:** Continuous **malignancy** scores per cell/spot in metadata

**Strengths:** True multimodal fusion; pretrained CRC model; spatial architecture mapping.  
**Limitations:** CRC model is primary application; custom training needed for other cancers.

---

### BiSCALE
**Multi-scale gene expression from whole-slide images**

| | |
|---|---|
| **Publication** | Zheng et al., 2026. *Advanced Science*. [DOI: 10.1002/advs.202521151](https://doi.org/10.1002/advs.202521151) |
| **GitHub** | https://github.com/Hailong-Zheng/BiSCALE |
| **Language** | Python |

**Approach:** Predicts gene expression from **H&E whole-slide images** at bulk and spot scales using WSI foundation model + Vision-Mamba fusion. Links predictions to clinical phenotypes for niche/subpopulation discovery.

**Inputs:** WSIs; training pairs with bulk RNA-seq and/or ST

**Outputs:** Predicted bulk/spot expression; phenotype-associated niches; risk stratification

**Strengths:** Uses routine pathology slides; no sequencing needed at inference.  
**Limitations:** Image-based (not direct sc/ST input); requires histology-RNA training pairs.

---

### stSurvTrans
**Bulk→spatial survival transfer learning**

| | |
|---|---|
| **Publication** | Miao et al., 2026-01. *IEEE Transactions on Computational Biology and Bioinformatics*. [DOI: 10.1109/tcbbio.2026.3677899](https://doi.org/10.1109/tcbbio.2026.3677899) |
| **GitHub** | https://github.com/Miaoyx323/stSurvTrans |
| **Language** | Python (PyTorch) |

**Approach:** **CVAE** harmonizes bulk and ST expression, then a **Weibull survival module** transfers bulk clinical survival to spatial spots, identifying prognosis-associated tissue structures.

**Inputs:** ST data (AnnData directory), bulk RNA-seq with survival in `.h5ad`

**Outputs:** Per-spot survival association; spatial maps of prognostic patterns

**Strengths:** Direct survival transfer to ST; validated in HCC (bile duct tumor thrombus).  
**Limitations:** Newer method; training can be compute-intensive.

---

### SP-printer
**Spatial-Phenotype printer for stage-specific microenvironments**

| | |
|---|---|
| **Publication** | Deng et al., 2026-06. *Journal of Translational Medicine*. [DOI: 10.1186/s12967-026-08425-2](https://doi.org/10.1186/s12967-026-08425-2) |
| **GitHub** | Not publicly released (as of early 2026) |
| **Language** | — |

**Approach:** Identifies **stage-specific metagenes** from bulk RNA-seq via S-score, projects them onto ST at pixel level with information-enhanced mapping, then aggregates to spot resolution for malignancy quantification.

**Inputs:** Bulk RNA-seq with stage labels; ST expression + coordinates

**Outputs:** Spot-level stage/malignancy scores; spatial TME characterization

**Strengths:** Links tumor stage phenotypes to spatial architecture; drug TME evaluation.  
**Limitations:** Overlaps SCTP/SpacePhenotyper conceptual space; no public code yet.

---

## Signature-based scoring

### PhenoMapR
**Semi-supervised prognostic signature mapping**

| | |
|---|---|
| **Publication** | In development |
| **GitHub** | https://github.com/brooksbenard/PhenoMapR |
| **Language** | R |

**Approach:** Maps **prognostic gene signatures** (PRECOG, TCGA, pediatric, ICI references) onto bulk, single-cell, and spatial data via weighted-sum scoring. Optional activity-adjusted scoring (regress cell-cycle/counts), permutation nulls, and donor-aware variants.

**Inputs:** Expression matrix or Seurat/SCE/SpatialExperiment; reference database + cancer type

**Outputs:** Per-sample/cell/spot prognostic scores; rank-ordered phenotype association

**Strengths:** No bulk-sc integration needed; works on spatial and sc directly; built-in cancer references; Shiny app.  
**Limitations:** Signature-based (not learning phenotype mapping de novo from user bulk data).

---

## Meta-frameworks & comparison toolkits

### SigBridgeR
**Significant cell-to-phenotype bridge in R**

| | |
|---|---|
| **Publication** | Wang et al., 2026-05. bioRxiv. [DOI: 10.64898/2026.05.08.723458](https://doi.org/10.64898/2026.05.08.723458) |
| **GitHub** | https://github.com/WangLabCSU/SigBridgeR |
| **Docs** | https://wanglabcsu.github.io/SigBridgeR/ |
| **Language** | R |

**Approach:** Registry-based R framework unifying **eight bulk→sc phenotype screening algorithms** under standardized preprocessing, parameter conventions, and output formats. Includes systematic benchmarking across four cancer types with positive/negative controls and **ensemble weighted voting**.

**Wrapped methods:** Scissor, scPAS, ScPP, DEGAS, PIPET, LP_SGL (LPSGL), rSIDISH, SCIPAC, rTiRank, scAB, scSurvival, SCellBOW, scPER, and others.

**Inputs:** scRNA-seq + bulk RNA-seq + phenotype (binary, continuous, or survival)

**Outputs:** Standardized phenotype-associated cell labels/scores; multi-method comparison plots

**Strengths:** Lowers barrier to cross-method benchmarking; reproducible multi-method workflows.  
**Limitations:** Preprint; wrapper quality depends on underlying method implementations.

---

## Related methods (adjacent scope)

These methods address closely related questions—linking sample phenotypes to cell states—but differ in input requirements or primary use case from core bulk→sc phenotype mapping.

### Augur
**Cell-type prioritization for perturbation response**

| | |
|---|---|
| **Publication** | Skinnider et al., 2020-07. *Nature Biotechnology* 39(1):30–34. [DOI: 10.1038/s41587-020-0605-1](https://doi.org/10.1038/s41587-020-0605-1) |
| **GitHub** | https://github.com/neurorestore/Augur |
| **Language** | R |

**Approach:** Ranks **cell types** by how well they predict sample-level experimental conditions (perturbation vs control) using random forest classification with cross-validation.

**Inputs:** Multi-sample scRNA-seq with per-sample condition labels (no bulk RNA-seq)

**Outputs:** AUC-based cell-type prioritization ranking

**Relevance:** Foundational for "which cells carry the phenotype?" but requires labeled sc cohorts, not bulk transfer.

---

### scRANK
**Prior-knowledge cell cluster ranking**

| | |
|---|---|
| **Publication** | Aoulas et al., 2024-04. *PLOS Computational Biology* 20(4):e1011550. [DOI: 10.1371/journal.pcbi.1011550](https://doi.org/10.1371/journal.pcbi.1011550) |
| **GitHub** | https://github.com/aoulas/scRANK |
| **Language** | R |

**Approach:** Maps user-provided **prior knowledge** (pathways, drug lists, disease genes) against scRNA-seq DE/pathway/drug-repurposing results to rank cell clusters.

**Inputs:** scRNA-seq with disease vs control; expert-defined checklist of genes/drugs/pathways

**Outputs:** Ranked cell clusters aligned with prior knowledge

**Relevance:** Interpretability-focused cluster ranking; not bulk clinical phenotype transfer.

---

### SSDA4Drug
**Semi-supervised bulk→sc drug response transfer**

| | |
|---|---|
| **Publication** | Liu et al., 2025-03. *Communications Biology* 8:478. [DOI: 10.1038/s42003-025-07959-3](https://doi.org/10.1038/s42003-025-07959-3) |
| **GitHub** | https://github.com/hliulab/SSDA4Drug |
| **Language** | Python |

**Approach:** **Semi-supervised adversarial domain adaptation** transfers pharmacogenomic drug-response knowledge from bulk/cell-line RNA-seq to scRNA-seq with few labeled target cells.

**Inputs:** Bulk/cell-line RNA-seq (source); scRNA-seq (target); optional few labeled sc cells

**Outputs:** Per-cell drug sensitivity/resistance predictions

**Relevance:** Bulk→sc transfer for **drug response**, not clinical survival/stage phenotypes.

---

### ATSDP-NET
**Attention-based transfer learning for sc drug response**

| | |
|---|---|
| **Publication** | 2025-08. *Frontiers in Medicine* 12:1631898. [DOI: 10.3389/fmed.2025.1631898](https://doi.org/10.3389/fmed.2025.1631898) |
| **GitHub** | Not publicly released |
| **Language** | Python |

**Approach:** Pre-trains on bulk RNA-seq drug response, then **transfer learning + multi-head attention** predicts drug sensitivity at single-cell resolution.

**Inputs:** Bulk RNA-seq with drug labels; scRNA-seq tumor data

**Outputs:** Per-cell drug response predictions

**Relevance:** Pharmacogenomics analog of bulk→sc clinical phenotype mapping.

---

## Out-of-scope adjacent tools

Methods sometimes confused with phenotype mapping but outside this doc's primary scope:

| Tool | Why excluded |
|------|--------------|
| **CellDiffusion** (bioRxiv 2025) | Generative bulk→sc **cell-type annotation** via virtual cells, not clinical phenotype mapping |
| **BayesPrism, CIBERSORTx, etc.** | Deconvolution → cell **proportions** vs phenotype; no per-cell labels |
| **PRECOG-style signature scoring** | Apply pre-built prognostic signatures without bulk–sc integration (see PhenoMapR) |
| **GLISS, spatial SVG tools** | Spatial **gene discovery**, not clinical phenotype projection |
| **SEDR, GraphST, STAligner, PRECAST, BANKSY, etc.** | Multi-slice ST **integration / domains** without clinical phenotype linking (see **stClinic** for clinical niches) |
| **MOFA, MEFISTO, MOFAcell** | Multi-view **factor analysis** with covariates; no explicit phenotype cell mapping |

---

## Choosing a method

| Your situation | Consider |
|----------------|----------|
| Have sc reference + large bulk cohort with phenotypes | **Scissor** (simple), **LP_SGL** (group-aware), **Shears** (scale + covariates), **SCIPAC** (p-values), **PACSI** (PPI network), **DEGAS** (deep learning) |
| Have bulk survival + sc reference | **scSurv**, **scRank-XMBD**, **SIDISH**, **TiRank**, **scSurvival** (if sc cohort has survival) |
| Have multi-sample sc with sample labels (no bulk) | **Pencil**, **scPhase**, **MultiMIL**, **PaSCient**, **scSurvival** (if survival), **Augur** (perturbation) |
| Have multi-slice ST (+ multi-omics) with clinical labels (survival, metastasis) | **stClinic** |
| Have ST + bulk clinical data | **SpaLinker**, **SpaPheno**, **TiRank**, **SpacePhenotyper**, **SCTP**, **stSurvTrans** (survival), **SP-printer** (stage) |
| Need spatial single-cell platforms (Xenium/CosMx) | **DEGAS spatial smoothing**, **SCTP** |
| Need Visium ST + bulk (prostate field effect) | **DEGAS-ST** |
| Want interpretable spatial biomarkers | **SpaPheno** (SHAP), **SpacePhenotyper** (Eigen-Patient) |
| Have histology slides + phenotypes | **BiSCALE** |
| Want prognostic signature scoring on any modality | **PhenoMapR** |
| Need formal per-cell significance | **SCIPAC**, **scPAS** |
| Atlas-scale (>1M cells) bulk integration | **Shears** |
| Patient-level (not per-cell) bulk+sc prognosis | **scBGDL** |
| Drug response bulk→sc transfer | **SSDA4Drug**, **ATSDP-NET** |
| Compare many methods at once | **SigBridgeR** |

---

## Method relationship diagram (bulk→sc family)

```
Bulk phenotype + sc reference
         │
         ├── Correlation + sparse regression ── Scissor
         ├── Correlation + sparse group lasso ── LP_SGL (Leiden groups)
         ├── Weighted deconv + GLM ─────────── Shears
         ├── NMF (multiresolution) ─────────── scAB
         ├── Network-regularized regression ── scPAS
         ├── Continuous association + p-val ── SCIPAC
         ├── PPI network proximity ─────────── PACSI
         ├── REO prognostic ranking ────────── scRank-XMBD
         ├── Bulk DEG → vector similarity ─── PIPET
         ├── Bulk DEG → AUCell enrichment ─── ScPP
         ├── Deep transfer learning ────────── DEGAS (core, 2022)
         ├── ST application (Visium) ───────── DEGAS-ST (prostate, 2025)
         ├── scSRT + spatial smoothing ─────── DEGAS spatial smoothing (2026)
         ├── Iterative VAE + Cox ───────────── SIDISH, scSurv
         ├── Sample-specific gene graphs ───── scBGDL (patient-level output)
         └── sc trajectory → bulk signature ── scPrognosis (indirect)
```

---

## References & links

### Primary papers (DOI index)
- Scissor: https://doi.org/10.1038/s41587-021-01091-3
- Augur: https://doi.org/10.1038/s41587-020-0605-1
- Pencil: https://doi.org/10.1038/s42256-023-00656-y
- LP_SGL: https://doi.org/10.1093/bib/bbad424
- PACSI: https://doi.org/10.1186/s12915-023-01658-3
- scRank-XMBD: https://doi.org/10.1093/bib/bbad078
- DEGAS: https://doi.org/10.1186/s13073-022-01012-2
- DEGAS-ST: https://doi.org/10.1093/gpbjnl/qzaf119
- DEGAS spatial smoothing: https://doi.org/10.1093/bioinformatics/btag098
- scAB: https://doi.org/10.1093/nar/gkac1109
- SCIPAC: https://doi.org/10.1186/s13059-024-03263-1
- scPAS: https://doi.org/10.1093/bib/bbae655
- PIPET: https://doi.org/10.1093/bib/bbae260
- ScPP: https://doi.org/10.1007/s12539-025-00803-6
- Shears: https://doi.org/10.1016/j.ccell.2025.12.003
- SIDISH: https://doi.org/10.1038/s41467-025-66162-4
- scSurv: https://doi.org/10.1093/bioinformatics/btaf646
- scBGDL: https://doi.org/10.1093/bib/bbaf467
- scPrognosis: https://doi.org/10.1371/journal.pcbi.1008133
- scPhase: https://doi.org/10.1186/s13073-026-01598-x
- TiRank: https://doi.org/10.1186/s13073-026-01604-2
- stSurvTrans: https://doi.org/10.1109/tcbbio.2026.3677899
- SP-printer: https://doi.org/10.1186/s12967-026-08425-2
- stClinic: https://doi.org/10.1038/s41467-025-60575-x
- SpaLinker: https://doi.org/10.1016/j.xgen.2025.100893
- SpaPheno: https://doi.org/10.1186/s13073-026-01645-7
- scSurvival: https://doi.org/10.1158/2159-8290.CD-25-0965
- PaSCient: https://doi.org/10.1016/j.cels.2026.101570
- CellPhenoX: https://doi.org/10.1002/advs.202503289
- scPER: https://doi.org/10.1002/advs.202514502
- SCellBOW: https://doi.org/10.7554/eLife.98469
- SCTP: https://doi.org/10.1002/imt2.70068
- BiSCALE: https://doi.org/10.1002/advs.202521151
- scRANK: https://doi.org/10.1371/journal.pcbi.1011550
- SSDA4Drug: https://doi.org/10.1038/s42003-025-07959-3
- ATSDP-NET: https://doi.org/10.3389/fmed.2025.1631898

### Preprints (not yet peer-reviewed)
- SigBridgeR: https://doi.org/10.64898/2026.05.08.723458
- MultiMIL: https://doi.org/10.1101/2024.07.29.605625
- scTransMIL: https://doi.org/10.1101/2025.04.22.649948
- SpacePhenotyper: https://doi.org/10.64898/2025.12.12.693322
- TinydenseR: https://doi.org/10.1101/2025.11.26.690752
- SCTP (original): https://doi.org/10.1101/2024.02.23.581547
- DEGAS-ST (preprint): https://doi.org/10.1101/2023.04.21.537852
- DEGAS spatial smoothing (preprint): https://doi.org/10.1101/2025.01.30.635803
- CellDiffusion: https://doi.org/10.1101/2025.10.27.684671

---

## Appendix: decision flowchart (previous version)

Before the taxonomy was converted to tables, the doc used this **mermaid flowchart** to route users by input data type:

```mermaid
flowchart TD
    A[Sample phenotype] --> B{What data do you have?}
    B --> C[sc + bulk RNA-seq]
    B --> D[sc cohort with sample labels]
    B --> E[Spatial + clinical / bulk]
    B --> F[Histology / WSI]
    B --> G[Compare many methods]

    C --> C1[Regression / correlation<br/>Scissor, Shears, SCIPAC, scPAS, PIPET, ScPP, scAB, LP_SGL, PACSI]
    C --> C2[Deep transfer learning<br/>DEGAS (core), SIDISH, scSurv, scBGDL]
    C --> C3[REO / survival ranking<br/>scRank-XMBD, TiRank]
    C --> C4[DEGAS ST extensions<br/>DEGAS-ST (Visium app), DEGAS spatial smoothing (scSRT)]

    D --> D1[MIL / attention<br/>scPhase, MultiMIL, PaSCient, scSurvival, Pencil]
    D --> D2[Sample-centric stats<br/>tinydenseR]
    D --> D3[Explainable ML<br/>CellPhenoX]
    D --> D4[Perturbation / priors<br/>Augur, scRANK]

    E --> E1[Bulk-to-spatial transfer<br/>SpacePhenotyper, SpaPheno, TiRank, stSurvTrans, SP-printer]
    E --> E2[Multi-slice ST + clinical graphs<br/>stClinic]
    E --> E3[TME feature linking<br/>SpaLinker]
    E --> E4[Multimodal deep fusion<br/>SCTP]
    E --> E5[scSRT smoothing<br/>DEGAS spatial smoothing]

    F --> F1[Image-to-expression<br/>BiSCALE]

    G --> G1[SigBridgeR meta-framework]
```

---

*Last updated: July 2026. Corrections and additions welcome—this field is moving quickly.*
