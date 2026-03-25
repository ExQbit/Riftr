import React from 'react';
import { Search } from 'lucide-react';
import { SEARCH_WRAPPER, SEARCH_ICON, SEARCH_INPUT } from '../../constants/design';

const SearchBar = React.memo(function SearchBar({ value, onChange, placeholder = "Search cards..." }) {
  return (
    <div className={SEARCH_WRAPPER}>
      <Search className={SEARCH_ICON} size={18} />
      <input
        type="text"
        placeholder={placeholder}
        value={value}
        onChange={e => onChange(e.target.value)}
        className={SEARCH_INPUT}
      />
    </div>
  );
});

export default SearchBar;
