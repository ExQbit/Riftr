import React, { createContext, useContext, useState, useCallback, useRef, useEffect } from 'react';
import { createPortal } from 'react-dom';
import { CheckCircle2, AlertTriangle, XCircle, Info, X } from 'lucide-react';

const UIContext = createContext(null);

export function useUI() {
  return useContext(UIContext);
}

// ========================================
// TOAST
// ========================================
const TOAST_ICONS = {
  success: <CheckCircle2 size={18} className="text-emerald-400 flex-shrink-0" />,
  error: <XCircle size={18} className="text-red-400 flex-shrink-0" />,
  warning: <AlertTriangle size={18} className="text-yellow-400 flex-shrink-0" />,
  info: <Info size={18} className="text-sky-400 flex-shrink-0" />,
};

const TOAST_COLORS = {
  success: 'border-emerald-500/30 bg-emerald-500/10',
  error: 'border-red-500/30 bg-red-500/10',
  warning: 'border-yellow-500/30 bg-yellow-500/10',
  info: 'border-sky-500/30 bg-sky-500/10',
};

function Toast({ toast, onDismiss }) {
  const [exiting, setExiting] = useState(false);

  useEffect(() => {
    const timer = setTimeout(() => {
      setExiting(true);
      setTimeout(() => onDismiss(toast.id), 300);
    }, toast.duration || 3000);
    return () => clearTimeout(timer);
  }, [toast, onDismiss]);

  return (
    <div
      className={`flex items-start gap-3 px-4 py-3 rounded-xl border backdrop-blur-md shadow-2xl transition-all duration-300 ${TOAST_COLORS[toast.type] || TOAST_COLORS.info} ${
        exiting ? 'opacity-0 translate-y-2' : 'opacity-100 translate-y-0'
      }`}
      style={{ animation: !exiting ? 'toast-in 0.3s ease-out' : undefined }}
    >
      {TOAST_ICONS[toast.type] || TOAST_ICONS.info}
      <p className="text-sm text-white font-medium flex-1">{toast.message}</p>
      <button onClick={() => { setExiting(true); setTimeout(() => onDismiss(toast.id), 300); }} className="text-slate-500 active:text-white p-0.5 flex-shrink-0">
        <X size={14} />
      </button>
    </div>
  );
}

// ========================================
// CONFIRM DIALOG
// ========================================
function ConfirmDialog({ dialog, onResolve }) {
  if (!dialog) return null;

  return createPortal(
    <div
      className="fixed inset-0 z-[99999] flex items-center justify-center"
      onClick={() => onResolve(false)}
    >
      <div className="absolute inset-0 bg-black/60 backdrop-blur-sm animate-in fade-in duration-200" />
      <div
        className="relative bg-slate-900 border border-slate-700 rounded-2xl p-6 mx-6 max-w-sm w-full shadow-2xl animate-in zoom-in-95 fade-in duration-200"
        onClick={e => e.stopPropagation()}
      >
        {dialog.title && (
          <h3 className="text-lg font-black text-white mb-2">{dialog.title}</h3>
        )}
        <p className="text-sm text-slate-400 mb-6 whitespace-pre-line">{dialog.message}</p>
        <div className="flex gap-3">
          <button
            onClick={() => onResolve(false)}
            className="flex-1 py-3 rounded-xl font-bold text-sm bg-slate-800 text-slate-300 active:scale-95 transition-all"
          >
            {dialog.cancelText || 'Cancel'}
          </button>
          <button
            onClick={() => onResolve(true)}
            className={`flex-1 py-3 rounded-xl font-bold text-sm active:scale-95 transition-all ${
              dialog.danger
                ? 'bg-red-600 text-white active:bg-red-500'
                : 'bg-amber-600 text-white active:bg-amber-500'
            }`}
          >
            {dialog.confirmText || 'Confirm'}
          </button>
        </div>
      </div>
    </div>,
    document.body
  );
}

// ========================================
// ALERT DIALOG (single button)
// ========================================
function AlertDialog({ dialog, onClose }) {
  if (!dialog) return null;

  return createPortal(
    <div
      className="fixed inset-0 z-[99999] flex items-center justify-center"
      onClick={onClose}
    >
      <div className="absolute inset-0 bg-black/60 backdrop-blur-sm animate-in fade-in duration-200" />
      <div
        className="relative bg-slate-900 border border-slate-700 rounded-2xl p-6 mx-6 max-w-sm w-full shadow-2xl animate-in zoom-in-95 fade-in duration-200"
        onClick={e => e.stopPropagation()}
      >
        {dialog.title && (
          <h3 className="text-lg font-black text-white mb-2">{dialog.title}</h3>
        )}
        <p className="text-sm text-slate-400 mb-6 whitespace-pre-line">{dialog.message}</p>
        <button
          onClick={onClose}
          className="w-full py-3 rounded-xl font-bold text-sm bg-amber-600 text-white active:bg-amber-500 active:scale-95 transition-all"
        >
          {dialog.buttonText || 'OK'}
        </button>
      </div>
    </div>,
    document.body
  );
}

// ========================================
// PROVIDER
// ========================================
let nextToastId = 0;

export default function UIProvider({ children }) {
  const [toasts, setToasts] = useState([]);
  const [confirmDialog, setConfirmDialog] = useState(null);
  const [alertDialog, setAlertDialog] = useState(null);
  const confirmResolveRef = useRef(null);

  const toast = useCallback((message, type = 'info', duration = 3000) => {
    const id = ++nextToastId;
    setToasts(prev => [...prev, { id, message, type, duration }]);
  }, []);

  const dismissToast = useCallback((id) => {
    setToasts(prev => prev.filter(t => t.id !== id));
  }, []);

  const confirm = useCallback((message, options = {}) => {
    return new Promise((resolve) => {
      confirmResolveRef.current = resolve;
      setConfirmDialog({
        message,
        title: options.title || 'Confirm',
        confirmText: options.confirmText || 'Confirm',
        cancelText: options.cancelText || 'Cancel',
        danger: options.danger || false,
      });
    });
  }, []);

  const handleConfirmResolve = useCallback((result) => {
    confirmResolveRef.current?.(result);
    confirmResolveRef.current = null;
    setConfirmDialog(null);
  }, []);

  const showAlert = useCallback((message, options = {}) => {
    return new Promise((resolve) => {
      setAlertDialog({
        message,
        title: options.title,
        buttonText: options.buttonText,
        _resolve: resolve,
      });
    });
  }, []);

  const handleAlertClose = useCallback(() => {
    alertDialog?._resolve?.();
    setAlertDialog(null);
  }, [alertDialog]);

  const value = { toast, confirm, alert: showAlert };

  return (
    <UIContext.Provider value={value}>
      {children}

      {/* Toasts */}
      {toasts.length > 0 && createPortal(
        <div className="fixed top-[max(1rem,env(safe-area-inset-top,1rem))] left-4 right-4 z-[99998] flex flex-col gap-2 pointer-events-none">
          {toasts.map(t => (
            <div key={t.id} className="pointer-events-auto">
              <Toast toast={t} onDismiss={dismissToast} />
            </div>
          ))}
        </div>,
        document.body
      )}

      {/* Confirm Dialog */}
      <ConfirmDialog dialog={confirmDialog} onResolve={handleConfirmResolve} />

      {/* Alert Dialog */}
      <AlertDialog dialog={alertDialog} onClose={handleAlertClose} />

      <style>{`
        @keyframes toast-in {
          from { opacity: 0; transform: translateY(-10px); }
          to { opacity: 1; transform: translateY(0); }
        }
      `}</style>
    </UIContext.Provider>
  );
}
