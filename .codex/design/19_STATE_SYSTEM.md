# State System

Every shipping surface defines loading, empty, error, ready and disabled/locked behavior where applicable. Background refresh should preserve usable content. Optimistic visual updates are allowed only when the domain supports rollback and must never bypass trusted success semantics. `AppStateSwitcher`/equivalent state composition should keep spatial stability.
