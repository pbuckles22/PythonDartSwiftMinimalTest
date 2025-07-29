# Context Index - Flutter Minesweeper with Python Integration

## Quick Start for Agents
Start with `AGENT_CONTEXT.md` for immediate understanding, then reference specific files as needed.

## Context File Hierarchy

### 🚀 **Immediate Context** (Read First)
- `AGENT_CONTEXT.md` - **TL;DR summary** (57 lines) - Start here!
- `PROJECT_STATUS.md` - **Current status** (142 lines) - What's working/not working

### 📚 **Specialized Context** (Reference by Task Type)
- `CONTEXT_PYTHON_INTEGRATION.md` - **Python integration details** (150 lines) - Technical Python implementation
- `CONTEXT_UI_UX.md` - **UI/UX implementation** (180 lines) - Interface and user experience
- `CONTEXT_TESTING.md` - **Testing framework** (200 lines) - Test implementation and issues
- `CONTEXT.md` - **Complete technical architecture** (384 lines) - Full implementation details
- `CONVERSATION_SUMMARY.md` - **Historical context** (433 lines) - Past decisions/attempts

### 📖 **Documentation** (Reference for specific tasks)
- `README.md` - **Project documentation** (187 lines) - Setup and usage
- `.cursorrules` - **Cursor-specific rules** (292 lines) - Development guidelines

## When to Reference Each File

### For **Python Integration Work** (Subprocess, 50/50 detection, Python scripts)
1. `AGENT_CONTEXT.md` - Understand current approach
2. `CONTEXT_PYTHON_INTEGRATION.md` - Deep Python technical details
3. `PROJECT_STATUS.md` - Check current Python issues

### For **UI/UX Work** (Interface, settings, visual feedback)
1. `AGENT_CONTEXT.md` - Get the gist
2. `CONTEXT_UI_UX.md` - UI implementation details
3. `PROJECT_STATUS.md` - Check current UI issues

### For **Testing Work** (Test failures, new tests, test framework)
1. `AGENT_CONTEXT.md` - Understand project structure
2. `CONTEXT_TESTING.md` - Testing framework details
3. `PROJECT_STATUS.md` - Check current test issues

### For **Quick Questions** (Simple bugs, basic functionality)
1. `AGENT_CONTEXT.md` - Get the gist
2. `PROJECT_STATUS.md` - Check current state

### For **Historical Context** (Why certain decisions were made)
1. `AGENT_CONTEXT.md` - Current approach
2. `CONVERSATION_SUMMARY.md` - Past attempts and decisions

### For **New Developer Setup**
1. `AGENT_CONTEXT.md` - Quick overview
2. `README.md` - Setup instructions
3. `CONTEXT.md` - Technical background

## Context Management Strategy

### **Keep in Agent Context** (Always Available)
- `AGENT_CONTEXT.md` - Essential for every interaction
- `PROJECT_STATUS.md` - Current state always needed

### **Reference on Demand** (Load when needed)
- `CONTEXT_PYTHON_INTEGRATION.md` - Only when working on Python integration
- `CONTEXT_UI_UX.md` - Only when working on UI/UX
- `CONTEXT_TESTING.md` - Only when working on testing
- `CONTEXT.md` - Only when working on technical implementation
- `CONVERSATION_SUMMARY.md` - Only when understanding historical decisions
- `README.md` - Only when setting up or documenting
- `.cursorrules` - Only when following development guidelines

## File Size Optimization

### **Current Total**: 1,495 lines
### **Optimized Context**: ~200 lines (AGENT_CONTEXT.md + PROJECT_STATUS.md)
### **Specialized Context**: ~530 lines (3 new specialized files)
### **Savings**: ~1,300 lines of context space for most interactions

## Usage Instructions for Agents

1. **Always start** with `AGENT_CONTEXT.md`
2. **Check current status** with `PROJECT_STATUS.md`
3. **Reference specialized files** based on the type of work:
   - Python work → `CONTEXT_PYTHON_INTEGRATION.md`
   - UI work → `CONTEXT_UI_UX.md`
   - Testing work → `CONTEXT_TESTING.md`
4. **Use this index** to know which file to reference for specific tasks

## Context File Purposes

| File | Purpose | When to Use | Lines | Priority |
|------|---------|-------------|-------|----------|
| `AGENT_CONTEXT.md` | Quick TL;DR | Every interaction | 57 | 🚀 Always |
| `PROJECT_STATUS.md` | Current state | Status checks | 142 | 🚀 Always |
| `CONTEXT_PYTHON_INTEGRATION.md` | Python details | Python work | 150 | 📚 On-demand |
| `CONTEXT_UI_UX.md` | UI implementation | UI/UX work | 180 | 📚 On-demand |
| `CONTEXT_TESTING.md` | Testing framework | Testing work | 200 | 📚 On-demand |
| `CONTEXT.md` | Technical architecture | Deep implementation | 384 | 📚 On-demand |
| `CONVERSATION_SUMMARY.md` | Historical context | Understanding decisions | 433 | 📚 On-demand |
| `README.md` | Documentation | Setup/usage | 187 | 📖 On-demand |
| `.cursorrules` | Development rules | Following guidelines | 292 | 📖 On-demand |

## Task-Specific Context Loading

### Python Integration Tasks
```
AGENT_CONTEXT.md + PROJECT_STATUS.md + CONTEXT_PYTHON_INTEGRATION.md
Total: ~350 lines (vs. 1,495 lines)
```

### UI/UX Tasks
```
AGENT_CONTEXT.md + PROJECT_STATUS.md + CONTEXT_UI_UX.md
Total: ~380 lines (vs. 1,495 lines)
```

### Testing Tasks
```
AGENT_CONTEXT.md + PROJECT_STATUS.md + CONTEXT_TESTING.md
Total: ~400 lines (vs. 1,495 lines)
```

### Quick Questions
```
AGENT_CONTEXT.md + PROJECT_STATUS.md
Total: ~200 lines (vs. 1,495 lines)
```

This structure reduces context from 1,495 lines to 200-400 lines for most interactions while maintaining access to detailed information when needed.