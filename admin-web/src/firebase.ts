import { initializeApp } from 'firebase/app'
import { getAuth, GoogleAuthProvider } from 'firebase/auth'
import { getFirestore } from 'firebase/firestore'

// These values are public by design in Firebase web apps — security is
// enforced by Firestore Rules (see firestore.rules), never by hiding this.
const firebaseConfig = {
  apiKey: 'AIzaSyAyRdPEWtlI8_1F_ZxWy9-VAykMFxXwuhU',
  authDomain: 'heyteacher-3021b.firebaseapp.com',
  projectId: 'heyteacher-3021b',
  storageBucket: 'heyteacher-3021b.firebasestorage.app',
  messagingSenderId: '854565098615',
  appId: '1:854565098615:web:9882481ee8896eca94a272',
  measurementId: 'G-Q81ZPVGX6P',
}

const app = initializeApp(firebaseConfig)
export const auth = getAuth(app)
export const db = getFirestore(app)
export const googleProvider = new GoogleAuthProvider()

/// The only account allowed into /admin. This is a UX gate only —
/// the real enforcement lives in firestore.rules (server-side).
export const ADMIN_EMAIL = 'spcolonna@gmail.com'
