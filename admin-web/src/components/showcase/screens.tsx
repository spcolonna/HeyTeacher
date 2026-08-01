// Faithful recreations of the real app screens (colors/typography/layout
// mirror lib/theme/palettes.dart "horizon" + lib/screens/*), built as static
// HTML/CSS so the landing never depends on live app screenshots.

function StatusBar() {
  return (
    <div className="flex items-center justify-between px-5 pb-1 pt-3 text-[11px] font-semibold text-slate-900">
      <span>9:41</span>
      <span className="flex items-center gap-1">
        <span>􀙇</span>
        <span>􀙚</span>
        <span>􀛨</span>
      </span>
    </div>
  )
}

function AppBar({ title }: { title: string }) {
  return (
    <div className="px-5 pb-3 pt-1 text-center text-[15px] font-bold text-slate-900">
      {title}
    </div>
  )
}

function BottomNav({ active }: { active: 0 | 1 | 2 | 3 }) {
  const items = [
    { icon: '💼', label: 'Jobs' },
    { icon: '📁', label: 'Materials' },
    { icon: '🎓', label: 'Classroom' },
    { icon: '🎁', label: 'Benefits' },
  ]
  return (
    <div className="mx-3 mb-3 flex items-center justify-around rounded-full bg-white px-2 py-2.5 shadow-lg">
      {items.map((it, i) => (
        <div
          key={it.label}
          className={`flex flex-col items-center gap-0.5 rounded-full px-2.5 py-1 text-[9px] font-semibold transition-colors ${
            i === active ? 'bg-brand/15 text-brand' : 'text-slate-400'
          }`}
        >
          <span className="text-sm leading-none">{it.icon}</span>
          {it.label}
        </div>
      ))}
    </div>
  )
}

function Chip({ children }: { children: React.ReactNode }) {
  return (
    <span className="rounded-full border border-slate-200 bg-white px-2 py-0.5 text-[9px] font-medium text-slate-600">
      {children}
    </span>
  )
}

function StatusPill({
  children,
  tone = 'success',
}: {
  children: React.ReactNode
  tone?: 'success' | 'accent'
}) {
  const tones =
    tone === 'success'
      ? 'bg-emerald-50 text-emerald-700 border-emerald-200'
      : 'bg-orange-50 text-brand-accent border-orange-200'
  return (
    <span className={`rounded-full border px-2 py-0.5 text-[9px] font-bold ${tones}`}>
      {children}
    </span>
  )
}

// ── Screen 1: Job Board ──────────────────────────────────────────────
export function JobsScreenMock() {
  const jobs = [
    {
      title: 'English Teacher — Primary',
      inst: 'Colegio San José',
      loc: 'Pocitos',
      shift: 'Morning',
      levels: ['Primary', 'Kinder'],
      apps: 12,
    },
    {
      title: 'Business English Coach',
      inst: 'Corporate Language Hub',
      loc: 'Centro',
      shift: 'Evening',
      levels: ['Adults'],
      apps: 4,
    },
    {
      title: 'Secondary English Teacher',
      inst: 'Liceo Nº 3',
      loc: 'Carrasco',
      shift: 'Afternoon',
      levels: ['Secondary'],
      apps: 8,
    },
  ]
  return (
    <Screen>
      <AppBar title="Job Board" />
      <div className="mx-4 mb-3 rounded-xl bg-slate-100 px-3 py-2 text-[10px] text-slate-400">
        🔍 Search jobs…
      </div>
      <div className="flex flex-col gap-2.5 px-4">
        {jobs.map((j) => (
          <div key={j.title} className="rounded-2xl bg-white p-3 shadow-sm">
            <div className="flex items-start justify-between gap-2">
              <span className="text-[11px] font-bold leading-tight text-slate-900">
                {j.title}
              </span>
              <StatusPill>Active</StatusPill>
            </div>
            <p className="mt-0.5 text-[10px] text-slate-500">{j.inst}</p>
            <p className="mt-1.5 text-[9px] text-slate-400">
              📍 {j.loc} &nbsp;·&nbsp; 🕐 {j.shift}
            </p>
            <div className="mt-2 flex flex-wrap gap-1">
              {j.levels.map((l) => (
                <Chip key={l}>{l}</Chip>
              ))}
            </div>
            <p className="mt-2 text-[9px] font-semibold text-brand">
              {j.apps} applications
            </p>
          </div>
        ))}
      </div>
    </Screen>
  )
}

// ── Screen 2: Teacher's Toolbox ──────────────────────────────────────
export function MaterialsScreenMock() {
  const materials = [
    { title: 'Animals Flashcards', by: 'Sarah M.', color: 'from-brand to-brand-cyan', icon: '🃏' },
    { title: 'Present Simple WS', by: 'Diego R.', color: 'from-orange-400 to-brand-accent', icon: '📄' },
    { title: 'Ice Breaker Games', by: 'Ana P.', color: 'from-purple-400 to-purple-600', icon: '🎉' },
    { title: 'Grammar Lesson Plan', by: 'Marcos L.', color: 'from-brand-cyan to-blue-500', icon: '📘' },
  ]
  return (
    <Screen>
      <AppBar title="Teacher's Toolbox" />
      <div className="mb-3 flex gap-1.5 overflow-hidden px-4">
        {['All', 'Flashcards', 'Worksheets', 'Games'].map((c, i) => (
          <span
            key={c}
            className={`whitespace-nowrap rounded-full px-2.5 py-1 text-[9px] font-semibold ${
              i === 0 ? 'bg-brand text-white' : 'bg-slate-100 text-slate-500'
            }`}
          >
            {c}
          </span>
        ))}
      </div>
      <div className="grid grid-cols-2 gap-2.5 px-4">
        {materials.map((m) => (
          <div key={m.title} className="overflow-hidden rounded-2xl bg-white shadow-sm">
            <div
              className={`flex h-16 items-center justify-center bg-gradient-to-br text-2xl ${m.color}`}
            >
              {m.icon}
            </div>
            <div className="p-2">
              <p className="text-[10px] font-bold leading-tight text-slate-900">{m.title}</p>
              <p className="mt-0.5 text-[9px] text-slate-400">By {m.by}</p>
            </div>
          </div>
        ))}
      </div>
    </Screen>
  )
}

// ── Screen 3: Virtual Classroom ──────────────────────────────────────
export function ClassroomScreenMock() {
  const groups = [
    { name: 'Beginners A1', students: 8, next: 'Today, 6:00 PM' },
    { name: 'Business English', students: 5, next: 'Tomorrow, 9:00 AM' },
  ]
  return (
    <Screen>
      <AppBar title="Virtual Classroom" />
      <div className="mx-4 mb-3 rounded-xl border border-brand/20 bg-brand/5 px-3 py-2 text-[9px] text-brand">
        📅 Connected to Google Calendar
      </div>
      <div className="flex flex-col gap-2.5 px-4">
        {groups.map((g) => (
          <div key={g.name} className="rounded-2xl bg-white p-3 shadow-sm">
            <div className="flex items-center justify-between">
              <span className="text-[11px] font-bold text-slate-900">{g.name}</span>
              <Chip>{g.students} students</Chip>
            </div>
            <div className="mt-2.5 flex items-center justify-between rounded-xl bg-slate-50 px-2.5 py-2">
              <div>
                <p className="text-[8px] font-semibold uppercase tracking-wide text-slate-400">
                  Next session
                </p>
                <p className="text-[10px] font-semibold text-slate-700">{g.next}</p>
              </div>
              <span className="rounded-full bg-emerald-500 px-2.5 py-1 text-[9px] font-bold text-white">
                🎥 Meet
              </span>
            </div>
          </div>
        ))}
        <div className="rounded-2xl border-2 border-dashed border-slate-200 p-4 text-center text-[10px] font-semibold text-slate-400">
          + Create new group
        </div>
      </div>
    </Screen>
  )
}

// ── Screen 4: Benefits ───────────────────────────────────────────────
export function BenefitsScreenMock() {
  const benefits = [
    { sponsor: 'BookNook Café', title: '15% off all day', color: 'from-brand to-brand-cyan' },
    { sponsor: 'LinguaPress', title: '2 months free', color: 'from-brand-accent to-orange-400' },
    { sponsor: 'TeachHub Pro', title: '30% off yearly plan', color: 'from-purple-400 to-brand-cyan' },
  ]
  return (
    <Screen>
      <AppBar title="Benefits" />
      <div className="flex flex-col gap-2.5 px-4">
        {benefits.map((b) => (
          <div
            key={b.sponsor}
            className={`overflow-hidden rounded-2xl bg-gradient-to-br p-3.5 text-white shadow-sm ${b.color}`}
          >
            <p className="text-[9px] font-medium text-white/80">{b.sponsor}</p>
            <p className="mt-1 text-[12px] font-bold">{b.title}</p>
            <span className="mt-2 inline-block rounded-full bg-white/20 px-2 py-0.5 text-[8px] font-semibold">
              📱 Show QR to redeem
            </span>
          </div>
        ))}
      </div>
    </Screen>
  )
}

function Screen({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex h-full w-full flex-col bg-slate-50 pt-1">
      <StatusBar />
      {children}
    </div>
  )
}

export const SCREENS = [
  { Component: JobsScreenMock, activeTab: 0 as const },
  { Component: MaterialsScreenMock, activeTab: 1 as const },
  { Component: ClassroomScreenMock, activeTab: 2 as const },
  { Component: BenefitsScreenMock, activeTab: 3 as const },
]

export { BottomNav }
