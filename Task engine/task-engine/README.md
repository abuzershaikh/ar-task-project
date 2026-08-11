# Task Engine

Enterprise-level Task Management System for crowdsourcing platform.

## Overview

Task Engine manages the complete lifecycle of tasks from creation to completion. It supports multiple task types (YouTube engagement, social media, surveys, etc.) with configurable workflows, validation rules, and state transitions.

## Architecture

### Core Components

1. **State Machine** - Manages task lifecycle and state transitions
2. **Command Services** - Handles all task operations
3. **Validation Engine** - Validates task data and transitions
4. **Deadline Manager** - Manages task expiry and timeouts
5. **Attempt Tracker** - Tracks worker attempts and retries

### Task Types Supported

- YouTube Tasks (Comments, Watch Time, Subscribers, Likes)
- Instagram Tasks (Followers, Likes, Comments)
- Twitter Tasks (Retweets, Likes, Follows)
- Survey Tasks
- Custom Tasks

## Task Lifecycle

```
DRAFT → ACTIVE → ASSIGNED → ACCEPTED → IN_PROGRESS → SUBMITTED → UNDER_REVIEW → APPROVED/REJECTED
```

## Features

- Multi-tenant task isolation
- Configurable validation rules per task type
- Automatic deadline management
- Retry and attempt tracking
- Event-driven architecture
- Idempotent operations
