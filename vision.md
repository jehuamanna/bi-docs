# Vision.

What are the programs with a similar Emacs architecture? These programs feature a tiny core that aids in the development of GUIs and enhances extensibility. The design must be ultra modular and extensible. I want examples in web apps.

It is okay to have a DSL or JavaScript as the language to extend the UI on the fly. If JavaScript, then security considerations should be put across.

The idea is similar to emacs inside a browser. But its not emacs, instead of that extending UI by building it as a small components using DSL/javascript and keep extending it by the user on the fly to have his own layouts and GUIs.


## Architecture & Core Design

### Core Functionality

What specific capabilities should the "tiny core" provide? (e.g., component registry, event system, state management, plugin loader?)

#### Answer

All of them.

### Emacs Inspiration

Which specific Emacs architectural patterns are most important to you? (e.g., buffer/window model, keybinding system, command palette, hooks/advice system?)

#### Answer

All of them.

## Extensibility & DSL

### DSL vs JavaScript: Do you have a preference between creating a custom DSL or using JavaScript? Or should the system support both?
#### Answer

both.

### Extension Scope: What should users be able to extend? (e.g., UI components, keybindings, commands, themes, entire layouts?)
#### Answer

All of them.

### Hot Reloading: Should extensions be loadable/unloadable without page refresh?
#### Answer

Yes.

## Security & Sandboxing

### Security Model: If using JavaScript, what level of sandboxing is needed? Should extensions have

#### Answer

- Full DOM access?
   - not sure (Secure ECMAScript (Agoric)?)
- Limited API surface?
 - yes
- Capability-based permissions?
 - yes
- Code review/signing requirements?
 - yes

## Use Cases & Target Audience

### Primary Use Case: What would be the main application of this system? (e.g., note-taking, code editing, general productivity, dashboard builder?)

#### Answer

Building BI dynamic dashboards.

### Target Users: Who are the expected users? (developers only, or broader audience?)

#### Answer

Developers only.

## Technical Preferences

### Framework/Stack: Any preferences for the underlying web technologies? (React, Vue, vanilla JS, WebComponents?)

#### Answer

React.

### State Persistence: Should user configurations and extensions persist across sessions?

#### Answer

Yes.
