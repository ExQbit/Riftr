import React from 'react';
import { Upload, Edit, Copy, Trash2, Download, FileUp, Gamepad2 } from 'lucide-react';

export default function DeckMenu({
  deck,
  isValid,
  onPublish,
  onEdit,
  onDuplicate,
  onDelete,
  onExport,
  onExportTts,
  onImport,
  onClose,
}) {
  return (
    <div className="absolute right-0 top-10 bg-slate-800 border border-slate-700 rounded-lg shadow-2xl overflow-hidden z-50 min-w-[160px]">
      <button
        onClick={(e) => {
          e.stopPropagation();
          if (isValid) onPublish();
          onClose();
        }}
        className={`w-full flex items-center gap-2 px-4 py-3 text-sm transition-all ${
          isValid ? 'text-emerald-400 hover:bg-slate-700' : 'text-slate-600 cursor-not-allowed'
        }`}
        disabled={!isValid}
      >
        <Upload size={16} />
        <span>Publish</span>
      </button>
      {onExport && (
        <button
          onClick={(e) => {
            e.stopPropagation();
            onExport();
            onClose();
          }}
          className="w-full flex items-center gap-2 px-4 py-3 text-sm text-sky-400 hover:bg-slate-700 transition-all"
        >
          <Download size={16} />
          <span>Export Text</span>
        </button>
      )}
      {onExportTts && (
        <button
          onClick={(e) => {
            e.stopPropagation();
            onExportTts();
            onClose();
          }}
          className="w-full flex items-center gap-2 px-4 py-3 text-sm text-violet-400 hover:bg-slate-700 transition-all"
        >
          <Gamepad2 size={16} />
          <span>Export TTS</span>
        </button>
      )}
      {onImport && (
        <button
          onClick={(e) => {
            e.stopPropagation();
            onImport();
            onClose();
          }}
          className="w-full flex items-center gap-2 px-4 py-3 text-sm text-amber-400 hover:bg-slate-700 transition-all"
        >
          <FileUp size={16} />
          <span>Import</span>
        </button>
      )}
      <button
        onClick={(e) => {
          e.stopPropagation();
          onEdit();
          onClose();
        }}
        className="w-full flex items-center gap-2 px-4 py-3 text-sm text-white hover:bg-slate-700 transition-all"
      >
        <Edit size={16} />
        <span>Edit</span>
      </button>
      <button
        onClick={(e) => {
          e.stopPropagation();
          onDuplicate();
          onClose();
        }}
        className="w-full flex items-center gap-2 px-4 py-3 text-sm text-white hover:bg-slate-700 transition-all"
      >
        <Copy size={16} />
        <span>Duplicate</span>
      </button>
      <button
        onClick={(e) => {
          e.stopPropagation();
          onDelete();
          onClose();
        }}
        className="w-full flex items-center gap-2 px-4 py-3 text-sm text-red-400 hover:bg-slate-700 transition-all"
      >
        <Trash2 size={16} />
        <span>Delete</span>
      </button>
    </div>
  );
}
