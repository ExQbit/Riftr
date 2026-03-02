// Quick debug script - run with: node src/debug-card.js
const fs = require('fs');

// Try to read the localStorage cache file or check API structure
// Since we can't access localStorage from Node, let's check the API proxy config
console.log("Check browser console: Open DevTools → Console → type:");
console.log("");
console.log("  JSON.parse(localStorage.getItem('riftbound_all_cards'))[0]");
console.log("");
console.log("Or for just the keys:");
console.log("");
console.log("  Object.keys(JSON.parse(localStorage.getItem('riftbound_all_cards'))[0])");
console.log("");
console.log("Copy the output and paste it here!");
