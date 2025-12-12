# Data Flows Analysis

## 1. State Management

### 1.1 State Containers

| State | Location | Type | Scope | Persistence |
|-------|----------|------|-------|-------------|

### 1.2 State Updates

| State | Updated By | Trigger | Side Effects |
|-------|------------|---------|--------------|

**State Summary**:

---

## 2. Component Communication

### 2.1 Data Passing

| From | To | Mechanism | Data |
|------|-----|-----------|------|

### 2.2 Event/Callback Flow

| Event | Source | Handler | Effect |
|-------|--------|---------|--------|

### 2.3 Shared State Access

| State | Consumers | Access Pattern |
|-------|-----------|----------------|

---

## 3. Data Transformations

### 3.1 Validation

| Input | Validator | Location | Rules | On Failure |
|-------|-----------|----------|-------|------------|

### 3.2 Parsing

| Source Format | Target Format | Parser | Location |
|---------------|---------------|--------|----------|

### 3.3 Formatting

| Data | Formatter | Output Format | Purpose |
|------|-----------|---------------|---------|

### 3.4 Enrichment

| Data | Enrichment | Source | Location |
|------|------------|--------|----------|

---

## 4. Data Sources & Sinks

### 4.1 Entry Points

| Entry Point | Data Type | Source | First Handler |
|-------------|-----------|--------|---------------|

### 4.2 Exit Points

| Exit Point | Data Type | Destination | Final Handler |
|------------|-----------|-------------|---------------|

### 4.3 Storage Points

| Storage | Type | Read By | Written By |
|---------|------|---------|------------|

---

## 5. Complete Flow Examples

### Flow: [Name]

```
[Step-by-step ASCII flow diagram]
```

**Description**:

**Data at each step**:
1.
2.
3.

---

## Summary

### Flow Patterns

| Pattern | Usage | Locations |
|---------|-------|-----------|

### Data Lifecycle

| Data Type | Created | Transformed | Stored | Consumed | Destroyed |
|-----------|---------|-------------|--------|----------|-----------|

### Bottlenecks & Concerns

| Location | Issue | Impact | Recommendation |
|----------|-------|--------|----------------|
