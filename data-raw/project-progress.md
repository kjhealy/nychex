# nychex: project progress and approach

## Goal

Build an R package providing tessellated hexagonal tile maps for New
York City geographies. The first (and currently only) geography is the
262 Neighborhood Tabulation Areas (NTA 2020), sourced from
`nycmaps::nyc_nta20_sf`.

## Approach

### Core algorithm

The hex maps are generated using `tilemaps::generate_map()`, which
implements the McNeill & Hale (2017) algorithm for converting polygon
geographies into tessellated tile maps. The key constraint is that
`generate_map()` requires contiguous input polygons. NYC's boroughs are
not all contiguous with each other, and several NTAs are islands or
have island fragments. The approach is therefore:

1. **Split by borough group.** Four groups are tiled separately:
   Manhattan, Bronx, Brooklyn/Queens (combined because they share a
   land border), and Staten Island.

2. **Prepare polygons.** For each group:
   - Cast MULTIPOLYGON geometries to POLYGON (`st_cast`).
   - Keep only the largest polygon per NTA (`slice_max` on area) to
     drop small fragments.
   - Remove NTAs that are geographically disconnected (islands) from
     the main group.
   - Simplify with `rmapshaper::ms_simplify()` to remove fine detail
     that could cause self-intersections.

3. **Generate hex tiles.** Call `generate_map(geometry, square = FALSE,
   flat_topped = FALSE)` on each contiguous group to produce
   pointy-topped hexagonal tiles.

4. **Add islands back.** Use `tilemaps::create_island()` to create
   individual hex tiles for each removed NTA, positioned approximately
   relative to the main group.

5. **Rescale to uniform hex size.** Each group's tiles are independently
   sized by `generate_map()` to fit that group's spatial extent, so hex
   sizes differ across groups. All groups are rescaled uniformly around
   their group centroid so that hex area (and therefore spacing) matches
   the median area across all 262 hexes. This preserves tessellation
   within each group.

6. **Assemble.** Translate each group so its centroid aligns with the
   geographic centroid of the corresponding borough(s) from the original
   `nycmaps::nyc_nta20_sf` data. Apply manual nudges to prevent
   borough overlap (Manhattan west, Bronx east, Staten Island closer
   to Brooklyn).

7. **Fine-tune island positions.** A helper function (`move_nta`) places
   island hexes into specific hex-grid slots relative to named
   reference hexes, using compass directions (e, w, ne, nw, se, sw).
   The helper derives hex spacing from the reference hex's borough
   group and supports an `anchor` parameter for positioning groups of
   hexes, and a `spacing_ref` parameter for cross-borough moves.

### Island and disconnected NTA handling

NTAs removed before tiling and added back as islands:

- **Manhattan (38 NTAs: 36 contiguous + 2 islands)**
  - MN0191 (Battery-Governors Island-Ellis Island-Liberty Island)
  - MN1191 (Randall's Island) -- repositioned W of QN0151

- **Bronx (50 NTAs: 46 contiguous + 4 islands)**
  - BX1003 (City Island area)
  - BX1071 (Pelham Bay Park islands) -- repositioned SE of BX0101
  - BX0291 (North & South Brother Islands) -- disconnects after simplification
  - QN0151 (Rikers Island) -- in Bronx group despite QN prefix; repositioned NW of QN0102

- **Brooklyn/Queens (151 NTAs: 141 contiguous + 10 removed)**
  - Single-hex islands: BK1891, BK5691, BK5692 (Jamaica Bay west,
    repositioned as a group SE of BK1892), QN8491 (Jamaica Bay East,
    repositioned SW of QN8381)
  - Rockaway chain (4 contiguous hexes): QN8492, QN1403, QN1402,
    QN1401 -- repositioned SE of QN8491, anchored on QN1491; horizontal
    order reversed to match west-to-east geography
  - QN1491 (Rockaway Community Park) -- disconnects after simplification;
    part of the Rockaway chain group
  - QN0761 (Fort Totten) -- disconnects after simplification;
    repositioned NE of QN0704

- **Staten Island (23 NTAs: 22 contiguous + 1 island)**
  - SI9591 (Hoffman & Swinburne Islands) -- repositioned SE of SI9592

### Borough outline generation

`nyc_boro_hex_outlines_sf` is derived from the hex map by unioning all
hexes per borough and extracting the largest polygon (dropping
disconnected island hexes). Brooklyn and Queens get separate outlines
so the internal border between them is visible.

## Data-raw scripts

| Script | Purpose |
|---|---|
| `_shared.R` | Common library calls for all scripts |
| `hex_manhattan.R` | Generate Manhattan hex tiles + islands |
| `hex_bronx.R` | Generate Bronx hex tiles + islands |
| `hex_brooklyn_queens.R` | Generate Brooklyn/Queens hex tiles + islands + Rockaway chain |
| `hex_staten_island.R` | Generate Staten Island hex tiles + island |
| `hex_assembly.R` | Rescale, position, combine all groups; fine-tune island placement |
| `hex_boro_outlines.R` | Generate borough outline polygons |
| `build_data.R` | Master script that sources all of the above in order |

Each borough script saves an intermediate `.rds` file (e.g.
`hex_manhattan.rds`). The assembly script loads all four, processes
them, and saves `hex_assembled.rds`. Sample figures for visual review
are saved to `data-raw/sample-figures/`.

### Census tract scripts

| Script | Purpose |
|---|---|
| `ct_hex_manhattan.R` | (inline in generation script) Manhattan tract hex tiles |
| `ct_hex_bronx.R` | (inline) Bronx tract hex tiles |
| `ct_hex_brooklyn.R` | (inline) Brooklyn tract hex tiles |
| `ct_hex_queens.R` | (inline) Queens tract hex tiles |
| `ct_hex_staten_island.R` | (inline) Staten Island tract hex tiles |
| `ct_hex_assembly.R` | Rescale, position, combine all borough tract groups |

Census tract hex maps are generated per-borough (not per-PUMA or
per-NTA). Each borough is processed independently: cast, slice to
largest polygon, remove island NTAs and disconnected tracts, simplify,
then tile. Brooklyn and Queens are tiled separately (unlike the NTA
map where they are combined), so there is a visible gap between them
in the assembled map.

## Package data objects

| Object | Description |
|---|---|
| `nyc_nta20_hex_sf` | 262-row sf object, one POLYGON hex per NTA, EPSG:2263 |
| `nyc_boro_hex_outlines_sf` | 5-row sf object, one POLYGON outline per borough, EPSG:2263 |
| `nyc_ct20_hex_sf` | 2,271-row sf object, one POLYGON hex per census tract, EPSG:2263 |

## Key dependencies (build-time)

- `tilemaps` -- hex tile generation (`generate_map`, `create_island`)
- `rmapshaper` -- polygon simplification
- `sf` -- spatial operations
- `nycmaps` -- source NTA 2020 boundaries
- `socviz` -- `%nin%` operator

## Status

- v0.2.0: Census tract 2020 hex map added.
  - 2,271 contiguous tracts (of 2,325 total) across all five boroughs.
  - Brooklyn and Queens tiled separately; visible gap between them.
  - 54 island/disconnected tracts excluded.
  - Borough-level tiling approach: each borough tiled independently
    with `generate_map()`, then rescaled and assembled.
  - PUMA-level tiling was explored but rejected due to gaps at PUMA
    boundaries within boroughs.
  - Combined BK/QN tiling was explored but `generate_map()` fails at
    ~1,200+ polygons (fragmented output).
- v0.1.0: NTA 2020 hex map and borough outlines complete.
  - All 262 NTAs represented, one hex each, no overlaps.
  - Uniform hex size across all borough groups.
- R CMD check passes with 0 errors, 0 warnings, 0 notes.
