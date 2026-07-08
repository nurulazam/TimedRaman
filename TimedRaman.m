function TimedRaman()
% TIMEDRAMAN  v1.0 — Renishaw WDF batch exporter with live preview,
% Savitzky-Golay smoothing, ALS baseline correction, per-file checkboxes,
% view modes (Single / Overlay / Waterfall), and metadata pop-out.
%
% Layout  : left panel (controls) | right panel (axes)
% Export  : two file pairs — raw and processed — .dat + .csv
% Checkbox: double-click a row to toggle; or use All/None buttons
% Metadata: select a file then click Info
%
% Software developed by Nurul Azam
% Email   : nurul_azam@outlook.com
% LinkedIn: https://www.linkedin.com/in/nurulazam/

% ── Colour palette (up to 12 files; raw=faint dashed, proc=bold solid) ──
FILE_COLORS = [
    0.09 0.47 0.80;   % blue
    0.88 0.36 0.17;   % orange-red
    0.55 0.25 0.67;   % purple
    0.16 0.62 0.42;   % teal
    0.79 0.63 0.00;   % gold
    0.82 0.24 0.49;   % pink
    0.30 0.67 0.90;   % sky
    0.47 0.72 0.19;   % lime
    0.95 0.54 0.20;   % amber
    0.40 0.40 0.40;   % gray
    0.13 0.47 0.71;   % steel
    0.58 0.40 0.74;   % lavender
];

BG  = [0.96 0.96 0.96];
BG2 = [0.99 0.99 0.99];

fig = figure('Name','TimedRaman v1.0', ...
    'NumberTitle','off','MenuBar','none','ToolBar','none', ...
    'Units','normalized','Position',[0.04 0.05 0.92 0.88], ...
    'Resize','on','Color',BG);

% ── Menu bar: Help > About ──────────────────────────────────────────────
hs.menu_help  = uimenu(fig,'Text','Help');
hs.menu_about = uimenu(hs.menu_help,'Text','About','Callback',@cb_about);

% ══════════════════════════════════════════════════════════════════════
%  LEFT PANEL  (normalized x: 0 → 0.30)
% ══════════════════════════════════════════════════════════════════════

uicontrol(fig,'Style','text','String','TimedRaman', ...
    'Units','normalized','Position',[0.01 0.965 0.28 0.030], ...
    'FontSize',11,'FontWeight','bold','HorizontalAlignment','left', ...
    'BackgroundColor',BG);

% ── Reference time ───────────────────────────────────────────────────
uicontrol(fig,'Style','text','String','Air Exposure Reference', ...
    'Units','normalized','Position',[0.01 0.930 0.28 0.025], ...
    'FontSize',8,'FontWeight','bold','HorizontalAlignment','left', ...
    'ForegroundColor',[0.35 0.35 0.35],'BackgroundColor',BG);
uicontrol(fig,'Style','text','String','Date:', ...
    'Units','normalized','Position',[0.01 0.903 0.050 0.022], ...
    'FontSize',8,'HorizontalAlignment','right','BackgroundColor',BG);
hs.date_edit = uicontrol(fig,'Style','edit','String','2026-04-16', ...
    'Units','normalized','Position',[0.065 0.905 0.11 0.022],'FontSize',8);
uicontrol(fig,'Style','text','String','Time:', ...
    'Units','normalized','Position',[0.178 0.903 0.040 0.022], ...
    'FontSize',8,'HorizontalAlignment','right','BackgroundColor',BG);
hs.time_edit = uicontrol(fig,'Style','edit','String','09:30', ...
    'Units','normalized','Position',[0.222 0.905 0.070 0.022],'FontSize',8);
hs.ampm_popup = uicontrol(fig,'Style','popupmenu','String',{'AM','PM'}, ...
    'Units','normalized','Position',[0.295 0.905 0.050 0.022],'FontSize',8);

% ── File list header ─────────────────────────────────────────────────
uicontrol(fig,'Style','text','String','WDF Files  (double-click row to toggle check)', ...
    'Units','normalized','Position',[0.01 0.874 0.22 0.024], ...
    'FontSize',8,'FontWeight','bold','HorizontalAlignment','left', ...
    'ForegroundColor',[0.35 0.35 0.35],'BackgroundColor',BG);
uicontrol(fig,'Style','pushbutton','String','All', ...
    'Units','normalized','Position',[0.238 0.874 0.035 0.024], ...
    'FontSize',7,'Callback',@cb_check_all);
uicontrol(fig,'Style','pushbutton','String','None', ...
    'Units','normalized','Position',[0.276 0.874 0.040 0.024], ...
    'FontSize',7,'Callback',@cb_check_none);

% ── Listbox + up/down ────────────────────────────────────────────────
hs.file_list = uicontrol(fig,'Style','listbox', ...
    'Units','normalized','Position',[0.01 0.570 0.270 0.300], ...
    'FontSize',8,'FontName','Consolas','Max',1,'Min',0, ...
    'Callback',@cb_list_select);

uicontrol(fig,'Style','pushbutton','String','^', ...
    'Units','normalized','Position',[0.284 0.780 0.030 0.055], ...
    'FontSize',13,'FontWeight','bold','Callback',@cb_move_up);
uicontrol(fig,'Style','pushbutton','String','v', ...
    'Units','normalized','Position',[0.284 0.715 0.030 0.055], ...
    'FontSize',13,'FontWeight','bold','Callback',@cb_move_down);

% ── File buttons ─────────────────────────────────────────────────────
uicontrol(fig,'Style','pushbutton','String','Add…', ...
    'Units','normalized','Position',[0.010 0.540 0.065 0.026],'FontSize',8, ...
    'Callback',@cb_add);
uicontrol(fig,'Style','pushbutton','String','Remove', ...
    'Units','normalized','Position',[0.080 0.540 0.070 0.026],'FontSize',8, ...
    'Callback',@cb_remove);
uicontrol(fig,'Style','pushbutton','String','Clear', ...
    'Units','normalized','Position',[0.155 0.540 0.060 0.026],'FontSize',8, ...
    'Callback',@cb_clear);
uicontrol(fig,'Style','pushbutton','String','Info', ...
    'Units','normalized','Position',[0.225 0.540 0.050 0.026],'FontSize',8, ...
    'Callback',@cb_metadata, ...
    'BackgroundColor',[0.84 0.90 0.98], ...
    'TooltipString','Show metadata for selected file');

% ── Processing ───────────────────────────────────────────────────────
uicontrol(fig,'Style','text','String','Processing', ...
    'Units','normalized','Position',[0.01 0.508 0.12 0.024], ...
    'FontSize',8,'FontWeight','bold','HorizontalAlignment','left', ...
    'ForegroundColor',[0.35 0.35 0.35],'BackgroundColor',BG);

uicontrol(fig,'Style','text','String','Apply to:', ...
    'Units','normalized','Position',[0.010 0.482 0.065 0.022], ...
    'FontSize',8,'HorizontalAlignment','right','BackgroundColor',BG);
hs.scope_popup = uicontrol(fig,'Style','popupmenu', ...
    'String',{'All checked files','Selected file only'}, ...
    'Units','normalized','Position',[0.078 0.483 0.145 0.022],'FontSize',8);
uicontrol(fig,'Style','pushbutton','String','Apply', ...
    'Units','normalized','Position',[0.228 0.483 0.050 0.022], ...
    'FontSize',8,'FontWeight','bold', ...
    'BackgroundColor',[0.18 0.50 0.18],'ForegroundColor','w', ...
    'Callback',@cb_apply_processing);

% ── Smoothing method selector + LIVE preview toggle ─────────────────
uicontrol(fig,'Style','text','String','Method:', ...
    'Units','normalized','Position',[0.010 0.458 0.055 0.020], ...
    'FontSize',7,'HorizontalAlignment','right','BackgroundColor',BG);
hs.smooth_method = uicontrol(fig,'Style','popupmenu', ...
    'String',{'Savitzky-Golay (SG)','Moving Average (MA)'}, ...
    'Units','normalized','Position',[0.068 0.459 0.160 0.020],'FontSize',8, ...
    'Callback',@cb_smooth_method_change);
hs.live_preview = uicontrol(fig,'Style','checkbox','String','Live preview', ...
    'Units','normalized','Position',[0.232 0.458 0.105 0.020], ...
    'FontSize',8,'Value',1,'BackgroundColor',BG, ...
    'TooltipString','Show smoothing result on selected file instantly as sliders move', ...
    'Callback',@(~,~)refresh_plot(ancestor(hs.live_preview,'figure')));

% SG controls (shown when SG selected)
hs.sg_on = uicontrol(fig,'Style','checkbox', ...
    'String','Smoothing ON', ...
    'Units','normalized','Position',[0.010 0.435 0.150 0.020], ...
    'FontSize',8,'Value',1,'BackgroundColor',BG, ...
    'Callback',@(~,~)refresh_plot(ancestor(hs.sg_on,'figure')));
uicontrol(fig,'Style','text','String','Window:', ...
    'Units','normalized','Position',[0.010 0.412 0.068 0.020], ...
    'FontSize',7,'HorizontalAlignment','right','BackgroundColor',BG);
hs.sg_win = uicontrol(fig,'Style','slider','Min',3,'Max',101,'Value',11, ...
    'Units','normalized','Position',[0.082 0.414 0.170 0.018], ...
    'SliderStep',[2/98 10/98],'Callback',@cb_sg_win);
hs.sg_win_lbl = uicontrol(fig,'Style','text','String','11 pts', ...
    'Units','normalized','Position',[0.256 0.412 0.040 0.020], ...
    'FontSize',7,'BackgroundColor',BG,'HorizontalAlignment','left');
uicontrol(fig,'Style','text','String','Poly order:', ...
    'Units','normalized','Position',[0.010 0.390 0.068 0.020], ...
    'FontSize',7,'HorizontalAlignment','right','BackgroundColor',BG);
hs.sg_ord = uicontrol(fig,'Style','slider','Min',2,'Max',5,'Value',3, ...
    'Units','normalized','Position',[0.082 0.392 0.170 0.018], ...
    'SliderStep',[1/3 1/3],'Callback',@cb_sg_ord);
hs.sg_ord_lbl = uicontrol(fig,'Style','text','String','3', ...
    'Units','normalized','Position',[0.256 0.390 0.040 0.020], ...
    'FontSize',7,'BackgroundColor',BG,'HorizontalAlignment','left');

% MA controls (shown when MA selected — same position, hidden by default)
hs.ma_win = uicontrol(fig,'Style','slider','Min',3,'Max',101,'Value',11, ...
    'Units','normalized','Position',[0.082 0.414 0.170 0.018], ...
    'SliderStep',[2/98 10/98],'Callback',@cb_ma_win,'Visible','off');
hs.ma_win_lbl = uicontrol(fig,'Style','text','String','11 pts', ...
    'Units','normalized','Position',[0.256 0.412 0.040 0.020], ...
    'FontSize',7,'BackgroundColor',BG,'HorizontalAlignment','left','Visible','off');
hs.ma_label = uicontrol(fig,'Style','text','String','Window:', ...
    'Units','normalized','Position',[0.010 0.412 0.068 0.020], ...
    'FontSize',7,'HorizontalAlignment','right','BackgroundColor',BG,'Visible','off');

% ALS baseline
hs.als_on = uicontrol(fig,'Style','checkbox', ...
    'String','Baseline correction (ALS)', ...
    'Units','normalized','Position',[0.010 0.365 0.200 0.022], ...
    'FontSize',8,'Value',1,'BackgroundColor',BG, ...
    'Callback',@(~,~)refresh_plot(ancestor(hs.als_on,'figure')));
uicontrol(fig,'Style','text','String','Smooth λ:', ...
    'Units','normalized','Position',[0.010 0.340 0.068 0.020], ...
    'FontSize',7,'HorizontalAlignment','right','BackgroundColor',BG);
hs.als_lam = uicontrol(fig,'Style','slider','Min',2,'Max',7,'Value',4, ...
    'Units','normalized','Position',[0.082 0.342 0.170 0.018], ...
    'SliderStep',[1/5 1/5],'Callback',@cb_als_lam);
hs.als_lam_lbl = uicontrol(fig,'Style','text','String','10^4', ...
    'Units','normalized','Position',[0.256 0.340 0.033 0.020], ...
    'FontSize',7,'BackgroundColor',BG,'HorizontalAlignment','left');
uicontrol(fig,'Style','text','String','Asymm p:', ...
    'Units','normalized','Position',[0.010 0.318 0.068 0.020], ...
    'FontSize',7,'HorizontalAlignment','right','BackgroundColor',BG);
hs.als_p = uicontrol(fig,'Style','slider','Min',1,'Max',9,'Value',2, ...
    'Units','normalized','Position',[0.082 0.320 0.170 0.018], ...
    'SliderStep',[1/8 1/8],'Callback',@cb_als_p);
hs.als_p_lbl = uicontrol(fig,'Style','text','String','0.01', ...
    'Units','normalized','Position',[0.256 0.318 0.033 0.020], ...
    'FontSize',7,'BackgroundColor',BG,'HorizontalAlignment','left');
uicontrol(fig,'Style','text','String','Iterations:', ...
    'Units','normalized','Position',[0.010 0.296 0.068 0.020], ...
    'FontSize',7,'HorizontalAlignment','right','BackgroundColor',BG);
hs.als_iter = uicontrol(fig,'Style','slider','Min',5,'Max',50,'Value',10, ...
    'Units','normalized','Position',[0.082 0.298 0.170 0.018], ...
    'SliderStep',[1/9 3/9],'Callback',@cb_als_iter);
hs.als_iter_lbl = uicontrol(fig,'Style','text','String','10', ...
    'Units','normalized','Position',[0.256 0.296 0.033 0.020], ...
    'FontSize',7,'BackgroundColor',BG,'HorizontalAlignment','left');

% ── Output ───────────────────────────────────────────────────────────
uicontrol(fig,'Style','text','String','Output', ...
    'Units','normalized','Position',[0.010 0.266 0.08 0.022], ...
    'FontSize',8,'FontWeight','bold','HorizontalAlignment','left', ...
    'ForegroundColor',[0.35 0.35 0.35],'BackgroundColor',BG);
uicontrol(fig,'Style','text','String','Folder:', ...
    'Units','normalized','Position',[0.010 0.242 0.055 0.022], ...
    'FontSize',8,'HorizontalAlignment','right','BackgroundColor',BG);
hs.outdir = uicontrol(fig,'Style','edit','String',pwd, ...
    'Units','normalized','Position',[0.068 0.243 0.196 0.022], ...
    'FontSize',7,'HorizontalAlignment','left');
uicontrol(fig,'Style','pushbutton','String','…', ...
    'Units','normalized','Position',[0.267 0.243 0.025 0.022], ...
    'FontSize',8,'Callback',@cb_browse);
uicontrol(fig,'Style','text','String','Base:', ...
    'Units','normalized','Position',[0.010 0.218 0.055 0.022], ...
    'FontSize',8,'HorizontalAlignment','right','BackgroundColor',BG);
hs.basename = uicontrol(fig,'Style','edit','String','MnTe_air_exposure', ...
    'Units','normalized','Position',[0.068 0.219 0.224 0.022],'FontSize',8);

uicontrol(fig,'Style','pushbutton','String','EXPORT  (.csv + .dat)  x2', ...
    'Units','normalized','Position',[0.010 0.185 0.282 0.030], ...
    'FontSize',10,'FontWeight','bold', ...
    'BackgroundColor',[0.15 0.50 0.15],'ForegroundColor','w', ...
    'Callback',@cb_export);

hs.status = uicontrol(fig,'Style','text','String','Ready.', ...
    'Units','normalized','Position',[0.010 0.140 0.282 0.040], ...
    'HorizontalAlignment','left','FontSize',8, ...
    'ForegroundColor',[0.10 0.10 0.55],'BackgroundColor',BG);

% ══════════════════════════════════════════════════════════════════════
%  RIGHT PANEL — plot (normalized x: 0.31 → 1.00)
% ══════════════════════════════════════════════════════════════════════

% Row 1: view mode + data mode + X range
uicontrol(fig,'Style','text','String','View:', ...
    'Units','normalized','Position',[0.315 0.957 0.038 0.026], ...
    'FontSize',8,'HorizontalAlignment','right','BackgroundColor',BG);
hs.btn_single = uicontrol(fig,'Style','togglebutton','String','Single', ...
    'Units','normalized','Position',[0.355 0.958 0.062 0.026],'FontSize',8,'Value',1, ...
    'Callback',@(s,~)cb_viewmode(s,'single'));
hs.btn_overlay = uicontrol(fig,'Style','togglebutton','String','Overlay', ...
    'Units','normalized','Position',[0.419 0.958 0.064 0.026],'FontSize',8,'Value',0, ...
    'Callback',@(s,~)cb_viewmode(s,'overlay'));
hs.btn_waterfall = uicontrol(fig,'Style','togglebutton','String','Waterfall', ...
    'Units','normalized','Position',[0.485 0.958 0.072 0.026],'FontSize',8,'Value',0, ...
    'Callback',@(s,~)cb_viewmode(s,'waterfall'));

uicontrol(fig,'Style','text','String','Data:', ...
    'Units','normalized','Position',[0.568 0.957 0.038 0.026], ...
    'FontSize',8,'HorizontalAlignment','right','BackgroundColor',BG);
hs.btn_raw = uicontrol(fig,'Style','togglebutton','String','Raw', ...
    'Units','normalized','Position',[0.608 0.958 0.052 0.026],'FontSize',8,'Value',1, ...
    'Callback',@(s,~)cb_datamode(s,'raw'));
hs.btn_proc = uicontrol(fig,'Style','togglebutton','String','Processed', ...
    'Units','normalized','Position',[0.662 0.958 0.078 0.026],'FontSize',8,'Value',0, ...
    'Callback',@(s,~)cb_datamode(s,'proc'));
hs.btn_both = uicontrol(fig,'Style','togglebutton','String','Both', ...
    'Units','normalized','Position',[0.742 0.958 0.050 0.026],'FontSize',8,'Value',0, ...
    'Callback',@(s,~)cb_datamode(s,'both'));

uicontrol(fig,'Style','text','String','X min:', ...
    'Units','normalized','Position',[0.803 0.957 0.040 0.026], ...
    'FontSize',8,'HorizontalAlignment','right','BackgroundColor',BG);
hs.xmin_edit = uicontrol(fig,'Style','edit','String','', ...
    'Units','normalized','Position',[0.845 0.959 0.048 0.024],'FontSize',8, ...
    'Callback',@cb_xrange,'TooltipString','Leave blank for auto');
uicontrol(fig,'Style','text','String','max:', ...
    'Units','normalized','Position',[0.895 0.957 0.030 0.026], ...
    'FontSize',8,'HorizontalAlignment','right','BackgroundColor',BG);
hs.xmax_edit = uicontrol(fig,'Style','edit','String','', ...
    'Units','normalized','Position',[0.927 0.959 0.048 0.024],'FontSize',8, ...
    'Callback',@cb_xrange,'TooltipString','Leave blank for auto');

% Row 2: waterfall offset + normalize
uicontrol(fig,'Style','text','String','Waterfall offset:', ...
    'Units','normalized','Position',[0.315 0.928 0.100 0.022], ...
    'FontSize',8,'HorizontalAlignment','right','BackgroundColor',BG);
hs.wf_slider = uicontrol(fig,'Style','slider','Min',0,'Max',5000,'Value',200, ...
    'Units','normalized','Position',[0.418 0.930 0.190 0.018], ...
    'SliderStep',[0.01 0.10],'Callback',@cb_wf_offset);
hs.wf_lbl = uicontrol(fig,'Style','text','String','200 a.u.', ...
    'Units','normalized','Position',[0.611 0.928 0.070 0.022], ...
    'FontSize',8,'BackgroundColor',BG);

uicontrol(fig,'Style','text','String','Normalize:', ...
    'Units','normalized','Position',[0.692 0.928 0.062 0.022], ...
    'FontSize',8,'HorizontalAlignment','right','BackgroundColor',BG);
hs.norm_popup = uicontrol(fig,'Style','popupmenu', ...
    'String',{'None','Max peak','GaAs LO (269 cm-1)','Custom cm-1'}, ...
    'Units','normalized','Position',[0.757 0.929 0.118 0.022],'FontSize',8, ...
    'Callback',@cb_norm);
hs.norm_wn = uicontrol(fig,'Style','edit','String','269', ...
    'Units','normalized','Position',[0.878 0.929 0.044 0.022],'FontSize',8, ...
    'Enable','off','TooltipString','Custom normalisation wavenumber cm-1', ...
    'Callback',@(~,~)refresh_plot(ancestor(hs.norm_wn,'figure')));

% Row 3: Y-axis controls
% Strategy: compute true data range first, then apply clip% from top (zoom)
% and manual overrides — no reliance on MATLAB auto-ylim after draw.
uicontrol(fig,'Style','text','String','Y min:', ...
    'Units','normalized','Position',[0.315 0.897 0.040 0.022], ...
    'FontSize',8,'HorizontalAlignment','right','BackgroundColor',BG);
hs.ymin_edit = uicontrol(fig,'Style','edit','String','', ...
    'Units','normalized','Position',[0.357 0.899 0.055 0.022],'FontSize',8, ...
    'Callback',@cb_yrange,'TooltipString','Manual Y min — leave blank for auto');
uicontrol(fig,'Style','text','String','max:', ...
    'Units','normalized','Position',[0.414 0.897 0.030 0.022], ...
    'FontSize',8,'HorizontalAlignment','right','BackgroundColor',BG);
hs.ymax_edit = uicontrol(fig,'Style','edit','String','', ...
    'Units','normalized','Position',[0.446 0.899 0.055 0.022],'FontSize',8, ...
    'Callback',@cb_yrange,'TooltipString','Manual Y max — leave blank for auto');

uicontrol(fig,'Style','text','String','Clip top %:', ...
    'Units','normalized','Position',[0.504 0.897 0.058 0.022], ...
    'FontSize',8,'HorizontalAlignment','right','BackgroundColor',BG);
hs.yclip_slider = uicontrol(fig,'Style','slider','Min',0,'Max',99,'Value',0, ...
    'Units','normalized','Position',[0.565 0.899 0.155 0.018], ...
    'SliderStep',[0.01 0.05],'Callback',@cb_yclip, ...
    'TooltipString','Clip the top N% of intensity range — reveals weak features under tall peaks');
hs.yclip_lbl = uicontrol(fig,'Style','text','String','0%', ...
    'Units','normalized','Position',[0.723 0.897 0.032 0.022], ...
    'FontSize',8,'BackgroundColor',BG,'HorizontalAlignment','left');

uicontrol(fig,'Style','text','String','Y base:', ...
    'Units','normalized','Position',[0.760 0.897 0.042 0.022], ...
    'FontSize',8,'HorizontalAlignment','right','BackgroundColor',BG);
hs.ybase_edit = uicontrol(fig,'Style','edit','String','', ...
    'Units','normalized','Position',[0.804 0.899 0.052 0.022],'FontSize',8, ...
    'Callback',@cb_yrange,'TooltipString','Raise Y floor — hides baseline, zooms into peaks');

uicontrol(fig,'Style','pushbutton','String','Reset View', ...
    'Units','normalized','Position',[0.860 0.897 0.075 0.024],'FontSize',8, ...
    'FontWeight','bold','BackgroundColor',[0.75 0.20 0.20],'ForegroundColor','w', ...
    'Callback',@cb_reset_view,'TooltipString','Reset all view options to defaults');

% Axes — shrunk by 3% vertically to make room for Y controls row
hs.ax = axes('Parent',fig, ...
    'Units','normalized','Position',[0.375 0.075 0.610 0.808], ...
    'Box','on','Color',BG2,'FontSize',8, ...
    'XGrid','on','YGrid','on','GridAlpha',0.15);
xlabel(hs.ax,'Raman shift (cm^{-1})','FontSize',9);
ylabel(hs.ax,'Intensity (a.u.)','FontSize',9);
title(hs.ax,'No files loaded','FontSize',9,'FontWeight','normal');


% ══════════════════════════════════════════════════════════════════════
%  App state
% ══════════════════════════════════════════════════════════════════════
D.hs          = hs;
D.files       = {};
D.timestamps  = datetime.empty;
D.filenames   = {};
D.checked     = logical([]);
D.wn          = {};
D.raw         = {};
D.proc        = {};
D.meta        = {};
D.colors      = FILE_COLORS;
D.view_mode   = 'single';
D.data_mode   = 'raw';
D.wf_offset   = 200;
D.norm_mode   = 'none';
guidata(fig, D);
end

% ══════════════════════════════════════════════════════════════════════
%  FILE MANAGEMENT
% ══════════════════════════════════════════════════════════════════════
function cb_add(src, ~)
    fig = ancestor(src,'figure'); D = guidata(fig);
    [fn,fp] = uigetfile('*.wdf','Select WDF files','MultiSelect','on');
    if isequal(fn,0), return; end
    if ischar(fn), fn = {fn}; end

    set(D.hs.status,'String','Loading…'); drawnow;
    for k = 1:numel(fn)
        fullp = fullfile(fp,fn{k});
        fi    = dir(fullp);
        D.files{end+1}   = fullp;
        D.filenames{end+1} = fn{k};
        D.checked(end+1) = true;
        D.proc{end+1}    = [];
        try
            [w,y,m]      = read_wdf_full(fullp);
            D.wn{end+1}  = w;
            D.raw{end+1} = y;
            D.meta{end+1}= m;
            % Prefer WDF internal acquisition time (UTC->local, already
            % zone-stripped in read_wdf_full). Fall back to OS mtime only
            % when FILETIME was zero or missing.
            if isfield(m,'acquisition_time') && ~isnat(m.acquisition_time)
                ts = m.acquisition_time;   % already local, no timezone tag
            else
                ts = datetime(fi.datenum,'ConvertFrom','datenum');
            end
        catch me
            D.wn{end+1}  = [];
            D.raw{end+1} = [];
            D.meta{end+1}= struct('error',me.message);
            ts = datetime(fi.datenum,'ConvertFrom','datenum');
        end
        D.timestamps(end+1) = ts;
    end
    [D.timestamps,ix] = sort(D.timestamps);
    D = reorder_all(D,ix);
    refresh_list(D);
    guidata(fig,D);
    refresh_plot(fig);
    update_status(fig);
end

function cb_remove(src, ~)
    fig = ancestor(src,'figure'); D = guidata(fig);
    sel = get(D.hs.file_list,'Value');
    if isempty(sel)||isempty(D.files), return; end
    keep = setdiff(1:numel(D.files),sel);
    D    = keep_fields(D,keep);
    refresh_list(D);
    if isempty(D.files)
        set(D.hs.file_list,'Value',[]);
    else
        set(D.hs.file_list,'Value',min(sel(1),numel(D.files)));
    end
    guidata(fig,D);
    refresh_plot(fig);
    update_status(fig);
end

function cb_clear(src, ~)
    fig = ancestor(src,'figure'); D = guidata(fig);
    D = keep_fields(D,[]);
    set(D.hs.file_list,'String',{},'Value',[]);
    guidata(fig,D);
    cla(D.hs.ax);
    title(D.hs.ax,'No files loaded','FontSize',9,'FontWeight','normal');
    update_status(fig);
end

function cb_check_all(src, ~)
    fig = ancestor(src,'figure'); D = guidata(fig);
    D.checked(:) = true;
    refresh_list(D); guidata(fig,D);
    refresh_plot(fig); update_status(fig);
end

function cb_check_none(src, ~)
    fig = ancestor(src,'figure'); D = guidata(fig);
    D.checked(:) = false;
    refresh_list(D); guidata(fig,D);
    refresh_plot(fig); update_status(fig);
end

function cb_list_select(src, ~)
    fig = ancestor(src,'figure'); D = guidata(fig);
    sel = get(src,'Value');
    if isempty(sel)||isempty(D.files), return; end
    % Double-click toggles checkbox
    if strcmp(get(fig,'SelectionType'),'open')
        D.checked(sel) = ~D.checked(sel);
        refresh_list(D);
        guidata(fig,D);
        update_status(fig);
    end
    guidata(fig,D);
    refresh_plot(fig);
end

% ── Metadata pop-out ─────────────────────────────────────────────────
function cb_metadata(src, ~)
    fig = ancestor(src,'figure'); D = guidata(fig);
    sel = get(D.hs.file_list,'Value');
    if isempty(sel)||isempty(D.files)
        msgbox('No file selected.','Info'); return;
    end
    idx = sel(1);
    m   = D.meta{idx};
    fn  = D.filenames{idx};
    ts  = datestr(D.timestamps(idx),'yyyy-mm-dd HH:MM:SS');
    npt = numel(D.wn{idx});
    if npt>0
        wnr = sprintf('%.2f  to  %.2f  cm-1', min(D.wn{idx}), max(D.wn{idx}));
    else
        wnr = 'N/A';
    end

    rows = { ...
        'File',             fn; ...
        'Timestamp (OS)',   ts; ...
        'Full path',        D.files{idx}; ...
        'Points',           num2str(npt); ...
        'Wavenumber range', wnr; ...
    };
    fns = fieldnames(m);
    for f = 1:numel(fns)
        nm  = fns{f};
        val = m.(nm);
        if isa(val,'datetime')
            valstr = datestr(val,'yyyy-mm-dd HH:MM:SS');
        elseif isnumeric(val)
            valstr = num2str(val,'%.4g');
        elseif ischar(val)
            valstr = val;
        else
            valstr = class(val);
        end
        rows{end+1,1} = nm;       %#ok<AGROW>
        rows{end,  2} = valstr;
    end

    nr      = size(rows,1);
    row_h   = 22;
    col_w1  = 170;
    col_w2  = 320;
    win_h   = nr*row_h + 50;
    win_w   = col_w1 + col_w2 + 20;

    mfig = figure('Name',['Metadata — ' fn], ...
        'NumberTitle','off','MenuBar','none','ToolBar','none', ...
        'Units','pixels','Position',[250 150 win_w win_h], ...
        'Resize','on','Color',[0.97 0.97 0.97]);

    uicontrol(mfig,'Style','text', ...
        'String',['Metadata:  ' fn], ...
        'Units','pixels','Position',[8 win_h-32 win_w-16 24], ...
        'FontSize',10,'FontWeight','bold','HorizontalAlignment','left', ...
        'BackgroundColor',[0.97 0.97 0.97]);

    for r = 1:nr
        ypos = win_h - 50 - (r-1)*row_h;
        bg = [0.97 0.97 0.97];
        if mod(r,2)==0, bg = [0.92 0.94 0.97]; end
        uicontrol(mfig,'Style','text','String', rows{r,1}, ...
            'Units','pixels','Position',[5 ypos col_w1-4 row_h-1], ...
            'FontSize',8,'FontWeight','bold','HorizontalAlignment','left', ...
            'BackgroundColor',bg,'ForegroundColor',[0.20 0.20 0.50]);
        uicontrol(mfig,'Style','text','String', rows{r,2}, ...
            'Units','pixels','Position',[col_w1+2 ypos col_w2 row_h-1], ...
            'FontSize',8,'HorizontalAlignment','left', ...
            'BackgroundColor',bg,'ForegroundColor',[0.10 0.10 0.10], ...
            'FontName','Consolas');
    end
end

% ── Help > About ─────────────────────────────────────────────────────
function cb_about(src, ~)
    fig = ancestor(src,'figure'); %#ok<NASGU>

    win_w = 380; win_h = 210;
    afig = figure('Name','About TimedRaman', ...
        'NumberTitle','off','MenuBar','none','ToolBar','none', ...
        'Units','pixels','Position',[300 250 win_w win_h], ...
        'Resize','off','Color',[0.97 0.97 0.97]);

    uicontrol(afig,'Style','text','String','TimedRaman', ...
        'Units','pixels','Position',[10 win_h-40 win_w-20 28], ...
        'FontSize',14,'FontWeight','bold','HorizontalAlignment','left', ...
        'BackgroundColor',[0.97 0.97 0.97]);

    uicontrol(afig,'Style','text','String','Version 1.0', ...
        'Units','pixels','Position',[10 win_h-64 win_w-20 20], ...
        'FontSize',9,'HorizontalAlignment','left', ...
        'ForegroundColor',[0.35 0.35 0.35],'BackgroundColor',[0.97 0.97 0.97]);

    lines = { ...
        'Software developed by Nurul Azam'; ...
        'Email:  nurul_azam@outlook.com'; ...
        'LinkedIn:  https://www.linkedin.com/in/nurulazam/' ...
    };
    for r = 1:numel(lines)
        ypos = win_h - 96 - (r-1)*22;
        uicontrol(afig,'Style','text','String', lines{r}, ...
            'Units','pixels','Position',[10 ypos win_w-20 20], ...
            'FontSize',9,'HorizontalAlignment','left', ...
            'BackgroundColor',[0.97 0.97 0.97]);
    end

    uicontrol(afig,'Style','pushbutton','String','Close', ...
        'Units','pixels','Position',[win_w-90 12 78 26], ...
        'FontSize',9,'Callback',@(~,~)close(afig));
end

% ══════════════════════════════════════════════════════════════════════
%  REORDER
% ══════════════════════════════════════════════════════════════════════
function cb_move_up(src, ~)
    fig = ancestor(src,'figure'); D = guidata(fig);
    sel = get(D.hs.file_list,'Value');
    if numel(sel)~=1||sel==1||isempty(D.files), return; end
    idx = [1:sel-2, sel, sel-1, sel+1:numel(D.files)];
    D   = reorder_all(D,idx);
    set(D.hs.file_list,'Value',sel-1);
    refresh_list(D); guidata(fig,D); refresh_plot(fig);
end

function cb_move_down(src, ~)
    fig = ancestor(src,'figure'); D = guidata(fig);
    sel = get(D.hs.file_list,'Value');
    if numel(sel)~=1||sel==numel(D.files)||isempty(D.files), return; end
    idx = [1:sel-1, sel+1, sel, sel+2:numel(D.files)];
    D   = reorder_all(D,idx);
    set(D.hs.file_list,'Value',sel+1);
    refresh_list(D); guidata(fig,D); refresh_plot(fig);
end

% ══════════════════════════════════════════════════════════════════════
%  VIEW / DATA MODE
% ══════════════════════════════════════════════════════════════════════
function cb_viewmode(btn, mode)
    fig = ancestor(btn,'figure'); D = guidata(fig);
    D.view_mode = mode;
    set(D.hs.btn_single,   'Value', strcmp(mode,'single'));
    set(D.hs.btn_overlay,  'Value', strcmp(mode,'overlay'));
    set(D.hs.btn_waterfall,'Value', strcmp(mode,'waterfall'));
    guidata(fig,D); refresh_plot(fig);
end

function cb_datamode(btn, mode)
    fig = ancestor(btn,'figure'); D = guidata(fig);
    D.data_mode = mode;
    set(D.hs.btn_raw, 'Value', strcmp(mode,'raw'));
    set(D.hs.btn_proc,'Value', strcmp(mode,'proc'));
    set(D.hs.btn_both,'Value', strcmp(mode,'both'));
    guidata(fig,D); refresh_plot(fig);
end


function cb_yrange(src, ~)
    fig = ancestor(src,'figure');
    refresh_plot(fig);
end

function cb_yclip(src, ~)
% Clip-top slider — update label then refresh.
    fig = ancestor(src,'figure'); D = guidata(fig);
    v = round(get(src,'Value'));
    set(src,'Value',v);
    set(D.hs.yclip_lbl,'String',sprintf('%d%%',v));
    refresh_plot(fig);
end

function cb_reset_view(src, ~)
% Reset ALL view controls back to defaults in one click.
    fig = ancestor(src,'figure'); D = guidata(fig);
    % Y controls
    set(D.hs.ymin_edit,    'String','');
    set(D.hs.ymax_edit,    'String','');
    set(D.hs.ybase_edit,   'String','');
    set(D.hs.yclip_slider, 'Value', 0);
    set(D.hs.yclip_lbl,    'String','0%');
    % X controls
    set(D.hs.xmin_edit,    'String','');
    set(D.hs.xmax_edit,    'String','');
    % View mode → Single, Data mode → Raw
    D.view_mode = 'single';
    set(D.hs.btn_single,   'Value',1);
    set(D.hs.btn_overlay,  'Value',0);
    set(D.hs.btn_waterfall,'Value',0);
    D.data_mode = 'raw';
    set(D.hs.btn_raw, 'Value',1);
    set(D.hs.btn_proc,'Value',0);
    set(D.hs.btn_both,'Value',0);
    % Waterfall offset
    D.wf_offset = 200;
    set(D.hs.wf_slider,'Value',200);
    set(D.hs.wf_lbl,   'String','200 a.u.');
    % Normalization → None
    D.norm_mode = 'none';
    set(D.hs.norm_popup,'Value',1);
    set(D.hs.norm_wn,   'Enable','off');
    guidata(fig,D);
    refresh_plot(fig);
end

function cb_xrange(src, ~)
    fig = ancestor(src,'figure');
    refresh_plot(fig);
end

function cb_wf_offset(src, ~)
    fig = ancestor(src,'figure'); D = guidata(fig);
    D.wf_offset = round(get(src,'Value'));
    set(D.hs.wf_lbl,'String',sprintf('%d a.u.',D.wf_offset));
    guidata(fig,D); refresh_plot(fig);
end

function cb_norm(src, ~)
    fig = ancestor(src,'figure'); D = guidata(fig);
    modes = {'none','max','gaas','custom'};
    D.norm_mode = modes{get(src,'Value')};
    set(D.hs.norm_wn,'Enable', strcmp(D.norm_mode,'custom')*1);
    guidata(fig,D); refresh_plot(fig);
end

% ══════════════════════════════════════════════════════════════════════
%  PROCESSING SLIDERS
% ══════════════════════════════════════════════════════════════════════
function cb_sg_win(src, ~)
    fig = ancestor(src,'figure'); D = guidata(fig);
    w = round(get(src,'Value'));
    if mod(w,2)==0, w = min(w+1,101); end
    set(src,'Value',w);
    set(D.hs.sg_win_lbl,'String',sprintf('%d pts',w));
    if get(D.hs.live_preview,'Value'), refresh_plot(fig); end
end
function cb_sg_ord(src, ~)
    fig = ancestor(src,'figure'); D = guidata(fig);
    set(D.hs.sg_ord_lbl,'String',num2str(round(get(src,'Value'))));
    if get(D.hs.live_preview,'Value'), refresh_plot(fig); end
end
function cb_ma_win(src, ~)
    fig = ancestor(src,'figure'); D = guidata(fig);
    w = round(get(src,'Value'));
    if mod(w,2)==0, w = min(w+1,101); end
    set(src,'Value',w);
    set(D.hs.ma_win_lbl,'String',sprintf('%d pts',w));
    if get(D.hs.live_preview,'Value'), refresh_plot(fig); end
end
function cb_smooth_method_change(src, ~)
% Toggle visibility of SG vs MA specific controls.
    fig = ancestor(src,'figure'); D = guidata(fig);
    v = get(src,'Value');   % 1=SG, 2=MA
    sg_vis = {'on','off'}; sg_vis = sg_vis{v};
    ma_vis = {'off','on'}; ma_vis = ma_vis{v};
    set(D.hs.sg_win,    'Visible', sg_vis);
    set(D.hs.sg_win_lbl,'Visible', sg_vis);
    set(D.hs.sg_ord,    'Visible', sg_vis);
    set(D.hs.sg_ord_lbl,'Visible', sg_vis);
    set(D.hs.ma_win,    'Visible', ma_vis);
    set(D.hs.ma_win_lbl,'Visible', ma_vis);
    set(D.hs.ma_label,  'Visible', ma_vis);
    if get(D.hs.live_preview,'Value'), refresh_plot(fig); end
end
function cb_als_lam(src, ~)
    fig = ancestor(src,'figure'); D = guidata(fig);
    e = round(get(src,'Value'));
    set(D.hs.als_lam_lbl,'String',sprintf('10^%d',e));
    if get(D.hs.live_preview,'Value') && get(D.hs.als_on,'Value')
        refresh_plot(fig);
    end
end
function cb_als_p(src, ~)
    fig = ancestor(src,'figure'); D = guidata(fig);
    pv = [0.001 0.002 0.005 0.01 0.02 0.05 0.10 0.20 0.50];
    set(D.hs.als_p_lbl,'String',num2str(pv(round(get(src,'Value')))));
    if get(D.hs.live_preview,'Value') && get(D.hs.als_on,'Value')
        refresh_plot(fig);
    end
end
function cb_als_iter(src, ~)
    fig = ancestor(src,'figure'); D = guidata(fig);
    set(D.hs.als_iter_lbl,'String',num2str(round(get(src,'Value'))));
end

% ══════════════════════════════════════════════════════════════════════
%  APPLY PROCESSING
% ══════════════════════════════════════════════════════════════════════
function cb_apply_processing(src, ~)
    fig = ancestor(src,'figure'); D = guidata(fig);
    if isempty(D.files), return; end

    smooth_on = get(D.hs.sg_on,'Value');
    als_on    = get(D.hs.als_on,'Value');
    method    = get(D.hs.smooth_method,'Value');  % 1=SG 2=MA
    sg_w      = round(get(D.hs.sg_win,'Value'));
    if mod(sg_w,2)==0, sg_w = sg_w+1; end
    sg_o      = round(get(D.hs.sg_ord,'Value'));
    ma_w      = round(get(D.hs.ma_win,'Value'));
    if mod(ma_w,2)==0, ma_w = ma_w+1; end
    als_e     = round(get(D.hs.als_lam,'Value'));
    pv        = [0.001 0.002 0.005 0.01 0.02 0.05 0.10 0.20 0.50];
    als_p     = pv(round(get(D.hs.als_p,'Value')));
    als_it    = round(get(D.hs.als_iter,'Value'));

    scope = get(D.hs.scope_popup,'Value');
    if scope==2
        sel = get(D.hs.file_list,'Value');
        if isempty(sel), return; end
        targets = sel;
    else
        targets = find(D.checked);
    end

    set(D.hs.status,'String','Processing…'); drawnow;
    for k = targets
        y = D.raw{k};
        if isempty(y), continue; end
        if smooth_on
            if method==1
                if sg_o < sg_w, y = sg_smooth(y, sg_w, sg_o);
                else, y = sg_smooth(y, sg_w, sg_w-1); end
            else
                y = ma_smooth(y, ma_w);
            end
        end
        if als_on, bl = als_baseline(y, 10^als_e, als_p, als_it); y = y - bl; end
        D.proc{k} = y;
    end
    guidata(fig,D);

    % Auto-switch to Both
    D.data_mode = 'both';
    set(D.hs.btn_raw, 'Value',0);
    set(D.hs.btn_proc,'Value',0);
    set(D.hs.btn_both,'Value',1);
    guidata(fig,D);
    refresh_plot(fig);
    update_status(fig);
end

% ══════════════════════════════════════════════════════════════════════
%  PLOT
% ══════════════════════════════════════════════════════════════════════
function refresh_plot(fig)
    D  = guidata(fig);
    ax = D.hs.ax;
    cla(ax); hold(ax,'on');

    if isempty(D.files)
        title(ax,'No files loaded','FontSize',9,'FontWeight','normal');
        hold(ax,'off'); return;
    end

    xmn_s = strtrim(get(D.hs.xmin_edit,'String'));
    xmx_s = strtrim(get(D.hs.xmax_edit,'String'));
    use_xl = ~isempty(xmn_s) && ~isempty(xmx_s);

    checked_idx = find(D.checked);
    if isempty(checked_idx)
        title(ax,'No files checked','FontSize',9,'FontWeight','normal');
        hold(ax,'off'); return;
    end

    sel = get(D.hs.file_list,'Value');
    if isempty(sel)||sel>numel(D.files), sel = checked_idx(1); end

    switch D.view_mode
        case 'single'
            plot_one(ax, D, sel, 0, true);
            title(ax, D.filenames{sel}, ...
                'FontSize',9,'FontWeight','normal','Interpreter','none');
        case 'overlay'
            for k = checked_idx
                plot_one(ax, D, k, 0, k==sel);
            end
            title(ax, sprintf('Overlay — %d spectra', numel(checked_idx)), ...
                'FontSize',9,'FontWeight','normal');
        case 'waterfall'
            for ki = 1:numel(checked_idx)
                k = checked_idx(ki);
                plot_one(ax, D, k, (ki-1)*D.wf_offset, k==sel);
            end
            title(ax, sprintf('Waterfall — %d spectra (offset %d a.u.)', ...
                numel(checked_idx), D.wf_offset), ...
                'FontSize',9,'FontWeight','normal');
    end

    if use_xl
        xlo = str2double(xmn_s); xhi = str2double(xmx_s);
        if ~isnan(xlo)&&~isnan(xhi)&&xhi>xlo, xlim(ax,[xlo xhi]); end
    end

    % ── Y-axis limits — computed from data, not from axes state ──────────
    % Collect all plotted Y values to get true data range
    lines_h = get(ax,'Children');
    all_y   = [];
    for li = 1:numel(lines_h)
        if isprop(lines_h(li),'YData')
            yd = get(lines_h(li),'YData');
            all_y = [all_y, yd(:)']; %#ok<AGROW>
        end
    end

    if ~isempty(all_y)
        data_min = min(all_y);
        data_max = max(all_y);
        data_rng = data_max - data_min;
        if data_rng < eps, data_rng = 1; end
    else
        data_min = 0; data_max = 1; data_rng = 1;
    end

    % Read controls
    ymn_s  = strtrim(get(D.hs.ymin_edit,'String'));
    ymx_s  = strtrim(get(D.hs.ymax_edit,'String'));
    ybs_s  = strtrim(get(D.hs.ybase_edit,'String'));
    clip   = get(D.hs.yclip_slider,'Value');   % 0–99 %

    % Y base (floor raise): if set, override data_min
    if ~isempty(ybs_s)
        yb = str2double(ybs_s);
        if ~isnan(yb), data_min = yb; end
    end

    % Clip top %: shorten visible range from the top
    ylo = data_min;
    yhi = data_max - clip/100 * data_rng;
    if yhi <= ylo, yhi = data_max; end   % safety: never invert

    % Manual overrides win over everything
    if ~isempty(ymn_s)
        v = str2double(ymn_s); if ~isnan(v), ylo = v; end
    end
    if ~isempty(ymx_s)
        v = str2double(ymx_s); if ~isnan(v), yhi = v; end
    end

    if yhi > ylo
        margin = (yhi-ylo)*0.03;
        ylim(ax, [ylo - margin, yhi + margin]);
    end

    xlabel(ax,'Raman shift (cm^{-1})','FontSize',9);
    ylabel(ax,'Intensity (a.u.)','FontSize',9);
    legend(ax,'show','Location','best','FontSize',7,'Interpreter','none');
    hold(ax,'off');
end

function plot_one(ax, D, k, offset, is_sel)
    wn = D.wn{k};
    if isempty(wn), return; end
    nc  = size(D.colors,1);
    col = D.colors(mod(k-1,nc)+1,:);
    lw  = 0.9 + 0.8*is_sel;
    name = D.filenames{k};

    yr = apply_norm(D, D.raw{k}, wn);
    yp = [];
    if ~isempty(D.proc{k})
        yp = apply_norm(D, D.proc{k}, wn);
    end

    % Live preview: compute on-the-fly from current slider settings.
    % Only shown for the selected file (is_sel=true) so it stays fast.
    y_live = [];
    if is_sel && get(D.hs.live_preview,'Value') && get(D.hs.sg_on,'Value')
        y_live = compute_live_smooth(D, D.raw{k});
        if get(D.hs.als_on,'Value') && ~isempty(y_live)
            pv     = [0.001 0.002 0.005 0.01 0.02 0.05 0.10 0.20 0.50];
            als_lam= 10^round(get(D.hs.als_lam,'Value'));
            als_p  = pv(round(get(D.hs.als_p,'Value')));
            als_it = round(get(D.hs.als_iter,'Value'));
            bl     = als_baseline(y_live, als_lam, als_p, als_it);
            y_live = y_live - bl;
        end
        y_live = apply_norm(D, y_live, wn);
    elseif is_sel && get(D.hs.live_preview,'Value') && get(D.hs.als_on,'Value')
        % ALS only, no smoothing
        pv     = [0.001 0.002 0.005 0.01 0.02 0.05 0.10 0.20 0.50];
        als_lam= 10^round(get(D.hs.als_lam,'Value'));
        als_p  = pv(round(get(D.hs.als_p,'Value')));
        als_it = round(get(D.hs.als_iter,'Value'));
        bl     = als_baseline(D.raw{k}, als_lam, als_p, als_it);
        y_live = apply_norm(D, D.raw{k} - bl, wn);
    end

    switch D.data_mode
        case 'raw'
            plot(ax, wn, yr+offset, '-', ...
                'Color',col,'LineWidth',lw,'DisplayName',name);
            if ~isempty(y_live)
                plot(ax, wn, y_live+offset, '-', ...
                    'Color',col,'LineWidth',lw+0.8, ...
                    'DisplayName',[name ' preview']);
            end
        case 'proc'
            if ~isempty(yp)
                plot(ax, wn, yp+offset, '-', ...
                    'Color',col,'LineWidth',lw+0.5, ...
                    'DisplayName',[name ' (proc)']);
            else
                if ~isempty(y_live)
                    plot(ax, wn, y_live+offset, '-', ...
                        'Color',col,'LineWidth',lw+0.8, ...
                        'DisplayName',[name ' preview']);
                else
                    plot(ax, wn, yr+offset, '--', ...
                        'Color',col,'LineWidth',lw, ...
                        'DisplayName',[name ' (raw/no proc)']);
                end
            end
        case 'both'
            col_r = col*0.4 + 0.6;
            plot(ax, wn, yr+offset, '--', ...
                'Color',col_r,'LineWidth',max(lw-0.3,0.5), ...
                'DisplayName',[name ' raw']);
            if ~isempty(yp)
                plot(ax, wn, yp+offset, '-', ...
                    'Color',col,'LineWidth',lw+0.5, ...
                    'DisplayName',[name ' proc']);
            end
            if ~isempty(y_live)
                % Preview shown as thick line when in Both mode
                plot(ax, wn, y_live+offset, '-', ...
                    'Color',min(col*1.2,1),'LineWidth',lw+1.0, ...
                    'DisplayName',[name ' preview']);
            end
    end
end

function y = compute_live_smooth(D, y_raw)
% Apply current smoothing slider settings to y_raw without touching D.proc.
    method = get(D.hs.smooth_method,'Value');  % 1=SG, 2=MA
    if method == 1
        sg_w = round(get(D.hs.sg_win,'Value'));
        if mod(sg_w,2)==0, sg_w = sg_w+1; end
        sg_o = round(get(D.hs.sg_ord,'Value'));
        if sg_o >= sg_w, sg_o = sg_w-1; end
        try
            y = sg_smooth(y_raw, sg_w, sg_o);
        catch
            y = y_raw;
        end
    else
        ma_w = round(get(D.hs.ma_win,'Value'));
        if mod(ma_w,2)==0, ma_w = ma_w+1; end
        y = ma_smooth(y_raw, ma_w);
    end
end

function y = apply_norm(D, y, wn)
% Normalise y vector.  For peak-based modes, use a local median over
% ±5 points around the target wavenumber — this makes normalisation
% robust against cosmic ray spikes hitting the reference point.
    if isempty(y), return; end
    switch D.norm_mode
        case 'max'
            % Use 95th percentile instead of max — immune to single spikes
            pk = prctile(y, 95);
            if pk > 0, y = y / pk; end
        case 'gaas'
            y = norm_to_peak(y, wn, 269);
        case 'custom'
            ref = str2double(get(D.hs.norm_wn,'String'));
            if ~isnan(ref), y = norm_to_peak(y, wn, ref); end
    end
end

function y = norm_to_peak(y, wn, twn)
% Normalise to a local peak value — median over ±5 pts for spike robustness.
    [~,ci] = min(abs(wn - twn));
    half   = 5;
    i1     = max(1, ci-half);
    i2     = min(numel(y), ci+half);
    r      = median(abs(y(i1:i2)));   % robust against single-point spikes
    if r > 0, y = y / r; end
end

% ══════════════════════════════════════════════════════════════════════
%  EXPORT
% ══════════════════════════════════════════════════════════════════════
function cb_export(src, ~)
    fig = ancestor(src,'figure'); D = guidata(fig);
    cidx = find(D.checked);
    if isempty(cidx)
        set(D.hs.status,'String','Nothing checked to export.'); return;
    end

    rd = strtrim(get(D.hs.date_edit,'String'));
    rt = strtrim(get(D.hs.time_edit,'String'));
    av = get(D.hs.ampm_popup,'Value'); ap={'AM','PM'};
    try
        t0 = datetime(sprintf('%s %s %s',rd,rt,ap{av}), ...
                      'InputFormat','yyyy-MM-dd hh:mm a');
    catch
        set(D.hs.status,'String','ERROR: invalid date/time.'); return;
    end

    outdir = strtrim(get(D.hs.outdir,'String'));
    base   = strtrim(get(D.hs.basename,'String'));
    nf     = numel(cidx);
    wn_all = cell(nf,1); raw_all = cell(nf,1);
    pro_all= cell(nf,1); names   = cell(nf,1);
    npts   = zeros(nf,1); elapsed = zeros(nf,1);

    for ki = 1:nf
        k           = cidx(ki);
        wn_all{ki}  = D.wn{k}(:);
        raw_all{ki} = D.raw{k}(:);
        pro_all{ki} = D.raw{k}(:);
        if ~isempty(D.proc{k}), pro_all{ki} = D.proc{k}(:); end
        [~,names{ki}] = fileparts(D.filenames{k});
        npts(ki)      = numel(D.wn{k});
        elapsed(ki)   = minutes(D.timestamps(k) - t0);
    end
    maxpts = max(npts);

    for pass = 1:2
        tag     = {'raw','proc'}; tag = tag{pass};
        int_all = raw_all; if pass==2, int_all = pro_all; end
        for ext = {'.csv','.dat'}
            sep = ','; if strcmp(ext{1},'.dat'), sep = sprintf('\t'); end
            fpath = fullfile(outdir,[base '_' tag '_timeseries' ext{1}]);
            fid   = fopen(fpath,'w');
            if fid==-1
                set(D.hs.status,'String',['Cannot write: ' fpath]); return;
            end
            write_timeseries(fid,sep,names,elapsed,wn_all,int_all,npts,maxpts);
            fclose(fid);
        end
        set(D.hs.status,'String',sprintf('Wrote %s files…',tag)); drawnow;
    end

    if all(npts==npts(1))
        msg = sprintf('Done! %d spectra x %d pts. Raw+Proc .csv/.dat exported.',nf,npts(1));
    else
        msg = sprintf('Done! %d spectra (%d-%d pts). Raw+Proc exported.',nf,min(npts),max(npts));
    end
    set(D.hs.status,'String',msg);
end

function write_timeseries(fid,sep,names,elapsed,wn_all,int_all,npts,maxpts)
    nf = numel(names);
    for k=1:nf
        if k>1, fprintf(fid,'%s',sep); end
        fprintf(fid,'Raman Shift%s%s',sep,names{k});
    end
    fprintf(fid,'\n');
    for k=1:nf
        if k>1, fprintf(fid,'%s',sep); end
        fprintf(fid,'cm-1%sa.u.',sep);
    end
    fprintf(fid,'\n');
    for k=1:nf
        if k>1, fprintf(fid,'%s',sep); end
        fprintf(fid,'%s%.1f min',sep,elapsed(k));
    end
    fprintf(fid,'\n');
    for i=1:maxpts
        for k=1:nf
            if k>1, fprintf(fid,'%s',sep); end
            if i<=npts(k)
                fprintf(fid,'%.6f%s%.6f',wn_all{k}(i),sep,int_all{k}(i));
            else
                fprintf(fid,'%s',sep);
            end
        end
        fprintf(fid,'\n');
    end
end

function cb_browse(src, ~)
    fig = ancestor(src,'figure'); D = guidata(fig);
    d = uigetdir(get(D.hs.outdir,'String'));
    if d~=0, set(D.hs.outdir,'String',d); end
end

% ══════════════════════════════════════════════════════════════════════
%  PROCESSING ALGORITHMS
% ══════════════════════════════════════════════════════════════════════
function ys = sg_smooth(y, win, order)
% Savitzky-Golay smoothing — no toolbox required.
% Derives coefficients from least-squares polynomial fit over sliding window.
    y    = y(:);  n = numel(y);
    half = (win-1)/2;
    m    = (-half:half)';
    A    = zeros(win,order+1);
    for p = 0:order, A(:,p+1) = m.^p; end
    C    = (A'*A) \ A';  % (order+1) x win
    c    = C(1,:)';      % smoothing coefficients

    ys = zeros(n,1);
    for i = 1:n
        i1  = max(1,i-half);  i2 = min(n,i+half);
        seg = y(i1:i2);
        c1  = half+1-(i-i1); c2 = c1+numel(seg)-1;
        cs  = c(c1:c2);
        ys(i) = (cs'*seg) / sum(cs);
    end
end

function ys = ma_smooth(y, win)
% Moving average smoothing — simple convolution, very fast.
% win must be odd; edges are handled by padding with edge values.
    y    = y(:);  n = numel(y);
    half = (win-1)/2;
    ypad = [y(1)*ones(half,1); y; y(end)*ones(half,1)];
    kern = ones(win,1)/win;
    ys   = conv(ypad, kern, 'valid');
    ys   = ys(1:n);   % conv('valid') may give n+1 pts for even — clamp
end

function bl = als_baseline(y, lam, p, niter)
% Asymmetric Least Squares (Eilers & Boelens 2005).
    y  = y(:);  n = numel(y);
    D2 = diff(speye(n),2);
    H  = lam*(D2'*D2);
    w  = ones(n,1);
    bl = zeros(n,1);
    for i = 1:niter    %#ok<FXUP>
        W  = spdiags(w,0,n,n);
        bl = (W+H) \ (w.*y);
        w  = p*(y>bl) + (1-p)*(y<=bl);
    end
end

% ══════════════════════════════════════════════════════════════════════
%  WDF READER
% ══════════════════════════════════════════════════════════════════════
function [wavenumber, intensity, meta] = read_wdf_full(filepath)
% Read wavenumber, first-spectrum intensity, and instrument metadata.
% WDF1 header offsets verified by direct binary inspection:
%   60-63 : npoints  (uint32)
%   64-67 : nspectra (uint32)
%   88-91 : laser wavenumber (float32)
%  116-119: WiRE version (2x uint16)
%  136-143: creation time (Windows FILETIME, uint64)
%  208-239: operator name (32-byte null-padded string)

    fid = fopen(filepath,'r','l');
    if fid==-1, error('Cannot open: %s',filepath); end
    raw = fread(fid,Inf,'*uint8')';
    fclose(fid);

    if numel(raw)<68 || ~isequal(raw(1:4),uint8('WDF1'))
        error('Not a WDF file: %s',filepath);
    end

    npts  = double(typecast(raw(61:64),'uint32'));
    nspec = double(typecast(raw(65:68),'uint32'));
    if npts==0, error('npoints=0 in WDF1 header: %s',filepath); end

    meta.npoints  = npts;
    meta.nspectra = nspec;

    if numel(raw)>=92
        lw = double(typecast(raw(89:92),'single'));
        if lw>0 && lw<5000, meta.laser_wavenumber_cm1 = lw; end
    end
    if numel(raw)>=120
        meta.wire_version = sprintf('%d.%d', ...
            typecast(raw(117:118),'uint16'), typecast(raw(119:120),'uint16'));
    end
    if numel(raw)>=144
        lo = double(typecast(raw(137:140),'uint32'));
        hi = double(typecast(raw(141:144),'uint32'));
        ft = hi*2^32 + lo;
        if ft > 0
            % Windows FILETIME: 100-ns ticks since 1601-01-01 00:00:00 UTC.
            % CORRECT conversion — construct datetime directly with explicit
            % UTC timezone, then convert to machine local time.
            % Using datenum as an intermediate is WRONG because datenum has
            % no timezone concept; tagging it 'UTC' afterwards is meaningless.
            secs_since_1601 = double(ft) / 1e7;
            dt_utc = datetime(1601, 1, 1, 0, 0, secs_since_1601, 'TimeZone', 'UTC');
            dt_local = datetime(dt_utc, 'TimeZone', 'local');
            dt_local.TimeZone = '';          % strip zone for arithmetic
            meta.acquisition_time = dt_local;
        end
    end
    if numel(raw)>=240
        op = char(raw(209:240));
        nul = find(op==0,1,'first');
        if ~isempty(nul) && nul>1, meta.operator = op(1:nul-1); end
    end

    % Walk block chain
    wdf1_size = double(typecast(raw(9:16),'uint64'));
    pos = wdf1_size+1;
    data_pos=0; xlst_pos=0; orgn_pos=0;

    while pos+15<=numel(raw)
        sig      = char(raw(pos:pos+3));
        blk_size = double(typecast(raw(pos+8:pos+15),'uint64'));
        if blk_size<16, break; end
        switch sig
            case 'DATA', data_pos=pos;
            case 'XLST', xlst_pos=pos;
            case 'ORGN', orgn_pos=pos;
        end
        if data_pos>0&&xlst_pos>0&&orgn_pos>0, break; end
        pos = pos+blk_size;
    end

    % ORGN block — stage XYZ, laser power
    if orgn_pos>0
        orgn_end = orgn_pos + double(typecast(raw(orgn_pos+8:orgn_pos+15),'uint64'));
        op = orgn_pos+16;
        while op+15<=min(orgn_end,numel(raw))
            otype = double(typecast(raw(op:op+3),'uint32'));
            oval  = double(typecast(raw(op+8:op+15),'double'));
            switch otype
                case 1, meta.stage_x_um = oval;
                case 2, meta.stage_y_um = oval;
                case 3, meta.stage_z_um = oval;
                case 22,meta.laser_power_pct = oval;
            end
            op = op+16;
        end
    end

    % DATA block
    if data_pos==0, error('DATA block not found: %s',filepath); end
    data_blk_size = double(typecast(raw(data_pos+8:data_pos+15),'uint64'));
    ps  = data_pos+16;
    pb  = data_blk_size-16;
    mxf = floor(pb/4);
    fw  = min(nspec*npts,mxf);
    pe  = ps+fw*4-1;
    if pe>numel(raw), error('DATA block past EOF: %s',filepath); end
    ir        = typecast(raw(ps:pe),'single');
    intensity = double(ir(1:min(npts,numel(ir))));

    % XLST block
    if xlst_pos==0
        wavenumber=(1:npts)'; return;
    end
    xlst_blk_size = double(typecast(raw(xlst_pos+8:xlst_pos+15),'uint64'));
    if (xlst_blk_size-16)>=(8+npts*4)
        ws = xlst_pos+24;
    else
        ws = xlst_pos+16;
    end
    we = ws+npts*4-1;
    if we>numel(raw), error('XLST past EOF: %s',filepath); end
    wavenumber = double(typecast(raw(ws:we),'single'));

    meta.wavenumber_min = min(wavenumber);
    meta.wavenumber_max = max(wavenumber);
end

% ══════════════════════════════════════════════════════════════════════
%  SHARED HELPERS
% ══════════════════════════════════════════════════════════════════════
function refresh_list(D)
    n = numel(D.filenames);
    if n==0, set(D.hs.file_list,'String',{}); return; end
    rd = strtrim(get(D.hs.date_edit,'String'));
    rt = strtrim(get(D.hs.time_edit,'String'));
    av = get(D.hs.ampm_popup,'Value'); ap={'AM','PM'};
    try
        t0 = datetime(sprintf('%s %s %s',rd,rt,ap{av}), ...
                      'InputFormat','yyyy-MM-dd hh:mm a');
        el = minutes(D.timestamps-t0); has_t0=true;
    catch
        has_t0=false;
    end
    strs = cell(n,1);
    for k=1:n
        cb = '[ ] '; if D.checked(k), cb='[x] '; end
        proc_tag = ''; if ~isempty(D.proc{k}), proc_tag=' *'; end
        if has_t0
            strs{k}=sprintf('%s%s  (%+.1f min)%s',cb,D.filenames{k},el(k),proc_tag);
        else
            strs{k}=sprintf('%s%s%s',cb,D.filenames{k},proc_tag);
        end
    end
    set(D.hs.file_list,'String',strs);
end

function D = keep_fields(D, idx)
    if isempty(idx)
        D.files={}; D.timestamps=datetime.empty; D.filenames={};
        D.checked=logical([]); D.wn={}; D.raw={}; D.proc={}; D.meta={};
    else
        D.files=D.files(idx); D.timestamps=D.timestamps(idx);
        D.filenames=D.filenames(idx); D.checked=D.checked(idx);
        D.wn=D.wn(idx); D.raw=D.raw(idx);
        D.proc=D.proc(idx); D.meta=D.meta(idx);
    end
end

function D = reorder_all(D, idx)
    D.files=D.files(idx); D.timestamps=D.timestamps(idx);
    D.filenames=D.filenames(idx); D.checked=D.checked(idx);
    D.wn=D.wn(idx); D.raw=D.raw(idx);
    D.proc=D.proc(idx); D.meta=D.meta(idx);
end

function update_status(fig)
    D = guidata(fig);
    nc = sum(D.checked);
    nt = numel(D.files);
    np = sum(~cellfun(@isempty,D.proc));
    w  = round(get(D.hs.sg_win,'Value'));
    o  = round(get(D.hs.sg_ord,'Value'));
    e  = round(get(D.hs.als_lam,'Value'));
    set(D.hs.status,'String', ...
        sprintf('%d/%d checked  |  SG w=%d p=%d  |  ALS lam=10^%d  |  proc:%d', ...
                nc,nt,w,o,e,np));
end
