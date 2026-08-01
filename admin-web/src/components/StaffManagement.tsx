// Mirrors the real institution staff system: lib/models/institution_staff.dart
// (StaffStatus: pending → accepted/removed, with levels[], removalReason,
// removalRating) and lib/screens/institution/manage_staff_screen.dart.

const BENEFITS = [
  {
    icon: '👥',
    title: 'Un roster, no una carpeta de emails',
    body: 'Todo tu equipo docente en un solo lugar, con su estado y sus datos de contacto.',
  },
  {
    icon: '🎯',
    title: 'Niveles asignados por docente',
    body: 'Definí qué niveles enseña cada profe (Kinder, Primary, Secondary, Adults) para organizar mejor la asignación de grupos.',
  },
  {
    icon: '📁',
    title: 'Materiales exclusivos del equipo',
    body: 'Compartí recursos que solo ve tu staff, además del banco público de materiales.',
  },
  {
    icon: '📋',
    title: 'Historial de bajas documentado',
    body: 'Si un docente deja de trabajar con vos, quedan registrados el motivo y una calificación — con contexto para el futuro.',
  },
]

export default function StaffManagement() {
  return (
    <section className="bg-slate-50 px-6 py-20">
      <div className="mx-auto grid max-w-6xl gap-12 md:grid-cols-2 md:items-center">
        {/* Text */}
        <div>
          <span className="inline-block rounded-full bg-brand-accent/10 px-3 py-1 text-xs font-bold uppercase tracking-wide text-brand-accent">
            Para instituciones
          </span>
          <h2 className="mt-4 text-3xl font-bold">Administrá tu equipo docente</h2>
          <p className="mt-3 text-slate-500">
            Más que publicar vacantes: HeyTeacher te da un panel real para gestionar a
            las personas que ya trabajan con vos.
          </p>

          <div className="mt-8 space-y-6">
            {BENEFITS.map((b) => (
              <div key={b.title} className="flex gap-4">
                <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-white text-lg shadow-sm">
                  {b.icon}
                </span>
                <div>
                  <h3 className="font-semibold text-slate-900">{b.title}</h3>
                  <p className="mt-0.5 text-sm leading-relaxed text-slate-500">{b.body}</p>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Mini roster mockup */}
        <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-xl">
          <div className="mb-3 flex items-center justify-between">
            <span className="text-sm font-bold text-slate-900">Manage Staff</span>
            <span className="rounded-full bg-brand px-3 py-1 text-[10px] font-bold text-white">
              + Add Teacher
            </span>
          </div>

          <p className="mb-2 text-[10px] font-bold uppercase tracking-wide text-slate-400">
            Pending requests
          </p>
          <RosterCard
            name="Camila Fernández"
            email="camila.f@gmail.com"
            badge={{ label: 'Pending', tone: 'bg-amber-50 text-amber-700 border-amber-200' }}
          />

          <p className="mb-2 mt-4 text-[10px] font-bold uppercase tracking-wide text-slate-400">
            Active staff
          </p>
          <RosterCard
            name="Rodrigo Blanco"
            email="rodrigo.b@gmail.com"
            levels={['Primary', 'Secondary']}
          />
          <RosterCard name="Valentina Souza" email="vale.souza@gmail.com" levels={['Adults']} />
        </div>
      </div>
    </section>
  )
}

function RosterCard({
  name,
  email,
  levels,
  badge,
}: {
  name: string
  email: string
  levels?: string[]
  badge?: { label: string; tone: string }
}) {
  return (
    <div className="mb-2 flex items-center gap-3 rounded-xl border border-slate-100 p-3">
      <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-brand/10 text-xs font-bold text-brand">
        {name[0]}
      </div>
      <div className="min-w-0 flex-1">
        <p className="truncate text-xs font-semibold text-slate-900">{name}</p>
        <p className="truncate text-[10px] text-slate-400">{email}</p>
      </div>
      {badge && (
        <span className={`shrink-0 rounded-full border px-2 py-0.5 text-[9px] font-bold ${badge.tone}`}>
          {badge.label}
        </span>
      )}
      {levels && (
        <div className="flex shrink-0 gap-1">
          {levels.map((l) => (
            <span
              key={l}
              className="rounded-full bg-slate-100 px-2 py-0.5 text-[9px] font-medium text-slate-600"
            >
              {l}
            </span>
          ))}
        </div>
      )}
    </div>
  )
}
