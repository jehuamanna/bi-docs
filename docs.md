# Extensible BI Dashboard Framework: Technical Documentation

## Project Overview

**Extensible BI Dashboard Framework** is a browser-based, highly extensible framework designed for building dynamic Business Intelligence (BI) dashboards. The system features a minimal core with maximum extensibility, allowing developers to create, customize, and extend UI components on-the-fly using both a custom DSL and JavaScript.

### Core Philosophy

- **Tiny Core, Maximum Extensibility**: Minimal core functionality with comprehensive plugin architecture
- **Plugin-Based Architecture**: Adopts proven patterns for extensibility and modularity
- **Developer-First Design**: Prioritizes developer experience with hot reloading, debugging tools, and clear APIs

---

## Table of Contents

1. [Core System Architecture](#1-core-system-architecture)
2. [Extension System](#2-extension-system)
3. [Security Model](#3-security-model)
4. [Advanced Features](#4-advanced-features)
5. [Data Persistence](#5-data-persistence)
6. [Technical Stack](#6-technical-stack)
7. [Use Cases & Examples](#7-use-cases--examples)
8. [References & Inspiration](#8-references--inspiration)
9. [Architecture Diagram](#9-architecture-diagram)
10. [Implementation Roadmap](#10-implementation-roadmap)

---

## 1. Core System Architecture

The minimal core provides essential infrastructure for the extensible framework.

---

#### 1.1 Component Registry

**Purpose**: Central registry for all UI components (built-in and user-defined)

**Core Responsibilities**:
- Component registration and discovery
- Lifecycle management (mount, unmount, update)
- Dependency resolution
- Version management

**Architecture Patterns**:

| Pattern | Description | Pros | Cons | Best For |
|---------|-------------|------|------|----------|
| **Service Locator** | Central registry with get/set | ✅ Simple<br>✅ Centralized<br>✅ Easy lookup | ❌ Global state<br>❌ Hidden dependencies<br>❌ Testing harder | Simple apps, quick prototypes |
| **Dependency Injection** | Components receive dependencies | ✅ Explicit dependencies<br>✅ Testable<br>✅ Decoupled | ❌ More boilerplate<br>❌ Complex setup<br>❌ Learning curve | Large apps, testability important |
| **Module Federation** | Webpack 5 feature for runtime loading | ✅ True code splitting<br>✅ Independent deployment<br>✅ Version isolation | ❌ Webpack-specific<br>❌ Complex config<br>❌ Build complexity | Micro-frontends, large teams |
| **Dynamic Import** | ES modules with import() | ✅ Native support<br>✅ Code splitting<br>✅ Simple | ❌ Limited metadata<br>❌ No version control<br>❌ Manual registry | Modern apps, simple plugins |

**Library Comparison**:

| Library | Type | Pros | Cons | Bundle Size | Use Case |
|---------|------|------|------|-------------|----------|
| **InversifyJS** | DI container | ✅ Full DI support<br>✅ Decorators<br>✅ TypeScript<br>✅ Mature | ❌ Large bundle<br>❌ Reflect metadata<br>❌ Complex API | ~15KB | Enterprise apps, complex DI |
| **TSyringe** | DI container | ✅ Lightweight DI<br>✅ Decorators<br>✅ Simple API<br>✅ TypeScript | ❌ Requires decorators<br>❌ Less features | ~3KB | TypeScript apps, moderate DI |
| **Awilix** | DI container | ✅ No decorators needed<br>✅ Flexible<br>✅ Good docs | ❌ Less type-safe<br>❌ Manual setup | ~5KB | Node.js-style, flexible DI |
| **Custom Registry** | DIY Map/Object | ✅ Full control<br>✅ Minimal size<br>✅ Simple | ❌ Manual implementation<br>❌ No DI features | <1KB | Simple needs, full control |

**BI Dashboard Examples**:

| Platform | Registry Pattern | Extension Method |
|----------|-----------------|----------------|
| **Observable** | Module-based registry | • Notebook cells as components<br>• Dynamic import for modules<br>• Runtime dependency resolution<br>• Version pinning per notebook |
| **Evidence** | File-based convention | • Components auto-discovered from /components<br>• Svelte component registry<br>• Build-time registration<br>• No runtime DI |
| **Count.co** | Component library | • Pre-built visualization components<br>• SQL-driven component binding<br>• Canvas-based layout registry<br>• Drag-and-drop component system |
| **tldraw** | Shape registry | • Shape definitions as components<br>• Tool registry pattern<br>• Custom shape API<br>• Runtime shape registration |
| **Omni Docs** | Plugin registry | • Plugin-based documentation system<br>• Markdown-based content<br>• Custom plugin API<br>• Runtime plugin registration |

**Recommended Architecture**:

```typescript
// Component registry with versioning and lifecycle
interface ComponentMetadata {
  id: string;
  name: string;
  version: string;
  dependencies?: string[];
  lazy?: boolean;
  loader?: () => Promise<Component>;
}

class ComponentRegistry {
  private components = new Map<string, ComponentMetadata>();
  private instances = new Map<string, Component>();
  
  register(metadata: ComponentMetadata): void {
    // Version conflict check
    if (this.components.has(metadata.id)) {
      const existing = this.components.get(metadata.id)!;
      if (existing.version !== metadata.version) {
        console.warn(`Version conflict: ${metadata.id}`);
      }
    }
    
    this.components.set(metadata.id, metadata);
  }
  
  async get(id: string): Promise<Component> {
    // Check cache
    if (this.instances.has(id)) {
      return this.instances.get(id)!;
    }
    
    const metadata = this.components.get(id);
    if (!metadata) {
      throw new Error(`Component not found: ${id}`);
    }
    
    // Resolve dependencies
    if (metadata.dependencies) {
      await Promise.all(
        metadata.dependencies.map(dep => this.get(dep))
      );
    }
    
    // Lazy load if needed
    const component = metadata.lazy && metadata.loader
      ? await metadata.loader()
      : metadata;
    
    this.instances.set(id, component);
    return component;
  }
  
  unregister(id: string): void {
    this.components.delete(id);
    this.instances.delete(id);
  }
}
```

*For detailed state management integration, see Section 1.3. For plugin lifecycle, see Section 1.4.*

#### 1.2 Event System

**Purpose**: Pub/sub event bus for inter-component communication

**Core Features**:
- Global and scoped event channels
- Event hooks and listeners
- Async event handling
- Event history and replay (for debugging)

**Architecture Patterns**:

| Pattern | Description | Pros | Cons | Best For |
|---------|-------------|------|------|----------|
| **Event Emitter** | Simple pub/sub | ✅ Simple<br>✅ Familiar<br>✅ Small | ❌ No type safety<br>❌ Memory leaks risk<br>❌ No scoping | Simple events, small apps |
| **Event Bus** | Centralized event hub | ✅ Decoupled<br>✅ Global access<br>✅ Easy debugging | ❌ Global state<br>❌ Hidden dependencies<br>❌ Testing harder | Cross-component communication |
| **Observable Streams** | RxJS-style | ✅ Powerful operators<br>✅ Composable<br>✅ Async-friendly | ❌ Learning curve<br>❌ Large bundle<br>❌ Overkill for simple cases | Complex async flows |
| **Custom Events** | DOM CustomEvent | ✅ Native API<br>✅ No dependencies<br>✅ Bubbling support | ❌ DOM-only<br>❌ Limited features<br>❌ Verbose | DOM-centric apps |

**Library Comparison**:

| Library | Type | Pros | Cons | Bundle Size | Use Case |
|---------|------|------|------|-------------|----------|
| **mitt** | Event emitter | ✅ Tiny (200B)<br>✅ TypeScript<br>✅ Simple API | ❌ Basic features<br>❌ No scoping<br>❌ No async | 200B | Minimal apps, simple events |
| **eventemitter3** | Event emitter | ✅ Fast<br>✅ Mature<br>✅ Well-tested | ❌ No TypeScript<br>❌ Larger bundle | ~2KB | Performance-critical |
| **RxJS** | Reactive streams | ✅ Very powerful<br>✅ Operators<br>✅ Async handling | ❌ Large (40KB+)<br>❌ Steep curve<br>❌ Complex | ~40KB | Complex async, data streams |
| **Nano Events** | Event emitter | ✅ Very small<br>✅ Simple<br>✅ TypeScript | ❌ Minimal features | 200B | Size-constrained |
| **EventEmitter2** | Enhanced emitter | ✅ Wildcards<br>✅ Namespaces<br>✅ Feature-rich | ❌ Larger<br>❌ More complex | ~5KB | Complex event patterns |

**Event System Patterns**:

| Feature | Implementation | Pros | Cons |
|---------|---------------|------|------|
| **Event Namespacing** | `user:login`, `data:update` | ✅ Organization<br>✅ Wildcards | ❌ String-based<br>❌ No type safety |
| **Typed Events** | TypeScript discriminated unions | ✅ Type-safe<br>✅ Autocomplete | ❌ More boilerplate<br>❌ TS-only |
| **Event Replay** | Store event history | ✅ Debugging<br>✅ Time-travel | ❌ Memory usage<br>❌ Complexity |
| **Scoped Channels** | Separate buses per scope | ✅ Isolation<br>✅ Less noise | ❌ More instances<br>❌ Coordination |

**BI Dashboard Examples**:

| Platform | Event Pattern | Implementation |
|----------|-------------|----------------|
| **Observable** | Reactive cells | • Cell dependencies as events<br>• Automatic re-execution<br>• Dataflow graph<br>• No explicit pub/sub |
| **Evidence** | Component events | • Svelte component events<br>• Custom events for data updates<br>• Build-time event binding |
| **Count.co** | Canvas events | • Cell update events<br>• Query execution events<br>• Collaboration events (real-time)<br>• Canvas state changes |
| **tldraw** | Shape events | • Shape change events<br>• Selection events<br>• Canvas interaction events<br>• History events (undo/redo) |
| **Omni Docs** | Plugin events | • Plugin-based event system<br>• Custom event API<br>• Runtime event registration |

**Recommended Architecture**:

```typescript
// Type-safe event system
type EventMap = {
  'dashboard:loaded': { id: string; data: any };
  'panel:updated': { panelId: string; changes: any };
  'data:fetched': { query: string; result: any };
  'user:action': { action: string; payload: any };
};

class TypedEventBus {
  private emitter = new EventEmitter();
  private history: Array<{ event: string; data: any; timestamp: number }> = [];
  private maxHistory = 100;
  
  on<K extends keyof EventMap>(
    event: K,
    handler: (data: EventMap[K]) => void
  ): () => void {
    this.emitter.on(event, handler);
    return () => this.emitter.off(event, handler);
  }
  
  emit<K extends keyof EventMap>(event: K, data: EventMap[K]): void {
    // Store in history
    this.history.push({ event, data, timestamp: Date.now() });
    if (this.history.length > this.maxHistory) {
      this.history.shift();
    }
    
    this.emitter.emit(event, data);
  }
  
  replay(fromTimestamp?: number): void {
    const events = fromTimestamp
      ? this.history.filter(e => e.timestamp >= fromTimestamp)
      : this.history;
    
    events.forEach(({ event, data }) => {
      this.emitter.emit(event, data);
    });
  }
  
  getHistory(): typeof this.history {
    return [...this.history];
  }
}
```

*For integration with hooks, see Section 2.2.6. For state synchronization, see Section 1.3.*

#### 1.3 State Management

**Purpose**: Centralized, reactive state management

**Core Features**:
- Immutable state updates
- Time-travel debugging
- State persistence and hydration
- Computed/derived state
- State snapshots and restoration

**Architecture Patterns**:

| Pattern | Description | Pros | Cons | Best For |
|---------|-------------|------|------|----------|
| **Flux/Redux** | Unidirectional data flow | ✅ Predictable<br>✅ Time-travel<br>✅ DevTools | ❌ Boilerplate<br>❌ Learning curve<br>❌ Verbose | Large apps, complex state |
| **Atomic State** | Fine-grained atoms | ✅ Minimal re-renders<br>✅ Composable<br>✅ Simple | ❌ Many atoms<br>❌ Coordination<br>❌ Less structure | React apps, performance-critical |
| **Proxy-Based** | Mutable API with tracking | ✅ Simple API<br>✅ Auto-tracking<br>✅ Intuitive | ❌ Proxy overhead<br>❌ Debugging harder | Rapid development |
| **Observable** | RxJS/MobX style | ✅ Reactive<br>✅ Powerful<br>✅ Composable | ❌ Learning curve<br>❌ Large bundle | Complex reactive flows |

**Library Comparison**:

| Library | Pattern | Pros | Cons | Bundle Size | Use Case |
|---------|---------|------|------|-------------|----------|
| **Zustand** | Flux-like | ✅ Simple API<br>✅ No providers<br>✅ Middleware<br>✅ Small bundle | ❌ Manual optimization<br>❌ Less structure | ~1KB | General-purpose, React |
| **Jotai** | Atomic | ✅ Minimal re-renders<br>✅ Bottom-up<br>✅ TypeScript<br>✅ Suspense | ❌ Many atoms<br>❌ Boilerplate<br>❌ Debugging | ~3KB | Performance-critical React |
| **Valtio** | Proxy | ✅ Mutable API<br>✅ Auto-tracking<br>✅ Simple<br>✅ Snapshots | ❌ Proxy limitations<br>❌ Less predictable | ~3KB | Rapid development, simple state |
| **Redux Toolkit** | Redux | ✅ Less boilerplate<br>✅ DevTools<br>✅ Mature<br>✅ Ecosystem | ❌ Still verbose<br>❌ Learning curve<br>❌ Larger | ~10KB | Enterprise, complex workflows |
| **MobX** | Observable | ✅ Very reactive<br>✅ Automatic tracking<br>✅ Powerful | ❌ Large bundle<br>❌ Magic behavior<br>❌ Learning curve | ~16KB | Complex reactive apps |
| **Recoil** | Atomic | ✅ React-first<br>✅ Async support<br>✅ Selectors | ❌ Experimental<br>❌ React-only<br>❌ Less mature | ~14KB | React apps, async state |
| **XState** | State machines | ✅ Predictable<br>✅ Visualizable<br>✅ Complex flows | ❌ Learning curve<br>❌ Verbose<br>❌ Overkill for simple | ~10KB | Complex state machines |

**State Management Features**:

| Feature | Implementation | Pros | Cons |
|---------|---------------|------|------|
| **Time-Travel** | Store action history | ✅ Debugging<br>✅ Undo/redo | ❌ Memory usage<br>❌ Complexity |
| **Persistence** | LocalStorage/IndexedDB sync | ✅ Survives refresh<br>✅ User experience | ❌ Serialization<br>❌ Migration |
| **Computed State** | Derived values/selectors | ✅ DRY principle<br>✅ Performance | ❌ Memoization needed<br>❌ Complexity |
| **Middleware** | Intercept actions | ✅ Logging<br>✅ Analytics<br>✅ Side effects | ❌ Indirection<br>❌ Debugging |

**BI Dashboard Examples**:

| Platform | State Pattern | Implementation |
|----------|-----------------|----------------|
| **Observable** | Reactive cells | • Each cell is state<br>• Automatic dependency tracking<br>• Dataflow graph execution<br>• No central store |
| **Evidence** | Svelte stores | • Writable stores for state<br>• Derived stores for computed<br>• Context for component state |
| **Count.co** | Canvas state | • Canvas-level state management<br>• Cell state with SQL results<br>• Collaborative state sync<br>• Local + server state |
| **tldraw** | Zustand store | • Centralized Zustand store<br>• Shape state management<br>• History state (undo/redo)<br>• Computed selectors |
| **Omni Docs** | Plugin state | • Plugin-based state management<br>• Custom state API<br>• Runtime state registration |

**Recommended Architecture**:

```typescript
// Zustand store with persistence and time-travel
import create from 'zustand';
import { persist, devtools } from 'zustand/middleware';
import { temporal } from 'zundo';

interface DashboardState {
  dashboards: Dashboard[];
  activeDashboard: string | null;
  panels: Record<string, Panel>;
  
  // Actions
  addDashboard: (dashboard: Dashboard) => void;
  updatePanel: (id: string, updates: Partial<Panel>) => void;
  setActiveDashboard: (id: string) => void;
  
  // Computed (via selectors)
  getActivePanels: () => Panel[];
}

const useDashboardStore = create<DashboardState>()(
  devtools(
    persist(
      temporal(
        (set, get) => ({
          dashboards: [],
          activeDashboard: null,
          panels: {},
          
          addDashboard: (dashboard) =>
            set((state) => ({
              dashboards: [...state.dashboards, dashboard]
            })),
          
          updatePanel: (id, updates) =>
            set((state) => ({
              panels: {
                ...state.panels,
                [id]: { ...state.panels[id], ...updates }
              }
            })),
          
          setActiveDashboard: (id) =>
            set({ activeDashboard: id }),
          
          getActivePanels: () => {
            const state = get();
            if (!state.activeDashboard) return [];
            return Object.values(state.panels).filter(
              p => p.dashboardId === state.activeDashboard
            );
          }
        }),
        { limit: 50 } // Time-travel limit
      ),
      { name: 'dashboard-storage' } // Persistence key
    )
  )
);
```

*For persistence strategies, see Section 5. For performance optimization, see Section 6.*


> **Note**: This section consolidates state management information. Technology recommendations and settings management patterns have been integrated here for completeness.

#### 1.4 Plugin Loader

**Purpose**: Dynamic loading and management of extensions

**Core Features**:
- Hot module replacement (HMR)
- Lazy loading of plugins
- Plugin dependency management
- Sandboxed execution context
- Plugin lifecycle hooks (init, activate, deactivate, destroy)

**Architecture Patterns**:

| Pattern | Description | Pros | Cons | Best For |
|---------|-------------|------|------|----------|
| **Dynamic Import** | ES modules import() | ✅ Native<br>✅ Code splitting<br>✅ Simple | ❌ Limited metadata<br>❌ No sandboxing | Modern apps, simple plugins |
| **Module Federation** | Webpack 5 feature | ✅ Independent deployment<br>✅ Version isolation<br>✅ Shared deps | ❌ Webpack-specific<br>❌ Complex setup | Micro-frontends |
| **SystemJS** | Universal module loader | ✅ Format-agnostic<br>✅ Runtime loading<br>✅ Import maps | ❌ Extra runtime<br>❌ Less common | Legacy support needed |
| **iframe Sandboxing** | Isolated execution | ✅ True isolation<br>✅ Security<br>✅ Separate context | ❌ Communication overhead<br>❌ Performance<br>❌ Complex | Untrusted plugins |
| **Web Workers** | Background threads | ✅ Non-blocking<br>✅ Isolated<br>✅ Parallel | ❌ No DOM access<br>❌ Message passing<br>❌ Limited | CPU-intensive plugins |

**Library Comparison**:

| Library | Type | Pros | Cons | Bundle Size | Use Case |
|---------|------|------|------|-------------|----------|
| **single-spa** | Micro-frontend framework | ✅ Framework-agnostic<br>✅ Lifecycle<br>✅ Mature | ❌ Complex setup<br>❌ Learning curve | ~5KB | Micro-frontends, large apps |
| **qiankun** | Micro-frontend (Alibaba) | ✅ Sandboxing<br>✅ CSS isolation<br>✅ Full-featured | ❌ Complex<br>❌ Chinese docs | ~15KB | Enterprise micro-frontends |
| **import-maps** | Native import maps | ✅ Native<br>✅ No build<br>✅ Simple | ❌ Browser support<br>❌ Limited features | 0KB | Modern browsers only |
| **SystemJS** | Module loader | ✅ Format-agnostic<br>✅ Import maps<br>✅ Mature | ❌ Extra runtime<br>❌ Less common | ~10KB | Legacy support |
| **Custom Loader** | DIY | ✅ Full control<br>✅ Tailored<br>✅ Minimal | ❌ Development time<br>❌ Testing | Varies | Specific requirements |

**Plugin Lifecycle Patterns**:

| Phase | Purpose | Typical Actions |
|-------|---------|-----------------|
| **Load** | Fetch plugin code | Download, parse, validate |
| **Initialize** | Setup plugin | Register components, create instances |
| **Activate** | Start plugin | Mount UI, start services, subscribe to events |
| **Deactivate** | Pause plugin | Unmount UI, pause services, keep state |
| **Destroy** | Cleanup plugin | Remove listeners, free resources, clear state |
| **Update** | Hot reload | Preserve state, swap implementation |

**BI Dashboard Examples**:

| Platform | Plugin System | Implementation |
|----------|--------------|----------------|
| **Observable** | Runtime imports | • Dynamic import() for modules<br>• npm: prefix for packages<br>• Version pinning<br>• No formal plugin API |
| **Evidence** | Component discovery | • File-based plugin system<br>• Auto-discovery from directories<br>• Build-time integration<br>• Svelte components |
| **Count.co** | Canvas plugins | • Visualization plugins<br>• Data connector plugins<br>• SQL function extensions<br>• Custom cell types |
| **tldraw** | Shape plugins | • Custom shape definitions<br>• Tool plugins<br>• UI override plugins<br>• Runtime registration |
| **Omni Docs** | Plugin system | • Markdown plugins<br>• Custom renderers<br>• Build-time and runtime plugins<br>• Plugin manifest |

**Recommended Architecture**:

```typescript
// Plugin loader with lifecycle and sandboxing
interface PluginManifest {
  id: string;
  name: string;
  version: string;
  main: string; // Entry point
  dependencies?: Record<string, string>;
  permissions?: string[];
  activationEvents?: string[];
}

interface Plugin {
  manifest: PluginManifest;
  activate: (context: PluginContext) => void | Promise<void>;
  deactivate?: () => void | Promise<void>;
}

class PluginLoader {
  private plugins = new Map<string, Plugin>();
  private activated = new Set<string>();
  
  async load(url: string): Promise<void> {
    // Fetch manifest
    const manifestUrl = `${url}/plugin.json`;
    const manifest: PluginManifest = await fetch(manifestUrl).then(r => r.json());
    
    // Check dependencies
    if (manifest.dependencies) {
      await this.resolveDependencies(manifest.dependencies);
    }
    
    // Load plugin code
    const module = await import(/* @vite-ignore */ `${url}/${manifest.main}`);
    const plugin: Plugin = {
      manifest,
      ...module.default
    };
    
    this.plugins.set(manifest.id, plugin);
  }
  
  async activate(id: string): Promise<void> {
    const plugin = this.plugins.get(id);
    if (!plugin) throw new Error(`Plugin not found: ${id}`);
    if (this.activated.has(id)) return;
    
    // Create sandboxed context
    const context = this.createContext(plugin);
    
    // Activate
    await plugin.activate(context);
    this.activated.add(id);
    
    console.log(`Plugin activated: ${id}`);
  }
  
  async deactivate(id: string): Promise<void> {
    const plugin = this.plugins.get(id);
    if (!plugin || !this.activated.has(id)) return;
    
    if (plugin.deactivate) {
      await plugin.deactivate();
    }
    
    this.activated.delete(id);
    console.log(`Plugin deactivated: ${id}`);
  }
  
  private createContext(plugin: Plugin): PluginContext {
    // Create limited API surface based on permissions
    return {
      registerCommand: (cmd) => commandRegistry.register(cmd),
      registerComponent: (comp) => componentRegistry.register(comp),
      // ... other APIs based on permissions
    };
  }
  
  private async resolveDependencies(deps: Record<string, string>): Promise<void> {
    // Resolve and load dependencies
    for (const [name, version] of Object.entries(deps)) {
      // Check if already loaded
      // Load from CDN or local
      // Version compatibility check
    }
  }
}
```

*For security and sandboxing, see Section 7. For hot module replacement, see Section 6.*


---

## 2. Extension System

The framework provides comprehensive extension capabilities through dual languages and multiple extension points.

---

### 2.1 Extension Languages

#### 2.1.1 Custom DSL


- **Purpose**: Declarative, safe UI composition
- **Features**:
  - Simple, readable syntax for common patterns
  - Type-safe by design
  - Limited to safe operations
  - Compiles to React components
  - Hot-reloadable

**Example DSL Syntax** (conceptual):
```
dashboard "Sales Overview" {
  layout: grid(2, 2)
  
  panel chart {
    type: line
    data: query("sales.monthly")
    position: (0, 0)
  }
  
  panel table {
    data: query("sales.top_products")
    position: (1, 0)
  }
}
```

#### 2.1.2 JavaScript Extensions


- **Purpose**: Full programmatic control for advanced use cases
- **Features**:
  - Access to extension API
  - React component creation
  - Custom data transformations
  - Integration with external libraries
  - Sandboxed execution


### 2.2 Extension Points

The framework provides multiple extension points for customizing every aspect of the system.

#### 2.2.1 UI Components



**Extension Capabilities**:
- Custom chart types and visualizations
- Data widgets (tables, cards, metrics)
- Input controls and forms
- Layout containers and panels
- Themes and styling systems

**Component Extension Patterns**:

| Pattern | Description | Pros | Cons | Best For |
|---------|-------------|------|------|----------|
| **React Component** | Standard React component | ✅ Familiar<br>✅ Full ecosystem<br>✅ Easy integration | ❌ React-only<br>❌ Bundle size | React-based dashboards |
| **Web Component** | Custom elements | ✅ Framework-agnostic<br>✅ Encapsulation<br>✅ Reusable | ❌ Less ecosystem<br>❌ Complexity | Multi-framework support |
| **Plugin API** | Declarative config | ✅ Simple<br>✅ Safe<br>✅ Validated | ❌ Less flexible<br>❌ Limited features | Simple extensions |
| **Render Function** | Function returning JSX/HTML | ✅ Flexible<br>✅ Lightweight<br>✅ Composable | ❌ No lifecycle<br>❌ Manual cleanup | Simple UI elements |

**BI Dashboard Examples**:

| Platform | Component System | Extension Method |
|----------|-----------------|------------------|
| **Observable** | Reactive cells | • Custom cells with JavaScript<br>• Import external libraries<br>• Inline HTML/SVG<br>• D3.js visualizations |
| **Evidence** | Svelte components | • Custom Svelte components in /components<br>• Markdown with component tags<br>• SQL + component binding |
| **Count.co** | Canvas components | • Custom visualization cells<br>• SQL-driven components<br>• React-based extensions<br>• Drag-and-drop integration |
| **tldraw** | Shape components | • Custom shape definitions<br>• SVG-based rendering<br>• Tool components<br>• React shape API |

**Recommended Architecture**:

```typescript
// Component extension API
interface ComponentExtension {
  id: string;
  type: 'chart' | 'widget' | 'control' | 'container';
  component: React.ComponentType<any>;
  schema?: JSONSchema; // Props validation
  defaultProps?: Record<string, any>;
  icon?: string;
  category?: string;
}

// Registration
extensionAPI.registerComponent({
  id: 'custom-heatmap',
  type: 'chart',
  component: CustomHeatmap,
  schema: {
    type: 'object',
    properties: {
      data: { type: 'array' },
      colorScheme: { type: 'string', enum: ['viridis', 'plasma'] }
    }
  },
  icon: 'grid',
  category: 'Advanced Charts'
});
```

*For component registry details, see Section 1.1. For React integration, see Section 8.1.*

#### 2.2.2 Commands & Command Palette



**Core Concepts**:
- **Command Registry**: All actions exposed as named commands
- **Fuzzy Search**: Quick command discovery with intelligent matching
- **Command History**: Recently used commands for quick access
- **Parameterized Commands**: Commands that accept arguments
- **Keyboard-First**: Fully navigable via keyboard

**Architecture Overview**:

A command palette is a **searchable command interface** that provides:
1. Unified access point for all application actions
2. Fuzzy search for command discovery
3. Keyboard-driven navigation (no mouse required)
4. Context-aware command filtering
5. Command execution with optional parameters

**Key Design Decisions**:

| Aspect | Recommended Approach | Rationale |
|--------|---------------------|-----------|
| **Search Algorithm** | Fuzzy matching with ranking | Handles typos, partial matches, and prioritizes relevance |
| **Command Structure** | Hierarchical with categories | Organizes commands logically, supports grouping |
| **Activation** | Global hotkey (Cmd/Ctrl+K) | Industry standard, muscle memory from other tools |
| **UI Pattern** | Modal overlay with input + list | Focuses attention, doesn't disrupt workflow |
| **Performance** | Virtual scrolling for large lists | Handles 1000+ commands without lag |
| **Extensibility** | Plugin-contributed commands | Extensions can register custom commands |

**Architecture Patterns**:

1. **Command Registration Pattern**
   ```typescript
   interface Command {
     id: string;
     name: string;
     description?: string;
     category?: string;
     keywords?: string[];
     icon?: string;
     execute: (args?: any) => void | Promise<void>;
     when?: () => boolean; // Context condition
   }
   ```

2. **Search Ranking Strategy**
   - Exact match (highest priority)
   - Prefix match
   - Fuzzy match with position weighting
   - Keyword match
   - Recent usage boost
   - Frequency boost

3. **UI State Management**
   - Open/closed state
   - Search query
   - Selected command index
   - Filtered & ranked results
   - Command history

**Library Comparison**:

| Library | Type | Pros | Cons | Bundle Size | Use Case |
|---------|------|------|------|-------------|----------|
| **kbar** | React component | ✅ Beautiful UI<br>✅ Nested actions<br>✅ TypeScript<br>✅ Animations<br>✅ Active development | ❌ React-only<br>❌ Opinionated styling<br>❌ Limited customization | ~15KB | Modern React apps, design-focused |
| **cmdk** | React primitive | ✅ Headless/unstyled<br>✅ Flexible<br>✅ Accessible<br>✅ Small bundle<br>✅ By Vercel | ❌ React-only<br>❌ Requires styling<br>❌ More setup needed | ~8KB | Custom designs, full control |
| **ninja-keys** | Web component | ✅ Framework-agnostic<br>✅ Web components<br>✅ Zero dependencies<br>✅ Easy integration | ❌ Less flexible<br>❌ Styling limitations<br>❌ Smaller ecosystem | ~12KB | Multi-framework, simple needs |
| **command-score** | Algorithm only | ✅ Just scoring logic<br>✅ Framework-agnostic<br>✅ Tiny size<br>✅ Fast | ❌ No UI<br>❌ Build everything yourself<br>❌ More work | ~2KB | Custom implementations |
| **Fuse.js** | Fuzzy search | ✅ Powerful search<br>✅ Configurable<br>✅ Framework-agnostic<br>✅ Mature | ❌ No UI<br>❌ Larger bundle<br>❌ Overkill for simple cases | ~20KB | Complex search requirements |
| **Custom Build** | DIY | ✅ Full control<br>✅ Minimal bundle<br>✅ Tailored features<br>✅ No dependencies | ❌ Development time<br>❌ Maintenance burden<br>❌ Reinventing wheel | Varies | Unique requirements, learning |

**Fuzzy Search Algorithm Comparison**:

| Algorithm | Approach | Pros | Cons | Best For |
|-----------|----------|------|------|----------|
| **Substring Match** | Simple `includes()` | ✅ Fast<br>✅ Simple<br>✅ Predictable | ❌ No typo tolerance<br>❌ No ranking<br>❌ Order-dependent | Simple lists, exact matching |
| **Levenshtein Distance** | Edit distance | ✅ Typo-tolerant<br>✅ Well-understood<br>✅ Good ranking | ❌ Slower (O(n²))<br>❌ No position weighting | Spell-check, small datasets |
| **Fuzzy Matching** (fzy, fzf-style) | Character sequence | ✅ Fast<br>✅ Position-aware<br>✅ Intuitive results<br>✅ Handles abbreviations | ❌ More complex<br>❌ Tuning needed | Command palettes, file search |
| **N-gram Based** | Token matching | ✅ Language-aware<br>✅ Good for text<br>✅ Handles word order | ❌ Slower<br>❌ More memory<br>❌ Complex setup | Full-text search, documents |

**BI Dashboard Examples**:

| Platform | Implementation | Features | Activation |
|----------|---------------|----------|------------|
| **Observable** | Custom React component | • Fuzzy search across notebooks<br>• Recent notebooks<br>• Command suggestions<br>• Cell navigation<br>• Keyboard shortcuts reference | Cmd/Ctrl+K |
| **Evidence** | Custom implementation | • Page navigation<br>• Component search<br>• Query execution<br>• Documentation search<br>• Settings access | Cmd/Ctrl+K |
| **Count.co** | Custom React | • Canvas search<br>• Cell navigation<br>• Query execution<br>• Data source selection<br>• Quick actions | Cmd/Ctrl+K |
| **tldraw** | Custom implementation | • Shape search<br>• Tool selection<br>• Canvas actions<br>• Quick commands<br>• Keyboard shortcuts | Cmd/Ctrl+K |
| **Linear** (inspiration) | cmdk-based | • Issue search<br>• Project navigation<br>• Quick actions<br>• Nested commands<br>• Beautiful animations | Cmd/Ctrl+K |

**Recommended Architecture for BI Dashboards**:

```typescript
// Command palette architecture
interface CommandPaletteState {
  isOpen: boolean;
  query: string;
  selectedIndex: number;
  commands: Command[];
  filteredCommands: Command[];
  recentCommands: string[];
  mode: 'commands' | 'dashboards' | 'search';
}

// Multi-mode support (like VS Code)
const modes = {
  commands: {
    prefix: '>',
    placeholder: 'Type a command...',
    source: () => getAllCommands()
  },
  dashboards: {
    prefix: '',
    placeholder: 'Search dashboards...',
    source: () => getDashboards()
  },
  search: {
    prefix: '/',
    placeholder: 'Search data...',
    source: (query) => searchData(query)
  }
};
```

**Performance Optimization Strategies**:

| Strategy | Technique | Impact |
|----------|-----------|--------|
| **Virtual Scrolling** | Render only visible items | Handles 10,000+ commands smoothly |
| **Debounced Search** | Delay search by 150-300ms | Reduces unnecessary computations |
| **Memoized Results** | Cache search results | Faster re-renders on navigation |
| **Web Workers** | Offload search to worker thread | Keeps UI responsive for large datasets |
| **Indexed Commands** | Pre-build search index | Sub-millisecond lookups |
| **Lazy Loading** | Load command metadata on-demand | Faster initial load |

**Accessibility Considerations**:

- **ARIA Labels**: Proper roles and labels for screen readers
- **Keyboard Navigation**: Arrow keys, Enter, Escape, Tab
- **Focus Management**: Trap focus in modal, restore on close
- **Announcements**: Screen reader feedback for results count
- **High Contrast**: Support for high contrast themes
- **Reduced Motion**: Respect `prefers-reduced-motion`

**Advanced Features**:

1. **Nested Commands** (Breadcrumb navigation)
   - Parent command opens sub-menu
   - Back navigation with Escape
   - Visual breadcrumb trail

2. **Command Scoring**
   - Frecency (frequency + recency)
   - User preference learning
   - Context-aware boosting

3. **Multi-Step Commands**
   - Command with parameter prompts
   - Wizard-like flows
   - Validation and error handling

4. **Command Chaining**
   - Execute multiple commands in sequence
   - Macro recording
   - Batch operations

**Recommended Stack for Your Framework**:

- **React Apps**: `cmdk` (headless) or `kbar` (styled)
- **Framework-Agnostic**: `ninja-keys` or custom build
- **Search Algorithm**: Fuzzy matching (fzy-style) with position weighting
- **UI Pattern**: Modal overlay with virtual scrolling
- **State Management**: Zustand or local React state
- **Persistence**: Recent commands in LocalStorage, frecency in IndexedDB
- **Activation**: Cmd/Ctrl+K (global), with mode switching support

**Implementation Checklist**:

- [ ] Command registration system
- [ ] Fuzzy search with ranking
- [ ] Keyboard navigation (↑↓ Enter Esc)
- [ ] Virtual scrolling for performance
- [ ] Recent commands tracking
- [ ] Context-aware filtering
- [ ] Multi-mode support (commands/search/navigation)
- [ ] Accessibility (ARIA, focus management)
- [ ] Visual feedback (loading, no results)
- [ ] Mobile support (optional for BI dashboards)

*For integration with keybindings, see Section 2.2.3. For state management patterns, see Section 9.1.1.*


**Extension Capabilities**:


- Custom actions and workflows
- Data processing pipelines
- External API integrations
- Batch operations
- Scheduled tasks

**Command Extension Patterns**:

| Pattern | Description | Use Case |
|---------|-------------|----------|
| **Simple Command** | Single action | Quick operations |
| **Parameterized** | Accepts arguments | Flexible actions |
| **Async Command** | Promise-based | API calls, long operations |
| **Composite** | Multiple sub-commands | Complex workflows |
| **Scheduled** | Cron-like execution | Periodic tasks |

**BI Dashboard Examples**:

| Platform | Command System | Extension Method |
|----------|---------------|------------------|
| **Observable** | Cell execution | • Cells as commands<br>• Function exports<br>• Import and call |
| **Evidence** | Build commands | • npm scripts<br>• CLI commands<br>• No runtime commands |
| **Count.co** | Canvas commands | • Cell execution commands<br>• Query commands<br>• Canvas actions |
| **tldraw** | Tool commands | • Shape commands<br>• Canvas commands<br>• Tool actions |
| **VS Code** | Commands API | • commands.registerCommand<br>• Command palette<br>• Keybinding integration |

**Recommended API**:

```typescript
// Command registration
extensionAPI.registerCommand({
  id: 'export-to-pdf',
  name: 'Export Dashboard to PDF',
  category: 'Export',
  execute: async (context) => {
    const dashboard = context.getActiveDashboard();
    const pdf = await generatePDF(dashboard);
    await downloadFile(pdf, 'dashboard.pdf');
  },
  when: (context) => context.hasActiveDashboard(),
  icon: 'download'
});

// Pipeline command
extensionAPI.registerPipeline({
  id: 'data-transform',
  steps: [
    { command: 'fetch-data', params: { source: 'api' } },
    { command: 'transform-data', params: { type: 'aggregate' } },
    { command: 'update-panel', params: { panelId: 'main' } }
  ]
});
```

*For command palette integration, see Section 2.2.2.*

#### 2.2.3 Keybindings



**Core Concepts**:
- **Global Keybindings**: System-wide keyboard shortcuts (always active)
- **Mode-Specific Keybindings**: Context-aware shortcuts based on active component
- **Keymaps**: Hierarchical keybinding definitions with priority resolution
- **Chord Support**: Multi-key sequences (e.g., `Ctrl+x Ctrl+s`)
- **Customizable**: Users can rebind any key combination

**Architecture Overview**:

The keybinding system follows a **command-based architecture** where:
1. Commands are first-class entities with unique IDs
2. Keybindings map to commands (many-to-one relationship)
3. Context evaluation determines which bindings are active
4. Priority hierarchy resolves conflicts (Local → Mode → Global)

**Key Design Decisions**:

| Aspect | Recommended Approach | Rationale |
|--------|---------------------|-----------|
| **Command Registry** | Centralized registry with command objects | Enables command palette, customization, and discoverability |
| **Context Awareness** | "When" clauses for conditional activation | Allows same key to trigger different commands based on context |
| **Conflict Resolution** | Priority-based hierarchy with context evaluation | Predictable behavior while supporting complex scenarios |
| **Chord Sequences** | Support multi-key sequences with timeout | Expands available key combinations for power users |
| **Persistence** | Store custom bindings in IndexedDB | User customizations persist across sessions |

**Library Recommendations by Use Case**:

- **Minimal Bundle Size** (<1KB): `tinykeys` - 400 bytes, chord support, zero dependencies
- **Feature-Rich** (~3KB): `hotkeys-js` - scope support, filtering, mature ecosystem
- **React Integration** (~2KB): `react-hotkeys-hook` - hooks-based, component-scoped
- **Full Control**: Custom implementation - tailored to exact needs, no dependencies

**BI Dashboard Examples**:

- **Observable**: Command palette (Cmd+K) with fuzzy search, cell-specific shortcuts, notebook-level keybindings
- **Evidence**: Vim-like modal keybindings for power users, context-aware navigation
- **Count.co**: Canvas shortcuts (navigation, cell execution, query editing), SQL editor keybindings
- **tldraw**: Canvas shortcuts (shape creation, selection, transformation), tool-specific bindings
- **VS Code** (pattern): Comprehensive "when" clause system, keybinding editor UI

*See Section 9.1.2 for detailed architectural analysis, pros/cons comparison, and implementation strategies.*


**Extension Capabilities**:


- Custom keyboard shortcuts
- Mode-specific bindings
- Chord sequences (multi-key)
- Macro recording and playback
- Context-aware activation

**Keybinding Extension Patterns**:

| Approach | Implementation | Pros | Cons |
|----------|---------------|------|------|
| **Declarative** | JSON/YAML config | ✅ Simple<br>✅ Validated<br>✅ Safe | ❌ Limited logic<br>❌ No dynamic binding |
| **Programmatic** | API calls | ✅ Flexible<br>✅ Dynamic<br>✅ Conditional | ❌ More complex<br>❌ Error-prone |
| **Hybrid** | Config + API | ✅ Best of both<br>✅ Validated + flexible | ❌ Two systems | 

**BI Dashboard Examples**:

| Platform | Keybinding System | Extension Method |
|----------|------------------|------------------|
| **Observable** | Built-in shortcuts | • Limited customization<br>• Cell-level shortcuts<br>• Cmd+K command palette |
| **Evidence** | Not extensible | • Fixed keybindings<br>• No custom shortcuts |
| **Count.co** | Canvas shortcuts | • Cell navigation keys<br>• Query execution shortcuts<br>• Custom keybindings |
| **tldraw** | Tool shortcuts | • Shape creation keys<br>• Canvas navigation<br>• Tool-specific bindings |
| **VS Code** | Keybindings API | • keybindings.json<br>• when clauses<br>• Full customization |

**Recommended API**:

```typescript
// Keybinding extension
extensionAPI.registerKeybinding({
  key: 'Ctrl+Shift+E',
  command: 'export-dashboard',
  when: 'dashboardActive && !editing',
  description: 'Export current dashboard'
});

// Macro support
extensionAPI.registerMacro({
  name: 'refresh-all-panels',
  keys: ['Ctrl+R', 'Ctrl+A'],
  actions: [
    { command: 'select-all-panels' },
    { command: 'refresh-panels' }
  ]
});
```

*For keybinding architecture, see Section 2.2.3 and 9.1.2.*


> **Note**: Detailed keybinding architecture consolidated here from multiple sections.

#### 2.2.4 Themes



**Extension Capabilities**:
- Color schemes and palettes
- Typography systems
- Component styling
- Dark/light mode variants
- Custom CSS variables

**Theme Extension Patterns**:

| Approach | Implementation | Pros | Cons |
|----------|---------------|------|------|
| **CSS Variables** | Override root variables | ✅ Simple<br>✅ Performant<br>✅ Dynamic | ❌ Limited scope<br>❌ No logic |
| **Theme Object** | JavaScript config | ✅ Type-safe<br>✅ Validated<br>✅ Programmatic | ❌ Runtime overhead<br>❌ More complex |
| **CSS File** | Separate stylesheet | ✅ Familiar<br>✅ Standard<br>✅ Cacheable | ❌ No dynamic<br>❌ Load overhead |
| **Hybrid** | Variables + Object | ✅ Flexible<br>✅ Best of both | ❌ Complexity |

**BI Dashboard Examples**:

| Platform | Theme System | Extension Method |
|----------|-------------|------------------|
| **Observable** | CSS variables | • Custom CSS in cells<br>• Theme cells<br>• CSS imports |
| **Evidence** | Tailwind config | • tailwind.config.js<br>• Custom CSS<br>• Component styling |
| **Count.co** | Theme settings | • Color customization<br>• Canvas themes<br>• CSS variables |
| **tldraw** | Theme system | • CSS variables<br>• Custom themes<br>• Dark/light mode<br>• Color overrides |

**Recommended API**:

```typescript
// Theme registration
extensionAPI.registerTheme({
  id: 'ocean-blue',
  name: 'Ocean Blue',
  type: 'dark',
  colors: {
    primary: '#0077be',
    background: '#001f3f',
    text: '#ffffff',
    // ... more colors
  },
  typography: {
    fontFamily: 'Inter, sans-serif',
    fontSize: {
      base: '14px',
      heading: '24px'
    }
  },
  shadows: {
    sm: '0 1px 2px rgba(0,0,0,0.1)',
    md: '0 4px 6px rgba(0,0,0,0.1)'
  }
});
```

*For theme architecture, see Section 9.1.3.*

#### 2.2.5 Layouts

**Buffer/Window Model**:


- **Buffers**: Logical content containers (data views, charts, tables)
- **Windows**: Visual panes that display buffers
- **Layout Management**: Split, resize, and arrange windows dynamically
- **Buffer Switching**: Quick navigation between different data views


**Extension Capabilities**:


- Window arrangements
- Dashboard templates
- Responsive breakpoints
- Grid configurations
- Split pane layouts

**Layout Extension Patterns**:

| Pattern | Description | Use Case |
|---------|-------------|----------|
| **Template** | Predefined layout | Quick start dashboards |
| **Programmatic** | Code-defined layout | Dynamic layouts |
| **Declarative** | JSON/YAML config | Shareable layouts |
| **Interactive** | Drag-and-drop | User customization |

**BI Dashboard Examples**:

| Platform | Layout System | Extension Method |
|----------|--------------|------------------|
| **Observable** | Notebook flow | • Linear cell layout<br>• Custom layouts via HTML<br>• Grid layouts in cells |
| **Evidence** | Page templates | • Markdown-based<br>• Component slots<br>• Fixed layouts |
| **Count.co** | Canvas layout | • Free-form canvas<br>• Cell positioning<br>• Auto-layout options<br>• Responsive grids |
| **tldraw** | Canvas system | • Infinite canvas<br>• Shape positioning<br>• Grouping and frames<br>• Custom layouts |

**Recommended API**:

```typescript
// Layout template registration
extensionAPI.registerLayoutTemplate({
  id: 'analytics-dashboard',
  name: 'Analytics Dashboard',
  description: '3-column layout with header',
  thumbnail: '/templates/analytics.png',
  layout: {
    type: 'grid',
    cols: 12,
    rows: 'auto',
    items: [
      { id: 'header', x: 0, y: 0, w: 12, h: 2, component: 'header' },
      { id: 'sidebar', x: 0, y: 2, w: 3, h: 10, component: 'sidebar' },
      { id: 'main', x: 3, y: 2, w: 9, h: 10, component: 'main' }
    ]
  },
  responsive: {
    mobile: { cols: 1 },
    tablet: { cols: 6 },
    desktop: { cols: 12 }
  }
});
```

*For layout architecture, see Section 9.1.4.*

#### 2.2.6 Hooks & Advice



**Core Concepts**:

**Hooks** are extension points that allow plugins to inject custom behavior at specific lifecycle events without modifying core code.

**Advice** is a technique to wrap or modify existing functions, enabling plugins to intercept, augment, or replace behavior.

**Architecture Overview**:

The hooks and advice system provides a **plugin architecture** that enables:
1. Decoupled extension points throughout the application
2. Multiple handlers for the same event (observer pattern)
3. Function interception and modification (aspect-oriented programming)
4. Plugin lifecycle management
5. Predictable execution order

**Key Design Decisions**:

| Aspect | Recommended Approach | Rationale |
|--------|---------------------|-----------|
| **Hook Registration** | Event emitter pattern with typed events | Type-safe, familiar pattern, supports multiple listeners |
| **Execution Order** | Priority-based with explicit ordering | Predictable behavior, handles dependencies |
| **Error Handling** | Isolated execution with error boundaries | One plugin failure doesn't break others |
| **Async Support** | Promise-based hooks with timeout | Handles async operations, prevents hanging |
| **Advice Pattern** | Middleware/decorator pattern | Composable, chainable, familiar to developers |
| **Unsubscribe** | Return cleanup function | Prevents memory leaks, follows React patterns |

**Hook Types & Use Cases**:

| Hook Category | Examples | Use Cases |
|---------------|----------|-----------|
| **Lifecycle Hooks** | `app-init`, `app-ready`, `app-destroy` | Initialize services, cleanup resources |
| **Render Hooks** | `before-render`, `after-render`, `render-error` | Inject UI, track performance, error handling |
| **State Hooks** | `before-state-change`, `after-state-change`, `state-hydrate` | Validation, logging, persistence |
| **Plugin Hooks** | `plugin-loaded`, `plugin-activated`, `plugin-unloaded` | Plugin coordination, dependency management |
| **Data Hooks** | `before-query`, `after-query`, `query-error` | Data transformation, caching, error handling |
| **Navigation Hooks** | `before-navigate`, `after-navigate`, `route-change` | Analytics, guards, breadcrumbs |
| **User Action Hooks** | `command-execute`, `keybinding-trigger`, `menu-click` | Analytics, macros, automation |

**Architecture Patterns**:

1. **Event Emitter Pattern** (Hooks)
   ```typescript
   interface HookSystem {
     on(event: string, handler: Function, priority?: number): () => void;
     emit(event: string, ...args: any[]): Promise<void>;
     once(event: string, handler: Function): () => void;
     off(event: string, handler: Function): void;
   }
   
   // Usage
   const unsubscribe = hooks.on('before-render', (context) => {
     console.log('Rendering:', context.component);
   });
   ```

2. **Middleware Pattern** (Advice)
   ```typescript
   type Middleware<T> = (
     context: T,
     next: () => Promise<any>
   ) => Promise<any>;
   
   // Usage
   const loggingMiddleware: Middleware<QueryContext> = async (ctx, next) => {
     console.log('Query start:', ctx.query);
     const result = await next();
     console.log('Query end:', result);
     return result;
   };
   ```

3. **Decorator Pattern** (Advice)
   ```typescript
   function withLogging(fn: Function) {
     return function(...args: any[]) {
       console.log('Before:', args);
       const result = fn.apply(this, args);
       console.log('After:', result);
       return result;
     };
   }
   ```

**Library Comparison**:

| Library | Type | Pros | Cons | Bundle Size | Use Case |
|---------|------|------|------|-------------|----------|
| **mitt** | Event emitter | ✅ Tiny (200B)<br>✅ Simple API<br>✅ TypeScript support<br>✅ No dependencies | ❌ No priority ordering<br>❌ No async handling<br>❌ Basic features only | 200B | Lightweight hooks, simple events |
| **eventemitter3** | Event emitter | ✅ Fast performance<br>✅ Mature<br>✅ Node.js compatible<br>✅ Well-tested | ❌ Larger bundle<br>❌ No TypeScript out of box<br>❌ No priority support | ~2KB | Production apps, performance-critical |
| **nanoevents** | Event emitter | ✅ Very small (200B)<br>✅ Simple<br>✅ TypeScript support | ❌ Minimal features<br>❌ No wildcards<br>❌ No priority | 200B | Minimal footprint, basic needs |
| **hookified** | Hook system | ✅ Built for plugins<br>✅ Priority support<br>✅ Async hooks<br>✅ Typed | ❌ Less popular<br>❌ Smaller ecosystem | ~3KB | Plugin systems, complex hooks |
| **Tapable** | Hook system | ✅ Webpack's hook system<br>✅ Very powerful<br>✅ Multiple hook types<br>✅ Battle-tested | ❌ Complex API<br>❌ Large bundle<br>❌ Steep learning curve | ~10KB | Complex plugin systems, Webpack-like |
| **Custom Build** | DIY | ✅ Tailored features<br>✅ Minimal size<br>✅ Full control | ❌ Development time<br>❌ Testing needed<br>❌ Maintenance | Varies | Specific requirements |

**Hook System Implementation Patterns**:

| Pattern | Description | Pros | Cons |
|---------|-------------|------|------|
| **Simple Event Emitter** | Basic pub/sub | ✅ Simple<br>✅ Familiar<br>✅ Small | ❌ No ordering<br>❌ No async control |
| **Priority Queue** | Ordered execution by priority | ✅ Predictable order<br>✅ Dependency handling | ❌ More complex<br>❌ Priority conflicts |
| **Async Waterfall** | Sequential async execution | ✅ Data transformation<br>✅ Pipeline pattern | ❌ Slower<br>❌ Error propagation |
| **Async Parallel** | Concurrent execution | ✅ Fast<br>✅ Independent handlers | ❌ No ordering<br>❌ Race conditions |
| **Async Series** | Sequential with results | ✅ Ordered<br>✅ Result aggregation | ❌ Slower<br>❌ Blocking |

**Advice Pattern Comparison**:

| Pattern | Implementation | Pros | Cons | Best For |
|---------|---------------|------|------|----------|
| **Proxy-Based** | ES6 Proxy | ✅ Transparent<br>✅ No code changes<br>✅ Powerful | ❌ Performance overhead<br>❌ Debugging harder<br>❌ Browser support | Dynamic interception |
| **Decorator-Based** | Function wrapping | ✅ Explicit<br>✅ Composable<br>✅ TypeScript support | ❌ Requires wrapping<br>❌ Boilerplate | Explicit augmentation |
| **Middleware Chain** | Express-style | ✅ Familiar pattern<br>✅ Composable<br>✅ Async-friendly | ❌ More setup<br>❌ Context passing | Request/response flows |
| **AOP Framework** | AspectJ-style | ✅ Powerful<br>✅ Declarative<br>✅ Cross-cutting | ❌ Complex<br>❌ Large bundle<br>❌ Learning curve | Enterprise apps |

**BI Dashboard Examples**:

| Platform | Hook System | Advice System | Implementation Details |
|----------|-------------|---------------|------------------------|
| **Observable** | Custom event system | Runtime notebook hooks | • Cell execution hooks<br>• Import hooks<br>• Reactive dependency tracking<br>• Custom hook for data loading |
| **Evidence** | Component lifecycle | Build-time hooks | • Page build hooks<br>• Component mount/unmount<br>• Data query hooks<br>• Markdown processing hooks |
| **Count.co** | Canvas lifecycle | Canvas hooks | • Cell execution hooks<br>• Query lifecycle hooks<br>• Canvas render hooks<br>• Collaboration hooks |
| **tldraw** | Shape lifecycle | Shape hooks | • Shape creation/update hooks<br>• Canvas interaction hooks<br>• History hooks (undo/redo)<br>• Selection hooks |
| **VS Code** | Extension API | Command/menu contribution | • Activation events<br>• Language server hooks<br>• Workspace events<br>• Decoration providers |
| **Webpack** | Tapable hooks | Compilation hooks | • Compiler hooks<br>• Compilation hooks<br>• Module hooks<br>• Asset optimization |

**Recommended Architecture for BI Dashboards**:

```typescript
// Hook system with priority and async support
class HookSystem {
  private hooks = new Map<string, Hook[]>();
  
  on(event: string, handler: Function, priority = 10): () => void {
    if (!this.hooks.has(event)) {
      this.hooks.set(event, []);
    }
    
    const hook = { handler, priority };
    const hooks = this.hooks.get(event)!;
    
    // Insert by priority (higher = earlier)
    const index = hooks.findIndex(h => h.priority < priority);
    if (index === -1) {
      hooks.push(hook);
    } else {
      hooks.splice(index, 0, hook);
    }
    
    // Return unsubscribe function
    return () => {
      const hooks = this.hooks.get(event);
      if (hooks) {
        const idx = hooks.indexOf(hook);
        if (idx > -1) hooks.splice(idx, 1);
      }
    };
  }
  
  async emit(event: string, context: any): Promise<any> {
    const hooks = this.hooks.get(event) || [];
    let result = context;
    
    for (const { handler } of hooks) {
      try {
        const handlerResult = await handler(result);
        // Allow handlers to transform data
        if (handlerResult !== undefined) {
          result = handlerResult;
        }
      } catch (error) {
        console.error(`Hook error in ${event}:`, error);
        // Continue with other hooks
      }
    }
    
    return result;
  }
}

// Advice system with middleware pattern
class AdviceSystem {
  private advices = new Map<string, Middleware[]>();
  
  addAdvice(target: string, middleware: Middleware): () => void {
    if (!this.advices.has(target)) {
      this.advices.set(target, []);
    }
    
    this.advices.get(target)!.push(middleware);
    
    return () => {
      const advices = this.advices.get(target);
      if (advices) {
        const idx = advices.indexOf(middleware);
        if (idx > -1) advices.splice(idx, 1);
      }
    };
  }
  
  async execute(target: string, context: any, original: Function): Promise<any> {
    const advices = this.advices.get(target) || [];
    
    // Build middleware chain
    let index = 0;
    const next = async (): Promise<any> => {
      if (index < advices.length) {
        const middleware = advices[index++];
        return middleware(context, next);
      } else {
        // Execute original function
        return original(context);
      }
    };
    
    return next();
  }
}
```

**Common Hook Patterns**:

1. **Data Transformation Pipeline**
   ```typescript
   // Transform data through multiple plugins
   hooks.on('data-transform', (data) => {
     return { ...data, transformed: true };
   });
   
   const result = await hooks.emit('data-transform', rawData);
   ```

2. **Validation Chain**
   ```typescript
   // Validate with multiple validators
   hooks.on('validate-dashboard', (dashboard) => {
     if (!dashboard.title) throw new Error('Title required');
     return dashboard;
   });
   ```

3. **Lifecycle Management**
   ```typescript
   // Plugin initialization
   hooks.on('plugin-loaded', async (plugin) => {
     await plugin.initialize();
     console.log(`Plugin ${plugin.name} loaded`);
   });
   ```

4. **Conditional Execution**
   ```typescript
   // Execute only if condition met
   hooks.on('before-save', (data) => {
     if (data.needsValidation) {
       return validate(data);
     }
     return data;
   });
   ```

**Performance Considerations**:

| Concern | Strategy | Impact |
|---------|----------|--------|
| **Too Many Hooks** | Debounce/throttle high-frequency hooks | Reduces CPU usage |
| **Slow Handlers** | Timeout enforcement | Prevents hanging |
| **Memory Leaks** | Automatic cleanup on plugin unload | Prevents memory growth |
| **Error Propagation** | Isolated execution with try/catch | Stability |
| **Async Coordination** | Promise.all for parallel, sequential for order | Performance vs order |

**Security Considerations**:

- **Sandboxing**: Execute plugin hooks in isolated context
- **Capability Checks**: Verify plugin has permission for hook
- **Input Validation**: Sanitize data passed to hooks
- **Timeout Enforcement**: Prevent infinite loops
- **Resource Limits**: Cap memory/CPU usage per hook

**Advanced Features**:

1. **Hook Composition**
   - Combine multiple hooks into one
   - Reusable hook patterns
   - Hook inheritance

2. **Conditional Hooks**
   - Execute only when condition met
   - Context-aware activation
   - Dynamic hook registration

3. **Hook Debugging**
   - Hook execution tracing
   - Performance profiling
   - Dependency visualization

4. **Hook Versioning**
   - API version compatibility
   - Deprecation warnings
   - Migration helpers

**Recommended Stack**:

- **Simple Hooks**: `mitt` (200B) or `eventemitter3` (~2KB)
- **Complex Plugin System**: `Tapable` or custom implementation
- **Advice/Middleware**: Custom middleware chain
- **Type Safety**: TypeScript with strict typing
- **Error Handling**: Isolated execution with error boundaries
- **Async**: Promise-based with timeout enforcement

**Implementation Checklist**:

- [ ] Hook registration system with priority
- [ ] Event emitter with typed events
- [ ] Async hook support with timeout
- [ ] Error isolation per handler
- [ ] Unsubscribe/cleanup mechanism
- [ ] Middleware/advice pattern
- [ ] Plugin lifecycle hooks
- [ ] Documentation for hook points
- [ ] Debugging/tracing tools
- [ ] Performance monitoring

*For plugin architecture, see Section 1.4. For extension patterns, see Section 2.1.*


### 2.3 Hot Reloading



**Overview**: Hot Module Replacement (HMR) enables developers to update extensions in real-time without losing application state, dramatically improving development velocity.

**Core Capabilities**:
- Live code updates without page refresh
- State preservation across reloads
- Error recovery and isolation
- Enhanced debugging and error reporting

**HMR Architecture Patterns**:

| Pattern | Description | Pros | Cons | Best For |
|---------|-------------|------|------|----------|
| **Full Reload** | Refresh entire page | ✅ Simple<br>✅ Reliable<br>✅ No state issues | ❌ Slow<br>❌ Loses state<br>❌ Poor DX | Production, simple apps |
| **Module HMR** | Replace individual modules | ✅ Fast<br>✅ Preserves state<br>✅ Good DX | ❌ Complex<br>❌ State management<br>❌ Edge cases | Development, modern apps |
| **Component HMR** | Replace React components | ✅ Very fast<br>✅ Preserves local state<br>✅ Best DX | ❌ React-specific<br>❌ Requires setup | React development |
| **Live Reload** | Watch files, auto-refresh | ✅ Simple<br>✅ Universal<br>✅ Reliable | ❌ Loses state<br>❌ Slower<br>❌ Full reload | Simple development |

**HMR Library Comparison**:

| Tool | Type | Pros | Cons | Use Case |
|------|------|------|------|----------|
| **Vite HMR** | Build tool | ✅ Very fast<br>✅ ESM-based<br>✅ Simple API<br>✅ React Fast Refresh | ❌ Vite-specific<br>❌ Modern browsers only | Modern React/Vue apps |
| **Webpack HMR** | Build tool | ✅ Mature<br>✅ Powerful<br>✅ Ecosystem<br>✅ Configurable | ❌ Complex<br>❌ Slower<br>❌ Large config | Enterprise apps |
| **Parcel HMR** | Build tool | ✅ Zero config<br>✅ Fast<br>✅ Automatic | ❌ Less control<br>❌ Smaller ecosystem | Quick prototypes |
| **React Fast Refresh** | React HMR | ✅ Preserves state<br>✅ Error recovery<br>✅ Best DX | ❌ React-only<br>❌ Requires setup | React development |
| **Custom HMR** | DIY | ✅ Full control<br>✅ Tailored | ❌ Complex<br>❌ Maintenance | Unique requirements |

**State Preservation Strategies**:

| Strategy | Implementation | Pros | Cons |
|----------|---------------|------|------|
| **Local State** | Component state preserved | ✅ Automatic<br>✅ Simple | ❌ Only local state<br>❌ Limited |
| **Global State** | Store persisted | ✅ Full state<br>✅ Reliable | ❌ Manual setup<br>❌ Serialization |
| **Snapshot** | Save/restore state | ✅ Complete<br>✅ Flexible | ❌ Complex<br>❌ Performance |
| **Hybrid** | Critical state persisted | ✅ Balanced<br>✅ Optimized | ❌ More logic | 

**BI Dashboard Examples**:

| Platform | HMR System | Implementation |
|----------|-----------|----------------|
| **Observable** | Live evaluation | • Cell re-execution on change<br>• Reactive dependency tracking<br>• Instant feedback<br>• State in cells |
| **Evidence** | Vite HMR | • Vite dev server<br>• Svelte HMR<br>• Fast refresh<br>• Component state preserved |
| **Count.co** | Vite HMR | • React Fast Refresh<br>• Canvas state preservation<br>• Cell hot reload<br>• Query result caching |
| **tldraw** | Vite HMR | • Shape state preservation<br>• Canvas hot reload<br>• Tool hot swap<br>• History preservation |

**Error Recovery Patterns**:

| Pattern | Description | Use Case |
|---------|-------------|----------|
| **Error Boundary** | React error boundaries | Isolate component errors |
| **Fallback UI** | Show error state | User-friendly error display |
| **Auto-Retry** | Retry failed reload | Transient errors |
| **Rollback** | Revert to last working | Critical failures |

**Recommended Architecture**:

```typescript
// HMR integration for extensions
if (import.meta.hot) {
  import.meta.hot.accept((newModule) => {
    // Preserve state
    const currentState = extensionAPI.getState();
    
    // Unload old extension
    extensionAPI.unload(extensionId);
    
    // Load new extension
    extensionAPI.load(newModule.default);
    
    // Restore state
    extensionAPI.setState(currentState);
    
    console.log('Extension hot reloaded:', extensionId);
  });
  
  import.meta.hot.dispose(() => {
    // Cleanup before reload
    extensionAPI.cleanup(extensionId);
  });
}

// Error recovery
window.addEventListener('error', (event) => {
  if (event.filename?.includes('/extensions/')) {
    // Extension error - isolate and recover
    extensionAPI.handleError(event.error);
    event.preventDefault();
  }
});
```

**Development Mode Features**:

- **Source Maps**: Map compiled code to source for debugging
- **Error Overlay**: Full-screen error display with stack traces
- **Console Integration**: Enhanced logging with extension context
- **Performance Profiling**: Track reload times and bottlenecks
- **State Inspector**: Visualize state changes
- **Network Monitoring**: Track extension API calls

*For build tool configuration, see Section 6. For plugin lifecycle, see Section 1.4.*


---

## 3. Security Model



**Overview**: A comprehensive security model protects users from malicious extensions while enabling powerful customization capabilities.

### 3.1 Sandboxing & Permissions

#### 6.1 Execution Environment

**Sandboxing Approaches**:

| Approach | Description | Pros | Cons | Best For |
|----------|-------------|------|------|----------|
| **SES (Secure ECMAScript)** | Hardened JavaScript subset | ✅ Strong isolation<br>✅ No global access<br>✅ Deterministic | ❌ Limited APIs<br>❌ Learning curve<br>❌ Compatibility | High-security needs |
| **iframe Sandbox** | Isolated iframe context | ✅ True isolation<br>✅ Separate origin<br>✅ CSP support | ❌ Communication overhead<br>❌ Performance<br>❌ Complex | Untrusted code |
| **Web Workers** | Background thread | ✅ No DOM access<br>✅ Isolated<br>✅ Parallel | ❌ No UI<br>❌ Message passing<br>❌ Limited | CPU-intensive tasks |
| **Proxy-Based** | Intercept API calls | ✅ Flexible<br>✅ Fine-grained<br>✅ Auditable | ❌ Performance overhead<br>❌ Complex<br>❌ Bypassable | API control |
| **VM Isolation** | Separate JavaScript VM | ✅ Complete isolation<br>✅ Resource limits | ❌ Large overhead<br>❌ Complex<br>❌ Limited browser support | Maximum security |

**Sandboxing Library Comparison**:

| Library | Type | Pros | Cons | Use Case |
|---------|------|------|------|----------|
| **SES (Agoric)** | Hardened JS | ✅ Strong security<br>✅ Deterministic<br>✅ Well-designed | ❌ Limited ecosystem<br>❌ Learning curve | High-security extensions |
| **Realms API** | TC39 proposal | ✅ Native<br>✅ Isolated globals<br>✅ Standard | ❌ Not widely supported<br>❌ Experimental | Future-proof |
| **vm2** | Node.js VM | ✅ Powerful<br>✅ Mature | ❌ Node-only<br>❌ Not browser | Server-side only |
| **Sandboxed iframe** | Native browser | ✅ Built-in<br>✅ Strong isolation<br>✅ CSP | ❌ Communication overhead<br>❌ Complex | Untrusted content |
| **Custom Proxy** | DIY | ✅ Full control<br>✅ Tailored | ❌ Development time<br>❌ Security risks | Specific needs |

**BI Dashboard Examples**:

| Platform | Security Model | Implementation |
|----------|---------------|----------------|
| **Observable** | Runtime sandboxing | • Restricted global scope<br>• No direct DOM access<br>• Controlled imports<br>• Rate limiting |
| **Evidence** | Build-time validation | • Component validation<br>• SQL parameterization<br>• No runtime eval<br>• Static analysis |
| **Count.co** | SQL sandboxing | • Parameterized queries<br>• Query validation<br>• Permission-based access<br>• Audit logging |
| **tldraw** | Client-side validation | • Shape validation<br>• Canvas bounds checking<br>• User permissions<br>• Collaboration security |

**DOM Access Control**:

```typescript
// Controlled DOM API
const createSandboxedAPI = (extensionId: string, permissions: string[]) => {
  const allowedAPIs: any = {};
  
  if (permissions.includes('ui:render')) {
    // Limited DOM access
    allowedAPIs.createElement = (tag: string) => {
      if (!['div', 'span', 'p', 'button'].includes(tag)) {
        throw new Error(`Tag ${tag} not allowed`);
      }
      return document.createElement(tag);
    };
  }
  
  if (permissions.includes('storage:local')) {
    // Namespaced storage
    allowedAPIs.storage = {
      get: (key: string) => localStorage.getItem(`ext_${extensionId}_${key}`),
      set: (key: string, value: string) => 
        localStorage.setItem(`ext_${extensionId}_${key}`, value)
    };
  }
  
  return allowedAPIs;
};
```

*For DOM access patterns, see Section 4.1. For API design, see Section 6.3.*

#### 6.2 Capability-Based Permissions

**Permission Model**:

Extensions declare required capabilities in manifest:

```json
{
  "id": "custom-chart",
  "name": "Custom Chart Extension",
  "version": "1.0.0",
  "permissions": [
    "data:read",
    "ui:render",
    "storage:local"
  ]
}
```

**Permission Categories**:

| Permission | Description | Risk Level | Use Cases |
|------------|-------------|------------|----------|
| `data:read` | Read dashboard data | Low | Visualizations, analytics |
| `data:write` | Modify dashboard data | Medium | Data transformations, filters |
| `ui:render` | Render custom UI | Low | Custom components, charts |
| `storage:local` | Access localStorage | Low | User preferences, cache |
| `storage:indexed` | Access IndexedDB | Medium | Large datasets, offline |
| `network:fetch` | Make HTTP requests | High | External APIs, data sources |
| `network:websocket` | WebSocket connections | High | Real-time data |
| `system:commands` | Register commands | Low | Custom actions |
| `system:keybindings` | Register keybindings | Low | Keyboard shortcuts |
| `system:eval` | Execute arbitrary code | Critical | Advanced extensions (rarely granted) |

**Permission Grant Patterns**:

| Pattern | Description | Pros | Cons |
|---------|-------------|------|------|
| **Install-Time** | User approves on install | ✅ Clear<br>✅ One-time | ❌ Users ignore<br>❌ All-or-nothing |
| **Runtime** | Request when needed | ✅ Contextual<br>✅ Granular | ❌ Interrupts flow<br>❌ Frequent prompts |
| **Tiered** | Basic vs advanced permissions | ✅ Balanced<br>✅ Progressive | ❌ More complex |
| **Automatic** | Based on extension type | ✅ No prompts<br>✅ Simple | ❌ Less control<br>❌ Security risk |

**Runtime Permission Validation**:

```typescript
class PermissionManager {
  private grants = new Map<string, Set<string>>();
  
  grant(extensionId: string, permission: string): void {
    if (!this.grants.has(extensionId)) {
      this.grants.set(extensionId, new Set());
    }
    this.grants.get(extensionId)!.add(permission);
    this.audit('grant', extensionId, permission);
  }
  
  check(extensionId: string, permission: string): boolean {
    return this.grants.get(extensionId)?.has(permission) ?? false;
  }
  
  enforce(extensionId: string, permission: string): void {
    if (!this.check(extensionId, permission)) {
      this.audit('denied', extensionId, permission);
      throw new Error(`Permission denied: ${permission}`);
    }
  }
  
  private audit(action: string, extensionId: string, permission: string): void {
    console.log(`[Security] ${action}: ${extensionId} -> ${permission}`);
    // Log to audit system
  }
}
```

*For permission UI patterns, see Section 2.2. For audit logging, see Section 6.3.*

#### 6.3 API Surface

**API Design Principles**:

- **Minimal Surface**: Only expose necessary functions
- **Explicit Over Implicit**: Clear, documented behavior
- **Versioned**: Maintain backward compatibility
- **Type-Safe**: TypeScript definitions
- **Auditable**: Log all sensitive operations

**API Versioning Strategies**:

| Strategy | Description | Pros | Cons |
|----------|-------------|------|------|
| **Semantic Versioning** | Major.Minor.Patch | ✅ Clear<br>✅ Standard<br>✅ Predictable | ❌ Breaking changes<br>❌ Migration needed |
| **API Levels** | Level 1, 2, 3 | ✅ Simple<br>✅ Clear deprecation | ❌ Less granular |
| **Feature Flags** | Opt-in features | ✅ Gradual rollout<br>✅ A/B testing | ❌ Complexity<br>❌ State explosion |
| **Parallel APIs** | v1, v2 coexist | ✅ No breaking changes<br>✅ Smooth migration | ❌ Maintenance burden<br>❌ Code duplication |

**Audit Logging**:

```typescript
interface AuditEvent {
  timestamp: number;
  extensionId: string;
  action: string;
  resource: string;
  success: boolean;
  metadata?: Record<string, any>;
}

class AuditLogger {
  private events: AuditEvent[] = [];
  
  log(event: Omit<AuditEvent, 'timestamp'>): void {
    this.events.push({
      ...event,
      timestamp: Date.now()
    });
    
    // Persist to IndexedDB
    // Send to analytics
    // Alert on suspicious patterns
  }
  
  query(filter: Partial<AuditEvent>): AuditEvent[] {
    return this.events.filter(event => 
      Object.entries(filter).every(([key, value]) => 
        event[key as keyof AuditEvent] === value
      )
    );
  }
}
```

*For API design patterns, see Section 1. For versioning, see Section 6.*

#### 6.4 Code Review & Signing

**Extension Marketplace Security**:

| Layer | Mechanism | Purpose |
|-------|-----------|----------|
| **Submission** | Manual review | Human verification |
| **Automated Scan** | Static analysis | Detect vulnerabilities |
| **Code Signing** | Cryptographic signature | Verify authenticity |
| **Sandboxing** | Runtime isolation | Limit damage |
| **Monitoring** | Usage analytics | Detect abuse |
| **Reporting** | User feedback | Community oversight |

**Code Signing Implementation**:

```typescript
// Extension signing
async function signExtension(extensionCode: string, privateKey: CryptoKey): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(extensionCode);
  
  const signature = await crypto.subtle.sign(
    { name: 'RSASSA-PKCS1-v1_5' },
    privateKey,
    data
  );
  
  return btoa(String.fromCharCode(...new Uint8Array(signature)));
}

// Signature verification
async function verifyExtension(
  extensionCode: string,
  signature: string,
  publicKey: CryptoKey
): Promise<boolean> {
  const encoder = new TextEncoder();
  const data = encoder.encode(extensionCode);
  const sig = Uint8Array.from(atob(signature), c => c.charCodeAt(0));
  
  return await crypto.subtle.verify(
    { name: 'RSASSA-PKCS1-v1_5' },
    publicKey,
    sig,
    data
  );
}
```

**Security Scanning Tools**:

| Tool | Type | Detects | Use Case |
|------|------|---------|----------|
| **ESLint Security** | Static analysis | Common vulnerabilities | Development |
| **npm audit** | Dependency scan | Known CVEs | CI/CD |
| **Snyk** | Vulnerability DB | Dependencies, code | Production |
| **SonarQube** | Code quality | Security hotspots | Enterprise |
| **Custom Rules** | Domain-specific | Extension-specific risks | Marketplace |

**User Warning System**:

```typescript
interface ExtensionTrust {
  level: 'verified' | 'reviewed' | 'community' | 'unverified';
  badges: string[];
  warnings: string[];
}

function getExtensionTrust(extension: Extension): ExtensionTrust {
  const trust: ExtensionTrust = {
    level: 'unverified',
    badges: [],
    warnings: []
  };
  
  if (extension.signature && verifySignature(extension)) {
    trust.level = 'verified';
    trust.badges.push('Code Signed');
  }
  
  if (extension.reviewStatus === 'approved') {
    trust.level = 'reviewed';
    trust.badges.push('Reviewed');
  }
  
  if (extension.permissions.includes('network:fetch')) {
    trust.warnings.push('Makes external network requests');
  }
  
  if (extension.permissions.includes('system:eval')) {
    trust.warnings.push('Can execute arbitrary code');
  }
  
  return trust;
}
```

**Recommended Security Stack**:

- **Sandboxing**: SES (Secure ECMAScript) for high-security
- **Permissions**: Capability-based with runtime checks
- **API**: Minimal, versioned, type-safe
- **Signing**: Ed25519 or RSA-2048 signatures
- **Scanning**: ESLint Security + Snyk
- **Monitoring**: Audit logs + anomaly detection
- **Marketplace**: Manual review + automated scanning

*For plugin architecture, see Section 1.4. For extension development, see Section 2.1.*


> **Note**: Security technologies (SES, CSP, Subresource Integrity) are detailed in Section 6.3.

---

## 4. Advanced Features

Modern BI dashboard capabilities including canvas interfaces, SQL integration, real-time collaboration, and performance optimization.

---

### 4.1 Canvas Architecture



**Overview**: Canvas-based interfaces (inspired by Count.co and tldraw) provide infinite workspace for flexible data exploration and visualization.

**Infinite Canvas Pattern**:

| Aspect | Implementation | Pros | Cons |
|--------|---------------|------|------|
| **Viewport Management** | Transform matrix | ✅ Smooth pan/zoom<br>✅ Efficient rendering | ❌ Complex math<br>❌ Coordinate transforms |
| **Virtualization** | Render visible area only | ✅ Performance<br>✅ Scales to large canvases | ❌ Implementation complexity<br>❌ Edge cases |
| **Spatial Indexing** | R-tree or Quadtree | ✅ Fast queries<br>✅ Collision detection | ❌ Memory overhead<br>❌ Update complexity |
| **Layer System** | Separate canvas layers | ✅ Compositing<br>✅ Selective updates | ❌ More canvases<br>❌ Coordination |

**Cell/Shape Positioning Systems**:

| System | Description | Use Case |
|--------|-------------|----------|
| **Absolute Positioning** | Fixed x, y coordinates | Manual layout, precise control |
| **Relative Positioning** | Position relative to parent | Nested components, groups |
| **Auto-Layout** | Algorithm-based positioning | Automatic organization, graphs |
| **Grid System** | Snap-to-grid alignment | Structured dashboards |
| **Flow Layout** | Flexbox/Grid-like | Responsive arrangements |

**Rendering Strategies**:

```typescript
// Canvas rendering with virtualization
class CanvasRenderer {
  private viewport: Viewport;
  private spatialIndex: RTree;
  
  render(ctx: CanvasRenderingContext2D) {
    // Get visible bounds
    const bounds = this.viewport.getVisibleBounds();
    
    // Query spatial index for visible items
    const visibleItems = this.spatialIndex.query(bounds);
    
    // Render only visible items
    for (const item of visibleItems) {
      this.renderItem(ctx, item);
    }
  }
  
  renderItem(ctx: CanvasRenderingContext2D, item: CanvasItem) {
    ctx.save();
    
    // Apply viewport transform
    this.viewport.applyTransform(ctx);
    
    // Render item
    item.render(ctx);
    
    ctx.restore();
  }
}
```

**Platform Examples**:

| Platform | Canvas Implementation | Key Features |
|----------|---------------------|--------------|
| **tldraw** | Custom canvas engine | • Infinite canvas<br>• Shape system<br>• Collaborative cursors<br>• History/undo |
| **Count.co** | React + Canvas | • Cell-based layout<br>• Free-form positioning<br>• Auto-layout options<br>• SQL-driven cells |
| **Observable** | HTML/SVG cells | • Linear notebook flow<br>• Custom layouts via HTML<br>• D3.js integration |

**Recommended Stack**:
- **Canvas Library**: Konva.js, Fabric.js, or custom WebGL
- **Spatial Index**: rbush (R-tree implementation)
- **Transform**: gl-matrix or custom matrix math
- **Gestures**: Hammer.js or custom touch handling

*For state management, see Section 1.3. For collaboration, see Section 4.3.*

### 4.2 SQL Integration



**Overview**: SQL-driven dashboards (inspired by Count.co) enable powerful data analysis with familiar query syntax.

**Query Execution Architecture**:

| Approach | Implementation | Pros | Cons |
|----------|---------------|------|------|
| **Client-Side SQL** | DuckDB WASM, SQLite WASM | ✅ No backend needed<br>✅ Fast queries<br>✅ Offline capable | ❌ Large bundle<br>❌ Memory limits<br>❌ Initial load time |
| **Server-Side SQL** | PostgreSQL, MySQL | ✅ Unlimited data<br>✅ Mature ecosystem<br>✅ Security | ❌ Network latency<br>❌ Backend required<br>❌ Scaling costs |
| **Hybrid** | Cache + server | ✅ Best of both<br>✅ Optimized | ❌ Complexity<br>❌ Sync issues |

**DuckDB WASM Architecture**:

```typescript
// DuckDB WASM integration
import * as duckdb from '@duckdb/duckdb-wasm';

class SQLEngine {
  private db: duckdb.AsyncDuckDB;
  private conn: duckdb.AsyncDuckDBConnection;
  
  async initialize() {
    const bundle = await duckdb.selectBundle({
      mvp: {
        mainModule: duckdb_wasm,
        mainWorker: duckdb_wasm_worker
      }
    });
    
    const worker = new Worker(bundle.mainWorker!);
    const logger = new duckdb.ConsoleLogger();
    this.db = new duckdb.AsyncDuckDB(logger, worker);
    await this.db.instantiate(bundle.mainModule);
    this.conn = await this.db.connect();
  }
  
  async query(sql: string, params?: any[]) {
    // Parameterized query for security
    const stmt = await this.conn.prepare(sql);
    const result = await stmt.query(...(params || []));
    return result.toArray();
  }
  
  async loadData(tableName: string, data: any[]) {
    // Load data into DuckDB
    await this.conn.insertArrowTable(
      tableName,
      arrowTable(data)
    );
  }
}
```

**Query Result Caching**:

| Strategy | Implementation | Use Case |
|----------|---------------|----------|
| **In-Memory Cache** | Map/LRU cache | Fast repeated queries |
| **IndexedDB Cache** | Persistent cache | Large result sets |
| **Query Fingerprint** | Hash-based key | Cache invalidation |
| **Incremental Updates** | Delta queries | Real-time data |

**Data Binding Patterns**:

```typescript
// Reactive SQL queries
import { useQuery } from './sql-hooks';

function DataCell({ sql, params }) {
  const { data, loading, error, refetch } = useQuery(sql, params);
  
  // Automatically re-execute when params change
  useEffect(() => {
    refetch();
  }, [params]);
  
  if (loading) return <Spinner />;
  if (error) return <Error message={error.message} />;
  
  return <DataTable data={data} />;
}
```

**Platform Examples**:

| Platform | SQL Implementation | Features |
|----------|-------------------|----------|
| **Count.co** | DuckDB + PostgreSQL | • SQL cells<br>• Query dependencies<br>• Result caching<br>• Parameterized queries |
| **Observable** | SQL cells (via connectors) | • Database connectors<br>• SQL template literals<br>• Reactive queries |
| **Evidence** | DuckDB + connectors | • SQL + Markdown<br>• Component binding<br>• Build-time queries |

**Recommended Stack**:
- **Client SQL**: DuckDB WASM (analytics), SQLite WASM (simple queries)
- **Caching**: React Query or SWR with IndexedDB
- **Parameterization**: Prepared statements, tagged templates
- **Visualization**: Observable Plot, Vega-Lite

*For data persistence, see Section 9.3. For component binding, see Section 4.1.*

### 4.3 Real-Time Collaboration



**Overview**: Multi-user collaboration (inspired by Count.co and tldraw) enables teams to work together in real-time.

**CRDT (Conflict-free Replicated Data Type) Libraries**:

| Library | Language | Pros | Cons | Bundle Size | Use Case |
|---------|----------|------|------|-------------|----------|
| **Yjs** | JavaScript | ✅ Mature<br>✅ Performant<br>✅ Rich ecosystem<br>✅ CRDT types | ❌ Learning curve<br>❌ Bundle size | ~50KB | Production apps |
| **Automerge** | JavaScript/Rust | ✅ Pure CRDT<br>✅ Offline-first<br>✅ Time travel | ❌ Larger bundle<br>❌ Performance | ~200KB | Offline-first apps |
| **Loro** | Rust (WASM) | ✅ High performance<br>✅ Small bundle<br>✅ Rich text | ❌ New/experimental<br>❌ Smaller ecosystem | ~100KB | Performance-critical |
| **Fluid Framework** | TypeScript | ✅ Microsoft-backed<br>✅ Enterprise features | ❌ Complex<br>❌ Azure dependency | Large | Enterprise |

**Yjs Integration Architecture**:

```typescript
// Yjs collaborative state
import * as Y from 'yjs';
import { WebrtcProvider } from 'y-webrtc';
import { IndexeddbPersistence } from 'y-indexeddb';

class CollaborationEngine {
  private doc: Y.Doc;
  private provider: WebrtcProvider;
  private persistence: IndexeddbPersistence;
  
  constructor(roomId: string) {
    this.doc = new Y.Doc();
    
    // WebRTC provider for P2P sync
    this.provider = new WebrtcProvider(roomId, this.doc);
    
    // IndexedDB for offline persistence
    this.persistence = new IndexeddbPersistence(roomId, this.doc);
  }
  
  // Shared canvas state
  getCanvas(): Y.Map<any> {
    return this.doc.getMap('canvas');
  }
  
  // Shared cells/shapes
  getCells(): Y.Array<any> {
    return this.doc.getArray('cells');
  }
  
  // Awareness (presence)
  getAwareness() {
    return this.provider.awareness;
  }
}
```

**Presence System**:

| Feature | Implementation | Use Case |
|---------|---------------|----------|
| **User Cursors** | Awareness state + SVG | Show where users are pointing |
| **Active Selection** | Highlighted shapes/cells | Show what users are editing |
| **User Avatars** | Avatar component | Identify collaborators |
| **Activity Feed** | Event log | Show recent changes |
| **Typing Indicators** | Awareness + debounce | Show who's typing |

**Conflict Resolution Strategies**:

| Strategy | Description | Pros | Cons |
|----------|-------------|------|------|
| **Last-Write-Wins** | Timestamp-based | ✅ Simple<br>✅ Fast | ❌ Data loss<br>❌ Not fair |
| **CRDT** | Mathematically convergent | ✅ No conflicts<br>✅ Automatic | ❌ Complex<br>❌ Memory overhead |
| **Operational Transform** | Transform operations | ✅ Proven<br>✅ Google Docs uses it | ❌ Very complex<br>❌ Hard to implement |
| **Manual Resolution** | User chooses | ✅ User control<br>✅ Transparent | ❌ Interrupts flow<br>❌ User burden |

**Platform Examples**:

| Platform | Collaboration System | Implementation |
|----------|---------------------|----------------|
| **tldraw** | Yjs + WebRTC | • Real-time shape sync<br>• Presence cursors<br>• History preservation<br>• Offline support |
| **Count.co** | Custom WebSocket | • Real-time cell updates<br>• Collaborative editing<br>• Presence indicators<br>• Comment threads |
| **Observable** | Limited collaboration | • Notebook sharing<br>• Fork-based workflow<br>• No real-time sync |

**Recommended Architecture**:

```typescript
// Collaborative canvas cell
function CollaborativeCell({ cellId }) {
  const collab = useCollaboration();
  const cells = collab.getCells();
  
  // Subscribe to cell changes
  const cell = useYArray(cells, cellId);
  
  // Update cell
  const updateCell = (changes) => {
    collab.doc.transact(() => {
      const cellData = cells.get(cellId);
      Object.assign(cellData, changes);
    });
  };
  
  // Show presence
  const awareness = collab.getAwareness();
  const users = useAwareness(awareness);
  
  return (
    <Cell data={cell} onChange={updateCell}>
      <PresenceCursors users={users} />
    </Cell>
  );
}
```

**Recommended Stack**:
- **CRDT**: Yjs (most mature and performant)
- **Transport**: WebRTC (P2P) or WebSocket (server-based)
- **Persistence**: IndexedDB (offline) + server backup
- **Presence**: Yjs Awareness API
- **Cursors**: Custom SVG overlay

*For state management, see Section 1.3. For canvas architecture, see Section 4.1.*

### 4.4 Performance Optimization



**Overview**: Canvas-based and data-intensive applications require specific performance optimizations.

**Canvas Rendering Optimizations**:

| Technique | Description | Performance Gain | Complexity |
|-----------|-------------|------------------|------------|
| **Virtual Scrolling** | Render visible items only | 10-100x | Medium |
| **Layer Separation** | Multiple canvas layers | 2-5x | Low |
| **WebGL Rendering** | GPU-accelerated | 10-50x | High |
| **Offscreen Canvas** | Background rendering | 2-3x | Medium |
| **Request Animation Frame** | Batch updates | 2-5x | Low |
| **Dirty Rectangle** | Partial redraws | 5-10x | Medium |

**State Management Optimizations**:

```typescript
// Structural sharing with Immer
import { produce } from 'immer';

const updateCanvas = produce((draft, action) => {
  // Immer creates efficient immutable updates
  const cell = draft.cells.find(c => c.id === action.cellId);
  if (cell) {
    cell.position = action.position;
  }
});

// Memoization for expensive computations
import { useMemo } from 'react';

function DataVisualization({ data, config }) {
  const processedData = useMemo(() => {
    // Expensive data transformation
    return processLargeDataset(data, config);
  }, [data, config]);
  
  return <Chart data={processedData} />;
}

// Lazy computation with computed values
import { computed } from '@preact/signals-react';

const visibleCells = computed(() => {
  const viewport = canvasState.viewport.value;
  return canvasState.cells.value.filter(cell =>
    isInViewport(cell, viewport)
  );
});
```

**Data Loading Strategies**:

| Strategy | Implementation | Use Case |
|----------|---------------|----------|
| **Lazy Loading** | Load on demand | Large datasets |
| **Pagination** | Load in chunks | Infinite scroll |
| **Streaming** | Progressive loading | Real-time data |
| **Prefetching** | Load ahead | Predictable navigation |
| **Caching** | Store results | Repeated queries |

**Bundle Optimization**:

```typescript
// Code splitting for large features
const AdvancedChart = lazy(() => import('./AdvancedChart'));

// Tree shaking - import only what you need
import { map, filter } from 'lodash-es';

// Dynamic imports for optional features
async function loadCollaboration() {
  if (user.hasPremium) {
    const { CollaborationEngine } = await import('./collaboration');
    return new CollaborationEngine();
  }
}
```

**Platform Benchmarks**:

| Platform | Initial Load | Canvas Render | Query Execution |
|----------|-------------|---------------|-----------------|
| **tldraw** | ~200KB | 60 FPS (1000 shapes) | N/A |
| **Count.co** | ~500KB | 60 FPS (100 cells) | <100ms (DuckDB) |
| **Observable** | ~300KB | 60 FPS (cells) | Varies |

**Recommended Optimizations**:
1. **Rendering**: Virtual scrolling + layer separation
2. **State**: Immer for immutability + signals for reactivity
3. **Data**: DuckDB WASM + IndexedDB caching
4. **Bundle**: Code splitting + tree shaking
5. **Network**: Service worker + prefetching

*For canvas rendering, see Section 4.1. For state management, see Section 1.3.*


---

## 5. Data Persistence

Configuration and data persistence strategies for the framework.

---

### 5.1 Storage Strategy & Configuration



#### User Configurations

#####.1 Settings Management

**Concept**: Centralized system for user preferences and application options.

**Architecture Approaches**:

1. **Hierarchical Settings Structure**
   - Nested configuration organized by domain (general, dashboard, visualization, performance)
   - Supports inheritance and overrides at different levels
   - Type-safe with schema validation

2. **Flat Key-Value Store**
   - Simple key-value pairs with dot notation (e.g., `dashboard.refreshInterval`)
   - Easy to serialize and persist
   - Less structure, more flexibility

3. **Hybrid Approach**
   - Hierarchical structure in memory
   - Flat storage for persistence
   - Best of both worlds

**Pros & Cons Analysis**:

| Approach | Pros | Cons | Best For |
|----------|------|------|----------|
| **Hierarchical** | ✅ Clear organization<br>✅ Type safety<br>✅ Easy validation<br>✅ Supports overrides | ❌ More complex to implement<br>❌ Harder to query dynamically<br>❌ Deeper nesting complexity | Large applications with many settings categories |
| **Flat Key-Value** | ✅ Simple implementation<br>✅ Easy persistence<br>✅ Dynamic queries<br>✅ Minimal overhead | ❌ No structure enforcement<br>❌ Harder to validate<br>❌ No type safety<br>❌ Namespace collisions | Small to medium apps, simple preferences |
| **Hybrid** | ✅ Structured in code<br>✅ Simple persistence<br>✅ Type-safe + flexible<br>✅ Best performance | ❌ Transformation overhead<br>❌ Two representations to maintain<br>❌ More complex architecture | Production BI dashboards requiring both structure and flexibility |

**State Management Library Comparison**:

| Library | Architecture | Pros | Cons | Use Case |
|---------|-------------|------|------|----------|
| **Zustand** | Flux-like store | ✅ Simple API<br>✅ No providers<br>✅ Middleware ecosystem<br>✅ Small bundle | ❌ Manual optimization needed<br>❌ Global state only | General-purpose settings management |
| **Jotai** | Atomic state | ✅ Fine-grained reactivity<br>✅ Minimal re-renders<br>✅ Composable atoms<br>✅ Bottom-up | ❌ Learning curve<br>❌ More boilerplate<br>❌ Debugging complexity | Complex, interconnected settings |
| **Valtio** | Proxy-based | ✅ Mutable API<br>✅ Automatic tracking<br>✅ Minimal boilerplate<br>✅ Intuitive | ❌ Proxy limitations<br>❌ Debugging harder<br>❌ Less ecosystem | Rapid development, simple state |
| **Redux Toolkit** | Redux pattern | ✅ Mature ecosystem<br>✅ DevTools<br>✅ Predictable<br>✅ Time-travel | ❌ Verbose<br>❌ Boilerplate<br>❌ Learning curve<br>❌ Larger bundle | Enterprise apps, complex workflows |

**Schema Validation Approaches**:

| Approach | Pros | Cons |
|----------|------|------|
| **Runtime Validation (Zod, Yup)** | ✅ Catches invalid data<br>✅ User input protection<br>✅ Type inference<br>✅ Clear error messages | ❌ Runtime overhead<br>❌ Bundle size increase<br>❌ Validation logic duplication |
| **TypeScript Only** | ✅ Zero runtime cost<br>✅ Compile-time safety<br>✅ No bundle impact<br>✅ IDE support | ❌ No runtime protection<br>❌ Can't validate external data<br>❌ Type erasure at runtime |
| **Hybrid (TS + Runtime)** | ✅ Best safety<br>✅ Validates external data<br>✅ Type-safe in code<br>✅ Comprehensive | ❌ Maintenance overhead<br>❌ Schema duplication<br>❌ Larger bundle |

**Persistence Strategy Comparison**:

| Strategy | Pros | Cons | Recommended For |
|----------|------|------|-----------------|
| **Eager Persistence** (Save on every change) | ✅ No data loss<br>✅ Always in sync<br>✅ Simple logic | ❌ Performance overhead<br>❌ Excessive writes<br>❌ Storage wear | Critical settings, small config |
| **Debounced Persistence** (Save after delay) | ✅ Reduced writes<br>✅ Better performance<br>✅ Batched updates | ❌ Potential data loss<br>❌ Complexity<br>❌ Timing issues | Frequently changing settings |
| **Manual Persistence** (Save on action) | ✅ User control<br>✅ Minimal writes<br>✅ Predictable | ❌ User must remember<br>❌ Data loss risk<br>❌ Poor UX | Power user tools, explicit saves |
| **Hybrid** (Critical eager, others debounced) | ✅ Balanced approach<br>✅ Optimized performance<br>✅ Data safety | ❌ Complex logic<br>❌ More code<br>❌ Configuration needed | Production BI dashboards |

**Recommended Architecture**: Hierarchical structure with Zustand, Zod validation, hybrid persistence (critical settings eager, UI preferences debounced), IndexedDB storage.

#####.2 Keybinding System

**Concept**: Customizable keyboard shortcuts for commands and actions.

**Architecture Approaches**:

1. **Command-Based Architecture**
   - Commands are first-class entities with IDs, names, and execution logic
   - Keybindings map to commands (many-to-one relationship)
   - Context-aware execution with "when" clauses
   - Supports command palette and keybinding customization

2. **Direct Event Binding**
   - Keybindings directly trigger functions
   - No command abstraction layer
   - Simpler but less flexible

3. **Keymap Hierarchy**
   - Global keybindings (always active)
   - Mode-specific keybindings (context-aware)
   - Component-local keybindings (scoped)
   - Priority-based resolution

**Pros & Cons Analysis**:

| Approach | Pros | Cons | Best For |
|----------|------|------|----------|
| **Command-Based** | ✅ Decoupled commands from keys<br>✅ Easy customization<br>✅ Command palette support<br>✅ Context-aware execution<br>✅ Discoverable | ❌ More complex architecture<br>❌ Additional abstraction layer<br>❌ Higher memory overhead<br>❌ Steeper learning curve | Complex applications with many commands, power users |
| **Direct Binding** | ✅ Simple implementation<br>✅ Minimal overhead<br>✅ Easy to understand<br>✅ Fast execution | ❌ Hard to customize<br>❌ No command palette<br>❌ Tight coupling<br>❌ Difficult to document | Simple apps, fixed keybindings, prototypes |
| **Keymap Hierarchy** | ✅ Context-aware<br>✅ Scoped bindings<br>✅ Priority resolution<br>✅ Flexible | ❌ Complexity in resolution<br>❌ Potential conflicts<br>❌ Debugging difficulty<br>❌ State management | Multi-mode applications, context-sensitive UIs |

**Keybinding Library Comparison**:

| Library | Size | Pros | Cons | Use Case |
|---------|------|------|------|----------|
| **tinykeys** | 400B | ✅ Minimal size<br>✅ Zero dependencies<br>✅ Chord support<br>✅ Modern API | ❌ Limited features<br>❌ No scope support<br>❌ Manual context handling | Size-constrained apps, simple keybindings |
| **hotkeys-js** | ~3KB | ✅ Scope support<br>✅ Key filtering<br>✅ Feature-rich<br>✅ Mature | ❌ Larger bundle<br>❌ Older API style<br>❌ Less TypeScript support | General-purpose, scope-aware bindings |
| **Mousetrap** | ~2KB | ✅ Popular<br>✅ Well-documented<br>✅ Chord sequences<br>✅ Mature | ❌ Not actively maintained<br>❌ No TypeScript<br>❌ Older patterns | Legacy apps, proven stability |
| **react-hotkeys-hook** | ~2KB | ✅ React hooks<br>✅ Component-scoped<br>✅ TypeScript support<br>✅ Modern | ❌ React-only<br>❌ Re-render considerations<br>❌ Hook limitations | React applications, component-local bindings |
| **Custom Solution** | Varies | ✅ Full control<br>✅ Tailored features<br>✅ No dependencies<br>✅ Optimized | ❌ Development time<br>❌ Maintenance burden<br>❌ Testing overhead<br>❌ Edge cases | Unique requirements, full control needed |

**Key Conflict Resolution Strategies**:

| Strategy | Pros | Cons |
|----------|------|------|
| **Priority-Based** (Global → Mode → Local) | ✅ Clear hierarchy<br>✅ Predictable<br>✅ Easy to reason about | ❌ May override important globals<br>❌ Inflexible<br>❌ Can't express complex rules |
| **Context-Aware** (When clauses) | ✅ Flexible<br>✅ Expressive<br>✅ Handles complex cases<br>✅ Fine-grained control | ❌ Complex to implement<br>❌ Harder to debug<br>❌ Performance overhead |
| **User-Defined Priority** | ✅ User control<br>✅ Flexible<br>✅ Handles edge cases | ❌ Complex UI<br>❌ User confusion<br>❌ Maintenance burden |

**Chord Sequence Considerations**:

| Aspect | Pros | Cons |
|--------|------|------|
| **Multi-Key Sequences** (e.g., Ctrl+K Ctrl+S) | ✅ More key combinations<br>✅ Familiar to power users<br>✅ Namespace expansion | ❌ Discoverability issues<br>❌ Timing complexity<br>❌ Harder for beginners |
| **Single Keys Only** | ✅ Simple<br>✅ Fast<br>✅ Easy to learn | ❌ Limited combinations<br>❌ Conflicts more likely<br>❌ Less powerful |

**Recommended Architecture**: Command-based with keymap hierarchy, context-aware execution, chord support, and user customization. Use tinykeys for minimal apps, hotkeys-js for feature-rich needs.

#####.3 Theme System

**Concept**: Visual styling and color schemes that can be switched dynamically.

**Architecture Approaches**:

1. **CSS Variables Approach**
   - Define theme tokens as CSS custom properties
   - Switch themes by changing root-level variables
   - No JavaScript required for styling
   - Native browser support

2. **CSS-in-JS with Theme Context**
   - Theme object passed through React context
   - Styles generated at runtime
   - Full JavaScript access to theme values
   - Dynamic styling capabilities

3. **Build-Time Theme Generation**
   - Themes compiled to separate CSS files
   - Zero runtime overhead
   - Static theme switching
   - Optimal performance

4. **Hybrid Approach**
   - CSS variables for colors and tokens
   - CSS-in-JS for complex dynamic styles
   - Best of both worlds

**Pros & Cons Analysis**:

| Approach | Pros | Cons | Best For |
|----------|------|------|----------|
| **CSS Variables** | ✅ Zero runtime cost<br>✅ Native browser support<br>✅ Simple implementation<br>✅ No JavaScript needed<br>✅ Excellent performance | ❌ Limited browser support (old browsers)<br>❌ No complex logic<br>❌ String values only<br>❌ Less type safety | Modern browsers, performance-critical apps |
| **CSS-in-JS (Runtime)** | ✅ Full JavaScript access<br>✅ Dynamic styling<br>✅ Type-safe<br>✅ Component-scoped<br>✅ Conditional styles | ❌ Runtime overhead<br>❌ Larger bundle<br>❌ FOUC potential<br>❌ Performance impact<br>❌ Hydration issues | Complex theming, dynamic styles |
| **Build-Time** | ✅ Zero runtime cost<br>✅ Optimal performance<br>✅ Static analysis<br>✅ Type-safe<br>✅ Small bundle | ❌ No runtime switching<br>❌ Build complexity<br>❌ Less flexible<br>❌ Requires rebuild | Static themes, maximum performance |
| **Hybrid** | ✅ Balanced performance<br>✅ Flexible<br>✅ Type-safe<br>✅ Best of both | ❌ More complex<br>❌ Two systems to maintain<br>❌ Learning curve | Production BI dashboards |

**Styling Library Comparison**:

| Library | Approach | Pros | Cons | Use Case |
|---------|----------|------|------|----------|
| **Tailwind CSS** | Utility-first | ✅ Rapid development<br>✅ Small production bundle<br>✅ Dark mode built-in<br>✅ Consistent design | ❌ Verbose HTML<br>❌ Learning curve<br>❌ Customization limits<br>❌ Not semantic | Fast development, consistent UI |
| **Styled-Components** | Runtime CSS-in-JS | ✅ Component-scoped<br>✅ Dynamic theming<br>✅ Popular ecosystem<br>✅ TypeScript support | ❌ Runtime overhead<br>❌ Bundle size<br>❌ SSR complexity<br>❌ Performance cost | Dynamic theming, component libraries |
| **Stitches** | Near-zero runtime | ✅ Minimal runtime<br>✅ Variants API<br>✅ Type-safe<br>✅ Good performance | ❌ Smaller ecosystem<br>❌ Learning curve<br>❌ Less mature | Performance + flexibility balance |
| **vanilla-extract** | Build-time | ✅ Zero runtime<br>✅ Type-safe<br>✅ Best performance<br>✅ CSS Modules-like | ❌ Build complexity<br>❌ No runtime theming<br>❌ Smaller ecosystem | Maximum performance, static themes |
| **Emotion** | Runtime CSS-in-JS | ✅ Flexible<br>✅ Framework-agnostic<br>✅ Good performance<br>✅ Popular | ❌ Runtime cost<br>❌ Bundle size<br>❌ Complexity | Framework-agnostic, flexible theming |
| **CSS Modules** | Build-time | ✅ Simple<br>✅ Scoped styles<br>✅ Zero runtime<br>✅ Familiar CSS | ❌ No dynamic theming<br>❌ Verbose<br>❌ Limited features | Simple apps, traditional CSS |

**Theme Switching Strategies**:

| Strategy | Pros | Cons |
|----------|------|------|
| **Class-Based** (`<html class="dark">`) | ✅ Simple<br>✅ CSS-only<br>✅ Fast<br>✅ No FOUC | ❌ Limited to predefined themes<br>❌ No gradual transitions |
| **Attribute-Based** (`<html data-theme="dark">`) | ✅ Semantic<br>✅ Multiple themes<br>✅ CSS-only<br>✅ Accessible | ❌ Slightly more verbose<br>❌ Browser support |
| **Context-Based** (React Context) | ✅ JavaScript access<br>✅ Dynamic values<br>✅ Type-safe | ❌ Runtime overhead<br>❌ Re-render cost<br>❌ Complexity |
| **CSS Variable Injection** | ✅ Dynamic<br>✅ Performant<br>✅ Flexible | ❌ JavaScript required<br>❌ FOUC potential |

**System Preference Integration**:

| Aspect | Pros | Cons |
|--------|------|------|
| **Auto-Detect** (`prefers-color-scheme`) | ✅ Respects user preference<br>✅ Better UX<br>✅ Accessibility<br>✅ Native API | ❌ User can't override easily<br>❌ May not match app context |
| **Manual Selection** | ✅ User control<br>✅ Predictable<br>✅ Simple | ❌ Ignores system preference<br>❌ Extra UI needed |
| **Hybrid** (Auto + Manual Override) | ✅ Best UX<br>✅ Respects preference<br>✅ User control | ❌ More complex<br>❌ State management needed |

**Recommended Architecture**: CSS Variables for tokens, Tailwind CSS for utility classes, system preference detection with manual override, persistent user choice in IndexedDB.

#####.4 Layout System

**Concept**: Flexible, user-customizable arrangement of dashboard components and panels.

**Architecture Patterns**:

1. **Grid-Based Layout**
   ```typescript
   interface GridLayout {
     id: string;
     items: GridItem[];
     cols: number;
     rowHeight: number;
   }
   
   interface GridItem {
     id: string;
     x: number;
     y: number;
     w: number;
     h: number;
     component: string;
     props: Record<string, any>;
   }
   ```

2. **Split Pane Layout** (Recursive)
   ```typescript
   interface SplitLayout {
     type: 'horizontal' | 'vertical';
     children: (SplitLayout | PanelLayout)[];
     sizes: number[]; // Percentage splits
   }
   
   interface PanelLayout {
     type: 'panel';
     component: string;
     props: Record<string, any>;
   }
   ```

**Best Libraries & Tools**:

1. **react-grid-layout** (Most popular)
   - Drag-and-drop grid
   - Responsive breakpoints
   - Collision detection
   - Used by: Grafana, many BI dashboards
   ```typescript
   import GridLayout from 'react-grid-layout';
   
   <GridLayout
     layout={layout}
     cols={12}
     rowHeight={30}
     onLayoutChange={handleLayoutChange}
     draggableHandle=".drag-handle"
   >
     {items.map(item => <div key={item.id}>{item.content}</div>)}
   </GridLayout>
   ```

2. **react-mosaic** (Split pane layouts)
   - Nested split views
   - Drag-and-drop rearrangement
   - Used by: Code editors, complex dashboards
   ```typescript
   import { Mosaic } from 'react-mosaic-component';
   
   <Mosaic
     value={mosaicLayout}
     onChange={setMosaicLayout}
     renderTile={(id) => <Panel id={id} />}
   />
   ```

3. **golden-layout** (Advanced)
   - Multi-window support
   - Tab containers
   - Popout windows
   - Used by: Trading platforms, complex BI tools

4. **allotment** (VS Code-style)
   - Split panes with resizable dividers
   - Nested layouts
   - Keyboard accessible
   - Used by: Code-like interfaces

5. **react-resizable-panels** (Modern)
   - Lightweight, accessible
   - Imperative API
   - Persistent layouts
   - Used by: Modern React apps

**BI Dashboard Examples**:
- **Observable**: Notebook-style (vertical flow) + custom layouts
- **Evidence**: Page-based layouts with component slots
- **Grafana**: react-grid-layout for dashboard panels
- **Metabase**: Fixed grid with responsive breakpoints
- **Apache Superset**: react-grid-layout with custom extensions
- **Tableau**: Proprietary grid system with containers

**Implementation Pattern**:
```typescript
// Layout manager with persistence
import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface LayoutStore {
  layouts: Record<string, Layout>;
  activeLayout: string;
  saveLayout: (id: string, layout: Layout) => void;
  loadLayout: (id: string) => void;
  deleteLayout: (id: string) => void;
}

const useLayoutStore = create<LayoutStore>()(
  persist(
    (set, get) => ({
      layouts: {},
      activeLayout: 'default',
      
      saveLayout: (id, layout) => 
        set((state) => ({
          layouts: { ...state.layouts, [id]: layout }
        })),
      
      loadLayout: (id) => {
        const layout = get().layouts[id];
        if (layout) {
          set({ activeLayout: id });
          applyLayout(layout);
        }
      },
      
      deleteLayout: (id) =>
        set((state) => {
          const { [id]: _, ...rest } = state.layouts;
          return { layouts: rest };
        })
    }),
    { name: 'dashboard-layouts' }
  )
);

// Layout presets
const layoutPresets = {
  default: {
    type: 'grid',
    items: [/* ... */]
  },
  analytics: {
    type: 'split',
    direction: 'horizontal',
    children: [/* ... */]
  },
  monitoring: {
    type: 'grid',
    items: [/* ... */]
  }
};
```

**Advanced Layout Features**:

1. **Responsive Breakpoints**
   ```typescript
   interface ResponsiveLayout {
     lg: GridItem[]; // Desktop
     md: GridItem[]; // Tablet
     sm: GridItem[]; // Mobile
   }
   ```

2. **Layout Templates**
   - Predefined layouts for common use cases
   - One-click application
   - Customizable after application

3. **Layout Sharing**
   - Export layout as JSON
   - Import from URL or file
   - Team templates

4. **Layout History**
   - Undo/redo support
   - Version history
   - Restore previous layouts

**Recommended Architecture for BI Dashboards**:

```typescript
// Unified configuration system
interface DashboardConfig {
  version: string;
  settings: Settings;
  keybindings: KeybindingConfig;
  theme: ThemeConfig;
  layout: LayoutConfig;
  extensions: ExtensionConfig[];
}

// Configuration manager
class ConfigManager {
  private config: DashboardConfig;
  private storage: StorageAdapter;
  private listeners: Set<(config: DashboardConfig) => void>;
  
  async load(): Promise<DashboardConfig> {
    const stored = await this.storage.get('dashboard-config');
    this.config = stored || defaultConfig;
    return this.config;
  }
  
  async save(): Promise<void> {
    await this.storage.set('dashboard-config', this.config);
    this.notifyListeners();
  }
  
  update(path: string, value: any): void {
    set(this.config, path, value);
    this.save();
  }
  
  export(): string {
    return JSON.stringify(this.config, null, 2);
  }
  
  import(json: string): void {
    const imported = JSON.parse(json);
    this.config = migrateConfig(imported);
    this.save();
  }
}
```

**Best Practices from Leading BI Platforms**:

1. **Observable**:
   - Reactive configuration (changes propagate automatically)
   - Notebook-level and cell-level settings
   - Git-friendly (text-based configs)

2. **Evidence**:
   - YAML for project config (version controlled)
   - UI for user preferences (browser storage)
   - Environment-based overrides

3. **Grafana**:
   - Hierarchical settings (global → org → dashboard → panel)
   - JSON-based dashboard definitions
   - Plugin-extensible configuration

4. **Metabase**:
   - Database-backed configuration
   - Admin UI for system settings
   - User preferences in browser storage

**Recommended Stack for Your Framework**:

```typescript
// Settings: Zustand + Zod + IndexedDB
// Keybindings: tinykeys + custom registry
// Themes: Tailwind CSS + CSS variables
// Layouts: react-grid-layout + react-resizable-panels
// Persistence: IndexedDB with migration support
// Export/Import: JSON with schema validation
```

#### Extension State
- **Plugin Configurations**: Extension-specific settings
- **Installed Extensions**: List of active plugins
- **Extension Data**: Plugin-managed data

#### Storage Options & Strategy

##### Client-Side Storage

**Primary Storage**
- **IndexedDB**: Large, structured data (dashboards, datasets, extension state)
  - Capacity: 50MB+ (typically unlimited with user prompt at ~50MB, can reach GBs)
  - Advantages: Large capacity, structured queries, transactions, async API
  - Use Case: Main persistent storage for dashboards and configurations
  
- **LocalStorage**: Small, simple key-value pairs (preferences)
  - Capacity: 5-10MB (varies by browser)
  - Advantages: Simple API, synchronous access
  - Limitations: Small size limit, string-only storage, synchronous (blocks UI)
  - Use Case: Basic preferences, feature flags

**Advanced Client Storage**
- **Cache API**: HTTP responses, assets, and API data
  - Capacity: Similar to IndexedDB (typically unlimited with prompt)
  - Advantages: Built for PWAs, offline-first, versioned caches
  - Use Case: Dashboard templates, static assets, API response caching
  
- **OPFS (Origin Private File System)**: High-performance file operations
  - Capacity: Large (GBs, quota-managed like IndexedDB)
  - Advantages: Fast, large capacity, works with Web Workers, better performance
  - Use Case: Large dataset caching, temporary file operations
  
- **File System Access API**: Direct file system read/write
  - Capacity: Limited only by user's disk space
  - Advantages: Native file integration, user control, large files
  - Limitations: Requires user permission, limited browser support
  - Use Case: Export/import dashboard configs, large dataset files

**Memory-Based Storage**
- **In-Memory State (Zustand/Jotai)**: Session-only volatile state
  - Capacity: Limited by browser's available RAM (typically hundreds of MBs)
  - Advantages: Fastest access, no serialization overhead
  - Limitations: Lost on page refresh, memory-constrained
  - Use Case: Active dashboard state, UI state, temporary calculations
  
- **SessionStorage**: Tab-scoped temporary data
  - Capacity: 5-10MB (same as LocalStorage)
  - Advantages: Automatic cleanup on tab close
  - Limitations: Small size, string-only storage
  - Use Case: Temporary filters, session-specific preferences

##### Server-Side/Hybrid Storage

**Backend Integration**
- **REST/GraphQL API**: Centralized data storage
  - Capacity: Unlimited (depends on server infrastructure)
  - Advantages: Scalable, secure, multi-user collaboration
  - Use Case: User accounts, shared dashboards, enterprise deployments
  
- **Firebase/Supabase**: Managed backend services
  - Capacity: Varies by plan (Free: 1GB, Paid: scalable to TBs)
  - Advantages: Real-time sync, built-in auth, managed infrastructure
  - Limitations: Vendor lock-in, cost at scale
  - Use Case: Rapid prototyping, real-time collaboration
  
- **PouchDB + CouchDB**: Offline-first with server sync
  - Capacity: Client (IndexedDB limits), Server (unlimited)
  - Advantages: Automatic sync, conflict resolution, works offline
  - Use Case: Offline-capable dashboards with eventual consistency

**Peer-to-Peer**
- **WebRTC Data Channels**: Direct peer-to-peer data sharing
  - Capacity: Limited by network bandwidth (not storage-based)
  - Advantages: No server required, direct user-to-user sync
  - Limitations: Complex setup, requires signaling server, ephemeral
  - Use Case: Collaborative editing without central server

##### Specialized Storage

**Database Engines**
- **SQLite WASM (sql.js)**: Full SQL database in browser
  - Capacity: Limited by available RAM (typically 100s of MBs)
  - Advantages: SQL queries, relational data, transactions
  - Limitations: Entire DB in memory, manual persistence to IndexedDB
  - Use Case: Complex queries on dashboard data, analytics
  
- **DuckDB WASM**: Analytical queries on large datasets
  - Capacity: Can handle GBs of data (with streaming/chunking)
  - Advantages: OLAP queries, Parquet support, fast analytics, columnar storage
  - Use Case: In-browser data analytics, large dataset processing
  
- **RxDB**: Reactive, offline-first database
  - Capacity: Uses IndexedDB underneath (50MB+ with prompt)
  - Advantages: Observable queries, multi-tab sync, encryption
  - Use Case: Reactive dashboards, multi-tab coordination

**Decentralized Storage**
- **Gun.js**: Decentralized graph database
  - Capacity: Limited by IndexedDB locally, distributed across peers
  - Advantages: P2P sync, offline-first, decentralized
  - Use Case: Decentralized apps, graph-based data
  
- **IPFS**: Distributed file storage
  - Capacity: Unlimited (distributed across network), local cache limited
  - Advantages: Content-addressed, permanent, decentralized
  - Limitations: Requires gateway/node, slower access
  - Use Case: Immutable dashboard templates, public data sharing
  
- **Ceramic Network**: Decentralized data with DIDs
  - Capacity: Unlimited (distributed), per-stream limits vary
  - Advantages: User-owned data, cross-app portability
  - Limitations: Emerging tech, requires infrastructure
  - Use Case: User-owned dashboard configurations

##### Recommended Tiered Strategy

**Tier 1: Hot Data (Active)**
- In-Memory State → Current dashboard state, UI state
- SessionStorage → Temporary filters, session data

**Tier 2: Warm Data (Recent)**
- IndexedDB → Dashboards, extensions, user preferences
- Cache API → Dashboard templates, static resources

**Tier 3: Cold Data (Archive)**
- Cloud Storage/Backend API → Backups, shared dashboards
- File System Access → Export/import, large files

**Tier 4: Analytics (Optional)**
- DuckDB WASM → In-browser analytics on large datasets
- SQLite WASM → Complex relational queries

##### Comparative Analysis: Pros & Cons

| Storage Type | Pros | Cons | Best For |
|-------------|------|------|----------|
| **IndexedDB** | ✅ Large capacity (GBs)<br>✅ Structured queries<br>✅ Transactions<br>✅ Async (non-blocking)<br>✅ Wide browser support | ❌ Complex API<br>❌ No cross-origin access<br>❌ User can clear data<br>❌ Quota management needed | Primary persistent storage for dashboards, configs, extension data |
| **LocalStorage** | ✅ Simple API<br>✅ Synchronous access<br>✅ Wide browser support<br>✅ Easy to use | ❌ Small capacity (5-10MB)<br>❌ String-only storage<br>❌ Synchronous (blocks UI)<br>❌ No transactions | Small preferences, feature flags, simple settings |
| **Cache API** | ✅ Built for offline-first<br>✅ Version control<br>✅ Large capacity<br>✅ Perfect for assets | ❌ Not for structured data<br>❌ More complex than LocalStorage<br>❌ Requires service worker knowledge | Static assets, API responses, dashboard templates |
| **OPFS** | ✅ High performance<br>✅ Large capacity (GBs)<br>✅ Works with Workers<br>✅ File-based operations | ❌ Limited browser support<br>❌ Newer API (less mature)<br>❌ More complex API<br>❌ Not for small data | Large datasets, file operations, high-performance needs |
| **File System Access** | ✅ Unlimited capacity<br>✅ Native file integration<br>✅ User control<br>✅ Cross-app sharing | ❌ Requires user permission<br>❌ Limited browser support<br>❌ Security restrictions<br>❌ Not automatic | Import/export, user-managed backups, large files |
| **In-Memory State** | ✅ Fastest access<br>✅ No serialization<br>✅ Simple to use<br>✅ No quota limits | ❌ Lost on refresh<br>❌ RAM-limited<br>❌ Not persistent<br>❌ Memory leaks possible | Active UI state, temporary calculations, session data |
| **SessionStorage** | ✅ Auto cleanup on close<br>✅ Simple API<br>✅ Tab-isolated<br>✅ Synchronous | ❌ Small capacity (5-10MB)<br>❌ Lost on tab close<br>❌ String-only<br>❌ Blocks UI | Temporary filters, wizard state, tab-specific data |
| **REST/GraphQL API** | ✅ Unlimited capacity<br>✅ Multi-user sync<br>✅ Centralized control<br>✅ Backup/recovery | ❌ Network dependency<br>❌ Latency issues<br>❌ Server costs<br>❌ Complex infrastructure | Enterprise deployments, collaboration, shared dashboards |
| **Firebase/Supabase** | ✅ Real-time sync<br>✅ Built-in auth<br>✅ Managed infrastructure<br>✅ Quick setup | ❌ Vendor lock-in<br>❌ Cost at scale<br>❌ Network dependency<br>❌ Limited customization | Rapid prototyping, real-time features, small-medium apps |
| **PouchDB + CouchDB** | ✅ Offline-first<br>✅ Auto sync<br>✅ Conflict resolution<br>✅ Works offline | ❌ Learning curve<br>❌ Specific data model<br>❌ Sync complexity<br>❌ Performance overhead | Offline apps, eventual consistency, distributed data |
| **WebRTC** | ✅ No server needed<br>✅ Direct P2P<br>✅ Low latency<br>✅ Private | ❌ Complex setup<br>❌ Requires signaling<br>❌ Not persistent<br>❌ Connection issues | Real-time collaboration, peer sharing, live editing |
| **SQLite WASM** | ✅ Full SQL support<br>✅ Relational queries<br>✅ Transactions<br>✅ Familiar API | ❌ RAM-limited (100s MB)<br>❌ Manual persistence<br>❌ Larger bundle size<br>❌ Serialization overhead | Complex queries, relational data, SQL familiarity |
| **DuckDB WASM** | ✅ Handles GBs of data<br>✅ OLAP queries<br>✅ Parquet support<br>✅ Fast analytics | ❌ Large bundle (~10MB)<br>❌ Learning curve<br>❌ Newer technology<br>❌ Limited docs | Analytics workloads, large datasets, BI queries |
| **RxDB** | ✅ Reactive queries<br>✅ Multi-tab sync<br>✅ Encryption<br>✅ Offline-first | ❌ Complex setup<br>❌ Large bundle<br>❌ Learning curve<br>❌ Performance overhead | Reactive apps, multi-tab coordination, encrypted data |
| **Gun.js** | ✅ Decentralized<br>✅ P2P sync<br>✅ Offline-first<br>✅ Graph database | ❌ Different paradigm<br>❌ Learning curve<br>❌ Limited tooling<br>❌ Sync complexity | Decentralized apps, graph data, P2P networks |
| **IPFS** | ✅ Permanent storage<br>✅ Content-addressed<br>✅ Decentralized<br>✅ Immutable | ❌ Slower access<br>❌ Requires gateway<br>❌ Complex setup<br>❌ Not for mutable data | Public data sharing, immutable content, archival |
| **Ceramic Network** | ✅ User-owned data<br>✅ Cross-app portability<br>✅ Decentralized identity<br>✅ Verifiable | ❌ Emerging tech<br>❌ Complex setup<br>❌ Limited adoption<br>❌ Infrastructure needs | User-owned configs, cross-app data, Web3 apps |

##### Decision Matrix

**Choose IndexedDB when:**
- You need persistent, structured data storage
- Working with dashboards, configs, or extension state
- Capacity requirements exceed LocalStorage limits
- You need transactions and complex queries

**Choose LocalStorage when:**
- Storing simple key-value preferences
- Data size is under 5MB
- You need synchronous access
- Simplicity is more important than features

**Choose In-Memory State when:**
- Data is temporary and session-specific
- Performance is critical
- You don't need persistence across refreshes
- Working with active UI state

**Choose Backend API when:**
- Multi-user collaboration is required
- Data needs to be shared across devices
- Centralized control and backup are important
- Enterprise features are needed

**Choose DuckDB/SQLite WASM when:**
- Complex analytical queries are required
- Working with large datasets (100s MB to GBs)
- SQL familiarity is a benefit
- In-browser analytics is needed

**Choose Decentralized Storage (IPFS/Ceramic/Gun) when:**
- User data ownership is critical
- Decentralization is a core requirement
- Building Web3 or P2P applications
- Avoiding vendor lock-in is important

#### Migration & Versioning
- **Schema Versioning**: Handle data format changes
- **Automatic Migration**: Upgrade old configurations
- **Rollback Support**: Revert to previous versions
- **Cross-Storage Sync**: Coordinate data across storage layers


> **Note**: Settings management, keybinding, theme, and layout configurations are detailed in Section 2.2.3.

---

## 6. Technical Stack



### 6.1 Technology Choices

#### 8.1 Frontend Framework & UI Libraries

**Core Framework**:
- **React**: Component-based UI library
- **React Hooks**: Modern state and lifecycle management
- **React Context**: Dependency injection and theming

**UI Component Libraries**:

| Library | Type | Pros | Cons | Bundle Size | Use Case |
|---------|------|------|------|-------------|----------|
| **shadcn/ui** | Copy-paste components | ✅ Full control<br>✅ Customizable<br>✅ Radix-based<br>✅ TypeScript | ❌ Manual updates<br>❌ No npm package | Varies | Modern React apps, full customization |
| **Radix UI** | Headless primitives | ✅ Accessible<br>✅ Unstyled<br>✅ Composable<br>✅ TypeScript | ❌ Requires styling<br>❌ More setup | ~5-10KB/component | Accessible, custom designs |
| **Headless UI** | Unstyled components | ✅ Tailwind-friendly<br>✅ Accessible<br>✅ Simple API | ❌ Limited components<br>❌ Tailwind-focused | ~5KB | Tailwind projects |
| **Mantine** | Full component library | ✅ 100+ components<br>✅ Hooks library<br>✅ Dark mode<br>✅ TypeScript | ❌ Large bundle<br>❌ Opinionated | ~50KB+ | Rapid development |
| **Chakra UI** | Component library | ✅ Accessible<br>✅ Themeable<br>✅ Composable<br>✅ Good DX | ❌ Bundle size<br>❌ Performance | ~40KB+ | Accessible apps |
| **Ant Design** | Enterprise UI | ✅ Comprehensive<br>✅ i18n support<br>✅ Design system | ❌ Very large<br>❌ Opinionated<br>❌ Chinese-focused | ~500KB+ | Enterprise dashboards |
| **Material UI** | Material Design | ✅ Mature<br>✅ Comprehensive<br>✅ Customizable | ❌ Large bundle<br>❌ Material-only | ~300KB+ | Material Design apps |

**Platform-Specific UI Libraries**:

| Platform | UI Stack | Components Used |
|----------|----------|-----------------|
| **Observable** | Custom React + D3 | • Custom React components<br>• D3.js for visualizations<br>• Observable Inputs (form controls)<br>• Custom notebook UI<br>• Inline HTML/SVG |
| **Count.co** | React + Custom | • Custom React components<br>• Canvas-based UI<br>• SQL editor (Monaco/CodeMirror)<br>• Custom chart library<br>• Drag-and-drop system |
| **Evidence** | Svelte + Tailwind | • Svelte components<br>• Tailwind CSS for styling<br>• Custom markdown renderer<br>• Built-in chart components<br>• SQL syntax highlighting |
| **tldraw** | React + Radix | • Custom React components<br>• Radix UI primitives<br>• Custom canvas renderer<br>• Shape toolbars<br>• Context menus |
| **Omni Docs** | React-based | • Custom documentation components<br>• Markdown renderer<br>• Code syntax highlighting<br>• Navigation components |

**Recommended Stack for BI Dashboards**:

```typescript
// Modern, performant UI stack
{
  framework: 'React 18+',
  components: 'shadcn/ui + Radix UI', // Accessible, customizable
  styling: 'Tailwind CSS',             // Utility-first
  charts: 'Observable Plot + D3.js',   // Data visualization
  editor: 'Monaco Editor',             // Code/SQL editing
  forms: 'React Hook Form',            // Form management
  tables: 'TanStack Table',            // Data tables
  icons: 'Lucide React',               // Icon system
  canvas: 'Konva.js or custom',        // Canvas rendering
}
```

**Component Categories for BI Dashboards**:

1. **Layout Components**:
   - Resizable panels (react-resizable-panels)
   - Grid layouts (react-grid-layout)
   - Tabs and navigation
   - Sidebar and header

2. **Data Input**:
   - Form controls (shadcn/ui forms)
   - SQL/Code editor (Monaco Editor)
   - Date pickers (react-day-picker)
   - Filters and search

3. **Data Display**:
   - Charts (Observable Plot, Recharts, Victory)
   - Tables (TanStack Table)
   - Cards and metrics
   - Lists and trees

4. **Interaction**:
   - Command palette (cmdk)
   - Context menus (Radix UI)
   - Tooltips and popovers
   - Modals and dialogs

5. **Feedback**:
   - Toast notifications (sonner)
   - Loading states
   - Error boundaries
   - Progress indicators

#### 8.2 State Management
- **Zustand** or **Jotai**: Lightweight, flexible state management
- **Immer**: Immutable state updates
- **IndexedDB**: Client-side persistence

#### 8.3 Build System
- **Vite**: Fast development server and build tool
- **ESBuild**: Fast JavaScript bundler
- **TypeScript**: Type-safe development

#### 8.4 Extension System
- **ES Modules**: Standard module format for extensions
- **Dynamic Import**: Lazy loading of extensions
- **Web Workers**: Isolated execution for heavy computations

#### 8.5 Security
- **SES (Secure ECMAScript)**: Hardened JavaScript environment
- **Content Security Policy**: Browser-level security
- **Subresource Integrity**: Verify external resources


> **Note**: State management details are in Section 1.3. Security technologies are in Section 2.1.

---

## 7. Use Cases & Examples



### 7.1 BI Dashboard Application

#### 7.1 Dashboard Builder
- **Drag-and-Drop**: Visual dashboard composition
- **Data Binding**: Connect components to data sources
- **Real-Time Updates**: Live data streaming and updates
- **Responsive Design**: Adaptive layouts for different screen sizes

#### 7.2 Data Visualization
- **Chart Library**: Comprehensive set of chart types
- **Custom Visualizations**: User-defined chart components
- **Interactive Filters**: Cross-filtering between components
- **Drill-Down**: Navigate from summary to detail views

#### 7.3 Developer Workflows
- **Version Control**: Dashboard configurations as code
- **Collaboration**: Share and fork dashboards
- **Testing**: Unit and integration tests for extensions
- **Deployment**: CI/CD integration for dashboard updates

---

## 8. References & Inspiration



### Open Source Projects

**Observable Ecosystem**:
- [Observable Runtime](https://github.com/observablehq/runtime) - Reactive notebook runtime with dependency resolution
- [Observable Plot](https://github.com/observablehq/plot) - Declarative visualization grammar
- [Observable Inputs](https://github.com/observablehq/inputs) - Interactive form controls and widgets
- [Observable Framework](https://github.com/observablehq/framework) - Static site generator for data apps

**tldraw Ecosystem**:
- [tldraw](https://github.com/tldraw/tldraw) - Infinite canvas SDK with collaborative features
- [Signia](https://github.com/tldraw/signia) - Fine-grained reactive state management
- [tldraw-yjs](https://github.com/tldraw/tldraw-yjs) - Yjs integration for collaboration

**Data & SQL**:
- [DuckDB WASM](https://github.com/duckdb/duckdb-wasm) - In-browser analytical SQL database
- [SQLite WASM](https://github.com/sql-js/sql.js) - SQLite compiled to WebAssembly
- [Arquero](https://github.com/uwdata/arquero) - Query processing and transformation library

**Collaboration**:
- [Yjs](https://github.com/yjs/yjs) - CRDT framework for building collaborative applications
- [Automerge](https://github.com/automerge/automerge) - JSON-like data structure for collaboration
- [Loro](https://github.com/loro-dev/loro) - High-performance CRDT library

**State Management**:
- [Zustand](https://github.com/pmndrs/zustand) - Lightweight state management
- [Jotai](https://github.com/pmndrs/jotai) - Primitive and flexible state management
- [Valtio](https://github.com/pmndrs/valtio) - Proxy-based state management
- [Signals](https://github.com/preactjs/signals) - Fine-grained reactivity

**Canvas & Rendering**:
- [Konva.js](https://github.com/konvajs/konva) - 2D canvas framework
- [Fabric.js](https://github.com/fabricjs/fabric.js) - Canvas library with SVG support
- [PixiJS](https://github.com/pixijs/pixijs) - WebGL rendering engine
- [rbush](https://github.com/mourner/rbush) - R-tree spatial indexing

### Platform Documentation

- [Observable Documentation](https://observablehq.com/documentation) - Notebook concepts and API
- [Count.co Documentation](https://count.co/docs) - Canvas-based BI platform
- [tldraw Developer Docs](https://tldraw.dev) - Canvas SDK and API reference
- [Omni Docs](https://omnidocs.com) - Documentation platform architecture

### Technical Articles & Resources

**Observable**:
- [How Observable Runs](https://observablehq.com/@observablehq/how-observable-runs) - Runtime architecture
- [Observable's Not JavaScript](https://observablehq.com/@observablehq/observables-not-javascript) - Reactive semantics
- [Introduction to Data](https://observablehq.com/@observablehq/introduction-to-data) - Data loading patterns

**tldraw**:
- [Building a Collaborative Canvas](https://tldraw.dev/blog/building-a-collaborative-canvas) - Collaboration architecture
- [How tldraw Works](https://tldraw.dev/docs/introduction) - Shape system and state management
- [Performance Optimization](https://tldraw.dev/docs/performance) - Rendering optimizations

**DuckDB WASM**:
- [DuckDB WASM Performance](https://duckdb.org/2021/10/29/duckdb-wasm.html) - Benchmarks and architecture
- [In-Browser Analytics](https://duckdb.org/docs/api/wasm/overview) - WASM integration guide

**Collaboration**:
- [Yjs Documentation](https://docs.yjs.dev/) - CRDT concepts and API
- [CRDT Explained](https://crdt.tech/) - Conflict-free replicated data types
- [Real-time Collaboration Patterns](https://www.figma.com/blog/how-figmas-multiplayer-technology-works/) - Figma's approach

### Design Patterns & Architecture

- [Reactive Programming](https://gist.github.com/staltz/868e7e9bc2a7b8c1f754) - Introduction to reactive thinking
- [Flux Architecture](https://facebook.github.io/flux/) - Unidirectional data flow
- [Event Sourcing](https://martinfowler.com/eaaDev/EventSourcing.html) - Event-driven architecture
- [CQRS Pattern](https://martinfowler.com/bliki/CQRS.html) - Command Query Responsibility Segregation

---

## 9. Architecture Diagram



**Updated Architecture** (reflects comprehensive system design):

```
┌───────────────────────────────────────────────────────────────────────┐
│                          User Interface Layer                         │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐     │
│  │Dashboard │ │ Command  │ │Extension │ │ Settings │ │  Theme   │     │
│  │ Builder  │ │ Palette  │ │ Manager  │ │  Panel   │ │ Switcher │     │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────┘     │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐                  │
│  │  Layout  │ │Keybinding│ │  Hooks   │ │  Advice  │                  │
│  │ Manager  │ │  Editor  │ │ Inspector│ │ Debugger │                  │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘                  │
└───────────────────────────────────────────────────────────────────────┘
                                    │
┌───────────────────────────────────────────────────────────────────────┐
│                           Core System Layer                           │
│  ┌────────────────┐ ┌────────────────┐ ┌────────────────┐             │
│  │   Component    │ │     Event      │ │     State      │             │
│  │    Registry    │ │     System     │ │  Management    │             │
│  │  (Lazy Load)   │ │ (Typed Events) │ │   (Zustand)    │             │
│  └────────────────┘ └────────────────┘ └────────────────┘             │
│  ┌────────────────┐ ┌────────────────┐ ┌────────────────┐             │
│  │     Plugin     │ │   Keybinding   │ │    Command     │             │
│  │     Loader     │ │     System     │ │    Registry    │             │
│  │  (HMR + DI)    │ │ (Chord + Ctx)  │ │  (Palette)     │             │
│  └────────────────┘ └────────────────┘ └────────────────┘             │
│  ┌────────────────┐ ┌────────────────┐ ┌────────────────┐             │
│  │     Hooks &    │ │     Theme      │ │     Layout     │             │
│  │     Advice     │ │     System     │ │     Engine     │             │
│  │  (Priority)    │ │ (CSS Vars)     │ │ (Grid/Mosaic)  │             │
│  └────────────────┘ └────────────────┘ └────────────────┘             │
└───────────────────────────────────────────────────────────────────────┘
                                    │
┌───────────────────────────────────────────────────────────────────────┐
│                         Extension Layer                               │
│  ┌──────────┐ ┌──────────┐  ┌──────────┐ ┌──────────┐ ┌──────────┐    │
│  │   DSL    │ │JavaScript│  │  React   │ │   Web    │ │  Themes  │    │
│  │Extensions│ │Extensions│  │Components│ │Components│ │ & Layouts│    │
│  └──────────┘ └──────────┘  └──────────┘ └──────────┘ └──────────┘    │
│  ┌──────────┐ ┌───────────┐ ┌──────────┐ ┌──────────┐                 │
│  │ Commands │ │Keybindings│ │  Hooks   │ │  Macros  │                 │
│  │          │ │           │ │          │ │          │                 │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘                  │
└───────────────────────────────────────────────────────────────────────┘
                                    │
┌───────────────────────────────────────────────────────────────────────┐
│                          Security Layer                               │
│  ┌────────────────┐ ┌────────────────┐ ┌────────────────┐             │
│  │   Sandboxed    │ │   Capability   │ │      Code      │             │
│  │   Execution    │ │   Permissions  │ │    Signing     │             │
│  │  (SES/iframe)  │ │  (Runtime)     │ │ (Crypto API)   │             │
│  └────────────────┘ └────────────────┘ └────────────────┘             │
│  ┌────────────────┐ ┌────────────────┐ ┌────────────────┐             │
│  │   API Surface  │ │  Audit Log     │ │   Marketplace  │             │
│  │   (Versioned)  │ │  (Tracking)    │ │    Review      │             │
│  └────────────────┘ └────────────────┘ └────────────────┘             │
└───────────────────────────────────────────────────────────────────────┘
                                    │
┌───────────────────────────────────────────────────────────────────────┐
│                        Persistence Layer                              │
│  ┌────────────────┐ ┌────────────────┐ ┌────────────────┐             │
│  │   IndexedDB    │ │  LocalStorage  │ │      OPFS      │             │
│  │  (Warm Data)   │ │  (Hot Data)    │ │  (Cold Data)   │             │
│  └────────────────┘ └────────────────┘ └────────────────┘             │
│  ┌────────────────┐ ┌────────────────┐ ┌────────────────┐             │
│  │   Cloud Sync   │ │   DuckDB WASM  │ │   Time-Travel  │             │
│  │  (REST/GQL)    │ │  (Analytics)   │ │    (Zundo)     │             │
│  └────────────────┘ └────────────────┘ └────────────────┘             │
└───────────────────────────────────────────────────────────────────────┘
                                    │
┌───────────────────────────────────────────────────────────────────────┐
│                       Development Layer                               │
│  ┌────────────────┐ ┌────────────────┐ ┌────────────────┐             │
│  │      HMR       │ │  Source Maps   │ │ Error Overlay  │             │
│  │  (Vite/WP)     │ │  (Debugging)   │ │  (Dev Mode)    │             │
│  └────────────────┘ └────────────────┘ └────────────────┘             │
│  ┌────────────────┐ ┌────────────────┐ ┌────────────────┐             │
│  │ State Inspector│ │  Performance   │ │  Network Mon   │             │
│  │  (DevTools)    │ │   Profiling    │ │  (Extension)   │             │
│  └────────────────┘ └────────────────┘ └────────────────┘             │
└───────────────────────────────────────────────────────────────────────┘
```

**Key Architecture Updates**:

1. **Core System Layer**:
   - Added Hooks & Advice system for extensibility
   - Theme System with CSS Variables
   - Layout Engine (Grid/Mosaic patterns)
   - Enhanced state management (Zustand with middleware)
   - Typed event system with history/replay

2. **Extension Layer**:
   - Expanded to include Web Components
   - Commands and Keybindings as first-class extensions
   - Hooks and Macros support
   - Theme and Layout templates

3. **Security Layer**:
   - Multiple sandboxing approaches (SES/iframe)
   - Runtime permission validation
   - Versioned API surface
   - Audit logging system
   - Marketplace review process

4. **Persistence Layer**:
   - Tiered storage strategy (Hot/Warm/Cold)
   - DuckDB WASM for analytics
   - Time-travel debugging (Zundo)
   - OPFS for large file storage

5. **Development Layer** (New):
   - Hot Module Replacement
   - Source maps and debugging tools
   - Error overlay and recovery
   - State inspector
   - Performance profiling
   - Network monitoring

**Data Flow**:
```
User Action → UI Layer → Core System → Extension Layer
                ↓              ↓              ↓
          Security Check → Permission → Sandboxed Execution
                                ↓
                         Persistence Layer
                                ↓
                         Development Tools (Dev Mode)
```

---

## 10. Implementation Roadmap



### Phase 1: Core Foundation
1. **Core Architecture**
   - Component registry
   - Event system
   - Basic state management
   - Plugin loader skeleton

2. **React Integration**
   - Base React components
   - Context providers
   - Hook-based API

### Phase 2: Core Patterns
1. **Buffer/Window System**
   - Buffer abstraction
   - Window management
   - Layout engine

2. **Keybinding System**
   - Keymap implementation
   - Chord support
   - Mode-specific bindings

3. **Command Palette**
   - Command registry
   - Fuzzy search
   - Command execution

### Phase 3: Extension System
1. **DSL Development**
   - Parser and compiler
   - Type system
   - React code generation

2. **JavaScript Extensions**
   - Sandboxed execution
   - Extension API
   - Hot module replacement

3. **Security Implementation**
   - SES integration
   - Permission system
   - Code signing infrastructure

### Phase 4: Canvas & Notebook Features
1. **Canvas System**
   - Infinite canvas implementation
   - Viewport management (pan/zoom)
   - Cell/shape positioning
   - Spatial indexing (R-tree)
   - Virtual scrolling

2. **SQL Integration**
   - DuckDB WASM integration
   - Query execution engine
   - Result caching (IndexedDB)
   - Reactive query bindings
   - Parameterized queries

3. **Visualization Components**
   - Observable Plot integration
   - Custom chart types
   - D3.js support
   - Interactive features
   - SQL-driven visualizations

4. **Collaboration System**
   - Yjs CRDT integration
   - WebRTC/WebSocket transport
   - Presence system (cursors, avatars)
   - Real-time sync
   - Conflict resolution

### Phase 5: Polish & Production
1. **State Persistence**
   - IndexedDB integration
   - Migration system
   - Export/import

2. **Developer Experience**
   - Documentation
   - Extension templates
   - Debugging tools

3. **Performance Optimization**
   - Code splitting
   - Lazy loading
   - Caching strategies

