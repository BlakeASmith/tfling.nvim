# Tfling v2 Design Documents Index

## Overview

This directory contains the complete design documentation for Tfling v2, a state management library for Neovim that provides a flexible, low-level API for creating toggleable screen experiences.

## Documents

### 📋 [SUMMARY.md](./SUMMARY.md)
**Quick overview and navigation guide**

Start here for a high-level understanding of Tfling v2. Includes:
- Key concepts
- Core API overview
- Architecture summary
- Implementation phases
- Quick examples

**Read this first** if you're new to the project.

---

### 🏗️ [DESIGN.md](./DESIGN.md)
**High-level architecture and design**

Comprehensive design document covering:
- Core philosophy and concepts
- Architecture overview
- API design
- Layout system
- Hook system
- Advanced features
- Migration from v1

**Read this** for understanding the overall design and architecture.

---

### 🔧 [TECHNICAL_SPEC.md](./TECHNICAL_SPEC.md)
**Detailed technical specification**

Deep dive into implementation details:
- Data structures
- Algorithms
- State management
- Window creation
- Buffer management
- Error handling
- Performance considerations

**Read this** when implementing or debugging.

---

### 📚 [EXAMPLES.md](./EXAMPLES.md)
**Usage examples and patterns**

Practical examples showing:
- Basic usage
- Advanced layouts
- Hook implementations
- Group management
- Plugin integration
- Real-world scenarios

**Read this** to learn how to use the API.

---

### 🗺️ [ROADMAP.md](./ROADMAP.md)
**Implementation roadmap**

Detailed implementation plan:
- Phase breakdown
- Task lists
- Dependencies
- Timeline estimates
- Success criteria
- Risk mitigation

**Read this** to understand the implementation plan.

---

### 📖 [API_REFERENCE.md](./API_REFERENCE.md)
**Complete API reference**

Quick reference for all APIs:
- Function signatures
- Parameters
- Return values
- Examples
- Common patterns

**Read this** as a quick reference while coding.

---

## Reading Order

### For Project Managers / Stakeholders
1. SUMMARY.md - Get the overview
2. ROADMAP.md - Understand timeline and phases

### For Architects / Designers
1. SUMMARY.md - Overview
2. DESIGN.md - Architecture and design
3. TECHNICAL_SPEC.md - Implementation details

### For Developers (New to Project)
1. SUMMARY.md - Overview
2. EXAMPLES.md - See how it works
3. DESIGN.md - Understand architecture
4. API_REFERENCE.md - Learn the API

### For Developers (Implementing)
1. TECHNICAL_SPEC.md - Implementation details
2. API_REFERENCE.md - API reference
3. EXAMPLES.md - Usage patterns
4. ROADMAP.md - Implementation plan

### For Plugin Developers (Using Tfling v2)
1. SUMMARY.md - Overview
2. EXAMPLES.md - Usage examples
3. API_REFERENCE.md - API reference
4. DESIGN.md - Understanding hooks and extensibility

## Key Concepts Quick Reference

### Experience
A logical grouping of windows/tabs/splits that can be toggled as a unit.

### Layout
Defines the structure: floats, splits, tabs, containers, and their relationships.

### Buffer Specification
Describes content: terminal, file, scratch buffer, or function-generated.

### Hooks
Lifecycle and event hooks for custom behavior.

### Groups
Collections of experiences managed together.

## Quick Start

```lua
local tfling = require("tfling.v2")

-- Create an experience
local exp = tfling.create({
  id = "my-tool",
  layout = {
    type = "float",
    config = { width = "80%", height = "60%", position = "center" },
    buffer = { type = "terminal", source = "bash" },
  },
})

-- Toggle it
exp:toggle()
```

## Design Status

✅ **Design Phase**: Complete
- [x] Architecture designed
- [x] API specified
- [x] Data structures defined
- [x] Algorithms specified
- [x] Examples created
- [x] Roadmap planned

⏳ **Implementation Phase**: Not started
- [ ] Phase 1: Core state management
- [ ] Phase 2: Layout engine
- [ ] Phase 3: Buffer management
- [ ] Phase 4: Hook system
- [ ] Phase 5: Advanced features
- [ ] Phase 6: Compatibility layer
- [ ] Phase 7: Polish & optimization

## Document Relationships

```
SUMMARY.md (overview)
    ├── DESIGN.md (architecture)
    │   └── TECHNICAL_SPEC.md (implementation)
    ├── EXAMPLES.md (usage)
    │   └── API_REFERENCE.md (reference)
    └── ROADMAP.md (plan)
```

## Contributing

When contributing to the design:

1. **Architecture changes**: Update DESIGN.md and TECHNICAL_SPEC.md
2. **API changes**: Update DESIGN.md, API_REFERENCE.md, and EXAMPLES.md
3. **New features**: Update all relevant documents
4. **Implementation progress**: Update ROADMAP.md

## Questions?

- **Architecture questions**: See DESIGN.md
- **Implementation questions**: See TECHNICAL_SPEC.md
- **Usage questions**: See EXAMPLES.md
- **API questions**: See API_REFERENCE.md
- **Timeline questions**: See ROADMAP.md

## Next Steps

1. Review all design documents
2. Get feedback from stakeholders
3. Finalize design based on feedback
4. Begin Phase 1 implementation
5. Set up testing infrastructure

---

**Last Updated**: Design phase complete
**Status**: Ready for implementation review
