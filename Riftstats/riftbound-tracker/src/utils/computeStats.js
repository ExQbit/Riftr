/**
 * Pure stats computation function extracted from useMatches.
 * Takes raw match data and returns comprehensive statistics.
 */
export function computeStats(matches) {
  if (!matches || matches.length === 0) return null;

  const sorted = [...matches].sort((a, b) => new Date(a.timestamp) - new Date(b.timestamp));
  const sortedDesc = [...sorted].reverse();

  const wr = (w, total) => total > 0 ? (w / total * 100).toFixed(1) : '0.0';

  // --- CORE ---
  const wins = matches.filter(m => m.result === 'win').length;
  const losses = matches.filter(m => m.result === 'loss').length;
  const draws = matches.filter(m => m.result === 'draw').length;
  const winRate = wr(wins, matches.length);

  // --- STREAKS ---
  let currentStreak = 0;
  let currentStreakType = null;
  let bestWinStreak = 0;
  let bestLossStreak = 0;
  let bestDrawStreak = 0;
  let tempWin = 0;
  let tempLoss = 0;
  let tempDraw = 0;

  for (const m of sortedDesc) {
    if (currentStreakType === null) {
      currentStreakType = m.result;
      currentStreak = 1;
    } else if (m.result === currentStreakType) {
      currentStreak++;
    } else {
      break;
    }
  }

  for (const m of sorted) {
    if (m.result === 'win') {
      tempWin++;
      tempLoss = 0;
      tempDraw = 0;
      if (tempWin > bestWinStreak) bestWinStreak = tempWin;
    } else if (m.result === 'loss') {
      tempLoss++;
      tempWin = 0;
      tempDraw = 0;
      if (tempLoss > bestLossStreak) bestLossStreak = tempLoss;
    } else {
      tempDraw++;
      tempWin = 0;
      tempLoss = 0;
      if (tempDraw > bestDrawStreak) bestDrawStreak = tempDraw;
    }
  }

  // --- RECENT FORM ---
  const recentForm = (n) => {
    const recent = sortedDesc.slice(0, n);
    if (recent.length === 0) return { wins: 0, losses: 0, draws: 0, total: 0, winRate: '0.0', results: [] };
    const w = recent.filter(m => m.result === 'win').length;
    const l = recent.filter(m => m.result === 'loss').length;
    const d = recent.length - w - l;
    return {
      wins: w,
      losses: l,
      draws: d,
      total: recent.length,
      winRate: wr(w, recent.length),
      results: recent.map(m => m.result),
    };
  };
  const last5 = recentForm(5);
  const last10 = recentForm(10);
  const last20 = recentForm(20);

  // --- SCORE STATS ---
  const scoredMatches = matches.filter(m => m.myScore !== undefined && m.oppScore !== undefined);
  let scoreStats = null;
  if (scoredMatches.length > 0) {
    const totalMyScore = scoredMatches.reduce((sum, m) => sum + m.myScore, 0);
    const totalOppScore = scoredMatches.reduce((sum, m) => sum + m.oppScore, 0);
    const avgMyScore = (totalMyScore / scoredMatches.length).toFixed(1);
    const avgOppScore = (totalOppScore / scoredMatches.length).toFixed(1);
    const avgDiff = (totalMyScore / scoredMatches.length - totalOppScore / scoredMatches.length).toFixed(1);

    const withDiff = scoredMatches.map(m => ({
      ...m,
      diff: Math.abs(m.myScore - m.oppScore),
    })).sort((a, b) => a.diff - b.diff);
    const closestGames = withDiff.slice(0, 3);

    const winsWithDiff = scoredMatches
      .filter(m => m.result === 'win')
      .map(m => ({ ...m, diff: m.myScore - m.oppScore }))
      .sort((a, b) => b.diff - a.diff);
    const biggestWin = winsWithDiff[0] || null;

    const lossesWithDiff = scoredMatches
      .filter(m => m.result === 'loss')
      .map(m => ({ ...m, diff: m.oppScore - m.myScore }))
      .sort((a, b) => b.diff - a.diff);
    const biggestLoss = lossesWithDiff[0] || null;

    scoreStats = {
      avgMyScore, avgOppScore, avgDiff,
      closestGames, biggestWin, biggestLoss,
      totalMyScore, totalOppScore,
    };
  }

  // --- FIRST vs SECOND ---
  // --- FIRST vs SECOND ---
  const firstMatches = matches.filter(m => m.isFirst);
  const secondMatches = matches.filter(m => !m.isFirst);
  const firstWins = firstMatches.filter(m => m.result === 'win').length;
  const secondWins = secondMatches.filter(m => m.result === 'win').length;
  const firstWR = wr(firstWins, firstMatches.length);
  const secondWR = wr(secondWins, secondMatches.length);

  const firstScored = firstMatches.filter(m => m.myScore !== undefined);
  const secondScored = secondMatches.filter(m => m.myScore !== undefined);
  const firstAvgScore = firstScored.length > 0
    ? (firstScored.reduce((s, m) => s + m.myScore, 0) / firstScored.length).toFixed(1) : '-';
  const secondAvgScore = secondScored.length > 0
    ? (secondScored.reduce((s, m) => s + m.myScore, 0) / secondScored.length).toFixed(1) : '-';

  // --- PER-DECK BREAKDOWN ---
  const deckMap = {};
  matches.forEach(m => {
    const key = m.deckId || m.deckName || 'Unknown';
    if (!deckMap[key]) {
      deckMap[key] = {
        name: m.deckName || 'Unknown',
        legendName: m.legendName || '',
        wins: 0, losses: 0, draws: 0, total: 0,
        firstWins: 0, firstTotal: 0,
        secondWins: 0, secondTotal: 0,
        totalMyScore: 0, totalOppScore: 0, scoredGames: 0,
        recentResults: [],
        matchups: {},
      };
    }
    const d = deckMap[key];
    d.total++;
    if (m.result === 'win') d.wins++;
    else if (m.result === 'loss') d.losses++;
    else d.draws++;

    if (m.isFirst) {
      d.firstTotal++;
      if (m.result === 'win') d.firstWins++;
    } else {
      d.secondTotal++;
      if (m.result === 'win') d.secondWins++;
    }

    if (m.myScore !== undefined && m.oppScore !== undefined) {
      d.totalMyScore += m.myScore;
      d.totalOppScore += m.oppScore;
      d.scoredGames++;
    }

    const opp = m.opponent || 'Unknown';
    if (!d.matchups[opp]) d.matchups[opp] = { wins: 0, losses: 0, draws: 0, total: 0, recentResults: [] };
    d.matchups[opp].total++;
    if (m.result === 'win') d.matchups[opp].wins++;
    else if (m.result === 'loss') d.matchups[opp].losses++;
    else d.matchups[opp].draws++;
    if (d.matchups[opp].recentResults.length < 10) d.matchups[opp].recentResults.push(m.result);
  });

  for (const m of sortedDesc) {
    const key = m.deckId || m.deckName || 'Unknown';
    if (deckMap[key] && deckMap[key].recentResults.length < 10) {
      deckMap[key].recentResults.push(m.result);
    }
  }

  const deckStats = Object.values(deckMap).map(d => ({
    ...d,
    winRate: wr(d.wins, d.total),
    firstWR: d.firstTotal > 0 ? wr(d.firstWins, d.firstTotal) : '-',
    secondWR: d.secondTotal > 0 ? wr(d.secondWins, d.secondTotal) : '-',
    avgMyScore: d.scoredGames > 0 ? (d.totalMyScore / d.scoredGames).toFixed(1) : '-',
    avgOppScore: d.scoredGames > 0 ? (d.totalOppScore / d.scoredGames).toFixed(1) : '-',
    avgDiff: d.scoredGames > 0 ? ((d.totalMyScore - d.totalOppScore) / d.scoredGames).toFixed(1) : '-',
    matchups: Object.entries(d.matchups)
      .map(([opp, data]) => ({
        opponent: opp, ...data,
        winRate: wr(data.wins, data.total),
      }))
      .sort((a, b) => b.total - a.total),
  })).sort((a, b) => b.total - a.total);

  // --- MATCHUP BREAKDOWN ---
  const matchupMap = {};
  matches.forEach(m => {
    const opp = m.opponent || 'Unknown';
    if (!matchupMap[opp]) {
      matchupMap[opp] = {
        wins: 0, losses: 0, draws: 0, total: 0,
        firstWins: 0, firstTotal: 0,
        secondWins: 0, secondTotal: 0,
        recentResults: [],
        decks: {},
      };
    }
    const mu = matchupMap[opp];
    mu.total++;
    if (m.result === 'win') mu.wins++;
    else if (m.result === 'loss') mu.losses++;
    else mu.draws++;
    if (m.isFirst === true) {
      mu.firstTotal++;
      if (m.result === 'win') mu.firstWins++;
    } else if (m.isFirst === false) {
      mu.secondTotal++;
      if (m.result === 'win') mu.secondWins++;
    }

    const deckKey = m.deckId || m.deckName || 'Unknown';
    const deckName = m.deckName || 'Unknown';
    if (!mu.decks[deckKey]) {
      mu.decks[deckKey] = {
        name: deckName, legendName: m.legendName || null,
        wins: 0, losses: 0, draws: 0, total: 0,
        firstWins: 0, firstTotal: 0,
        secondWins: 0, secondTotal: 0,
        totalMyScore: 0, totalOppScore: 0, scoredGames: 0,
        recentResults: [],
      };
    }
    const dd = mu.decks[deckKey];
    dd.total++;
    if (m.result === 'win') dd.wins++;
    else if (m.result === 'loss') dd.losses++;
    else dd.draws++;
    if (m.isFirst) { dd.firstTotal++; if (m.result === 'win') dd.firstWins++; }
    else { dd.secondTotal++; if (m.result === 'win') dd.secondWins++; }
    if (m.myScore !== undefined && m.oppScore !== undefined) {
      dd.totalMyScore += m.myScore; dd.totalOppScore += m.oppScore; dd.scoredGames++;
    }
  });

  for (const m of sortedDesc) {
    const opp = m.opponent || 'Unknown';
    if (matchupMap[opp] && matchupMap[opp].recentResults.length < 10) {
      matchupMap[opp].recentResults.push(m.result);
    }
    const deckKey = m.deckId || m.deckName || 'Unknown';
    if (matchupMap[opp]?.decks[deckKey] && matchupMap[opp].decks[deckKey].recentResults.length < 10) {
      matchupMap[opp].decks[deckKey].recentResults.push(m.result);
    }
  }

  const matchupStats = Object.entries(matchupMap).map(([opp, d]) => ({
    opponent: opp, ...d,
    winRate: wr(d.wins, d.total),
    firstWR: d.firstTotal > 0 ? wr(d.firstWins, d.firstTotal) : '-',
    secondWR: d.secondTotal > 0 ? wr(d.secondWins, d.secondTotal) : '-',
    deckBreakdown: Object.values(d.decks).map(dd => ({
      ...dd,
      winRate: wr(dd.wins, dd.total),
      firstWR: dd.firstTotal > 0 ? wr(dd.firstWins, dd.firstTotal) : '-',
      secondWR: dd.secondTotal > 0 ? wr(dd.secondWins, dd.secondTotal) : '-',
      avgMyScore: dd.scoredGames > 0 ? (dd.totalMyScore / dd.scoredGames).toFixed(1) : '-',
      avgOppScore: dd.scoredGames > 0 ? (dd.totalOppScore / dd.scoredGames).toFixed(1) : '-',
      avgDiff: dd.scoredGames > 0 ? ((dd.totalMyScore - dd.totalOppScore) / dd.scoredGames).toFixed(1) : '-',
    })).sort((a, b) => b.total - a.total),
  })).sort((a, b) => b.total - a.total);

  // --- FORMAT BREAKDOWN ---
  const formatMap = {};
  matches.forEach(m => {
    const fmt = m.format || 'bo1';
    if (!formatMap[fmt]) formatMap[fmt] = { wins: 0, losses: 0, draws: 0, total: 0 };
    formatMap[fmt].total++;
    if (m.result === 'win') formatMap[fmt].wins++;
    else if (m.result === 'loss') formatMap[fmt].losses++;
    else formatMap[fmt].draws++;
  });
  const formatStats = Object.entries(formatMap).map(([fmt, d]) => ({
    format: fmt,
    ...d,
    winRate: wr(d.wins, d.total),
  })).sort((a, b) => a.format.localeCompare(b.format));

  // --- BF CHOSEN STATS ---
  const allGamesFlat = matches.flatMap(m => m.games || []);
  const bfChosenGames = allGamesFlat.filter(g => g.bfChosen);
  const bfRandomGames = allGamesFlat.filter(g => !g.bfChosen);
  const bfChosenWR = bfChosenGames.length > 0
    ? wr(bfChosenGames.filter(g => g.result === 'win').length, bfChosenGames.length) : null;
  const bfRandomWR = bfRandomGames.length > 0
    ? wr(bfRandomGames.filter(g => g.result === 'win').length, bfRandomGames.length) : null;
  const bfStats = (bfChosenGames.length > 0 || bfRandomGames.length > 0) ? {
    chosenWR: bfChosenWR, chosenTotal: bfChosenGames.length,
    randomWR: bfRandomWR, randomTotal: bfRandomGames.length,
  } : null;

  // --- WIN RATE OVER TIME ---
  const timeline = sorted.map((m, i) => {
    const slice = sorted.slice(0, i + 1);
    const w = slice.filter(s => s.result === 'win').length;
    const rollingSlice = sorted.slice(Math.max(0, i - 9), i + 1);
    const rollingW = rollingSlice.filter(s => s.result === 'win').length;
    return {
      index: i + 1,
      winRate: parseFloat((w / slice.length * 100).toFixed(1)),
      rollingWR: parseFloat((rollingW / rollingSlice.length * 100).toFixed(1)),
      result: m.result,
      timestamp: m.timestamp,
      opponent: m.opponent,
      deckName: m.deckName,
    };
  });

  return {
    winRate, total: matches.length, wins, losses, draws,
    currentStreak, currentStreakType, bestWinStreak, bestLossStreak, bestDrawStreak,
    last5, last10, last20,
    scoreStats,
    firstWR, firstTotal: firstMatches.length, firstWins,
    secondWR, secondTotal: secondMatches.length, secondWins,
    firstAvgScore, secondAvgScore,
    deckStats, matchupStats,
    formatStats, bfStats,
    timeline,
  };
}
