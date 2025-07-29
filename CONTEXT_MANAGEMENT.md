# Context Management Strategy

## 🧠 Memory Management & Context Switching

### Context Categories

#### 1. **Core Architecture** (Always Loaded)
- **File**: `.cursorrules`
- **Purpose**: Critical architecture patterns, anti-patterns, key interfaces
- **Memory**: Always available to all agents
- **Content**: Repository patterns, feature flags, immutable state rules

#### 2. **Current Session Context** (Loaded as Needed)
- **Files**: `CONTEXT.md`, `CONTEXT_TESTING.md`, `TODO.md`
- **Purpose**: Current session focus, specific tasks, immediate priorities
- **Memory**: Load when switching focus areas
- **Content**: Current bugs, testing status, immediate tasks

#### 3. **Detailed Documentation** (Reference Only)
- **Files**: `ARCHITECTURE_CONTEXT.md`, `CONVERSATION_SUMMARY.txt`
- **Purpose**: Comprehensive documentation, historical context
- **Memory**: Load only when needed for deep understanding
- **Content**: Complete architecture docs, conversation history

### Context Switching Commands

#### For Agents: Context Loading Commands

```markdown
# Load Testing Context
"Load testing context" or "Switch to testing focus"
- Loads: CONTEXT_TESTING.md, TODO.md (testing sections)
- Unloads: Other session contexts
- Focus: Test failures, debugging, test coverage

# Load Development Context  
"Load development context" or "Switch to feature development"
- Loads: CONTEXT.md, TODO.md (feature sections)
- Unloads: Testing context
- Focus: New features, bug fixes, implementation

# Load Architecture Context
"Load architecture context" or "Deep architecture review"
- Loads: ARCHITECTURE_CONTEXT.md
- Unloads: Session contexts
- Focus: Architecture decisions, pattern validation

# Load Historical Context
"Load historical context" or "Review conversation history"
- Loads: CONVERSATION_SUMMARY.txt
- Unloads: Current session contexts
- Focus: Understanding previous decisions, avoiding repeated mistakes

# Unload Context
"Unload [context name]" or "Drop [context] from memory"
- Removes specific context from memory
- Frees up memory for other contexts
- Example: "Unload testing context"
```

#### Context-Specific Focus Areas

##### Testing Context
```markdown
# Testing Focus Commands
"Focus on test failures" - Load CONTEXT_TESTING.md
"Debug test issues" - Load test-specific sections
"Review test coverage" - Load coverage analysis
"Fix failing tests" - Load test failure details
```

##### Development Context
```markdown
# Development Focus Commands
"Focus on feature implementation" - Load CONTEXT.md
"Work on bug fixes" - Load bug-specific sections
"Implement new feature" - Load feature requirements
"Review code quality" - Load architecture patterns
```

##### Architecture Context
```markdown
# Architecture Focus Commands
"Review architecture patterns" - Load ARCHITECTURE_CONTEXT.md
"Validate design decisions" - Load architecture validation
"Check for anti-patterns" - Load anti-pattern documentation
"Plan new feature architecture" - Load design patterns
```

### Memory Management Benefits

#### 1. **Reduced Memory Usage**
- Only load relevant context for current task
- Free memory when switching focus areas
- Prevent context overflow

#### 2. **Improved Focus**
- Clear separation of concerns
- Reduced cognitive load
- Better task-specific responses

#### 3. **Faster Response Times**
- Less context to process
- More relevant information
- Streamlined decision making

#### 4. **Better Context Switching**
- Clear commands for context changes
- Explicit memory management
- Predictable behavior

### Implementation Strategy

#### For Current Session
```markdown
# Current Focus: 50/50 Safe Move Implementation
- Loaded: CONTEXT.md (general), TODO.md (50/50 section)
- Unloaded: CONTEXT_TESTING.md (not needed for implementation)
- Memory: Optimized for feature development
```

#### For Testing Session
```markdown
# Current Focus: Test Debugging
- Loaded: CONTEXT_TESTING.md, TODO.md (testing section)
- Unloaded: CONTEXT.md (implementation details)
- Memory: Optimized for test analysis
```

#### For Architecture Review
```markdown
# Current Focus: Architecture Validation
- Loaded: ARCHITECTURE_CONTEXT.md
- Unloaded: Session contexts
- Memory: Optimized for pattern analysis
```

### Context Loading Patterns

#### Pattern 1: Task-Specific Loading
```markdown
User: "Fix the 50/50 safe move bug"
Agent: Loads development context, focuses on implementation
User: "Now run the tests"
Agent: Unloads development context, loads testing context
```

#### Pattern 2: Deep Dive Loading
```markdown
User: "Why did the 50/50 implementation fail?"
Agent: Loads architecture context, analyzes patterns
User: "Let's implement it properly"
Agent: Unloads architecture context, loads development context
```

#### Pattern 3: Context Switching
```markdown
User: "I'm done with testing, let's work on features"
Agent: "Unloading testing context, loading development context"
User: "Actually, let me review the architecture first"
Agent: "Unloading development context, loading architecture context"
```

### Best Practices

#### 1. **Explicit Context Management**
- Always state what context is being loaded/unloaded
- Confirm context switches with user
- Provide clear focus areas

#### 2. **Memory Optimization**
- Unload contexts when switching focus
- Load only necessary sections
- Clear memory when tasks are complete

#### 3. **Context Validation**
- Verify loaded context is relevant to current task
- Check for conflicting information
- Ensure architecture compliance

#### 4. **User Communication**
- Explain context changes clearly
- Provide reasoning for context switches
- Confirm user intent before switching

### Example Context Switch

```markdown
User: "I want to work on implementing the undo feature"

Agent: "Switching to development context...
- Loading: CONTEXT.md (feature implementation patterns)
- Loading: TODO.md (undo feature requirements)  
- Unloading: CONTEXT_TESTING.md (not needed for implementation)
- Memory: Optimized for feature development

Ready to work on undo feature implementation. I'll check the repository interface first to ensure we follow the established patterns."
```

This context management strategy ensures efficient memory usage while maintaining focus on current tasks. 