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

4. **Basic Layout Parsing** (`lua/tfling/v2/layout.lua`)
   - [ ] Layout structure validation
   - [ ] Layout normalization
   - [ ] Simple layout types (float, split, tab)

5. **Tests**
   - [ ] Unit tests for StateManager
   - [ ] Unit tests for Experience lifecycle
   - [ ] Integration tests for basic show/hide

**Estimated Time**: 2-3 weeks

**Dependencies**: None

**Deliverables**:
- Working state management system
- Basic experience creation and lifecycle
- Simple layout support (single float or split)

## Phase 2: Layout Engine (Priority: Critical)

**Goal**: Implement the layout engine that creates windows, tabs, and splits according to layout specifications.

### Tasks

1. **Window Creation** (`lua/tfling/v2/window.lua`)
   - [ ] Floating window creation
   - [ ] Split window creation (horizontal/vertical)
   - [ ] Tab creation
   - [ ] Container handling
   - [ ] Window configuration calculation
   - [ ] Window hierarchy tracking

2. **Layout Engine** (`lua/tfling/v2/layout.lua` - expanded)
   - [ ] Recursive layout traversal
   - [ ] Nested layout support
   - [ ] Layout-to-window mapping
   - [ ] Window restoration from saved configs
   - [ ] Layout validation and error handling

3. **Geometry Calculations** (`lua/tfling/v2/geometry.lua`)
   - [ ] Floating window position calculation
   - [ ] Split size calculation (percentage/absolute)
   - [ ] Window positioning algorithms
   - [ ] Screen boundary handling

4. **Window Registry** (`lua/tfling/v2/window.lua` - expanded)
   - [ ] Window-to-experience mapping
   - [ ] Window config saving/restoration
   - [ ] Window cleanup on hide/destroy
   - [ ] Window event handling (WinClosed, WinEnter)

5. **Tests**
   - [ ] Unit tests for window creation
   - [ ] Unit tests for layout parsing
   - [ ] Integration tests for complex layouts
   - [ ] E2E tests for multi-window experiences

**Estimated Time**: 3-4 weeks

**Dependencies**: Phase 1

**Deliverables**:
- Complete layout engine
- Support for nested layouts
- Window creation and restoration
- Complex multi-window experiences

## Phase 3: Buffer Management (Priority: High)

**Goal**: Implement buffer creation, management, and lifecycle handling.

### Tasks

1. **Buffer Creation** (`lua/tfling/v2/buffer.lua`)
   - [ ] Terminal buffer creation
   - [ ] File buffer creation
   - [ ] Scratch buffer creation
   - [ ] Function-based buffer creation
   - [ ] Buffer options application

2. **Terminal Integration**
   - [ ] Terminal job management
   - [ ] Terminal exit handling
   - [ ] Terminal command sending
   - [ ] Session providers (tmux, abduco)

3. **Buffer Lifecycle**
   - [ ] Buffer persistence (persistent vs ephemeral)
   - [ ] Buffer recreation on show
   - [ ] Buffer cleanup on hide/destroy
   - [ ] Buffer-to-experience mapping

4. **Buffer Registry** (`lua/tfling/v2/buffer.lua` - expanded)
   - [ ] Buffer tracking
   - [ ] Buffer spec storage
   - [ ] Buffer validation
   - [ ] Buffer event handling (BufEnter, BufDelete)

5. **Tests**
   - [ ] Unit tests for buffer creation
   - [ ] Unit tests for terminal management
   - [ ] Integration tests for buffer lifecycle
   - [ ] E2E tests for persistent buffers

**Estimated Time**: 2-3 weeks

**Dependencies**: Phase 2

**Deliverables**:
- Complete buffer management system
- Terminal support with session providers
- Buffer lifecycle handling
- Buffer persistence options

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

## Phase 5: Advanced Features (Priority: Medium)

**Goal**: Implement advanced features like groups, dependencies, and dynamic layouts.

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

3. **Dynamic Layouts**
   - [ ] Layout modification API
   - [ ] Layout reapplication
   - [ ] Layout diffing (for optimization)

4. **Window Operations** (`lua/tfling/v2/experience.lua` - expanded)
   - [ ] Window resize
   - [ ] Window reposition
   - [ ] Window focus
   - [ ] Window close

5. **Layout Builder** (`lua/tfling/v2/builder.lua`)
   - [ ] Fluent API implementation
   - [ ] Builder state management
   - [ ] Layout construction
   - [ ] Builder validation

6. **Tests**
   - [ ] Unit tests for groups
   - [ ] Unit tests for dependencies
   - [ ] Unit tests for dynamic layouts
   - [ ] Integration tests for advanced features

**Estimated Time**: 3-4 weeks

**Dependencies**: Phase 2, Phase 3, Phase 4

**Deliverables**:
- Experience groups
- Dependency system
- Dynamic layout modification
- Window operations API
- Layout builder

## Phase 6: Compatibility & Migration (Priority: Medium)

**Goal**: Provide compatibility layer for v1 users and migration tools.

### Tasks

1. **v1 Compatibility Layer** (`lua/tfling/v2/compat/v1.lua`)
   - [ ] `tfling.term()` compatibility
   - [ ] `tfling.buff()` compatibility
   - [ ] Window config conversion
   - [ ] Hook conversion (setup → hooks)

2. **Migration Tools**
   - [ ] Migration script/guide
   - [ ] Config converter
   - [ ] Deprecation warnings

3. **Documentation**
   - [ ] Migration guide
   - [ ] API comparison
   - [ ] Breaking changes document

4. **Tests**
   - [ ] Compatibility layer tests
   - [ ] Migration tests
   - [ ] Backward compatibility tests

**Estimated Time**: 1-2 weeks

**Dependencies**: Phase 1-5

**Deliverables**:
- v1 compatibility layer
- Migration tools and documentation
- Backward compatibility maintained

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
  layout.lua            -- Layout engine and parsing
  window.lua            -- Window creation and management
  buffer.lua            -- Buffer creation and management
  hooks.lua             -- Hook system
  geometry.lua          -- Geometry calculations
  groups.lua            -- Experience groups
  builder.lua           -- Layout builder API
  util.lua              -- Utility functions
  compat/
    v1.lua              -- v1 compatibility layer
```

### Testing Strategy

1. **Unit Tests**: Test individual modules in isolation
2. **Integration Tests**: Test module interactions
3. **E2E Tests**: Test complete workflows
4. **Performance Tests**: Benchmark critical paths

### Release Strategy

1. **Alpha Release**: After Phase 1-2 (core functionality)
2. **Beta Release**: After Phase 3-4 (complete feature set)
3. **RC Release**: After Phase 5-6 (advanced features + compatibility)
4. **Stable Release**: After Phase 7 (polish and optimization)

## Risk Mitigation

### Technical Risks

1. **Complex Layout Handling**
   - Mitigation: Start with simple layouts, gradually add complexity
   - Fallback: Limit nesting depth if needed

2. **Window State Restoration**
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
- Basic layouts (float, split) work

### Phase 2 Success
- Complex nested layouts work
- Window restoration works
- Multi-window experiences work

### Phase 3 Success
- All buffer types work
- Terminal integration works
- Buffer lifecycle works correctly

### Phase 4 Success
- All hooks execute correctly
- Hook cancellation works
- Event hooks work

### Phase 5 Success
- Groups work correctly
- Dependencies work correctly
- Dynamic layouts work

### Overall Success
- API is intuitive and powerful
- Performance is acceptable
- Documentation is complete
- Users can migrate from v1 easily

## Timeline Summary

- **Phase 1**: 2-3 weeks
- **Phase 2**: 3-4 weeks
- **Phase 3**: 2-3 weeks
- **Phase 4**: 1-2 weeks
- **Phase 5**: 3-4 weeks
- **Phase 6**: 1-2 weeks
- **Phase 7**: 2-3 weeks

**Total Estimated Time**: 14-21 weeks (~3.5-5 months)

## Next Steps

1. Review and finalize design documents
2. Set up project structure
3. Begin Phase 1 implementation
4. Set up testing infrastructure
5. Create initial documentation
