# TimedRaman

A single-file MATLAB GUI application (`TimedRaman.m`) for loading, previewing, processing, and batch-exporting **Renishaw WDF** Raman spectroscopy files as a time series (e.g., for tracking a sample's spectral evolution over air exposure, aging, or another time-based experiment).

**Version:** 1.0

**Developed by:** Nurul Azam
**Email:** nurul_azam@outlook.com
**LinkedIn:** https://www.linkedin.com/in/nurulazam/

This developer information is also available inside the application itself via **Help → About**.

## What it does

1. **Loads `.wdf` files directly** by parsing the binary WDF1 format itself (no Renishaw/WiRE software or toolbox required).
2. **Orders spectra in time** using either the acquisition timestamp embedded in the WDF file itself, or the file's OS modification time as a fallback.
3. **Lets you preview and compare spectra** interactively (single / overlay / waterfall views, raw vs. processed vs. both).
4. **Applies signal processing** — smoothing (Savitzky-Golay or moving average) and baseline correction (Asymmetric Least Squares) — with live preview as you drag sliders.
5. **Exports a combined time-series table** (wavenumber + intensity per file, annotated with elapsed time from a reference point) in both `.csv` and `.dat` formats, for raw and processed data separately.

## Requirements

- MATLAB (developed against standard MATLAB graphics/base functions — `datetime`, `uicontrol`, `spdiags`, etc.)
- No toolboxes required: the Savitzky-Golay filter and ALS baseline are implemented from scratch (`sg_smooth`, `als_baseline`), not from the Signal Processing or Curve Fitting toolboxes.
- Input files: binary `.wdf` files from Renishaw WiRE software (WDF1 format).

## Running it

```matlab
TimedRaman
```

This opens a single window split into a **left control panel** and a **right plotting panel**. A **Help → About** menu item shows the application version and developer contact details.

## Interface guide

### Help menu
**Help → About** opens a dialog showing the application name, version (1.0), and developer contact details (name, email, LinkedIn).

### Air Exposure Reference (top-left)
Set a reference date/time (`Date`, `Time`, `AM/PM`). All elapsed-time annotations in the file list and in the exported time series are computed relative to this timestamp (`sample timestamp − reference time`, in minutes).

### File list
- **Add…** — opens a file picker (multi-select) for `.wdf` files. Each file is parsed immediately; wavenumber axis, intensity, and metadata are extracted and cached. Files are auto-sorted chronologically after loading.
- **Remove / Clear** — remove selected file(s) or clear the whole list.
- **All / None** — check/uncheck all files (checked files are the ones plotted in Overlay/Waterfall mode and included in export).
- **Double-click a row** to toggle its checkbox.
- **^ / v** — reorder the selected file up/down in the list.
- **Info** — opens a pop-up window listing full metadata for the selected file (timestamp, path, point count, wavenumber range, plus everything pulled from the WDF header: laser wavenumber, WiRE version, operator name, stage X/Y/Z position, laser power).
- Each row shows a `[x]`/`[ ]` checkbox, filename, elapsed time from the reference (if valid), and a `*` if the file has been processed.

### Processing panel
- **Apply to:** choose whether the next processing operation targets all *checked* files or only the currently *selected* file.
- **Method:** Savitzky-Golay (window size + polynomial order sliders) or Moving Average (window size slider).
- **Live preview:** shows the effect of current slider settings on the selected spectrum instantly, without committing it to `D.proc`.
- **Baseline correction (ALS):** toggle + three sliders — smoothing λ (10^2–10^7), asymmetry `p` (0.001–0.5), and iteration count. Uses the Eilers & Boelens (2005) asymmetric least-squares algorithm.
- **Apply** — commits the current smoothing/baseline settings to the target file(s), storing the result as "processed" data and auto-switching the view to "Both" (raw + processed overlaid).

### Plot controls (top-right)
- **View:** Single (one spectrum) / Overlay (all checked, same baseline) / Waterfall (all checked, vertically offset by the waterfall-offset slider).
- **Data:** Raw / Processed / Both.
- **X min/max:** manual x-axis (wavenumber) limits; blank = auto.
- **Waterfall offset:** vertical spacing (a.u.) between spectra in waterfall view.
- **Normalize:** None / Max peak (95th-percentile-based, spike-robust) / GaAs LO mode (269 cm⁻¹) / Custom cm⁻¹ — all peak-based modes use a median over ±5 points around the target wavenumber to resist cosmic-ray spikes.
- **Y min/max/base, Clip top %:** fine control over the y-axis — raise the floor to hide baseline, or clip a percentage off the top to reveal weak features under strong peaks.
- **Reset View** — restores all view/plot settings to defaults in one click.

### Output panel
- **Folder / Base** — output directory and base filename for exports.
- **EXPORT (.csv + .dat) x2** — writes **four files**:
  - `<base>_raw_timeseries.csv` / `.dat`
  - `<base>_proc_timeseries.csv` / `.dat`
  
  Each file is a wide table: for every checked spectrum, a `Raman Shift` / intensity column pair, headed by filename, units, and elapsed time (minutes) from the reference timestamp. `.csv` is comma-delimited, `.dat` is tab-delimited. If a file was never processed, its "processed" column falls back to its raw data.
- **Status bar** — shows current state (files checked/total, SG/ALS parameter summary, processed count) and progress/error messages.

## WDF file parsing details

The binary reader (`read_wdf_full`) parses the Renishaw WDF1 container format directly:

- Validates the `WDF1` magic bytes at the file start.
- Reads header fields at fixed offsets: point count, spectrum count, laser wavenumber, WiRE version, acquisition time (Windows FILETIME → UTC `datetime` → converted to local time), and operator name.
- Walks the block chain looking for `DATA` (intensities), `XLST` (wavenumber axis), and `ORGN` (stage X/Y/Z position, laser power) blocks by signature and size.
- Extracts the first spectrum's intensity array and the shared wavenumber axis.

These offsets were determined by direct binary inspection of sample files and are documented in comments directly above the `read_wdf_full` function in the source.

## Processing algorithms (implemented from scratch)

| Algorithm | Function | Notes |
|---|---|---|
| Savitzky-Golay smoothing | `sg_smooth` | Least-squares polynomial fit over a sliding window; derives its own coefficients (no toolbox). |
| Moving average smoothing | `ma_smooth` | Simple convolution with edge-value padding. |
| ALS baseline correction | `als_baseline` | Eilers & Boelens (2005) asymmetric least squares, iterative reweighting. |

## Known limitations / things to check before trusting output

- **Single-spectrum WDF only in practice:** `read_wdf_full` extracts only the *first* spectrum from a WDF file (`intensity = double(ir(1:min(npts,numel(ir))))`), even though it reads `nspectra`. Multi-spectrum/map WDF files will only yield their first spectrum.
- **Fixed WDF header offsets:** the byte offsets used to read header fields (npoints, nspectra, laser wavenumber, WiRE version, FILETIME, operator name) are hard-coded based on inspection of specific sample files. Files from different WiRE software versions could have different offsets — verify metadata (via the **Info** button) looks sane after loading unfamiliar files.
- **Timestamp fallback:** if the WDF FILETIME field is zero/missing, the app falls back to the OS file modification time, which may not reflect the true acquisition time (e.g., if files were copied/moved).
- **Elapsed-time / export depends on the reference date-time field** being a valid, parseable date — invalid input blocks export with an error in the status bar.
- **No undo for "Apply":** applying processing overwrites the previous processed result for the target file(s); raw data is preserved separately so re-processing from scratch is always possible, but there's no processing history.
- **GUI-only, no command-line/scripted interface:** there is no way to batch-run this outside of interacting with the UI (e.g., no headless export function you can call directly with a list of files).

## File structure inside the script

```
TimedRaman()                   — main entry point; builds UI, defines app state D (guidata)
├── MENU                        — cb_about (Help → About dialog with developer info)
├── FILE MANAGEMENT             — cb_add, cb_remove, cb_clear, cb_check_all/none, cb_list_select, cb_metadata
├── REORDER                     — cb_move_up, cb_move_down
├── VIEW / DATA MODE            — cb_viewmode, cb_datamode, cb_yrange, cb_yclip, cb_xrange, cb_reset_view,
│                                  cb_wf_offset, cb_norm
├── PROCESSING SLIDERS          — cb_sg_win/ord, cb_ma_win, cb_smooth_method_change, cb_als_lam/p/iter
├── APPLY PROCESSING            — cb_apply_processing
├── PLOT                        — refresh_plot, plot_one, compute_live_smooth, apply_norm, norm_to_peak
├── EXPORT                      — cb_export, write_timeseries, cb_browse
├── PROCESSING ALGORITHMS       — sg_smooth, ma_smooth, als_baseline
├── WDF READER                  — read_wdf_full
└── SHARED HELPERS              — refresh_list, keep_fields, reorder_all, update_status
```

## Typical workflow

1. Set the **Air Exposure Reference** date/time to your experiment's t=0.
2. **Add…** your `.wdf` files (they'll auto-sort by time).
3. Use **Info** to sanity-check metadata on a couple of files.
4. Tune **Method** / **Window** / **Poly order** and **ALS** sliders with **Live preview** on, watching the **Single** view.
5. Set **Apply to: All checked files**, click **Apply**.
6. Switch to **Overlay** or **Waterfall** view to inspect all spectra together; adjust **Normalize** and **Y-axis** controls as needed.
7. Set **Folder**/**Base** name, click **EXPORT** to write the four output files.
