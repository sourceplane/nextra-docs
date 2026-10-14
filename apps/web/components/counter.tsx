'use client'

// Upstream defined this component inline in pages/another.mdx. Nextra 4 renders
// MDX as React Server Components, where hooks are not available, so the same
// code lives here as a client component and the page imports it.
import { useState } from 'react'
import styles from './counters.module.css'

export const Counter = () => {
  const [count, setCount] = useState(0);
  return (
    <div>
      <button onClick={() => setCount(count + 1)} className={styles.counter}>Clicked {count} times</button>
    </div>
  );
};
