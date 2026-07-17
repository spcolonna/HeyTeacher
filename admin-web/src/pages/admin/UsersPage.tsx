import { useState } from 'react'
import { useCollection } from '../../useCollection'
import type { AppUser, UserType } from '../../types'
import {
  Badge,
  Card,
  Empty,
  ErrorBox,
  Loading,
  PageHeader,
  Td,
  Th,
  fmtDate,
} from '../../components/Ui'

const TYPE_TONE: Record<UserType, 'success' | 'info' | 'warning'> = {
  teacher: 'success',
  institution: 'info',
  admin: 'warning',
}

export default function UsersPage() {
  const { items, error } = useCollection<AppUser & { id: string }>('users', {
    orderByField: 'createdAt',
  })
  const [search, setSearch] = useState('')
  const [type, setType] = useState<UserType | 'all'>('all')

  if (error) return <ErrorBox error={error} />
  if (!items) return <Loading />

  const filtered = items.filter((u) => {
    const matchesType = type === 'all' || u.userType === type
    const matchesSearch = [u.displayName, u.email]
      .join(' ')
      .toLowerCase()
      .includes(search.toLowerCase())
    return matchesType && matchesSearch
  })

  return (
    <>
      <PageHeader title="Cuentas" count={items.length} />

      <div className="mb-4 flex flex-wrap gap-3">
        <input
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Buscar por nombre o email…"
          className="w-full max-w-xs rounded-lg border border-slate-800 bg-slate-900 px-4 py-2 text-sm text-white placeholder:text-slate-600 focus:border-brand focus:outline-none"
        />
        <div className="flex gap-2">
          {(['all', 'teacher', 'institution'] as const).map((t) => (
            <button
              key={t}
              onClick={() => setType(t)}
              className={`rounded-lg px-3 py-1.5 text-xs font-medium transition ${
                type === t
                  ? 'bg-brand text-white'
                  : 'bg-slate-900 text-slate-400 hover:bg-slate-800'
              }`}
            >
              {t === 'all' ? 'Todas' : t}
            </button>
          ))}
        </div>
      </div>

      <Card>
        {filtered.length === 0 ? (
          <Empty>No hay cuentas que coincidan.</Empty>
        ) : (
          <table className="w-full">
            <thead className="border-b border-slate-800">
              <tr>
                <Th>Usuario</Th>
                <Th>Email</Th>
                <Th>Tipo</Th>
                <Th>Verificado</Th>
                <Th>Alta</Th>
                <Th>UID</Th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800/70">
              {filtered.map((u) => (
                <tr key={u.id} className="hover:bg-slate-800/30">
                  <Td>
                    <div className="flex items-center gap-3">
                      {u.photoUrl ? (
                        <img
                          src={u.photoUrl}
                          alt=""
                          className="h-8 w-8 rounded-full object-cover"
                        />
                      ) : (
                        <div className="flex h-8 w-8 items-center justify-center rounded-full bg-slate-800 text-xs font-bold text-slate-400">
                          {(u.displayName || '?')[0].toUpperCase()}
                        </div>
                      )}
                      <span className="font-medium text-white">{u.displayName}</span>
                    </div>
                  </Td>
                  <Td>{u.email}</Td>
                  <Td>
                    <Badge tone={TYPE_TONE[u.userType] ?? 'neutral'}>{u.userType}</Badge>
                  </Td>
                  <Td>{u.isVerified ? '✓' : '—'}</Td>
                  <Td>{fmtDate(u.createdAt)}</Td>
                  <Td>
                    <code className="text-xs text-slate-600">{u.id.slice(0, 8)}…</code>
                  </Td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </Card>

      <p className="mt-4 text-xs text-slate-600">
        Borrar una cuenta requiere eliminarla también de Firebase Authentication, que
        no es accesible desde el navegador. Si necesitás esa función, se hace con una
        Cloud Function.
      </p>
    </>
  )
}
