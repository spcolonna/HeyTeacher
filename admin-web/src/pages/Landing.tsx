import AppShowcase from '../components/showcase/AppShowcase'
import ApplicationFlow from '../components/ApplicationFlow'
import StaffManagement from '../components/StaffManagement'

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
              href="https://apps.apple.com/uy/app/heyteacher/id6759878731"
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
        <p className="mx-auto mt-3 max-w-xl text-center text-slate-500">
          Un recorrido rápido por la app — tocá una tarjeta para saltar a esa pantalla.
        </p>
        <div className="mt-14">
          <AppShowcase />
        </div>
      </section>

      <ApplicationFlow />

      <StaffManagement />

      {/* CTA */}
      <section className="px-6 py-20 text-center">
        <h2 className="text-3xl font-bold">Sumate hoy</h2>
        <p className="mx-auto mt-4 max-w-xl text-slate-600">
          Creá tu cuenta gratis con tu email o tu cuenta de Google y dá el próximo
          paso en tu carrera docente.
        </p>
        <a
          href="https://apps.apple.com/uy/app/heyteacher/id6759878731"
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
