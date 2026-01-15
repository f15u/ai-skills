# Effect Atom Examples

Detailed code examples for each pattern in the Effect Atom skill.

## Pattern 1: Simple Local State

### Counter with Atom.writable

```typescript
// Simple counter atom
export const counterAtom = Atom.writable(
  () => 0, // Initial value
  (ctx, value: number) => {
    ctx.setSelf(value);
  }
);

// Usage in component
function Counter() {
  const [count, setCount] = useAtom(counterAtom);

  return (
    <div>
      <span>{count}</span>
      <button onClick={() => setCount(count + 1)}>Increment</button>
    </div>
  );
}
```

### Toggle State

```typescript
// Boolean toggle atom
export const toggleAtom = Atom.writable(
  () => false,
  (ctx, value: boolean) => {
    ctx.setSelf(value);
  }
);

// Usage
function Toggle() {
  const [isOn, setIsOn] = useAtom(toggleAtom);

  return (
    <button onClick={() => setIsOn(!isOn)}>
      {isOn ? 'ON' : 'OFF'}
    </button>
  );
}
```

### Form Input State

```typescript
// Text input atom
export const inputAtom = Atom.writable(
  () => "",
  (ctx, value: string) => {
    ctx.setSelf(value);
  }
);

// Usage
function Input() {
  const [value, setValue] = useAtom(inputAtom);

  return (
    <input
      value={value}
      onChange={(e) => setValue(e.target.value)}
    />
  );
}
```

---

## Pattern 2: Async State Synchronization

### HTTP API Definition

```typescript
import { HttpApi, HttpApiEndpoint, HttpApiGroup } from "@effect/platform";
import { Schema } from "effect";

// Define request/response schemas
const MarkAsReadRequest = Schema.Struct({
  messageIds: Schema.Array(MessageId),
});

// Define API endpoints
export class MessagesApi extends HttpApi.make("messages-api").add(
  HttpApiGroup.make("messages")
    .add(
      HttpApiEndpoint.get("getMessages", "/messages")
        .setUrlParams(GetMessagesParams)
        .addSuccess(GetMessagesResponse)
    )
    .add(
      HttpApiEndpoint.post("markAsRead", "/messages/mark-read")
        .setPayload(MarkAsReadRequest)
        .addSuccess(Schema.Void)
    )
) {}
```

### HTTP Client with AtomHttpApi.Tag

```typescript
import { AtomHttpApi } from "@effect-atom/atom-react";
import { FetchHttpClient } from "@effect/platform";

export class MessagesClient extends AtomHttpApi.Tag<MessagesClient>()("MessagesClient", {
  api: MessagesApi,
  httpClient: FetchHttpClient.layer,
  baseUrl: "http://localhost:3001",
}) {}
```

### Queue-Based Batch Processor Atom

```typescript
import { Atom } from "@effect-atom/atom-react";
import { Effect, Queue, Stream, Duration, Chunk, Schedule } from "effect";

// Batch processor with retry logic
const batchProcessorAtom = appRuntime
  .atom(
    Effect.gen(function* () {
      const client = yield* MessagesClient;
      const networkMonitor = yield* NetworkMonitor;
      const markAsReadQueue = yield* Queue.unbounded<MessageId>();

      // Process queue with batching and retries
      yield* pipe(
        Stream.fromQueue(markAsReadQueue),
        Stream.tap((value) => Effect.log(`Queued up ${value}`)),
        Stream.groupedWithin(25, Duration.seconds(5)), // Batch: max 25 items or 5s
        Stream.tap((batch) => Effect.log(`Batching: ${Chunk.join(batch, ", ")}`)),
        Stream.mapEffect(
          (batch) =>
            client.messages
              .markAsRead({
                payload: { messageIds: Chunk.toReadonlyArray(batch) as MessageId[] },
              })
              .pipe(
                networkMonitor.latch.whenOpen, // Wait for network
                Effect.retry({
                  times: 3,
                  schedule: Schedule.exponential("500 millis", 2)
                }),
                Effect.tap(() =>
                  Effect.sync(() => {
                    const ids = Chunk.toReadonlyArray(batch) as MessageId[];
                    console.log(`Batched: ${ids.join(", ")}`);
                    onBatchSuccess?.(ids);
                  })
                ),
                Effect.tapErrorCause(() =>
                  Effect.sync(() => {
                    const ids = Chunk.toReadonlyArray(batch) as MessageId[];
                    console.error("Batch failed:", ids.join(", "));
                    onBatchError?.({
                      message: "Failed to mark messages as read",
                      failedIds: ids,
                    });
                  })
                ),
                Effect.catchAllCause((cause) =>
                  Effect.log(cause, "Error processing batch")
                )
              ),
          { concurrency: 1 }
        ),
        Stream.runDrain,
        Effect.forkScoped
      );

      return { markAsReadQueue };
    })
  )
  .pipe(Atom.keepAlive);
```

### React Hook with Optimistic Updates

```typescript
export const useMarkMessagesAsRead = (messages: readonly Message[]) => {
  const processorResult = useAtomValue(batchProcessorAtom);
  const [readMessageIds, setReadMessageIds] = React.useState<Set<string>>(new Set());
  const [batchError, setBatchError] = React.useState<BatchError>(null);

  // Register batch callbacks
  React.useEffect(() => {
    setBatchCallbacks({
      onError: setBatchError,
      onSuccess: (ids) => {
        setReadMessageIds((prev) => {
          const next = new Set(prev);
          ids.forEach((id) => next.add(id));
          return next;
        });
      },
    });
    return () => setBatchCallbacks({ onError: null, onSuccess: null });
  }, []);

  // Mark as read: optimistic update + queue for server sync
  const markAsRead = React.useCallback(
    (id: Message["id"]) => {
      if (queuedMessageIds.has(id)) return;
      queuedMessageIds.add(id);

      // Queue for server sync
      if (Result.isSuccess(processorResult)) {
        processorResult.value.markAsReadQueue.unsafeOffer(id);
      }

      // Optimistic local update
      setReadMessageIds((prev) => new Set(prev).add(id));
    },
    [processorResult]
  );

  return { markAsRead, readMessageIds, batchError };
};
```

---

## Pattern 3: Dual-Phase Atom (Immediate Access + Async Updates)

### Router Location

```typescript
// Router location with immediate sync access
export const locationAtom = Atom.make((get) => {
  get.addFinalizer(
    router.subscribe("onRendered", (_) => {
      get.setSelf(_.toLocation);
    }),
  );
  return router.state.location; // Immediate sync access
});
```

### React Native Navigation

```typescript
// React Native navigation ref with state updates
export const navigationRefAtom = Atom.make((get) => {
  const ref = createNavigationContainerRef<RootStackParamList>();

  get.addFinalizer(
    ref.addListener("state", () => {
      get.setSelf(ref); // Trigger updates on state changes
    }),
  );

  return ref; // Return immediately, no async wait
});
```

---

## Pattern 4: Runtime-Based Dependency Injection

### App Runtime with Multiple Services

```typescript
import { Atom } from "@effect-atom/atom-react";
import { Layer, Logger } from "effect";

// Compose multiple service layers
const AppLayer = Layer.mergeAll(
  Logger.pretty,
  MessagesClient.layer,
  NetworkMonitor.Default
);

// Create runtime
export const appRuntime = Atom.runtime(AppLayer);
```

### Dynamic Runtime Configuration

```typescript
// Dynamic runtime with conditional layer configuration
static runtime = Atom.runtime((get) => {
  const remoteUrl = get(remoteUrlAtom)
  return pipe(
    this.Default,
    Option.isSome(remoteUrl)
      ? Layer.provide(...)
      : Function.identity,
    Layer.provideMerge(ServiceLayer),
    Layer.provide(Layer.succeed(Identity, get(identityAtom)))
  )
})
```

### Navigation Service Injection

```typescript
// Navigation service dependency injection
export class NavigationRef extends Context.Tag("NavigationRef")<
  NavigationRef,
  NavigationContainerRefWithCurrent<RootStackParamList>
>() {}

export const navigationRuntime = Atom.runtime((get) =>
  Layer.succeed(NavigationRef, get(navigationRefAtom)),
);
```

---

## Pattern 5: Query vs Command Separation

### Query Example

```typescript
// Cached query with TTL
export const dataAtom = (id: string) =>
  ApiClient.query("getData", { id }, { timeToLive: "10 minutes" });
```

### Command Example

```typescript
// Command with side effects
export const loginAtom = ApiClient.runtime.atom(
  Effect.fnUntraced(function* (get) {
    const client = yield* ApiClient;
    const location = get(currentLocationAtom);
    yield* client("login", { location });
  }),
);
```

### Query: Current State (Sync Read)

```typescript
export const currentRouteAtom = Atom.make((get) => {
  const ref = get(navigationRefAtom);
  return ref.getCurrentRoute();
});
```

### Command: Navigation Action (Waits for Readiness)

```typescript
export const navigateAtom = Atom.fnSync(
  (args: { route: string; params?: any }, get) => {
    get(
      navigationRuntime.atom(
        Effect.gen(function* () {
          const ref = yield* NavigationRef;
          yield* Effect.async<void>((resume) => {
            if (ref.isReady()) {
              ref.navigate(args.route, args.params);
              resume(Effect.void);
            } else {
              const unsubscribe = ref.addListener("ready", () => {
                ref.navigate(args.route, args.params);
                unsubscribe();
                resume(Effect.void);
              });
            }
          });
        }),
      ),
    );
  },
);
```

---

## Pattern 6: KVS Pattern (Persistent State)

### Persistent State with Schema Validation

```typescript
export const userPrefsAtom = pipe(
  Atom.kvs<Option.Option<UserPreferences>>({
    runtime: Atom.runtime(BrowserKeyValueStore.layerLocalStorage),
    key: "userPreferences",
    schema: Schema.Option(UserPreferences),
    defaultValue: Option.none,
  }),
  Atom.keepAlive
);
```

### Shared KVS Runtime

```typescript
// 1. Create shared KVS runtime
export const kvsRuntime = Atom.runtime(BrowserKeyValueStore.layerLocalStorage);

// 2. Use in multiple atoms
export const settingAtom = pipe(
  Atom.kvs({
    runtime: kvsRuntime,
    key: "app.setting",
    schema: Schema.String,
    defaultValue: "default",
  }),
  Atom.keepAlive
);
```

---

## Pattern 7: Result Pattern (Non-Throwing Async)

### Result Pattern with Fallback

```typescript
// Result pattern with fallback to cached data
export const dataAtom = Atom.family((key: DataKey) =>
  pipe(
    Atom.make((get) => {
      const fullData = get(fullDataAtom(key.id));
      if (key.cached && fullData._tag !== "Success") {
        return Result.success(key.cached); // Return cached immediately
      }
      return Result.map(fullData, (_) => _.summary);
    }),
    Atom.setIdleTTL("5 minutes")
  )
);
```

### Usage in React Component

```typescript
function Component() {
  const result = useAtomValue(dataAtom({ id: "123" }))

  return Result.match(result, {
    onLoading: () => <Spinner />,
    onError: (error) => <Error error={error} />,
    onSuccess: (data) => <DataView data={data} />,
  })
}
```

---

## Pattern 8: Atom.family for Parameterized Atoms

### Parameterized Atom with Caching

```typescript
// Parameterized atom with caching per ID
export const itemStatsAtom = Atom.family((id: string) =>
  pipe(
    ApiClient.query("itemStats", { id }),
    Atom.map((_) => Option.flatten(Result.value(_))),
    Atom.setIdleTTL("10 minutes")
  )
);
```

### Usage in Component

```typescript
function ItemCard({ id }: { id: string }) {
  const stats = useAtomValue(itemStatsAtom(id));
  // Atom is created once per unique id
}
```

---

## Pattern 9: Derived/Computed Atoms

### Simple Derived Atom

```typescript
const minimizeAtom = Atom.make((get) => {
  const path = get(locationAtom).pathname;
  return path !== "/" || get(queryIsSetAtom);
});
```

### Derived Atom with Fallback Logic

```typescript
export const itemRatingAtom = Atom.family((item: ItemInfo) =>
  Atom.make((get) => {
    const stats = get(itemStatsAtom(item.id));
    return Option.isSome(stats)
      ? stats.value.averageRating
      : item.defaultRating;
  }),
);
```

---

## Pattern 10: Atom.fnSync for Imperative Actions

### Counter Atom with Write Action

```typescript
export const focusAtom = Atom.writable(
  () => 0,
  (ctx, _: void) => {
    ctx.setSelf(ctx.get(focusAtom) + 1);
  },
);
```

### Navigation Action Atom

```typescript
export const navigateAtom = Atom.fnSync(
  (args: { route: string; params?: any }, get) => {
    get(navigationRuntime.atom(Effect.gen(function* () {
      // async navigation logic
    })))
  }
)

// Usage in component:
function MyComponent() {
  const navigate = useAtomSet(navigateAtom)
  return <Button onPress={() => navigate({ route: "Home" })} />
}
```

---

## Pattern 11: Stream-Based Data Loading

### Infinite Scroll with Stream.paginateEffect

```typescript
// Create a stream that fetches messages page by page
const messagesStream = Stream.paginateEffect(
  undefined as string | undefined,
  (cursor) =>
    Effect.gen(function* () {
      const client = yield* MessagesClient;
      const response = yield* client.messages.getMessages({
        urlParams: cursor !== undefined ? { cursor } : {},
      });

      const nextState =
        response.nextCursor !== null
          ? Option.some(response.nextCursor)
          : Option.none();

      return [response.messages, nextState] as const;
    })
);

// Use Atom.pull for infinite scroll
export const messagesAtom = appRuntime.pull(messagesStream).pipe(Atom.keepAlive);

// React hook
export const useMessagesQuery = () => {
  const [result, pull] = useAtom(messagesAtom);
  const refresh = useAtomRefresh(messagesAtom);
  return { result, pull, refresh };
};
```

### Stream-Based Pagination with Mailbox

```typescript
export const resultsAtom = pipe(
  ApiClient.runtime.pull(
    Effect.fnUntraced(function* (get) {
      const client = yield* ApiClient;
      const query = get(queryTrimmedAtom);

      const mailbox = yield* Mailbox.make<Item>(32);

      yield* pipe(
        Effect.gen(function* () {
          let offset = 0;
          while (true) {
            const data = yield* client("search", { query, offset });
            yield* mailbox.offerAll(data.results);
            offset += data.results.length;
            if (offset >= data.totalCount) break;
          }
        }),
        Mailbox.into(mailbox),
        Effect.forkScoped
      );

      return Mailbox.toStream(mailbox);
    }, Stream.unwrapScoped)
  ),
  Atom.keepAlive
);
```

---

## Pattern 12: Effect Layer Composition

### Compose Multiple Service Layers

```typescript
const runtime = Atom.runtime(
  pipe(Geolocation.layer, Layer.merge(ApiClient.layer))
);

export const geoAtom = runtime.atom(
  Effect.gen(function* () {
    const geo = yield* Geolocation.Geolocation;
    return yield* geo.getCurrentPosition();
  }),
);
```

---

## Pattern 13: HTTP API Integration

See Pattern 2 examples above for complete HTTP API integration with `AtomHttpApi.Tag`, including:
- API schema definition with `HttpApi` and `HttpApiEndpoint`
- Client creation with `AtomHttpApi.Tag`
- Runtime integration with `Layer.merge`
- Usage in atoms with `yield* Client`

---

## Common Pitfalls Examples

### ✅ Correct: Return Result Immediately

```typescript
export const goodAtom = runtime.atom(
  Effect.gen(function* () {
    const data = yield* Effect.promise(() => fetch(...))
    return data
  })
)
// Returns Result<Loading|Error|Success> immediately
```

### ✅ Correct: Use runtime.atom for Effects

```typescript
export const goodAtom = myRuntime.atom(myEffect);
```

### ✅ Correct: Use useAtomSet for Actions

```typescript
function Good() {
  const action = useAtomSet(actionAtom)
  return <Button onPress={() => action(args)} />
}
```
