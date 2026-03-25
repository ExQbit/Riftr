// ============================================
// DESIGN SYSTEM - Einheitliche Styles für alle Komponenten
// ============================================

// --- Card Image Styles ---
export const CARD_IMAGE = 'w-full h-full object-cover';
export const CARD_CONTAINER = 'relative overflow-hidden rounded-xl';
export const CARD_ASPECT_PORTRAIT = 'aspect-[2/3]';
export const CARD_ASPECT_LANDSCAPE = 'aspect-[3/2]';

// --- Filter Pill Styles ---
const PILL_BASE = 'px-5 py-2.5 rounded-full text-sm font-bold whitespace-nowrap flex-shrink-0 transition-all';
const PILL_ACTIVE = 'bg-amber-600 text-white';
const PILL_INACTIVE = 'bg-slate-900 text-slate-400 border border-slate-800';
export const PILL_CONTAINER = 'flex gap-2 overflow-x-auto pb-2';

// --- Search Bar ---
export const SEARCH_WRAPPER = 'relative';
export const SEARCH_ICON = 'absolute left-4 top-3.5 text-slate-500';
export const SEARCH_INPUT = 'w-full bg-slate-900 border border-slate-800 rounded-xl py-3 pl-12 pr-4 text-sm focus:ring-2 ring-amber-500/40 outline-none';

// --- Modal Styles ---
export const MODAL_OVERLAY = 'fixed inset-0 bg-black/80 z-50 flex items-center justify-center p-4';
export const MODAL_CONTAINER = 'bg-slate-900 rounded-3xl w-full h-full max-h-[95vh] flex flex-col';
export const MODAL_HEADER = 'flex items-center justify-between p-4 border-b border-slate-800';
export const MODAL_TITLE = 'text-xl font-black text-white';

// --- Section Styles ---
export const SECTION_BG = 'bg-slate-900/30 p-2 rounded-3xl';
export const SECTION_TITLE = 'text-sm font-black text-slate-400 mb-2 px-1';

// --- Badge Styles ---
export const BADGE_COUNT = 'absolute bottom-1 left-1 bg-amber-600 text-white font-black text-[10px] rounded-md px-1.5 py-0.5 flex items-center justify-center';

// --- Spacing ---
export const PAGE_PADDING = 'max-w-full mx-auto px-2 py-4';

// --- Helper: Pill className basierend auf active state ---
export const pillClass = (isActive) =>
  `${PILL_BASE} ${isActive ? PILL_ACTIVE : PILL_INACTIVE}`;
