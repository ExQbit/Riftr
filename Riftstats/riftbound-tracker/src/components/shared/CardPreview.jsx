import React, { useState, useRef, useCallback } from 'react';
import { createPortal } from 'react-dom';

// Hook: detects long press (500ms) without triggering on scroll
// Returns handlers + a ref to check if long press just fired (to block onClick)
export function useLongPress(onLongPress, onTap, delay = 400) {
  const timerRef = useRef(null);
  const movedRef = useRef(false);
  const firedRef = useRef(false);
  const isTouchRef = useRef(false);
  const startPos = useRef({ x: 0, y: 0 });

  const start = useCallback((e) => {
    isTouchRef.current = e.type === 'touchstart';
    if (e.touches?.[0]) {
      startPos.current = { x: e.touches[0].clientX, y: e.touches[0].clientY };
    } else {
      startPos.current = { x: e.clientX, y: e.clientY };
    }
    movedRef.current = false;
    firedRef.current = false;
    timerRef.current = setTimeout(() => {
      if (!movedRef.current) {
        firedRef.current = true;
        onLongPress?.();
      }
    }, delay);
  }, [onLongPress, delay]);

  const move = useCallback((e) => {
    if (movedRef.current) return;
    let dx = 0, dy = 0;
    if (e.touches?.[0]) {
      dx = Math.abs(e.touches[0].clientX - startPos.current.x);
      dy = Math.abs(e.touches[0].clientY - startPos.current.y);
    } else {
      dx = Math.abs(e.clientX - startPos.current.x);
      dy = Math.abs(e.clientY - startPos.current.y);
    }
    if (dx > 10 || dy > 10) {
      movedRef.current = true;
      clearTimeout(timerRef.current);
    }
  }, []);

  const end = useCallback((e) => {
    clearTimeout(timerRef.current);
    // Fire tap immediately on touchend (skip waiting for onClick)
    if (e.type === 'touchend' && !movedRef.current && !firedRef.current) {
      e.preventDefault(); // Prevent ghost click
      onTap?.();
    }
  }, [onTap]);

  const cancel = useCallback(() => {
    clearTimeout(timerRef.current);
  }, []);

  // Fallback for mouse (desktop) - only fire if not from touch
  const handleClick = useCallback((e) => {
    if (isTouchRef.current) {
      // Already handled by touchend
      e.preventDefault();
      return;
    }
    if (!movedRef.current && !firedRef.current) {
      onTap?.();
    }
  }, [onTap]);

  const handlers = {
    onTouchStart: start,
    onTouchMove: move,
    onTouchEnd: end,
    onTouchCancel: cancel,
    onMouseDown: start,
    onMouseMove: move,
    onMouseUp: cancel,
    onMouseLeave: cancel,
    onClick: handleClick,
  };

  return handlers;
}

// Fullscreen card preview overlay
export default function CardPreview({ card, onClose }) {
  if (!card) return null;

  const isLandscape = card.orientation === 'landscape' || card.classification?.type === 'Battlefield';

  return createPortal(
    <div
      onClick={onClose}
      onTouchEnd={(e) => { e.preventDefault(); onClose(); }}
      style={{
        position: 'fixed',
        top: 0,
        left: 0,
        width: '100vw',
        height: '100dvh',
        zIndex: 999999,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        background: 'rgba(0,0,0,0.85)',
        backdropFilter: 'blur(8px)',
        WebkitBackdropFilter: 'blur(8px)',
        padding: '2rem',
      }}
      className="animate-in fade-in duration-200"
    >
      <div
        onClick={(e) => e.stopPropagation()}
        className="relative max-w-sm w-full animate-in zoom-in-95 duration-200"
      >
        <img
          src={card.media?.image_url}
          alt={card.name}
          className={`w-full rounded-2xl shadow-2xl ${isLandscape ? 'aspect-[3/2]' : 'aspect-[2/3]'} object-cover`}
          draggable={false}
        />
        <p className="text-center text-white font-bold text-lg mt-4">{card.name}</p>
        <p className="text-center text-slate-400 text-xs mt-1">Tap anywhere to close</p>
      </div>
    </div>,
    document.body
  );
}
