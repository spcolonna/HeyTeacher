const FEATURES = [
  {
    icon: '💼',
    title: 'Bolsa de trabajo',
    body: 'Encontrá vacantes de inglés filtradas por zona, turno y nivel, y postulate directamente con tu perfil profesional.',
  },
  {
    icon: '📚',
    title: "The Teacher's Toolbox",
    body: 'Compartí y descargá lesson plans, flashcards, worksheets e icebreakers creados por la comunidad.',
  },
  {
    icon: '🎓',
    title: 'Aula virtual',
    body: 'Organizá tus grupos y agendá clases con Google Meet, sincronizadas con tu calendario.',
  },
  {
    icon: '🎁',
    title: 'Beneficios exclusivos',
    body: 'Descuentos de nuestros partners, canjeables desde la app con tu código QR.',
  },
]

const FOR_TEACHERS = [
  'Postulate a vacantes que encajen con tu perfil',
  'Construí tu CV con certificaciones (FCE, CAE, TESOL, CELTA…)',
  'Seguí el estado de cada postulación',
  'Accedé a materiales de toda la comunidad',
]

const FOR_INSTITUTIONS = [
  'Publicá vacantes y llegá a profes calificados',
  'Revisá postulantes y sus perfiles completos',
  'Gestioná tu equipo docente en un lugar',
  'Construí el perfil de tu institución',
]

export default function Landing() {
  return (
    <div className="min-h-screen bg-white text-slate-900">
      {/* Nav */}
      <header className="sticky top-0 z-10 border-b border-slate-100 bg-white/80 backdrop-blur">
        <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">
          <div className="flex items-center gap-3">
            <img
              src="/logo.jpeg"
              alt="HeyTeacher"
              className="h-9 w-9 rounded-lg object-cover"
            />
            <span className="text-xl font-bold text-brand">HeyTeacher!</span>
          </div>
          <a
            href="#descargar"
            className="rounded-full bg-brand px-5 py-2 text-sm font-semibold text-white transition hover:bg-brand-dark"
          >
            Descargar
          </a>
        </div>
      </header>

      {/* Hero */}
      <section className="bg-gradient-to-br from-brand to-brand-cyan px-6 py-24 text-white">
        <div className="mx-auto max-w-3xl text-center">
          <img
            src="/logo.jpeg"
            alt="HeyTeacher"
            className="mx-auto mb-8 h-24 w-24 rounded-2xl object-cover shadow-2xl ring-4 ring-white/20"
          />
          <p className="mb-4 text-sm font-semibold uppercase tracking-[0.2em] text-white/70">
            Connect · Teach · Grow
          </p>
          <h1 className="text-4xl font-extrabold leading-tight sm:text-5xl">
            La comunidad de profesores de inglés de Uruguay
          </h1>
          <p className="mx-auto mt-6 max-w-2xl text-lg text-white/90">
            HeyTeacher conecta docentes con instituciones educativas. Encontrá tu
            próximo trabajo, compartí materiales y crecé profesionalmente — todo
            en una sola app.
          </p>
          <div className="mt-10 flex flex-wrap justify-center gap-4" id="descargar">
            <a
              href="https://apps.apple.com/app/heyteacher"
              className="rounded-xl bg-white px-6 py-3 font-semibold text-brand shadow-lg transition hover:bg-slate-50"
            >
               Descargar en el App Store
            </a>
            <span className="rounded-xl border border-white/40 px-6 py-3 font-semibold text-white/80">
              ▶ Google Play — próximamente
            </span>
          </div>
        </div>
      </section>

      {/* Features */}
      <section className="mx-auto max-w-6xl px-6 py-20">
        <h2 className="text-center text-3xl font-bold">Todo lo que necesitás</h2>
        <div className="mt-12 grid gap-8 sm:grid-cols-2 lg:grid-cols-4">
          {FEATURES.map((f) => (
            <div key={f.title} className="rounded-2xl border border-slate-100 p-6 shadow-sm">
              <div className="text-3xl">{f.icon}</div>
              <h3 className="mt-4 text-lg font-semibold">{f.title}</h3>
              <p className="mt-2 text-sm leading-relaxed text-slate-600">{f.body}</p>
            </div>
          ))}
        </div>
      </section>

      {/* Audiences */}
      <section className="bg-slate-50 px-6 py-20">
        <div className="mx-auto grid max-w-5xl gap-8 md:grid-cols-2">
          <AudienceCard title="Para profesores" items={FOR_TEACHERS} />
          <AudienceCard title="Para instituciones" items={FOR_INSTITUTIONS} />
        </div>
      </section>

      {/* CTA */}
      <section className="px-6 py-20 text-center">
        <h2 className="text-3xl font-bold">Sumate hoy</h2>
        <p className="mx-auto mt-4 max-w-xl text-slate-600">
          Creá tu cuenta gratis con tu email o tu cuenta de Google y dá el próximo
          paso en tu carrera docente.
        </p>
        <a
          href="https://apps.apple.com/app/heyteacher"
          className="mt-8 inline-block rounded-xl bg-brand px-8 py-4 font-semibold text-white shadow-lg transition hover:bg-brand-dark"
        >
          Descargar HeyTeacher!
        </a>
      </section>

      {/* Footer */}
      <footer className="border-t border-slate-100 px-6 py-10">
        <div className="mx-auto flex max-w-6xl flex-col items-center justify-between gap-4 text-sm text-slate-500 sm:flex-row">
          <span>© {new Date().getFullYear()} HeyTeacher</span>
          <nav className="flex gap-6">
            <a className="hover:text-brand" href="https://spcolonna.github.io/heyteacher-support/privacy.html">
              Privacidad
            </a>
            <a className="hover:text-brand" href="https://spcolonna.github.io/heyteacher-support/terms.html">
              Términos
            </a>
            <a className="hover:text-brand" href="mailto:spcolonna@gmail.com">
              Soporte
            </a>
          </nav>
        </div>
      </footer>
    </div>
  )
}

function AudienceCard({ title, items }: { title: string; items: string[] }) {
  return (
    <div className="rounded-2xl bg-white p-8 shadow-sm">
      <h3 className="text-xl font-bold text-brand">{title}</h3>
      <ul className="mt-6 space-y-3">
        {items.map((item) => (
          <li key={item} className="flex gap-3 text-slate-700">
            <span className="text-brand">✓</span>
            <span>{item}</span>
          </li>
        ))}
      </ul>
    </div>
  )
}
