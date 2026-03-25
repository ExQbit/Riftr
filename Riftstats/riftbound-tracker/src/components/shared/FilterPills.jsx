import React from 'react';
import { PILL_CONTAINER, pillClass } from '../../constants/design';

const FilterPills = React.memo(function FilterPills({ filters, activeFilter, onFilterChange }) {
  return (
    <div className={PILL_CONTAINER}>
      {filters.map(filter => (
        <button
          key={filter.value}
          onClick={() => onFilterChange(filter.value)}
          className={pillClass(activeFilter === filter.value)}
        >
          {filter.label}
        </button>
      ))}
    </div>
  );
});

export default FilterPills;
