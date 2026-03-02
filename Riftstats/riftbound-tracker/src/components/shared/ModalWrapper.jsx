import React, { useEffect } from 'react';
import { Plus } from 'lucide-react';
import { MODAL_OVERLAY, MODAL_CONTAINER, MODAL_HEADER, MODAL_TITLE } from '../../constants/design';

export default function ModalWrapper({ isOpen, onClose, title, children, fullHeight = true }) {
  // Lock body scroll when modal is open
  useEffect(() => {
    if (!isOpen) return;
    const scrollY = window.scrollY;
    document.body.style.position = 'fixed';
    document.body.style.top = `-${scrollY}px`;
    document.body.style.width = '100%';
    return () => {
      document.body.style.position = '';
      document.body.style.top = '';
      document.body.style.width = '';
      window.scrollTo(0, scrollY);
    };
  }, [isOpen]);

  if (!isOpen) return null;

  return (
    <div className={MODAL_OVERLAY} onClick={onClose}>
      <div
        className={fullHeight ? MODAL_CONTAINER : 'bg-slate-900 border border-slate-800 rounded-3xl w-full sm:max-w-lg p-6'}
        onClick={(e) => e.stopPropagation()}
      >
        <div className={MODAL_HEADER}>
          <h3 className={MODAL_TITLE}>{title}</h3>
          <button onClick={onClose} className="text-slate-400 hover:text-white">
            <Plus size={24} className="rotate-45" />
          </button>
        </div>
        {children}
      </div>
    </div>
  );
}
