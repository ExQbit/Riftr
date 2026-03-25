import React, { useState, useEffect } from 'react';
import { Plus } from 'lucide-react';

export default function EditDeckModal({ isOpen, onClose, deck, onSave }) {
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');

  useEffect(() => {
    if (deck) {
      setName(deck.name || '');
      setDescription(deck.description || '');
    }
  }, [deck]);

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

  if (!isOpen || !deck) return null;

  const handleSave = () => {
    if (!name.trim()) {
      alert('Deck name cannot be empty');
      return;
    }
    onSave(deck.id, name.trim(), description.trim());
  };

  return (
    <div
      className="fixed inset-0 bg-black/80 z-[100] flex items-end sm:items-center justify-center overflow-y-auto"
      onClick={onClose}
    >
      <div
        className="bg-slate-900 border border-slate-800 rounded-t-3xl sm:rounded-3xl w-full sm:max-w-lg p-6 my-auto"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-center justify-between mb-6">
          <h3 className="text-xl font-black text-white">Edit Deck</h3>
          <button onClick={onClose} className="text-slate-400 hover:text-white">
            <Plus size={24} className="rotate-45" />
          </button>
        </div>

        <div className="space-y-4">
          <div>
            <label className="block text-sm font-bold text-slate-400 mb-2">Deck Name</label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="w-full bg-slate-800 border border-slate-700 rounded-xl py-3 px-4 text-white focus:ring-2 ring-amber-500/40 outline-none"
              placeholder="Enter deck name..."
            />
          </div>

          <div>
            <label className="block text-sm font-bold text-slate-400 mb-2">Description (Optional)</label>
            <textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              className="w-full bg-slate-800 border border-slate-700 rounded-xl py-3 px-4 text-white focus:ring-2 ring-amber-500/40 outline-none resize-none"
              placeholder="Enter deck description..."
              rows={3}
            />
          </div>

          <div className="flex gap-3 pt-2">
            <button
              onClick={onClose}
              className="flex-1 py-3 px-4 bg-slate-800 hover:bg-slate-700 text-white font-bold rounded-xl transition-all"
            >
              Cancel
            </button>
            <button
              onClick={handleSave}
              className="flex-1 py-3 px-4 bg-amber-600 hover:bg-amber-500 text-white font-bold rounded-xl transition-all"
            >
              Save Changes
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
