import React from 'react';
import { CARD_IMAGE, CARD_CONTAINER, CARD_ASPECT_PORTRAIT, CARD_ASPECT_LANDSCAPE, BADGE_COUNT } from '../../constants/design';

const CardImage = React.memo(function CardImage({
  card,
  count,
  onClick,
  showName = false,
  className = '',
  children
}) {
  const isLandscape = card.orientation === 'landscape';
  const aspect = isLandscape ? CARD_ASPECT_LANDSCAPE : CARD_ASPECT_PORTRAIT;

  return (
    <div className={`relative ${isLandscape ? 'col-span-2' : ''} ${className}`}>
      <div
        className={`${CARD_CONTAINER} ${aspect} ${onClick ? 'cursor-pointer active:scale-95 transition-all' : ''}`}
        onClick={onClick}
        role={onClick ? 'button' : undefined}
      >
        <img
          src={card.media?.image_url || card.imageUrl}
          alt={card.name}
          className={CARD_IMAGE}
          loading="lazy"
        />
        {count > 1 && (
          <div className={BADGE_COUNT}>{count}</div>
        )}
        {children}
      </div>
      {showName && (
        <p className="text-xs font-bold text-center mt-1 truncate">{card.name}</p>
      )}
    </div>
  );
});

export default CardImage;
