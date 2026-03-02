import React, { useState } from 'react';
import { Mail, Zap } from 'lucide-react';
import { auth } from '../constants/firebase';
import {
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  GoogleAuthProvider,
  signInWithPopup,
  signInAnonymously
} from 'firebase/auth';

export default function LoginScreen() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isRegistering, setIsRegistering] = useState(false);
  const [authError, setAuthError] = useState('');

  const handleEmailAuth = async (e) => {
    e.preventDefault();
    setAuthError('');
    try {
      if (isRegistering) {
        await createUserWithEmailAndPassword(auth, email, password);
      } else {
        await signInWithEmailAndPassword(auth, email, password);
      }
    } catch (err) {
      setAuthError(err.message.includes('auth/user-not-found') ? 'Account not found.' : 'Login failed.');
    }
  };

  const handleGoogleAuth = async () => {
    const provider = new GoogleAuthProvider();
    try { await signInWithPopup(auth, provider); } catch (err) { setAuthError('Google login failed.'); }
  };

  return (
    <div className="min-h-screen bg-slate-950 flex items-center justify-center p-6">
      <div className="max-w-md w-full bg-slate-900 rounded-3xl p-8 border border-slate-800 shadow-2xl">
        <div className="text-center mb-8">
          <h1 className="text-3xl font-black text-amber-500 mb-2">RIFTR</h1>
          <p className="text-slate-500 text-sm">Your Riftbound Companion</p>
        </div>

        <form onSubmit={handleEmailAuth} className="space-y-4">
          <div className="relative">
            <Mail className="absolute left-4 top-3.5 text-slate-500" size={18} />
            <input
              type="email" placeholder="Email" value={email} onChange={e => setEmail(e.target.value)} required
              className="w-full bg-slate-800 border-none rounded-xl py-3 pl-12 pr-4 text-sm focus:ring-2 ring-amber-500/40 outline-none"
            />
          </div>
          <div className="relative">
            <Zap className="absolute left-4 top-3.5 text-slate-500" size={18} />
            <input
              type="password" placeholder="Password" value={password} onChange={e => setPassword(e.target.value)} required
              className="w-full bg-slate-800 border-none rounded-xl py-3 pl-12 pr-4 text-sm focus:ring-2 ring-amber-500/40 outline-none"
            />
          </div>
          {authError && <p className="text-rose-500 text-xs text-center font-bold">{authError}</p>}
          <button className="w-full bg-amber-600 hover:bg-amber-500 py-4 rounded-xl font-black transition-all active:scale-95 shadow-lg shadow-emerald-900/20">
            {isRegistering ? 'REGISTER' : 'SIGN IN'}
          </button>
        </form>

        <div className="flex items-center my-6">
          <div className="flex-1 h-[1px] bg-slate-800"></div>
          <span className="px-4 text-[10px] text-slate-600 font-bold">OR</span>
          <div className="flex-1 h-[1px] bg-slate-800"></div>
        </div>

        <button onClick={handleGoogleAuth} className="w-full bg-white text-black py-4 rounded-xl font-black flex items-center justify-center gap-2 transition-all hover:bg-slate-200 active:scale-95">
          <svg className="w-5 h-5" viewBox="0 0 24 24"><path fill="currentColor" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/><path fill="currentColor" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/><path fill="currentColor" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l3.66-2.84z"/><path fill="currentColor" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/></svg>
          GOOGLE LOGIN
        </button>

        <button onClick={async () => { try { await signInAnonymously(auth); } catch (err) { setAuthError('Guest login failed.'); } }} className="w-full mt-3 bg-slate-800 text-slate-400 py-3 rounded-xl font-bold text-sm flex items-center justify-center gap-2 transition-all hover:bg-slate-700 hover:text-white active:scale-95 border border-slate-700">
          CONTINUE AS GUEST
        </button>

        <p className="mt-6 text-center text-xs text-slate-500">
          {isRegistering ? 'Already have an account?' : 'No account yet?'}
          <button onClick={() => setIsRegistering(!isRegistering)} className="ml-2 text-amber-500 font-bold hover:underline">
            {isRegistering ? 'Sign in now' : 'Register now'}
          </button>
        </p>

        <p className="mt-6 pt-4 border-t border-slate-800 text-center text-[9px] text-slate-600 leading-relaxed">
          Riftr was created under Riot Games' "Legal Jibber Jabber" policy using assets owned by Riot Games. Riot Games does not endorse or sponsor this project.
        </p>
      </div>
    </div>
  );
}
