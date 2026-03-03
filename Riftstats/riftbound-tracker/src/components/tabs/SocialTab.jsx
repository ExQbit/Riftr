import React, { useState, useEffect, useMemo } from 'react';
import { Edit, ArrowLeft, Save, X, Users, ChevronRight, Layers, Compass, LogOut } from 'lucide-react';
import { t } from '../../constants/i18n';
import { useUI } from '../shared/UIProvider';
import useProfile from '../../hooks/useProfile';
import AuthorProfile from '../shared/AuthorProfile';
import { useGameData } from '../../contexts/AppContexts';
import { useAppData } from '../../contexts/AppContexts';

export default function SocialTab({ onTabChange }) {
  const { allCards, cardLookup } = useGameData();
  const {
    user, publicDecks, savedDecks, matchStats: stats,
    myFollowing, follow, unfollow, isFollowing, getFollowerCount,
    getQuantity, logout,
  } = useAppData();
  const ui = useUI();
  const { profile, profileLoading, updateProfile, fetchProfiles, profileCache } = useProfile(user);
  const [view, setView] = useState('home'); // 'home' | 'edit-profile' | 'author'
  const [selectedFollowedUser, setSelectedFollowedUser] = useState(null);

  // Edit profile form state
  const [editName, setEditName] = useState('');
  const [editBio, setEditBio] = useState('');
  const [editAvatarUrl, setEditAvatarUrl] = useState('');
  const [saving, setSaving] = useState(false);

  // Fetch profiles of followed users
  useEffect(() => {
    if (myFollowing.length > 0) {
      fetchProfiles(myFollowing);
    }
  }, [myFollowing, fetchProfiles]);

  // Resolve display name for a followed user
  const resolveFollowedName = (uid) => {
    const cached = profileCache.get(uid);
    if (cached?.displayName) return cached.displayName;
    const deck = publicDecks.find(d => d.authorId === uid);
    if (deck?.authorName) return deck.authorName;
    return t.unknownPlayer || 'Unknown Player';
  };

  // Build followed user list with metadata
  const followedUsers = useMemo(() => {
    return myFollowing.map(uid => {
      const cached = profileCache.get(uid);
      const userDecks = publicDecks.filter(d => d.authorId === uid);
      const deckCount = userDecks.length;
      const followers = getFollowerCount?.(uid) || 0;

      return {
        uid,
        displayName: cached?.displayName || resolveFollowedName(uid),
        avatarUrl: cached?.avatarUrl || null,
        bio: cached?.bio || null,
        deckCount,
        followers,
      };
    }).sort((a, b) => b.deckCount - a.deckCount);
  }, [myFollowing, profileCache, publicDecks, getFollowerCount]);

  // Own profile display values
  const ownName = profile?.displayName || user?.displayName || user?.email?.split('@')[0] || 'Anonymous';
  const ownBio = profile?.bio || '';
  const ownAvatarUrl = profile?.avatarUrl || null;
  const ownInitial = (ownName || '?')[0].toUpperCase();
  const ownPublishedCount = publicDecks.filter(d => d.authorId === user?.uid).length;
  const ownFollowerCount = getFollowerCount?.(user?.uid) || 0;

  // Enter edit mode
  const handleEditProfile = () => {
    setEditName(ownName);
    setEditBio(ownBio);
    setEditAvatarUrl(ownAvatarUrl || '');
    setView('edit-profile');
  };

  // Save profile
  const handleSaveProfile = async () => {
    setSaving(true);
    try {
      await updateProfile({
        displayName: editName.trim() || ownName,
        bio: editBio.trim().slice(0, 150),
        avatarUrl: editAvatarUrl.trim() || null,
      });
      ui?.toast(t.profileSaved || 'Profile saved!', 'success');
      setView('home');
    } catch (err) {
      console.error('Error saving profile:', err);
      ui?.toast('Error saving profile', 'error');
    } finally {
      setSaving(false);
    }
  };

  // Open followed user's profile
  const handleOpenProfile = (uid) => {
    const name = resolveFollowedName(uid);
    setSelectedFollowedUser({ authorId: uid, authorName: name });
    setView('author');
  };

  // ========================================
  // AUTHOR PROFILE VIEW
  // ========================================
  if (view === 'author' && selectedFollowedUser) {
    return (
      <AuthorProfile
        selectedAuthor={selectedFollowedUser}
        authorProfile={profileCache.get(selectedFollowedUser.authorId)}
        user={user}
        onBack={() => { setView('home'); setSelectedFollowedUser(null); }}
        allCards={allCards}
        publicDecks={publicDecks}
        savedDecks={savedDecks}
        stats={stats}
        getQuantity={getQuantity}
        follow={follow}
        unfollow={unfollow}
        isFollowing={isFollowing}
        getFollowerCount={getFollowerCount}
        onLoadDeck={null}
        onDuplicateDeck={null}
      />
    );
  }

  // ========================================
  // EDIT PROFILE VIEW
  // ========================================
  if (view === 'edit-profile') {
    return (
      <div className="space-y-4 animate-in fade-in slide-in-from-bottom-4 duration-500 pb-24 px-2 pt-4">
        <button onClick={() => setView('home')} className="flex items-center gap-2 text-slate-400 hover:text-white transition-all active:scale-95">
          <ArrowLeft size={18} />
          <span className="text-sm font-bold">Back</span>
        </button>

        <div className="bg-slate-900 border border-slate-800 rounded-3xl p-6 space-y-5">
          <h2 className="text-lg font-black text-white">{t.editProfile || 'Edit Profile'}</h2>

          {/* Avatar */}
          <div className="flex flex-col items-center gap-3">
            {editAvatarUrl ? (
              <img src={editAvatarUrl} alt="Avatar" className="w-20 h-20 rounded-full object-cover" onError={(e) => { e.target.style.display = 'none'; }} />
            ) : (
              <div className="w-20 h-20 rounded-full bg-gradient-to-br from-amber-600 to-amber-400 flex items-center justify-center">
                <span className="text-3xl font-black text-white">{(editName || '?')[0].toUpperCase()}</span>
              </div>
            )}
            <div className="w-full">
              <label className="text-[10px] font-black text-slate-500 uppercase mb-1.5 block">{t.avatarUrl || 'Avatar URL'}</label>
              <div className="flex gap-2">
                <input
                  type="url"
                  placeholder={t.enterAvatarUrl || 'Paste image URL...'}
                  value={editAvatarUrl}
                  onChange={e => setEditAvatarUrl(e.target.value)}
                  onBlur={() => setTimeout(() => window.scrollTo(0, 0), 50)}
                  className="flex-1 bg-slate-800 border-none rounded-xl py-2.5 px-3 text-sm focus:ring-2 ring-amber-500/40 outline-none text-white placeholder:text-slate-600"
                />
                {editAvatarUrl && (
                  <button onClick={() => setEditAvatarUrl('')} className="p-2 text-slate-500 hover:text-rose-400 active:scale-95 transition-all">
                    <X size={16} />
                  </button>
                )}
              </div>
            </div>
          </div>

          {/* Display Name */}
          <div>
            <label className="text-[10px] font-black text-slate-500 uppercase mb-1.5 block">{t.displayName || 'Display Name'}</label>
            <input
              type="text"
              maxLength={30}
              value={editName}
              onChange={e => setEditName(e.target.value)}
              onBlur={() => setTimeout(() => window.scrollTo(0, 0), 50)}
              className="w-full bg-slate-800 border-none rounded-xl py-2.5 px-3 text-sm focus:ring-2 ring-amber-500/40 outline-none text-white"
            />
          </div>

          {/* Bio */}
          <div>
            <div className="flex items-center justify-between mb-1.5">
              <label className="text-[10px] font-black text-slate-500 uppercase">{t.bio || 'Bio'}</label>
              <span className="text-[10px] font-bold text-slate-600">{editBio.length}/150</span>
            </div>
            <textarea
              maxLength={150}
              rows={3}
              value={editBio}
              onChange={e => setEditBio(e.target.value)}
              onBlur={() => setTimeout(() => window.scrollTo(0, 0), 50)}
              placeholder="Tell us about yourself..."
              className="w-full bg-slate-800 border-none rounded-xl py-2.5 px-3 text-sm focus:ring-2 ring-amber-500/40 outline-none resize-none text-white placeholder:text-slate-600"
            />
          </div>

          {/* Save button */}
          <button
            onClick={handleSaveProfile}
            disabled={saving}
            className="w-full flex items-center justify-center gap-2 bg-amber-600 hover:bg-amber-500 text-white font-bold py-3 rounded-xl transition-all active:scale-[0.98] disabled:opacity-50"
          >
            <Save size={16} />
            {saving ? 'Saving...' : (t.saveProfile || 'Save Profile')}
          </button>
        </div>
      </div>
    );
  }

  // ========================================
  // HOME VIEW
  // ========================================
  return (
    <div className="space-y-4 animate-in fade-in slide-in-from-bottom-4 duration-500 pb-24">
      {/* Gold Ornament Header */}
      <div className="text-center pt-3 pb-1">
        <div className="flex items-center justify-center gap-3 mb-2">
          <div className="h-px w-12 bg-gradient-to-r from-transparent to-amber-500/50" />
          <div className="w-1.5 h-1.5 rotate-45 bg-amber-500/60" />
          <div className="h-px w-12 bg-gradient-to-l from-transparent to-amber-500/50" />
        </div>
        <h2 className="text-xs font-black uppercase tracking-[0.3em] bg-gradient-to-r from-amber-200 via-yellow-100 to-amber-200 bg-clip-text text-transparent">
          Unite The Legends
        </h2>
      </div>

      {/* Own Profile Card */}
      <div className="bg-slate-900 border border-slate-800 rounded-3xl p-6">
        <div className="flex items-center gap-4">
          {ownAvatarUrl ? (
            <img src={ownAvatarUrl} alt={ownName} className="w-16 h-16 rounded-full object-cover flex-shrink-0" />
          ) : (
            <div className="w-16 h-16 rounded-full bg-gradient-to-br from-amber-600 to-amber-400 flex items-center justify-center flex-shrink-0">
              <span className="text-2xl font-black text-white">{ownInitial}</span>
            </div>
          )}
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2">
              <h2 className="text-xl font-black text-white truncate">{ownName}</h2>
              <span className="px-1.5 py-0.5 rounded text-[9px] font-black bg-slate-700 text-slate-400 border border-slate-600 uppercase shrink-0">Free</span>
            </div>
            {ownBio && <p className="text-xs text-slate-400 mt-0.5 line-clamp-2">{ownBio}</p>}
            <div className="flex items-center gap-2 mt-2">
              <button
                onClick={handleEditProfile}
                className="flex items-center gap-1.5 px-4 py-1.5 rounded-full text-xs font-bold bg-slate-800 text-slate-400 border border-slate-700 transition-all active:scale-95"
              >
                <Edit size={12} />
                {t.editProfile || 'Edit Profile'}
              </button>
              {logout && (
                <button
                  onClick={async () => { if (await ui?.confirm('Are you sure you want to logout?', { title: 'Logout', confirmText: 'Logout', danger: true })) logout(); }}
                  className="flex items-center gap-1.5 px-4 py-1.5 rounded-full text-xs font-bold bg-slate-800 text-rose-400 border border-slate-700 transition-all active:scale-95"
                >
                  <LogOut size={12} />
                  Logout
                </button>
              )}
            </div>
          </div>
        </div>

        {/* Stats row */}
        <div className="flex items-center justify-center gap-4 mt-5 bg-slate-800/50 rounded-2xl py-3 px-2">
          <div className="text-center flex-1">
            <p className="text-lg font-black text-white">{ownPublishedCount}</p>
            <p className="text-[10px] text-slate-500 font-bold uppercase">{t.published || 'Published'}</p>
          </div>
          <div className="w-px h-8 bg-slate-700" />
          <div className="text-center flex-1">
            <p className="text-lg font-black text-white">{myFollowing.length}</p>
            <p className="text-[10px] text-slate-500 font-bold uppercase">{t.following}</p>
          </div>
          <div className="w-px h-8 bg-slate-700" />
          <div className="text-center flex-1">
            <p className="text-lg font-black text-white">{ownFollowerCount}</p>
            <p className="text-[10px] text-slate-500 font-bold uppercase">{t.followers}</p>
          </div>
        </div>
      </div>

      {/* Following divider */}
      <div className="flex items-center gap-2 px-1">
        <Users size={12} className="text-amber-500/50" />
        <span className="text-[10px] font-bold uppercase tracking-[0.15em] text-amber-500/40">{t.followingList || 'Following'} ({followedUsers.length})</span>
        <div className="h-px flex-1 bg-gradient-to-r from-amber-500/15 to-transparent" />
      </div>

      {followedUsers.length === 0 ? (
        <div className="py-16 px-8 text-center bg-slate-900 rounded-3xl border border-slate-800 relative overflow-hidden">
          {/* Decorative background circles */}
          <div className="absolute top-4 left-8 w-24 h-24 rounded-full bg-amber-600/5 blur-xl" />
          <div className="absolute bottom-4 right-8 w-32 h-32 rounded-full bg-amber-500/5 blur-xl" />
          <div className="relative z-10">
            <div className="w-16 h-16 rounded-full bg-slate-800 flex items-center justify-center mx-auto mb-4">
              <Users size={28} className="text-slate-600" />
            </div>
            <p className="text-slate-400 font-bold text-sm">{t.noFollowing || 'You are not following anyone yet.'}</p>
            <p className="text-slate-600 text-xs mt-1.5 mb-5">{t.noFollowingHint || 'Browse Public Decks to discover players.'}</p>
            {onTabChange && (
              <button
                onClick={() => onTabChange('deckbuilder')}
                className="inline-flex items-center gap-2 px-5 py-2.5 rounded-full text-xs font-bold bg-amber-600 hover:bg-amber-500 text-white transition-all active:scale-95"
              >
                <Compass size={14} />
                Discover Players
              </button>
            )}
          </div>
        </div>
      ) : (
        <div className="space-y-2">
          {followedUsers.map(fu => {
            const initial = (fu.displayName || '?')[0].toUpperCase();
            return (
              <button
                key={fu.uid}
                onClick={() => handleOpenProfile(fu.uid)}
                className="w-full bg-slate-900 border border-slate-800 rounded-2xl p-4 flex items-center gap-3 transition-all active:scale-[0.98] hover:border-slate-700 text-left"
              >
                {fu.avatarUrl ? (
                  <img src={fu.avatarUrl} alt={fu.displayName} className="w-12 h-12 rounded-full object-cover flex-shrink-0" />
                ) : (
                  <div className="w-12 h-12 rounded-full bg-gradient-to-br from-amber-600 to-amber-400 flex items-center justify-center flex-shrink-0">
                    <span className="text-lg font-black text-white">{initial}</span>
                  </div>
                )}
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-1.5">
                    <p className="text-sm font-bold text-white truncate">{fu.displayName}</p>
                    <span className="px-1.5 py-0.5 rounded text-[8px] font-black bg-slate-700 text-slate-400 border border-slate-600 uppercase shrink-0">Free</span>
                  </div>
                  <div className="flex items-center gap-2 mt-0.5">
                    <span className="text-[10px] text-slate-500">
                      <Layers size={10} className="inline mr-0.5" />{fu.deckCount} Decks
                    </span>
                    <span className="text-[10px] text-slate-600">&middot;</span>
                    <span className="text-[10px] text-slate-500">
                      {fu.followers} {t.followers}
                    </span>
                  </div>
                </div>
                <ChevronRight size={16} className="text-slate-600 flex-shrink-0" />
              </button>
            );
          })}
        </div>
      )}
    </div>
  );
}
