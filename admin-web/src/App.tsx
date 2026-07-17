import { Suspense, lazy } from 'react'
import { BrowserRouter, Route, Routes } from 'react-router-dom'
import Landing from './pages/Landing'

// Lazy-loaded so the public landing never downloads the Firebase SDK —
// it ships in a separate chunk that only /admin visitors pay for.
const AdminApp = lazy(() => import('./pages/admin/AdminApp'))

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Landing />} />
        <Route
          path="/admin/*"
          element={
            <Suspense
              fallback={
                <div className="flex min-h-screen items-center justify-center bg-slate-950 text-white">
                  Cargando…
                </div>
              }
            >
              <AdminApp />
            </Suspense>
          }
        />
      </Routes>
    </BrowserRouter>
  )
}
