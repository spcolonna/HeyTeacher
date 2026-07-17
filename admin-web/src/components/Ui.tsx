import type { Timestamp } from 'firebase/firestore'

export function PageHeader({ title, count }: { title: string; count?: number }) {
  return (
    <div className="mb-6 flex items-baseline gap-3">
      <h1 className="text-2xl font-bold text-white">{title}</h1>
      {count !== undefined && (
        <span className="text-sm text-slate-500">{count} en total</span>
      )}
    </div>
  )
}

export function Card({ children }: { children: React.ReactNode }) {
  return (
    <div className="overflow-hidden rounded-xl border border-slate-800 bg-slate-900">
      {children}
    </div>
  )
}

export function Loading() {
  return <div className="p-10 text-center text-slate-500">Cargando…</div>
}

export function Empty({ children }: { children: React.ReactNode }) {
  return <div className="p-10 text-center text-slate-500">{children}</div>
}

export function ErrorBox({ error }: { error: string }) {
  return (
    <div className="rounded-xl border border-red-900 bg-red-950/40 p-6 text-red-300">
      <p className="font-semibold">No se pudieron cargar los datos</p>
      <p className="mt-1 text-sm text-red-400/80">{error}</p>
    </div>
  )
}

export function Th({ children }: { children: React.ReactNode }) {
  return (
    <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
      {children}
    </th>
  )
}

export function Td({ children }: { children: React.ReactNode }) {
  return <td className="px-4 py-3 align-top text-sm text-slate-300">{children}</td>
}

export function Badge({
  children,
  tone = 'neutral',
}: {
  children: React.ReactNode
  tone?: 'neutral' | 'success' | 'warning' | 'danger' | 'info'
}) {
  const tones = {
    neutral: 'bg-slate-800 text-slate-300',
    success: 'bg-emerald-950 text-emerald-400 border border-emerald-900',
    warning: 'bg-amber-950 text-amber-400 border border-amber-900',
    danger: 'bg-red-950 text-red-400 border border-red-900',
    info: 'bg-sky-950 text-sky-400 border border-sky-900',
  }
  return (
    <span className={`inline-block rounded-full px-2.5 py-0.5 text-xs font-medium ${tones[tone]}`}>
      {children}
    </span>
  )
}

export function DangerButton({
  onClick,
  children,
}: {
  onClick: () => void
  children: React.ReactNode
}) {
  return (
    <button
      onClick={onClick}
      className="rounded-lg border border-red-900 px-3 py-1.5 text-xs font-medium text-red-400 transition hover:bg-red-950"
    >
      {children}
    </button>
  )
}

export function fmtDate(ts?: Timestamp | null): string {
  if (!ts) return '—'
  return ts.toDate().toLocaleDateString('es-UY', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  })
}
