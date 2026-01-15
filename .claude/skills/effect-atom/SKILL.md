---
name: effect-atom
description: >
  Patterns and best practices for @effect-atom/atom state management.
  Use when implementing Effect atoms, React state sync, async operations, reactive patterns, or dependency injection.
  Extract patterns for local state, async sync, dual-phase atoms, query/command separation, persistent state, stream data loading, and HTTP API integration.
  Update existing Effect atom implementations with best practices.
  Requires @effect-atom/atom package.
allowed-tools:
  - Read
  - Grep
  - Glob
context: fork
---

# Effect Atom Patterns

Patterns and best practices for working with @effect-atom/atom in Effect applications.

See [EXAMPLES.md](EXAMPLES.md) for detailed code examples.

## Pattern 1: Simple Local State

**Use when**: You need basic component or app-level state (counter, toggle, form inputs).

**Key principle**: Use `Atom.writable` for simple mutable state with get/set operations.

**Structure**:
- Define with `Atom.writable(init, write)` where:
  - `init`: Function returning initial value
  - `write`: Function `(ctx, value) => void` to handle updates
- Access with `useAtom(atom)` for read/write
- Access with `useAtomValue(atom)` for read-only
- Update with `useAtomSet(atom)` for write-only

---

## Pattern 2: Async State Synchronization

**Use when**: Local state needs to sync to server with batching, retries, or optimistic updates.

**Key principle**: Combine local optimistic state with background queue processing using `runtime.atom` and `Stream` for reliable server sync.

**Structure**:
1. Create queue-based processor atom with `runtime.atom(Effect.gen(...))`
2. Use `Queue.unbounded<T>()` for buffering updates
3. Process with `Stream.fromQueue(queue).pipe(Stream.groupedWithin(...))`
4. Add retry logic with `Effect.retry({ times, schedule })`
5. Handle optimistic updates in React state
6. Sync via `queue.unsafeOffer(value)` when Result is Success

**Components**:
- **Processor Atom**: Background Effect managing queue and API calls
- **Local State**: Optimistic updates with React.useState
- **Sync Logic**: Queue offers with retry/batching

---

## Pattern 3: Dual-Phase Atom (Immediate Access + Async Updates)

**Use when**: You need immediate synchronous access to a value, but it updates asynchronously.

**Example use cases**: Navigation ref, router location, external listeners.

**Key principle**: Never block atom creation. Return synchronous value immediately, subscribe to updates via `get.addFinalizer()`.

**Structure**:
- Use `Atom.make((get) => ...)` with initial sync value
- Register cleanup/subscriptions with `get.addFinalizer(...)`
- Update atom with `get.setSelf(...)` in listener callbacks

---

## Pattern 4: Runtime-Based Dependency Injection

**Use when**: Atoms need to consume other atoms as Effect Layer dependencies.

**Key principle**: Create `Atom.runtime` that reads atoms and injects them as Effect Context/Layer dependencies.

**Structure**:
- Create `Atom.runtime((get) => ...)` to build Layer from atoms
- Read atoms with `get(otherAtom)`
- Use `pipe` with `Layer.provide`, `Layer.provideMerge`, `Layer.succeed`
- Access services in atoms via `yield* ServiceTag`

---

## Pattern 5: Query vs Command Separation

**Use when**: Distinguishing read operations (queries) from write operations (commands).

### Query Pattern (Cached Reads)

**Characteristics**:
- Returns `Result<Loading|Error|Success<T>>`
- Cached with TTL
- Synchronous atom access
- No side effects
- Use `ApiClient.query("method", params, { timeToLive: "10 minutes" })`

### Command Pattern (Async Actions)

**Characteristics**:
- Uses `runtime.atom(Effect...)`
- Performs side effects
- Returns `Result<T>` that resolves when Effect completes
- Use `Effect.fnUntraced(function* (get) { ... })` for generator effects

---

## Pattern 6: KVS Pattern (Persistent State)

**Use when**: State needs to persist across app restarts.

**Key principle**: Use `Atom.kvs` with schema validation for persistent state. Add `pipe(..., Atom.keepAlive)` to prevent garbage collection.

**Structure**:
1. Create shared KVS runtime: `Atom.runtime(BrowserKeyValueStore.layerLocalStorage)`
2. Use in atoms with `Atom.kvs({ runtime, key, schema, defaultValue })`
3. Wrap with `pipe(..., Atom.keepAlive)` for long-lived state

---

## Pattern 7: Result Pattern (Non-Throwing Async)

**Use when**: Async operations should not throw/suspend rendering.

**Key principle**: Return `Result<T>` immediately with loading/error/success states. Never throw Promises or block rendering.

**Usage in React**:
- Use `Result.match(result, { onLoading, onError, onSuccess })`
- Handle all three states explicitly
- Provide fallback to cached data when loading

---

## Pattern 8: Atom.family for Parameterized Atoms

**Use when**: Creating atoms dynamically based on parameters (IDs, keys).

**Characteristics**:
- Memoized per unique parameter
- Garbage collected when idle (use `setIdleTTL` or `keepAlive`)
- Type-safe parameter constraints
- Use `Atom.family((param) => pipe(...))`

---

## Pattern 9: Derived/Computed Atoms

**Use when**: Computing values from other atoms without side effects.

**Key principle**: Use `Atom.make((get) => ...)` for pure transformations of other atom values. Automatically updates when dependencies change.

**Structure**:
- Read dependencies with `get(otherAtom)`
- Perform pure computation
- Return computed value
- Combine with `Atom.family` for parameterized derived atoms

---

## Pattern 10: Atom.fnSync for Imperative Actions

**Use when**: User actions need to trigger effects (not just read state).

**Key principle**: `Atom.fnSync` + `useAtomSet` for actions. `Atom.writable` for simple state mutations. Trigger Effects via `get(runtime.atom(...))`.

**Structure**:
- Define with `Atom.fnSync((args, get) => { ... })`
- Call `get(runtime.atom(Effect...))` inside for async work
- Use `useAtomSet(actionAtom)` hook in components
- Call action in event handlers

---

## Pattern 11: Stream-Based Data Loading

**Use when**: Loading paginated/streaming data from server.

**Key principle**: Use `runtime.pull` with `Stream` for continuous data. Use `Mailbox` to buffer chunks. Fork background task with `Effect.forkScoped`.

**Structure**:
- Use `runtime.pull(Stream.paginateEffect(...))` for infinite scroll
- Use `Stream.fromQueue` for queue-based streams
- Create `Mailbox` for buffering: `yield* Mailbox.make<T>(bufferSize)`
- Loop to fetch data and `yield* mailbox.offerAll(data)`
- Fork with `pipe(..., Mailbox.into(mailbox), Effect.forkScoped)`
- Return `Mailbox.toStream(mailbox)`
- Wrap with `pipe(..., Atom.keepAlive)`

---

## Pattern 12: Effect Layer Composition

**Use when**: Building modular runtime dependencies.

**Key principle**: Compose layers with `Layer.merge`, `Layer.provide`, `Layer.provideMerge`. Create runtime once, reuse for multiple atoms accessing same services.

**Structure**:
- Use `pipe(Layer1, Layer.merge(Layer2))` to combine
- Create runtime: `Atom.runtime(composedLayer)`
- Access services: `yield* ServiceTag` in atoms
- Share runtime across multiple atoms

---

## Pattern 13: HTTP API Integration

**Use when**: Building type-safe HTTP clients for atom-based apps.

**Key principle**: Use `AtomHttpApi.Tag` to create Effect-integrated HTTP clients with automatic retry, error handling, and streaming support.

**Structure**:
- Define API schema with `HttpApi.make("name").add(HttpApiGroup...)`
- Create client with `AtomHttpApi.Tag<T>()("Name", { api, httpClient, baseUrl })`
- Use in runtime: `Layer.merge(Client.layer)`
- Access in atoms: `yield* Client` then call endpoints

---

## Common Pitfalls

### ❌ Don't: Block atom creation on async

```typescript
export const badAtom = Atom.make(async (get) => {
  const data = await fetch(...)  // WRONG
  return data
})
```

### ✅ Do: Return Result immediately

Use `runtime.atom(Effect...)` which returns `Result<Loading|Error|Success>` immediately.

---

### ❌ Don't: Use atoms without runtime for Effects

```typescript
export const badAtom = Atom.make((get) => {
  Effect.runPromise(myEffect); // WRONG: no runtime context
});
```

### ✅ Do: Use runtime.atom for Effects

```typescript
export const goodAtom = myRuntime.atom(myEffect);
```

---

### ❌ Don't: Call hooks in callbacks

```typescript
function Bad() {
  return <Button onPress={() => useAtomValue(atom)} />  // WRONG
}
```

### ✅ Do: Use useAtomSet for actions

```typescript
function Good() {
  const action = useAtomSet(actionAtom)
  return <Button onPress={() => action(args)} />
}
```

---

## Quick Reference

| Pattern       | Atom Type                    | Use Case               | Hook           |
| ------------- | ---------------------------- | ---------------------- | -------------- |
| Local State   | `Atom.writable`              | Simple mutable state   | `useAtom`      |
| Async Sync    | `runtime.atom` + `Queue`     | Server sync + batching | `useAtomValue` |
| Dual-Phase    | `Atom.make` + `addFinalizer` | External listeners     | `useAtomValue` |
| Runtime DI    | `Atom.runtime`               | Effect Layer deps      | -              |
| Query         | `runtime.query`              | Cached reads           | `useAtomValue` |
| Command       | `runtime.atom(Effect)`       | Async actions          | `useAtomMount` |
| Action        | `Atom.fnSync`                | Imperative actions     | `useAtomSet`   |
| Persistent    | `Atom.kvs`                   | LocalStorage/IndexedDB | `useAtom`      |
| Derived       | `Atom.make((get) => ...)`    | Computed values        | `useAtomValue` |
| Parameterized | `Atom.family`                | Per-ID atoms           | `useAtomValue` |
| Streaming     | `runtime.pull`               | Paginated data         | `useAtom`      |
| HTTP API      | `AtomHttpApi.Tag`            | Type-safe HTTP clients | -              |

---

For detailed code examples, see [EXAMPLES.md](EXAMPLES.md).
