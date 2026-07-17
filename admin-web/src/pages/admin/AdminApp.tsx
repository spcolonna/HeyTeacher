import { useEffect, useState } from 'react'
import { Navigate, Route, Routes } from 'react-router-dom'
import { onAuthStateChanged, signInWithPopup, signOut, type User } from 'firebase/auth'
import { ADMIN_EMAIL, auth, googleProvider } from '../../firebase'
import NavBar from '../../components/NavBar'
import MaterialsPage from './MaterialsPage'
import JobsPage from './JobsPage'
import UsersPage from './UsersPage'
import BenefitsPage from './BenefitsPage'

export default function AdminApp() {
  // undefined = still resolving the auth state, null = signed out
  const [user, setUser] = useState<User | null | undefined>(undefined)

  useEffect(() => onAuthStateChanged(auth, setUser), [])

  if (user === undefined) return <Centered>Cargando…</Centered>

  if (!user) {
    return (
      <Centered>
        <div className="w-full max-w-sm space-y-6 rounded-2xl border border-slate-800 bg-slate-900 p-10 text-center shadow-2xl">
          <h1 className="text-2xl font-bold text-white">HeyTeacher Admin</h1>
          <p className="text-sm text-slate-400">Acceso restringido</p>
          <button
            onClick={() => signInWithPopup(auth, googleProvider)}
            className="w-full rounded-xl bg-brand px-8 py-3 font-semibold text-white transition hover:bg-brand-dark"
          >
            Iniciar sesión con Google
          </button>
        </div>
      </Centered>
    )
  }

  // UX gate only — Firestore Rules are what actually block non-admins.
  if (user.email !== ADMIN_EMAIL) {
    return (
      <Centered>
        <div className="w-full max-w-sm space-y-6 rounded-2xl border border-red-900 bg-slate-900 p-10 text-center shadow-2xl">
          <h1 className="text-xl font-bold text-red-400">Acceso denegado</h1>
          <p className="text-sm text-slate-400">
            {user.email} no tiene permisos de administrador.
          </p>
          <button
            onClick={() => signOut(auth)}
            className="rounded-xl bg-slate-700 px-6 py-2 text-white transition hover:bg-slate-600"
          >
            Cerrar sesión
          </button>
        </div>
      </Centered>
    )
  }

  return (
    <div className="min-h-screen bg-slate-950">
      <NavBar email={user.email!} onSignOut={() => signOut(auth)} />
      <main className="mx-auto max-w-7xl px-6 py-8">
        <Routes>
          <Route index element={<Navigate to="materials" replace />} />
          <Route path="materials" element={<MaterialsPage />} />
          <Route path="jobs" element={<JobsPage />} />
          <Route path="users" element={<UsersPage />} />
          <Route path="benefits" element={<BenefitsPage />} />
        </Routes>
      </main>
    </div>
  )
}

function Centered({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex min-h-screen items-center justify-center bg-slate-950 p-6 text-lg text-white">
      {children}
    </div>
  )
}
