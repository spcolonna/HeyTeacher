import { useState } from 'react'
import {
  Timestamp,
  addDoc,
  collection,
  deleteDoc,
  doc,
  updateDoc,
} from 'firebase/firestore'
import { db } from '../../firebase'
import { useCollection } from '../../useCollection'
import {
  BENEFIT_CATEGORY_LABELS,
  type Benefit,
  type BenefitCategory,
} from '../../types'
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

type FormState = {
  sponsorName: string
  sponsorLogo: string
  title: string
  description: string
  discount: string
  category: BenefitCategory
  validUntil: string // yyyy-mm-dd (input[type=date])
  isActive: boolean
  termsAndConditions: string
  websiteUrl: string
}

const EMPTY_FORM: FormState = {
  sponsorName: '',
  sponsorLogo: '',
  title: '',
  description: '',
  discount: '',
  category: 'lifestyle',
  validUntil: '',
  isActive: true,
  termsAndConditions: '',
  websiteUrl: '',
}

export default function BenefitsPage() {
  const { items, error } = useCollection<Benefit>('benefits')
  const [editing, setEditing] = useState<Benefit | 'new' | null>(null)

  if (error) return <ErrorBox error={error} />
  if (!items) return <Loading />

  return (
    <>
      <div className="mb-6 flex items-center justify-between">
        <PageHeader title="Beneficios" count={items.length} />
        <button
          onClick={() => setEditing('new')}
          className="rounded-lg bg-brand px-4 py-2 text-sm font-semibold text-white transition hover:bg-brand-dark"
        >
          + Nuevo beneficio
        </button>
      </div>

      {editing && (
        <BenefitForm
          benefit={editing === 'new' ? null : editing}
          onClose={() => setEditing(null)}
        />
      )}

      <Card>
        {items.length === 0 ? (
          <Empty>Todavía no hay beneficios. Creá el primero.</Empty>
        ) : (
          <table className="w-full">
            <thead className="border-b border-slate-800">
              <tr>
                <Th>Sponsor</Th>
                <Th>Título</Th>
                <Th>Descuento</Th>
                <Th>Categoría</Th>
                <Th>Vence</Th>
                <Th>Estado</Th>
                <Th>Acciones</Th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800/70">
              {items.map((b) => (
                <tr key={b.id} className="hover:bg-slate-800/30">
                  <Td>
                    <div className="flex items-center gap-3">
                      {b.sponsorLogo && (
                        <img
                          src={b.sponsorLogo}
                          alt=""
                          className="h-8 w-8 rounded object-contain"
                        />
                      )}
                      <span className="font-medium text-white">{b.sponsorName}</span>
                    </div>
                  </Td>
                  <Td>{b.title}</Td>
                  <Td>
                    <Badge tone="warning">{b.discount}</Badge>
                  </Td>
                  <Td>{BENEFIT_CATEGORY_LABELS[b.category] ?? b.category}</Td>
                  <Td>{fmtDate(b.validUntil)}</Td>
                  <Td>
                    <Badge tone={b.isActive ? 'success' : 'neutral'}>
                      {b.isActive ? 'Activo' : 'Inactivo'}
                    </Badge>
                  </Td>
                  <Td>
                    <div className="flex gap-2">
                      <button
                        onClick={() => setEditing(b)}
                        className="rounded-lg border border-slate-700 px-3 py-1.5 text-xs text-slate-300 transition hover:bg-slate-800"
                      >
                        Editar
                      </button>
                      <button
                        onClick={() =>
                          updateDoc(doc(db, 'benefits', b.id), { isActive: !b.isActive })
                        }
                        className="rounded-lg border border-slate-700 px-3 py-1.5 text-xs text-slate-300 transition hover:bg-slate-800"
                      >
                        {b.isActive ? 'Desactivar' : 'Activar'}
                      </button>
                      <DangerButton
                        onClick={async () => {
                          if (!confirm(`¿Eliminar "${b.title}"?`)) return
                          try {
                            await deleteDoc(doc(db, 'benefits', b.id))
                          } catch (e) {
                            alert(`No se pudo eliminar: ${(e as Error).message}`)
                          }
                        }}
                      >
                        Eliminar
                      </DangerButton>
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

function BenefitForm({
  benefit,
  onClose,
}: {
  benefit: Benefit | null
  onClose: () => void
}) {
  const [form, setForm] = useState<FormState>(
    benefit
      ? {
          sponsorName: benefit.sponsorName,
          sponsorLogo: benefit.sponsorLogo ?? '',
          title: benefit.title,
          description: benefit.description,
          discount: benefit.discount,
          category: benefit.category,
          validUntil: benefit.validUntil
            ? benefit.validUntil.toDate().toISOString().slice(0, 10)
            : '',
          isActive: benefit.isActive,
          termsAndConditions: benefit.termsAndConditions ?? '',
          websiteUrl: benefit.websiteUrl ?? '',
        }
      : EMPTY_FORM,
  )
  const [saving, setSaving] = useState(false)

  const set = <K extends keyof FormState>(k: K, v: FormState[K]) =>
    setForm((f) => ({ ...f, [k]: v }))

  async function save(e: React.FormEvent) {
    e.preventDefault()
    setSaving(true)
    try {
      // Field names must match Benefit.fromFirestore() in lib/models/benefit.dart
      const payload = {
        sponsorName: form.sponsorName.trim(),
        sponsorLogo: form.sponsorLogo.trim(),
        title: form.title.trim(),
        description: form.description.trim(),
        discount: form.discount.trim(),
        category: form.category,
        validUntil: Timestamp.fromDate(new Date(form.validUntil)),
        isActive: form.isActive,
        termsAndConditions: form.termsAndConditions.trim() || null,
        websiteUrl: form.websiteUrl.trim() || null,
      }

      if (benefit) {
        await updateDoc(doc(db, 'benefits', benefit.id), payload)
      } else {
        await addDoc(collection(db, 'benefits'), payload)
      }
      onClose()
    } catch (err) {
      alert(`No se pudo guardar: ${(err as Error).message}`)
    } finally {
      setSaving(false)
    }
  }

  return (
    <form
      onSubmit={save}
      className="mb-6 space-y-4 rounded-xl border border-slate-800 bg-slate-900 p-6"
    >
      <h2 className="font-semibold text-white">
        {benefit ? `Editar: ${benefit.title}` : 'Nuevo beneficio'}
      </h2>

      <div className="grid gap-4 sm:grid-cols-2">
        <Field label="Sponsor *">
          <Input
            value={form.sponsorName}
            onChange={(v) => set('sponsorName', v)}
            required
          />
        </Field>
        <Field label="Título *">
          <Input value={form.title} onChange={(v) => set('title', v)} required />
        </Field>
        <Field label="Descuento *" hint='ej: "20% OFF", "1 mes gratis"'>
          <Input value={form.discount} onChange={(v) => set('discount', v)} required />
        </Field>
        <Field label="Categoría *">
          <select
            value={form.category}
            onChange={(e) => set('category', e.target.value as BenefitCategory)}
            className="w-full rounded-lg border border-slate-700 bg-slate-950 px-3 py-2 text-sm text-white focus:border-brand focus:outline-none"
          >
            {Object.entries(BENEFIT_CATEGORY_LABELS).map(([v, label]) => (
              <option key={v} value={v}>
                {label}
              </option>
            ))}
          </select>
        </Field>
        <Field label="Válido hasta *">
          <Input
            type="date"
            value={form.validUntil}
            onChange={(v) => set('validUntil', v)}
            required
          />
        </Field>
        <Field label="Logo (URL)" hint="URL pública de la imagen">
          <Input value={form.sponsorLogo} onChange={(v) => set('sponsorLogo', v)} />
        </Field>
        <Field label="Sitio web">
          <Input value={form.websiteUrl} onChange={(v) => set('websiteUrl', v)} />
        </Field>
      </div>

      <Field label="Descripción *">
        <textarea
          value={form.description}
          onChange={(e) => set('description', e.target.value)}
          required
          rows={2}
          className="w-full rounded-lg border border-slate-700 bg-slate-950 px-3 py-2 text-sm text-white focus:border-brand focus:outline-none"
        />
      </Field>

      <Field label="Términos y condiciones">
        <textarea
          value={form.termsAndConditions}
          onChange={(e) => set('termsAndConditions', e.target.value)}
          rows={2}
          className="w-full rounded-lg border border-slate-700 bg-slate-950 px-3 py-2 text-sm text-white focus:border-brand focus:outline-none"
        />
      </Field>

      <label className="flex items-center gap-2 text-sm text-slate-300">
        <input
          type="checkbox"
          checked={form.isActive}
          onChange={(e) => set('isActive', e.target.checked)}
          className="rounded"
        />
        Activo (visible en la app)
      </label>

      <div className="flex gap-3 pt-2">
        <button
          type="submit"
          disabled={saving}
          className="rounded-lg bg-brand px-5 py-2 text-sm font-semibold text-white transition hover:bg-brand-dark disabled:opacity-50"
        >
          {saving ? 'Guardando…' : 'Guardar'}
        </button>
        <button
          type="button"
          onClick={onClose}
          className="rounded-lg bg-slate-800 px-5 py-2 text-sm text-slate-300 transition hover:bg-slate-700"
        >
          Cancelar
        </button>
      </div>
    </form>
  )
}

function Field({
  label,
  hint,
  children,
}: {
  label: string
  hint?: string
  children: React.ReactNode
}) {
  return (
    <label className="block">
      <span className="mb-1 block text-xs font-medium text-slate-400">
        {label}
        {hint && <span className="ml-2 font-normal text-slate-600">{hint}</span>}
      </span>
      {children}
    </label>
  )
}

function Input({
  value,
  onChange,
  type = 'text',
  required = false,
}: {
  value: string
  onChange: (v: string) => void
  type?: string
  required?: boolean
}) {
  return (
    <input
      type={type}
      value={value}
      required={required}
      onChange={(e) => onChange(e.target.value)}
      className="w-full rounded-lg border border-slate-700 bg-slate-950 px-3 py-2 text-sm text-white focus:border-brand focus:outline-none"
    />
  )
}
