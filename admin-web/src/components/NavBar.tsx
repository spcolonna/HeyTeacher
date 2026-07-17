import { NavLink } from 'react-router-dom'

const TABS = [
  { to: 'materials', label: 'Materiales' },
  { to: 'jobs', label: 'Ofertas' },
  { to: 'users', label: 'Cuentas' },
  { to: 'benefits', label: 'Beneficios' },
]

export default function NavBar({
  email,
  onSignOut,
}: {
  email: string
  onSignOut: () => void
}) {
  return (
    <header className="border-b border-slate-800 bg-slate-900">
      <div className="mx-auto flex max-w-7xl flex-wrap items-center gap-4 px-6 py-4">
        <span className="font-bold text-white">HeyTeacher Admin</span>
        <nav className="flex flex-1 gap-1">
          {TABS.map((t) => (
            <NavLink
              key={t.to}
              to={t.to}
              className={({ isActive }) =>
                `rounded-lg px-4 py-2 text-sm font-medium transition ${
                  isActive
                    ? 'bg-brand text-white'
                    : 'text-slate-400 hover:bg-slate-800 hover:text-white'
                }`
              }
            >
              {t.label}
            </NavLink>
          ))}
        </nav>
        <span className="text-xs text-slate-500">{email}</span>
        <button
          onClick={onSignOut}
          className="rounded-lg bg-slate-800 px-3 py-1.5 text-xs text-slate-300 transition hover:bg-slate-700"
        >
          Salir
        </button>
      </div>
    </header>
  )
}
