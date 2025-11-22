# Tfling v2 Implementation Roadmap

## Overview

This document outlines the implementation plan for Tfling v2, breaking down the work into phases with clear priorities and dependencies.

## Phase 0: Foundation & Planning ✅

- [x] Design document creation
- [x] Technical specification
- [x] Examples and use cases
- [x] API design finalization

**Status**: Complete

## Phase 1: Core State Management (Priority: Critical)

**Goal**: Implement the fundamental state management system that tracks experiences and their lifecycle.

### Tasks

1. **StateManager Module** (`lua/tfling/v2/state.lua`)
   - [ ] Experience storage (Map<id, Experience>)
   - [ ] Active experiences tracking
   - [ ] Window-to-experience mapping
   - [ ] Buffer-to-experience mapping
   - [ ] Basic CRUD operations (create, get, list, destroy)
   - [ ] State queries (is_visible, is_hidden, etc.)

2. **Experience Class** (`lua/tfling/v2/experience.lua`)
   - [ ] Experience object structure
   - [ ] State transitions (created → visible → hidden → destroyed)
   - [ ] Basic show/hide/toggle methods
   - [ ] Metadata storage
   - [ ] Window/buffer tracking

3. **Core API** (`lua/tfling/v2/init.lua`)
   - [ ] `tfling.create()` function
   - [ ] `tfling.show()` function
   - [ ] `tfling.hide()` function
   - [ ] `tfling.toggle()` function
   - [ ] `tfling.destroy()` function
   - [ ] `tfling.get()` function
   - [ ] `tfling.state()` function
   - [ ] `tfling.list()` function

4. **Tests**
   - [ ] Unit tests for StateManager
   - [ ] Unit tests for Experience lifecycle
   - [ ] Integration tests for basic show/hide

**Estimated Time**: 2-3 weeks

**Dependencies**: None

**Deliverables**:
- Working state management system
- Basic experience creation and lifecycle
- Experience state tracking

## Phase 2: Registration System (Priority: Critical)

**Goal**: Implement the registration system for windows, buffers, and tabs.

### Tasks

1. **Window Registration** (`lua/tfling/v2/registry.lua`)
   - [ ] Window registration API
   - [ ] Window validation
   - [ ] Window-to-experience mapping
   - [ ] Window unregistration
   - [ ] Window options handling

2. **Buffer Registration** (`lua/tfling/v2/registry.lua`)
   - [ ] Buffer registration API
   - [ ] Buffer validation
   - [ ] Buffer-to-experience mapping
   - [ ] Buffer unregistration
   - [ ] Buffer options handling

3. **Tab Registration** (`lua/tfling/v2/registry.lua`)
   - [ ] Tabpage registration API
   - [ ] Tabpage validation
   - [ ] Tab-to-experience mapping
   - [ ] Tab unregistration
   - [ ] Tab options handling

4. **Registration Options** (`lua/tfling/v2/registry.lua`)
   - [ ] Options parsing and validation
   - [ ] Default options handling
   - [ ] Options storage per element

5. **Bulk Registration** (`lua/tfling/v2/registry.lua`)
   - [ ] Bulk registration API
   - [ ] Batch validation
   - [ ] Error handling

6. **Tests**
   - [ ] Unit tests for registration
   - [ ] Unit tests for validation
   - [ ] Unit tests for unregistration
   - [ ] Integration tests for registration flow

**Estimated Time**: 2-3 weeks

**Dependencies**: Phase 1

**Deliverables**:
- Complete registration system
- Window/buffer/tab registration APIs
- Registration options support
- Bulk registration support

## Phase 3: Lifecycle Management (Priority: High)

**Goal**: Implement show/hide/toggle lifecycle management with state saving and restoration.

### Tasks

1. **State Saving** (`lua/tfling/v2/lifecycle.lua`)
   - [ ] Window config saving
   - [ ] Buffer state saving
   - [ ] Tab state saving
   - [ ] Cursor position saving
   - [ ] View state saving

2. **State Restoration** (`lua/tfling/v2/lifecycle.lua`)
   - [ ] Window config restoration
   - [ ] Buffer state restoration
   - [ ] Tab state restoration
   - [ ] Cursor position restoration
   - [ ] View state restoration

3. **Show Operation** (`lua/tfling/v2/lifecycle.lua`)
   - [ ] Window validation and restoration
   - [ ] Tab switching
   - [ ] Focus management
   - [ ] Invalid element handling

4. **Hide Operation** (`lua/tfling/v2/lifecycle.lua`)
   - [ ] State saving before hide
   - [ ] Window closing (based on options)
   - [ ] Tab closing (based on options)
   - [ ] Buffer cleanup (based on options)

5. **Window Cleanup** (`lua/tfling/v2/lifecycle.lua`)
   - [ ] Invalid window detection
   - [ ] Window cleanup on hide
   - [ ] Window cleanup on destroy
   - [ ] Registry cleanup

6. **Tests**
   - [ ] Unit tests for state saving
   - [ ] Unit tests for state restoration
   - [ ] Integration tests for show/hide
   - [ ] E2E tests for lifecycle

**Estimated Time**: 2-3 weeks

**Dependencies**: Phase 2

**Deliverables**:
- Complete lifecycle management
- State saving and restoration
- Show/hide/toggle operations
- Window cleanup handling

## Phase 4: Hook System (Priority: High)

**Goal**: Implement the hook system for extensibility and custom behavior.

### Tasks

1. **Hook Registration** (`lua/tfling/v2/hooks.lua`)
   - [ ] Hook storage per experience
   - [ ] Global hooks support
   - [ ] Hook validation

2. **Hook Execution**
   - [ ] Hook execution order
   - [ ] Hook context (Experience object)
   - [ ] Hook cancellation (return false)
   - [ ] Error handling in hooks

3. **Lifecycle Hooks**
   - [ ] before_create / after_create
   - [ ] before_show / after_show
   - [ ] before_hide / after_hide
   - [ ] before_destroy / after_destroy

4. **Event Hooks**
   - [ ] on_focus (WinEnter)
   - [ ] on_buffer_enter (BufEnter)
   - [ ] on_window_close (WinClosed)

5. **Hook Utilities**
   - [ ] Hook chaining
   - [ ] Hook debugging/logging
   - [ ] Hook performance monitoring

6. **Tests**
   - [ ] Unit tests for hook execution
   - [ ] Unit tests for hook cancellation
   - [ ] Integration tests for lifecycle hooks
   - [ ] E2E tests for complex hook scenarios

**Estimated Time**: 1-2 weeks

**Dependencies**: Phase 1, Phase 2

**Deliverables**:
- Complete hook system
- All lifecycle hooks working
- Event hooks working
- Hook utilities and debugging

## Phase 5: Window Operations (Priority: Medium)

**Goal**: Implement window manipulation and query APIs.

### Tasks

1. **Window Resize** (`lua/tfling/v2/experience.lua`)
   - [ ] Resize floating windows
   - [ ] Resize split windows
   - [ ] Percentage and absolute sizing
   - [ ] Relative sizing (+10%, -5%, etc.)

2. **Window Reposition** (`lua/tfling/v2/experience.lua`)
   - [ ] Reposition floating windows
   - [ ] Position presets (center, top-left, etc.)
   - [ ] Absolute and relative positioning

3. **Window Focus** (`lua/tfling/v2/experience.lua`)
   - [ ] Focus specific window
   - [ ] Focus primary window
   - [ ] Focus next/previous window

4. **Query Methods** (`lua/tfling/v2/experience.lua`)
   - [ ] Get registered windows
   - [ ] Get registered buffers
   - [ ] Get registered tabs
   - [ ] Check if element is registered
   - [ ] Get element options

5. **Tests**
   - [ ] Unit tests for window operations
   - [ ] Unit tests for query methods
   - [ ] Integration tests for operations

**Estimated Time**: 1-2 weeks

**Dependencies**: Phase 1, Phase 2, Phase 3

**Deliverables**:
- Window resize API
- Window reposition API
- Window focus API
- Query methods API

## Phase 6: Advanced Features (Priority: Medium)

**Goal**: Implement advanced features like groups, dependencies, and bulk operations.

### Tasks

1. **Experience Groups** (`lua/tfling/v2/groups.lua`)
   - [ ] Group creation and management
   - [ ] Group show/hide/toggle
   - [ ] Group membership tracking
   - [ ] Group-level hooks

2. **Dependency System**
   - [ ] Dependency declaration
   - [ ] Dependency graph building
   - [ ] Circular dependency detection
   - [ ] Automatic dependency show/hide

3. **Bulk Operations**
   - [ ] Bulk registration API
   - [ ] Batch show/hide operations
   - [ ] Experience cloning

4. **Tests**
   - [ ] Unit tests for groups
   - [ ] Unit tests for dependencies
   - [ ] Unit tests for bulk operations
   - [ ] Integration tests for advanced features

**Estimated Time**: 2-3 weeks

**Dependencies**: Phase 1-5

**Deliverables**:
- Experience groups
- Dependency system
- Bulk operations

## Phase 7: Polish & Optimization (Priority: Low)

**Goal**: Performance optimization, error handling improvements, and polish.

### Tasks

1. **Performance Optimization**
   - [ ] Window creation batching
   - [ ] State lookup optimization
   - [ ] Memory management improvements
   - [ ] Redraw minimization

2. **Error Handling**
   - [ ] Comprehensive error messages
   - [ ] Error recovery mechanisms
   - [ ] Validation improvements
   - [ ] Error logging

3. **Documentation**
   - [ ] Complete API documentation
   - [ ] More examples
   - [ ] Best practices guide
   - [ ] Troubleshooting guide

4. **Testing**
   - [ ] Performance benchmarks
   - [ ] Stress tests
   - [ ] Edge case tests
   - [ ] Memory leak tests

5. **User Experience**
   - [ ] Better error messages
   - [ ] Debugging utilities
   - [ ] Status reporting
   - [ ] Configuration validation

**Estimated Time**: 2-3 weeks

**Dependencies**: All previous phases

**Deliverables**:
- Optimized performance
- Robust error handling
- Complete documentation
- Production-ready code

## Implementation Strategy

### Development Approach

1. **Incremental Development**: Build and test each phase before moving to the next
2. **Test-Driven**: Write tests alongside implementation
3. **Documentation**: Keep documentation updated as features are added
4. **User Feedback**: Gather feedback early and often

### Code Organization

```
lua/tfling/v2/
  init.lua              -- Main entry point, exports API
  state.lua             -- StateManager implementation
  experience.lua        -- Experience class and methods
  registry.lua          -- Window/buffer/tab registration
  lifecycle.lua         -- Show/hide/toggle lifecycle
  hooks.lua             -- Hook system
  groups.lua            -- Experience groups
  util.lua              -- Utility functions
```

### Testing Strategy

1. **Unit Tests**: Test individual modules in isolation
2. **Integration Tests**: Test module interactions
3. **E2E Tests**: Test complete workflows
4. **Performance Tests**: Benchmark critical paths

### Release Strategy

1. **Alpha Release**: After Phase 1-2 (core functionality)
2. **Beta Release**: After Phase 3-4 (complete feature set)
3. **RC Release**: After Phase 5-6 (advanced features)
4. **Stable Release**: After Phase 7 (polish and optimization)

## Risk Mitigation

### Technical Risks

1. **Window State Restoration**
   - Mitigation: Comprehensive testing of window restoration
   - Fallback: Recreate windows if restoration fails

3. **Performance with Many Experiences**
   - Mitigation: Optimize state lookups, batch operations
   - Fallback: Limit maximum concurrent experiences

### Timeline Risks

1. **Scope Creep**
   - Mitigation: Strict phase boundaries, defer non-critical features
   - Fallback: Extend timeline or reduce scope

2. **Unexpected Complexity**
   - Mitigation: Prototype complex features early
   - Fallback: Simplify or defer complex features

## Success Criteria

### Phase 1 Success
- Can create and toggle simple experiences
- State management works correctly
- Experience lifecycle works

### Phase 2 Success
- Window/buffer/tab registration works
- Registration options work correctly
- Bulk registration works

### Phase 3 Success
- State saving and restoration works
- Show/hide operations work correctly
- Window cleanup works

### Phase 4 Success
- All hooks execute correctly
- Hook cancellation works
- Event hooks work

### Phase 5 Success
- Window operations work correctly
- Experience query methods work

### Phase 6 Success
- Groups work correctly
- Dependencies work correctly
- Bulk operations work

### Overall Success
- API is intuitive and powerful
- Registration model works smoothly
- Performance is acceptable
- Documentation is complete

## Timeline Summary

- **Phase 1**: 2-3 weeks
- **Phase 2**: 2-3 weeks
- **Phase 3**: 2-3 weeks
- **Phase 4**: 1-2 weeks
- **Phase 5**: 2-3 weeks
- **Phase 6**: 2-3 weeks

**Total Estimated Time**: 11-17 weeks (~2.5-4 months)

## Next Steps

1. Review and finalize design documents
2. Set up project structure
3. Begin Phase 1 implementation
4. Set up testing infrastructure
5. Create initial documentation

## Design Changes from Original Plan

### Design Decisions
- **No Layout Engine**: Plugins handle window creation
- **No Buffer Creation**: Plugins handle buffer creation
- **Registration Model**: Core feature - dynamic registration of UI elements

### New Focus
- **Registration Model**: Core feature - dynamic registration of UI elements
- **State Management**: Focus on grouping and lifecycle, not creation
- **Separation of Concerns**: Clear boundary between plugin creation and Tfling management
