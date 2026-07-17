import { useState } from 'react'
import { deleteDoc, doc, updateDoc } from 'firebase/firestore'
import { db } from '../../firebase'
import { useCollection } from '../../useCollection'
import type { JobPosting, JobStatus } from '../../types'
import {
  Badge,
  Card,
  DangerButton,
  Empty,
  ErrorBox,
  Loading,
  PageHeader,
  Td,
  Th,
  fmtDate,
} from '../../components/Ui'

const STATUS_TONE: Record<JobStatus, 'success' | 'info' | 'neutral'> = {
  active: 'success',
  filled: 'info',
  closed: 'neutral',
}

export default function JobsPage() {
  const { items, error } = useCollection<JobPosting>('jobs', {
    orderByField: 'postedAt',
  })
  const [filter, setFilter] = useState<JobStatus | 'all'>('all')

  if (error) return <ErrorBox error={error} />
  if (!items) return <Loading />

  const filtered = filter === 'all' ? items : items.filter((j) => j.status === filter)

  async function setStatus(job: JobPosting, status: JobStatus) {
    try {
      await updateDoc(doc(db, 'jobs', job.id), { status })
    } catch (e) {
      alert(`No se pudo actualizar: ${(e as Error).message}`)
    }
  }

  async function remove(job: JobPosting) {
    const ok = confirm(
      `¿Eliminar la vacante "${job.jobTitle}" de ${job.institutionName}?\n\nEsta acción no se puede deshacer.`,
    )
    if (!ok) return
    try {
      await deleteDoc(doc(db, 'jobs', job.id))
    } catch (e) {
      alert(`No se pudo eliminar: ${(e as Error).message}`)
    }
  }

  return (
    <>
      <PageHeader title="Ofertas de trabajo" count={items.length} />

      <div className="mb-4 flex gap-2">
        {(['all', 'active', 'filled', 'closed'] as const).map((f) => (
          <button
            key={f}
            onClick={() => setFilter(f)}
            className={`rounded-lg px-3 py-1.5 text-xs font-medium transition ${
              filter === f
                ? 'bg-brand text-white'
                : 'bg-slate-900 text-slate-400 hover:bg-slate-800'
            }`}
          >
            {f === 'all' ? 'Todas' : f}
          </button>
        ))}
      </div>

      <Card>
        {filtered.length === 0 ? (
          <Empty>No hay vacantes con ese filtro.</Empty>
        ) : (
          <table className="w-full">
            <thead className="border-b border-slate-800">
              <tr>
                <Th>Puesto</Th>
                <Th>Institución</Th>
                <Th>Ubicación</Th>
                <Th>Estado</Th>
                <Th>Postulantes</Th>
                <Th>Publicada</Th>
                <Th>Acciones</Th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800/70">
              {filtered.map((j) => (
                <tr key={j.id} className="hover:bg-slate-800/30">
                  <Td>
                    <span className="font-medium text-white">{j.jobTitle}</span>
                    <p className="mt-0.5 line-clamp-1 max-w-sm text-xs text-slate-500">
                      {j.description}
                    </p>
                  </Td>
                  <Td>{j.institutionName}</Td>
                  <Td>{j.location}</Td>
                  <Td>
                    <Badge tone={STATUS_TONE[j.status] ?? 'neutral'}>{j.status}</Badge>
                  </Td>
                  <Td>{j.applicationsCount ?? 0}</Td>
                  <Td>{fmtDate(j.postedAt)}</Td>
                  <Td>
                    <div className="flex gap-2">
                      {j.status === 'active' ? (
                        <button
                          onClick={() => setStatus(j, 'closed')}
                          className="rounded-lg border border-slate-700 px-3 py-1.5 text-xs text-slate-300 transition hover:bg-slate-800"
                        >
                          Cerrar
                        </button>
                      ) : (
                        <button
                          onClick={() => setStatus(j, 'active')}
                          className="rounded-lg border border-slate-700 px-3 py-1.5 text-xs text-slate-300 transition hover:bg-slate-800"
                        >
                          Reabrir
                        </button>
                      )}
                      <DangerButton onClick={() => remove(j)}>Eliminar</DangerButton>
                    </div>
                  </Td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </Card>
    </>
  )
}
