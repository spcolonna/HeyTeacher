import { useState } from 'react'
import { deleteDoc, doc } from 'firebase/firestore'
import { db } from '../../firebase'
import { useCollection } from '../../useCollection'
import { MATERIAL_CATEGORY_LABELS, type TeachingMaterial } from '../../types'
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

export default function MaterialsPage() {
  const { items, error } = useCollection<TeachingMaterial>('materials', {
    orderByField: 'uploadedAt',
  })
  const [search, setSearch] = useState('')

  if (error) return <ErrorBox error={error} />
  if (!items) return <Loading />

  const filtered = items.filter((m) =>
    [m.title, m.uploaderName, ...(m.tags ?? [])]
      .join(' ')
      .toLowerCase()
      .includes(search.toLowerCase()),
  )

  async function remove(m: TeachingMaterial) {
    const ok = confirm(
      `¿Eliminar "${m.title}" de ${m.uploaderName}?\n\nEsta acción no se puede deshacer.`,
    )
    if (!ok) return
    try {
      await deleteDoc(doc(db, 'materials', m.id))
    } catch (e) {
      alert(`No se pudo eliminar: ${(e as Error).message}`)
    }
  }

  return (
    <>
      <PageHeader title="Materiales" count={items.length} />

      <input
        value={search}
        onChange={(e) => setSearch(e.target.value)}
        placeholder="Buscar por título, autor o tag…"
        className="mb-4 w-full max-w-md rounded-lg border border-slate-800 bg-slate-900 px-4 py-2 text-sm text-white placeholder:text-slate-600 focus:border-brand focus:outline-none"
      />

      <Card>
        {filtered.length === 0 ? (
          <Empty>No hay materiales que coincidan.</Empty>
        ) : (
          <table className="w-full">
            <thead className="border-b border-slate-800">
              <tr>
                <Th>Título</Th>
                <Th>Categoría</Th>
                <Th>Autor</Th>
                <Th>Origen</Th>
                <Th>Subido</Th>
                <Th>Descargas</Th>
                <Th>Acciones</Th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800/70">
              {filtered.map((m) => (
                <tr key={m.id} className="hover:bg-slate-800/30">
                  <Td>
                    <span className="font-medium text-white">{m.title}</span>
                    <p className="mt-0.5 line-clamp-1 max-w-md text-xs text-slate-500">
                      {m.description}
                    </p>
                  </Td>
                  <Td>
                    <Badge>{MATERIAL_CATEGORY_LABELS[m.category] ?? m.category}</Badge>
                  </Td>
                  <Td>{m.uploaderName}</Td>
                  <Td>
                    {m.institutionName ? (
                      <Badge tone="info">{m.institutionName}</Badge>
                    ) : (
                      <Badge tone="success">Público</Badge>
                    )}
                  </Td>
                  <Td>{fmtDate(m.uploadedAt)}</Td>
                  <Td>{m.downloadCount ?? 0}</Td>
                  <Td>
                    <div className="flex gap-2">
                      {m.fileUrl && (
                        <a
                          href={m.fileUrl}
                          target="_blank"
                          rel="noreferrer"
                          className="rounded-lg border border-slate-700 px-3 py-1.5 text-xs text-slate-300 transition hover:bg-slate-800"
                        >
                          Ver
                        </a>
                      )}
                      <DangerButton onClick={() => remove(m)}>Eliminar</DangerButton>
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
