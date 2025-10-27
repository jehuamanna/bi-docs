# Extensible BI Dashboard Framework: Technical Documentation

## Project Overview

**Extensible BI Dashboard Framework** is a browser-based, highly extensible framework designed for building dynamic Business Intelligence (BI) dashboards. The system features a minimal core with maximum extensibility, allowing developers to create, customize, and extend UI components on-the-fly using both a custom DSL and JavaScript.

### Core Philosophy

- **Tiny Core, Maximum Extensibility**: Minimal core functionality with comprehensive plugin architecture
- **Plugin-Based Architecture**: Adopts proven patterns for extensibility and modularity
- **Developer-First**: Built for developers who need powerful customization capabilities
- **Security-Conscious**: Sandboxed execution environment with capability-based permissions

---

## Architecture

### 1. Core System Components

The minimal core provides essential infrastructure:

#### 1.1 Component Registry
- **Purpose**: Central registry for all UI components (built-in and user-defined)
- **Responsibilities**:
  - Component registration and discovery
  - Lifecycle management (mount, unmount, update)
  - Dependency resolution
  - Version management

#### 1.2 Event System
- **Purpose**: Pub/sub event bus for inter-component communication
- **Features**:
  - Global and scoped event channels
  - Event hooks and listeners
  - Async event handling
  - Event history and replay (for debugging)

#### 1.3 State Management
- **Purpose**: Centralized, reactive state management
- **Features**:
  - Immutable state updates
  - Time-travel debugging
  - State persistence and hydration
  - Computed/derived state
  - State snapshots and restoration

#### 1.4 Plugin Loader
- **Purpose**: Dynamic loading and management of extensions
- **Features**:
  - Hot module replacement (HMR)
  - Lazy loading of plugins
  - Plugin dependency management
  - Sandboxed execution context
  - Plugin lifecycle hooks (init, activate, deactivate, destroy)

---

### 2. Core Architectural Patterns

#### 2.1 Buffer/Window Model
- **Buffers**: Logical content containers (data views, charts, tables)
- **Windows**: Visual panes that display buffers
- **Layout Management**: Split, resize, and arrange windows dynamically
- **Buffer Switching**: Quick navigation between different data views

#### 2.2 Keybinding System
- **Global Keybindings**: System-wide keyboard shortcuts
- **Mode-Specific Keybindings**: Context-aware shortcuts based on active component
- **Keymaps**: Hierarchical keybinding definitions
- **Chord Support**: Multi-key sequences (e.g., `Ctrl+x Ctrl+s`)
- **Customizable**: Users can rebind any key combination

#### 2.3 Command Palette
- **Command Registry**: All actions exposed as named commands
- **Fuzzy Search**: Quick command discovery
- **Command History**: Recently used commands
- **Parameterized Commands**: Commands that accept arguments
- **Keyboard-First**: Fully navigable via keyboard

#### 2.4 Hooks & Advice System
- **Hooks**: Extension points for custom behavior
  - `before-render`, `after-render`
  - `before-state-change`, `after-state-change`
  - `plugin-loaded`, `plugin-unloaded`
- **Advice**: Wrap or modify existing functions
  - `before-advice`: Run before original function
  - `after-advice`: Run after original function
  - `around-advice`: Wrap and control original function execution

---

## Extensibility

### 3. Dual Extension Languages

#### 3.1 Custom DSL
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

#### 3.2 JavaScript Extensions
- **Purpose**: Full programmatic control for advanced use cases
- **Features**:
  - Access to extension API
  - React component creation
  - Custom data transformations
  - Integration with external libraries
  - Sandboxed execution

---

### 4. Extension Scope

Users can extend all aspects of the system:

#### 4.1 UI Components
- Custom chart types
- Data visualization widgets
- Input controls and forms
- Layout containers
- Themes and styling

#### 4.2 Keybindings
- Custom keyboard shortcuts
- Mode-specific bindings
- Macro recording and playback

#### 4.3 Commands
- Custom actions and workflows
- Data processing pipelines
- External API integrations

#### 4.4 Themes
- Color schemes
- Typography
- Component styling
- Dark/light mode variants

#### 4.5 Layouts
- Window arrangements
- Dashboard templates
- Responsive breakpoints

---

### 5. Hot Reloading

- **Live Updates**: Extensions reload without page refresh
- **State Preservation**: Maintain application state during reload
- **Error Recovery**: Graceful handling of extension errors
- **Development Mode**: Enhanced debugging and error reporting

---

## Security Model

### 6. Sandboxing & Permissions

#### 6.1 Execution Environment
- **Sandboxed JavaScript**: Extensions run in isolated context
- **Secure ECMAScript**: Consider Agoric's SES for hardened JavaScript
- **Limited DOM Access**: Controlled access to DOM APIs
- **No Direct Network Access**: All external requests go through core API

#### 6.2 Capability-Based Permissions
Extensions request specific capabilities:
- `data:read` - Read dashboard data
- `data:write` - Modify dashboard data
- `ui:render` - Render custom UI components
- `storage:local` - Access local storage
- `network:fetch` - Make HTTP requests
- `system:commands` - Register commands

#### 6.3 API Surface
- **Minimal, Explicit API**: Only expose necessary functions
- **Versioned API**: Maintain backward compatibility
- **Permission Checks**: Runtime validation of capabilities
- **Audit Log**: Track extension actions

#### 6.4 Code Review & Signing
- **Extension Marketplace**: Curated, reviewed extensions
- **Code Signing**: Cryptographic signatures for verified extensions
- **Security Scanning**: Automated analysis for common vulnerabilities
- **User Warnings**: Clear indicators for unverified extensions

---

## Use Case: BI Dynamic Dashboards

### 7. Primary Application

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

## Technical Stack

### 8. Technology Choices

#### 8.1 Frontend Framework
- **React**: Component-based UI library
- **React Hooks**: Modern state and lifecycle management
- **React Context**: Dependency injection and theming

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

---

## State Persistence

### 9. Configuration & Data Persistence

#### 9.1 User Configurations
- **Settings**: User preferences and options
- **Keybindings**: Custom keyboard shortcuts
- **Themes**: Selected color schemes
- **Layouts**: Window arrangements and dashboard templates

#### 9.2 Extension State
- **Plugin Configurations**: Extension-specific settings
- **Installed Extensions**: List of active plugins
- **Extension Data**: Plugin-managed data

#### 9.3 Storage Options & Strategy

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

#### 9.4 Migration & Versioning
- **Schema Versioning**: Handle data format changes
- **Automatic Migration**: Upgrade old configurations
- **Rollback Support**: Revert to previous versions
- **Cross-Storage Sync**: Coordinate data across storage layers

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        User Interface                        │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │ Dashboard│  │  Command │  │ Extension│  │  Settings│   │
│  │  Builder │  │  Palette │  │  Manager │  │   Panel  │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                         Core System                          │
│  ┌────────────────┐  ┌────────────────┐  ┌──────────────┐  │
│  │   Component    │  │     Event      │  │    State     │  │
│  │    Registry    │  │     System     │  │  Management  │  │
│  └────────────────┘  └────────────────┘  └──────────────┘  │
│  ┌────────────────┐  ┌────────────────┐  ┌──────────────┐  │
│  │     Plugin     │  │   Keybinding   │  │   Command    │  │
│  │     Loader     │  │     System     │  │   Registry   │  │
│  └────────────────┘  └────────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                      Extension Layer                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │   DSL    │  │JavaScript│  │  Custom  │  │  Themes  │   │
│  │Extensions│  │Extensions│  │Components│  │          │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                      Security Layer                          │
│  ┌────────────────┐  ┌────────────────┐  ┌──────────────┐  │
│  │   Sandboxed    │  │  Capability    │  │     Code     │  │
│  │   Execution    │  │  Permissions   │  │    Signing   │  │
│  └────────────────┘  └────────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                    Persistence Layer                         │
│  ┌────────────────┐  ┌────────────────┐  ┌──────────────┐  │
│  │   IndexedDB    │  │  LocalStorage  │  │ Cloud Sync   │  │
│  └────────────────┘  └────────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## Implementation Roadmap

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

### Phase 4: BI Dashboard Features
1. **Dashboard Builder**
   - Visual editor
   - Component library
   - Data binding

2. **Visualization Components**
   - Chart library integration
   - Custom chart types
   - Interactive features

3. **Data Layer**
   - Data source connectors
   - Query builder
   - Real-time updates

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

---

## Key Design Decisions

### 10. Critical Considerations

#### 10.1 Security vs. Flexibility
- **Challenge**: Balancing powerful extensibility with security
- **Solution**: Layered security model with explicit permissions
- **Trade-off**: Some flexibility sacrificed for safety

#### 10.2 DSL Complexity
- **Challenge**: Designing a DSL that's simple yet powerful
- **Solution**: Start minimal, expand based on user feedback
- **Trade-off**: May require JavaScript for advanced cases

#### 10.3 Performance
- **Challenge**: Hot reloading without performance degradation
- **Solution**: Incremental updates, code splitting, lazy loading
- **Trade-off**: Increased complexity in module system

#### 10.4 State Management
- **Challenge**: Maintaining state during hot reload
- **Solution**: State serialization and hydration
- **Trade-off**: Some state may be non-serializable

#### 10.5 Backward Compatibility
- **Challenge**: Evolving API without breaking extensions
- **Solution**: Versioned API with deprecation warnings
- **Trade-off**: Maintenance burden of multiple API versions

---

## Similar Projects & Inspiration

### 11. Reference Implementations

#### 11.1 Extensible Web Apps
- **Jupyter Notebook**: Cell-based editing with extensions
- **Observable**: Reactive notebooks with live updates
- **CodeMirror**: Extensible code editor

#### 11.2 Extensible Dashboards
- **Grafana**: Plugin-based dashboard system
- **Apache Superset**: Extensible BI platform
- **Metabase**: Customizable analytics

#### 11.3 Plugin Architectures
- **VS Code**: Extension marketplace and API
- **Figma**: Plugin system for design tools
- **Chrome Extensions**: Browser extension model

#### 11.4 Security Models
- **Agoric**: SES-based secure JavaScript
- **Deno**: Permission-based runtime
- **Salesforce Lightning**: Secure component framework

---

## Success Metrics

### 12. Project Goals

#### 12.1 Technical Metrics
- **Core Size**: < 50KB gzipped
- **Extension Load Time**: < 100ms
- **Hot Reload Time**: < 500ms
- **Memory Footprint**: Efficient with 100+ extensions

#### 12.2 Developer Experience
- **Time to First Extension**: < 30 minutes
- **Documentation Coverage**: 100% of public API
- **Extension Ecosystem**: Active marketplace

#### 12.3 Security
- **Zero Critical Vulnerabilities**: Regular security audits
- **Extension Review Time**: < 48 hours
- **Incident Response**: < 24 hours for critical issues

---

## Conclusion

This framework represents an ambitious vision: bringing legendary extensibility to modern web-based BI dashboards. By combining a minimal core with comprehensive extension capabilities, dual language support (DSL + JavaScript), and a robust security model, the system empowers developers to build highly customized, dynamic dashboards while maintaining safety and performance.

The architecture draws from proven patterns (VS Code, Grafana, extensible editors) while innovating in areas like hot reloading, capability-based permissions, and dual-language extensibility. The result is a platform that's both powerful for experts and approachable for developers building their first extension.

**Next Steps**: Begin with Phase 1 implementation, focusing on core architecture and React integration. Iterate based on developer feedback, prioritizing security and performance from day one.
