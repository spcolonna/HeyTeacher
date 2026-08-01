import { useEffect, useState } from 'react'
import { BottomNav, SCREENS } from './screens'

const CAPTIONS = [
  { icon: '💼', title: 'Bolsa de trabajo', body: 'Filtrá por zona, turno y nivel, y postulate con tu perfil.' },
  { icon: '📚', title: "Teacher's Toolbox", body: 'Compartí y descargá materiales creados por la comunidad.' },
  { icon: '🎓', title: 'Aula virtual', body: 'Agendá clases con Google Meet, sincronizadas a tu calendario.' },
  { icon: '🎁', title: 'Beneficios', body: 'Descuentos de partners, canjeables con tu código QR.' },
]

const INTERVAL_MS = 3200

export default function AppShowcase() {
  const [active, setActive] = useState(0)

  useEffect(() => {
    const id = setInterval(() => {
      setActive((i) => (i + 1) % SCREENS.length)
    }, INTERVAL_MS)
    return () => clearInterval(id)
  }, [])

  const { Component } = SCREENS[active]

  return (
    <div className="mx-auto flex max-w-5xl flex-col items-center gap-12 md:flex-row md:items-center md:justify-center">
      {/* Phone frame */}
      <div className="relative shrink-0">
        <div className="relative h-[560px] w-[280px] rounded-[2.5rem] border-[10px] border-slate-900 bg-slate-900 shadow-2xl">
          {/* Notch */}
          <div className="absolute left-1/2 top-0 z-10 h-5 w-28 -translate-x-1/2 rounded-b-2xl bg-slate-900" />
          {/* Screen */}
          <div className="relative h-full w-full overflow-hidden rounded-[2rem] bg-slate-50">
            <div className="flex h-full flex-col justify-between">
              <div key={active} className="flex-1 animate-showcase-fade overflow-hidden">
                <Component />
              </div>
              <BottomNav active={SCREENS[active].activeTab} />
            </div>
          </div>
        </div>

        {/* Dots */}
        <div className="mt-6 flex justify-center gap-2">
          {SCREENS.map((_, i) => (
            <button
              key={i}
              onClick={() => setActive(i)}
              aria-label={`Ver pantalla ${i + 1}`}
              className={`h-2 rounded-full transition-all ${
                i === active ? 'w-6 bg-brand' : 'w-2 bg-slate-300'
              }`}
            />
          ))}
        </div>
      </div>

      {/* Captions */}
      <div className="w-full max-w-sm space-y-3">
        {CAPTIONS.map((c, i) => (
          <button
            key={c.title}
            onClick={() => setActive(i)}
            className={`flex w-full items-start gap-4 rounded-2xl border p-4 text-left transition-all ${
              i === active
                ? 'border-brand/30 bg-brand/5 shadow-sm'
                : 'border-transparent hover:bg-slate-50'
            }`}
          >
            <span className="text-2xl">{c.icon}</span>
            <span>
              <span className={`block text-sm font-bold ${i === active ? 'text-brand' : 'text-slate-900'}`}>
                {c.title}
              </span>
              <span className="mt-0.5 block text-xs leading-relaxed text-slate-500">
                {c.body}
              </span>
            </span>
          </button>
        ))}
      </div>
    </div>
  )
}
