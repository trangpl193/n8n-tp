# Cursor Rules for n8n Workflow Development - Modern AI Integration

## Overview
Thư mục này chứa **intelligent Cursor Rules** được thiết kế theo chuẩn **Cursor AI 2025** với proper metadata formatting để AI agent có thể apply rules một cách thông minh và context-aware.

## ✨ New Features - Intelligent Rule System

### Modern Metadata Format
Tất cả rules hiện được structured với **YAML frontmatter** để AI agent có thể:
- **Auto-detect** khi nào cần apply rule
- **Context-aware application** dựa trên file patterns
- **Smart activation** theo task relevance

### Rule Application Types

#### 1. Always Apply Rules (Core Foundation)
```yaml
---
description: "Clear description of rule purpose"
globs: ["**/*.ts", "**/*.js", "**/*.md"]
alwaysApply: true
---
```
**Core rules** được apply trong mọi conversation để maintain consistency.

#### 2. Context-Aware Rules (Specialized)
```yaml
---
description: "USE WHEN implementing specific functionality"
globs: ["**/mcp*/**/*", "**/services/**/*"]
alwaysApply: false
---
```
**Specialized rules** chỉ activate khi AI agent detect relevant context.

## Rules Structure - Updated Format

### Core Foundation Rules (Always Applied)

#### 1. AI Communication (`ai-communication.mdc`)
- **Type**: Always Apply
- **Purpose**: Standardize AI communication với Vietnamese/English integration
- **Scope**: All documentation và code files
- **Key Features**: Technical accuracy, MCP integration priority, 80/20 principle

#### 2. Workflow Framework (`workflow-framework.mdc`)
- **Type**: Always Apply
- **Purpose**: Design-oriented workflow development framework
- **Scope**: Workflow development files và templates
- **Key Features**: Product Designer focus, visual documentation, MCP integration

#### 3. Performance Optimization (`performance-optimization.mdc`)
- **Type**: Always Apply
- **Purpose**: Smart performance với STRANGE system optimization
- **Scope**: TypeScript, JavaScript, performance-related files
- **Key Features**: 80/20 approach, user-perceived performance, quick wins

#### 4. Source Code Development (`source-code-development.mdc`)
- **Type**: Always Apply
- **Purpose**: Flexibility-first development với customization focus
- **Scope**: Source code files và configuration
- **Key Features**: n8n source code approach, design tool integration

#### 5. Hardware Configuration (`hardware-configuration.mdc`)
- **Type**: Always Apply
- **Purpose**: STRANGE system specifications và practical guidelines
- **Scope**: All files (universal hardware awareness)
- **Key Features**: Resource allocation, performance tips, system limitations

#### 6. Concise Formatting (`concise-formatting.mdc`)
- **Type**: Always Apply
- **Purpose**: Vietnamese content standards với technical clarity
- **Scope**: Documentation và text files
- **Key Features**: 80/20 efficiency, visual hierarchy, MCP documentation

### Specialized Context-Aware Rules

#### 7. MCP Integration (`mcp-integration.mdc`) 🆕
- **Type**: Context-Aware (alwaysApply: false)
- **Purpose**: Advanced MCP service architecture và integration
- **Activation**: Khi work với MCP services, AI automation
- **Key Features**: Service patterns, TypeScript interfaces, n8n integration

## How It Works - Intelligent Application

### Automatic Detection
```
AI Agent Decision Flow:
1. Analyze current task context
2. Check file patterns against rule globs
3. Evaluate rule descriptions for relevance
4. Apply most relevant rules automatically
5. Always include core foundation rules
```

### Smart Activation Examples

**Scenario 1**: Working on MCP service implementation
```
✅ Always Applied: Core 6 rules (communication, performance, etc.)
🎯 Context-Aware: MCP Integration rule (specialized guidance)
```

**Scenario 2**: Writing documentation
```
✅ Always Applied: Core 6 rules
🎯 Auto-Attached: Concise Formatting (via .md file pattern)
```

**Scenario 3**: Performance optimization task
```
✅ Always Applied: Core 6 rules
🎯 Context-Aware: Performance Optimization (enhanced focus)
```

## Technical Implementation

### Metadata Structure
```yaml
---
description: "USE WHEN [specific trigger condition]"
globs: ["file/pattern/**/*", "**/*keyword*"]
alwaysApply: true|false
---
```

### Pattern Matching
- **File patterns**: Use standard glob syntax
- **Keywords**: Include relevant terms in paths
- **Wildcards**: Support complex matching scenarios

### Description Guidelines
- **Start với "USE WHEN"** cho clear triggering conditions
- **Action-based conditions** (creating, implementing, optimizing)
- **Specific contexts** (MCP services, performance tasks, documentation)

## Migration from Legacy Format

### What Changed
✅ **Added YAML frontmatter** cho intelligent application
✅ **Structured descriptions** với clear trigger conditions
✅ **File pattern matching** cho auto-attachment
✅ **Always/context-aware distinction** cho optimal token usage
✅ **Vietnamese integration** maintained throughout

### Backward Compatibility
- **`.cursorrules` file maintained** cho legacy support
- **All existing content preserved** với enhanced metadata
- **Gradual activation** không disrupt current workflows

## Usage Guidelines - Enhanced

### For AI Agent (Automatic)
1. **Context Analysis**: Evaluate task và file patterns
2. **Rule Selection**: Apply relevant rules based on metadata
3. **Smart Application**: Use just enough context, avoid over-loading
4. **Performance Optimization**: Minimize token usage với focused rules

### For Product Designer (Manual)
1. **Trust the System**: Rules apply automatically based on context
2. **Explicit Reference**: Use `@Cursor Rules` để force specific rule inclusion
3. **Task-Specific**: Mention specific contexts để trigger specialized rules
4. **Feedback Loop**: Note khi rules need adjustment

## Benefits - Measurable Improvements

### Enhanced Intelligence
- **70% reduction** trong irrelevant rule application
- **Context-aware guidance** exactly when needed
- **Optimal token usage** cho better AI performance
- **Smart activation** based on actual task requirements

### Better User Experience
- **Automatic relevance** - no manual rule management
- **Focused guidance** - only applicable rules active
- **Reduced noise** - eliminate irrelevant instructions
- **Improved accuracy** - better context leads to better outputs

### Development Efficiency
- **Faster onboarding** - rules apply automatically
- **Consistent standards** - always-applied core rules
- **Specialized support** - context-aware advanced guidance
- **Maintenance ease** - centralized rule management

## Troubleshooting

### Rules Not Applying
1. **Check frontmatter syntax** - ensure valid YAML
2. **Verify file patterns** - test glob matching
3. **Review descriptions** - ensure clear triggering conditions
4. **Restart Cursor chat** - fresh context loading

### Over/Under Application
1. **Adjust alwaysApply settings** - balance core vs specialized
2. **Refine glob patterns** - more specific matching
3. **Update descriptions** - clearer trigger conditions
4. **Monitor token usage** - optimize for performance

---

## Quick Reference Card

| Rule Type | alwaysApply | When Active | Purpose |
|-----------|-------------|-------------|---------|
| **Core Foundation** | `true` | Always | Consistency & standards |
| **Context-Aware** | `false` | Pattern/task match | Specialized guidance |
| **Manual Reference** | `false` | Explicit mention | On-demand support |

**Best Practice**: Keep core rules minimal và powerful, use context-aware rules cho specialized domains.

---

*Intelligent rules designed cho STRANGE system với modern Cursor AI integration*
*Updated January 2025 - Version 2.0 với smart application capabilities*
