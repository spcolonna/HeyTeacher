// Mirrors the real states in lib/models/job_application.dart
// (ApplicationStatus: pending → reviewed → accepted/rejected) and the
// tracking UI in my_applications_screen.dart / applicants_screen.dart.

const STEPS = [
  {
    icon: '📝',
    label: 'Postulás',
    tone: 'bg-slate-100 text-slate-600',
    body: 'Con un toque, la institución recibe tu perfil completo: CV, certificaciones y experiencia.',
  },
  {
    icon: '👀',
    label: 'En revisión',
    tone: 'bg-amber-50 text-amber-700',
    body: 'La institución ve tu perfil profesional entero — no solo un CV adjunto.',
  },
  {
    icon: '💬',
    label: 'Seguimiento',
    tone: 'bg-sky-50 text-sky-700',
    body: 'Podés ver el estado actualizado en cualquier momento, sin tener que preguntar.',
  },
  {
    icon: '✅',
    label: 'Resultado',
    tone: 'bg-emerald-50 text-emerald-700',
    body: 'Aceptada o rechazada, con nota de la institución si la dejaron. Sin postulaciones perdidas en un email.',
  },
]

export default function ApplicationFlow() {
  return (
    <section className="mx-auto max-w-6xl px-6 py-20">
      <div className="mx-auto max-w-2xl text-center">
        <span className="inline-block rounded-full bg-brand/10 px-3 py-1 text-xs font-bold uppercase tracking-wide text-brand">
          Para profesores
        </span>
        <h2 className="mt-4 text-3xl font-bold">Postulaciones con seguimiento real</h2>
        <p className="mt-3 text-slate-500">
          Nada de mandar un CV por email y no saber más nada. Cada postulación tiene un
          estado claro, de punta a punta.
        </p>
      </div>

      <div className="relative mt-14 grid gap-6 md:grid-cols-4">
        {/* Connecting line (desktop only) */}
        <div className="absolute left-0 right-0 top-8 hidden h-0.5 bg-slate-100 md:block" />

        {STEPS.map((s, i) => (
          <div key={s.label} className="relative flex flex-col items-center text-center">
            <div
              className={`z-10 flex h-16 w-16 items-center justify-center rounded-full text-2xl ring-8 ring-white ${s.tone}`}
            >
              {s.icon}
            </div>
            <span className="mt-4 text-xs font-bold uppercase tracking-wide text-slate-400">
              Paso {i + 1}
            </span>
            <h3 className="mt-1 font-bold text-slate-900">{s.label}</h3>
            <p className="mt-2 text-sm leading-relaxed text-slate-500">{s.body}</p>
          </div>
        ))}
      </div>
    </section>
  )
}
