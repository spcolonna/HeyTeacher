import { useEffect, useState } from 'react'
import {
  collection,
  onSnapshot,
  orderBy,
  query,
  type QueryConstraint,
} from 'firebase/firestore'
import { db } from './firebase'

/// Live-subscribes to a Firestore collection and maps each doc to `{ id, ...data }`.
/// Returns the same shape for every admin page so they stay consistent.
export function useCollection<T extends { id: string }>(
  path: string,
  opts: { orderByField?: string; desc?: boolean } = {},
) {
  const [items, setItems] = useState<T[] | undefined>(undefined)
  const [error, setError] = useState<string | null>(null)

  const { orderByField, desc = true } = opts

  useEffect(() => {
    const constraints: QueryConstraint[] = orderByField
      ? [orderBy(orderByField, desc ? 'desc' : 'asc')]
      : []

    const unsub = onSnapshot(
      query(collection(db, path), ...constraints),
      (snap) => {
        setItems(snap.docs.map((d) => ({ id: d.id, ...d.data() }) as unknown as T))
        setError(null)
      },
      (err) => setError(err.message),
    )
    return unsub
  }, [path, orderByField, desc])

  return { items, error }
}
