import { initializeApp } from 'firebase/app';
import { getFirestore } from 'firebase/firestore';
import { getAuth } from 'firebase/auth';

const firebaseConfig = {
  apiKey: "AIzaSyAEYIlo1s-w6O-Y-9w4_ebqfT-dv8mmf_o",
  authDomain: "riftr-10527.firebaseapp.com",
  projectId: "riftr-10527",
  storageBucket: "riftr-10527.firebasestorage.app",
  messagingSenderId: "677251344019",
  appId: "1:677251344019:web:d4d44f6b691575a32d0f66",
  measurementId: "G-22G7J83D4R"
};

const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getFirestore(app);
export const appId = 'riftr-v1';
