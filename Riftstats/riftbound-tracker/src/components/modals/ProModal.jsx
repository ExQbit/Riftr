import React, { useState } from 'react';
import { createPortal } from 'react-dom';
import { X, Layers, BarChart2, Palette, Headphones } from 'lucide-react';
import { useUI } from '../shared/UIProvider';

const FEATURES = [
  { icon: Layers, label: 'Unlimited Deck Publishing', active: true },
  { icon: BarChart2, label: 'Advanced Match Analytics', active: false },
  { icon: Palette, label: 'Visual Customization', active: false },
  { icon: Headphones, label: 'Priority Support', active: false },
];

const PLANS = [
  { id: 'monthly', label: 'Monthly', price: '4,99 €', badge: 'Most popular', discount: '30% discount' },
  { id: 'weekly', label: 'Weekly', price: '1,99 €', badge: null, discount: null },
];

export default function ProModal({ isOpen, onClose }) {
  const [selectedPlan, setSelectedPlan] = useState('monthly');
  const ui = useUI();

  if (!isOpen) return null;

  const handleContinue = () => {
    ui.toast('Coming Soon — Stay tuned!', 'info');
  };

  return createPortal(
    <div className="fixed inset-0 z-[999999] bg-slate-950 flex flex-col animate-in fade-in duration-200">
      {/* Header */}
      <div className="relative flex items-center justify-center pt-4 pb-2 px-4">
        <button
          onClick={onClose}
          className="absolute left-4 top-4 w-10 h-10 flex items-center justify-center rounded-full bg-slate-800/80 text-slate-400 active:scale-95 transition-all"
        >
          <X size={20} />
        </button>
      </div>

      {/* Scrollable content */}
      <div className="flex-1 overflow-y-auto px-6 pb-8">
        {/* Logo / Icon */}
        <div className="flex justify-center mb-3">
          <div className="w-16 h-16 rounded-2xl bg-gradient-to-br from-amber-500 to-amber-700 flex items-center justify-center shadow-lg shadow-amber-500/20">
            <span className="text-2xl font-black text-white">R</span>
          </div>
        </div>

        {/* Title */}
        <h1 className="text-2xl font-black text-white text-center mb-6">
          Unlock RiftStats Pro
        </h1>

        {/* Feature Grid */}
        <div className="grid grid-cols-2 gap-3 mb-8">
          {FEATURES.map(({ icon: Icon, label, active }) => (
            <div
              key={label}
              className={`rounded-2xl p-4 flex flex-col items-center justify-center text-center gap-2 min-h-[110px] transition-all ${
                active
                  ? 'bg-amber-500/15 border-2 border-amber-500'
                  : 'bg-slate-800/80 border-2 border-slate-700'
              }`}
            >
              <Icon size={24} className={active ? 'text-amber-400' : 'text-slate-500'} />
              <span className={`text-sm font-bold leading-tight ${active ? 'text-white' : 'text-slate-400'}`}>
                {label}
              </span>
            </div>
          ))}
        </div>

        {/* Plans Section */}
        <h2 className="text-lg font-black text-white text-center mb-4">Our Plans</h2>

        <div className="grid grid-cols-2 gap-3 mb-6">
          {PLANS.map((plan) => {
            const isSelected = selectedPlan === plan.id;
            return (
              <button
                key={plan.id}
                onClick={() => setSelectedPlan(plan.id)}
                className={`relative rounded-2xl p-4 flex flex-col items-center justify-center gap-1 min-h-[120px] transition-all active:scale-[0.97] ${
                  isSelected
                    ? 'bg-slate-900 border-2 border-amber-500 shadow-lg shadow-amber-500/10'
                    : 'bg-slate-800/80 border-2 border-slate-700'
                }`}
              >
                {plan.badge && (
                  <span className="absolute -top-2.5 left-1/2 -translate-x-1/2 px-2.5 py-0.5 rounded-full text-[10px] font-black bg-emerald-500 text-white whitespace-nowrap">
                    {plan.badge}
                  </span>
                )}
                <span className={`text-base font-bold ${isSelected ? 'text-white' : 'text-slate-300'}`}>
                  {plan.label}
                </span>
                <span className={`text-xl font-black ${isSelected ? 'text-white' : 'text-slate-400'}`}>
                  {plan.price}
                </span>
                {plan.discount && (
                  <span className="text-[11px] font-bold text-emerald-400">{plan.discount}</span>
                )}
              </button>
            );
          })}
        </div>

        {/* Continue Button */}
        <button
          onClick={handleContinue}
          className="w-full py-4 rounded-full bg-amber-500 hover:bg-amber-400 text-white font-black text-base transition-all active:scale-[0.98] shadow-lg shadow-amber-500/20"
        >
          Continue
        </button>

        {/* Footer Text */}
        <p className="text-[11px] text-slate-500 text-center mt-4 leading-relaxed">
          These subscription plans are auto-renewable and can be cancelled at any time.{' '}
          <span className="underline">Restore your purchase.</span>
        </p>

        <div className="flex items-center justify-center gap-4 mt-3">
          <span className="text-[11px] text-slate-600 underline">Privacy Policy</span>
          <span className="text-[11px] text-slate-600 underline">Terms of Use</span>
        </div>
      </div>
    </div>,
    document.body
  );
}
