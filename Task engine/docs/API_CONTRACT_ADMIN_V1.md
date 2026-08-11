# Admin API Contract v1.0

## Base URL
```
http://localhost:3000/api/v1/admin
```

## Authentication
All endpoints require JWT token in Authorization header:
```
Authorization: Bearer <access_token>
```

## Response Format
```typescript
{
  success: boolean;
  data?: T;
  message?: string;
  statusCode: number;
  meta?: {
    page?: number;
    pageSize?: number;
    total?: number;
    totalPages?: number;
  };
}
```

## Error Response
```typescript
{
  success: false;
  message: string;
  statusCode: number;
  error?: string;
}
```

---

## 1. Authentication

### POST /auth/login
Admin login
```typescript
Request:
{
  email: string;
  password: string;
}

Response:
{
  success: true;
  data: {
    access_token: string;
    refresh_token: string;
    user: {
      id: string;
      email: string;
      name: string;
      role: 'SUPER_ADMIN' | 'ADMIN' | 'OPERATIONS' | 'FINANCE' | 'KYC_REVIEWER' | 'SUPPORT';
      is_active: boolean;
      created_at: string;
      last_login_at: string | null;
    }
  }
}
```

### POST /auth/logout
```typescript
Response: { success: true }
```

### GET /auth/profile
```typescript
Response: { success: true, data: AdminUser }
```

### POST /auth/refresh
```typescript
Request: { refresh_token: string }
Response: { success: true, data: { access_token: string } }
```

---

## 2. Dashboard

### GET /dashboard/stats
Platform overview statistics
```typescript
Response:
{
  success: true;
  data: {
    total_buyers: number;
    active_buyers: number;
    total_workers: number;
    active_workers: number;
    today_revenue: number;
    worker_earnings: number;
    platform_margin: number;
    pending_payout: number;
    active_campaigns: number;
    active_tasks: number;
    pending_review: number;
    allocation_pending: number;
  }
}
```

### GET /dashboard/alerts
Platform alerts
```typescript
Response:
{
  success: true;
  data: Array<{
    id: string;
    type: 'KYC_PENDING' | 'TASK_ALLOCATION' | 'LOW_WORKER' | 'PAYMENT_FAILED';
    title: string;
    message: string;
    count: number;
    priority: 'HIGH' | 'MEDIUM' | 'LOW';
    action_url?: string;
    created_at: string;
  }>
}
```

### GET /dashboard/activity
Recent activity feed
```typescript
Query: ?page=1&pageSize=20

Response:
{
  success: true;
  data: Array<{
    id: string;
    type: 'TASK_APPROVED' | 'ORDER_CREATED' | 'WORKER_REGISTERED' | 'PAYOUT_PROCESSED';
    title: string;
    description: string;
    entity_type: 'task' | 'order' | 'worker' | 'payout';
    entity_id: string;
    created_at: string;
  }>,
  meta: PaginationMeta
}
```

---

## 3. Workers Management

### GET /workers
List all workers with filters
```typescript
Query:
?page=1
&pageSize=20
&status=ACTIVE|INACTIVE|SUSPENDED|BANNED
&kyc_status=PENDING|VERIFIED|REJECTED
&search=<name|email|phone>
&sort_by=created_at|quality_score|rating
&sort_order=asc|desc

Response:
{
  success: true;
  data: Array<{
    id: string;
    name: string;
    email: string;
    phone: string;
    status: UserStatus;
    kyc_status: KycStatus;
    quality_score: number;
    completion_rate: number;
    rating: number;
    total_tasks: number;
    completed_tasks: number;
    total_earnings: number;
    created_at: string;
    last_active_at: string | null;
  }>,
  meta: PaginationMeta
}
```

### GET /workers/:id
Worker detail
```typescript
Response:
{
  success: true;
  data: {
    id: string;
    name: string;
    email: string;
    phone: string;
    status: UserStatus;
    kyc_status: KycStatus;
    
    // Scores
    quality_score: number;
    reliability_score: number;
    completion_rate: number;
    rating: number;
    experience_score: number;
    
    // Stats
    total_tasks: number;
    completed_tasks: number;
    rejected_tasks: number;
    timeout_tasks: number;
    total_earnings: number;
    pending_earnings: number;
    
    // Recent activity
    last_active_at: string | null;
    last_task_at: string | null;
    created_at: string;
    updated_at: string;
  }
}
```

### GET /workers/:id/score-breakdown
Worker score calculation details
```typescript
Response:
{
  success: true;
  data: {
    worker_id: string;
    quality_score: { value: number; weight: number; contribution: number };
    reliability_score: { value: number; weight: number; contribution: number };
    completion_rate: { value: number; weight: number; contribution: number };
    rating: { value: number; weight: number; contribution: number };
    experience_score: { value: number; weight: number; contribution: number };
    final_score: number;
    rank: number;
    percentile: number;
    last_calculated_at: string;
  }
}
```

### GET /workers/:id/tasks
Worker task history
```typescript
Query: ?page=1&pageSize=20&status=<TaskStatus>

Response:
{
  success: true;
  data: Array<{
    id: string;
    campaign_id: string;
    campaign_name: string;
    service_name: string;
    status: TaskStatus;
    reward_amount: number;
    assigned_at: string;
    accepted_at: string | null;
    submitted_at: string | null;
    completed_at: string | null;
    deadline: string;
  }>,
  meta: PaginationMeta
}
```

### GET /workers/:id/earnings
Worker earnings history
```typescript
Query: ?page=1&pageSize=20&status=PENDING|APPROVED|PAID

Response:
{
  success: true;
  data: Array<{
    id: string;
    task_id: string;
    campaign_name: string;
    amount: number;
    status: 'PENDING' | 'APPROVED' | 'PAID';
    earned_at: string;
    paid_at: string | null;
  }>,
  meta: PaginationMeta
}
```

### GET /workers/:id/kyc
Worker KYC details
```typescript
Response:
{
  success: true;
  data: {
    id: string;
    worker_id: string;
    status: KycStatus;
    documents: Array<{
      type: 'AADHAAR' | 'PAN' | 'GOVERNMENT_ID';
      file_url: string;
      verified: boolean;
    }>;
    submitted_at: string | null;
    verified_at: string | null;
    verified_by: string | null;
    rejection_reason: string | null;
  }
}
```

### PUT /workers/:id/suspend
Suspend worker
```typescript
Request: { reason: string }
Response: { success: true }
```

### PUT /workers/:id/ban
Ban worker
```typescript
Request: { reason: string; permanent: boolean }
Response: { success: true }
```

### PUT /workers/:id/activate
Activate suspended/banned worker
```typescript
Response: { success: true }
```

---

## 4. Buyers Management

### GET /buyers
List all buyers
```typescript
Query:
?page=1
&pageSize=20
&status=ACTIVE|INACTIVE|SUSPENDED
&type=REGULAR|API_ENABLED
&search=<name|email>

Response:
{
  success: true;
  data: Array<{
    id: string;
    company_name: string;
    email: string;
    phone: string;
    status: UserStatus;
    is_api_enabled: boolean;
    balance: number;
    reserved_balance: number;
    total_orders: number;
    active_orders: number;
    created_at: string;
  }>,
  meta: PaginationMeta
}
```

### GET /buyers/:id
Buyer detail
```typescript
Response:
{
  success: true;
  data: {
    id: string;
    company_name: string;
    email: string;
    phone: string;
    status: UserStatus;
    is_api_enabled: boolean;
    
    // Balance
    balance: number;
    reserved_balance: number;
    available_balance: number;
    
    // Stats
    total_orders: number;
    active_orders: number;
    completed_orders: number;
    cancelled_orders: number;
    total_spent: number;
    
    // Dates
    created_at: string;
    last_order_at: string | null;
  }
}
```

### GET /buyers/:id/balance-ledger
Buyer balance transaction history
```typescript
Query: ?page=1&pageSize=20

Response:
{
  success: true;
  data: Array<{
    id: string;
    type: 'CREDIT' | 'DEBIT' | 'RESERVE' | 'RELEASE' | 'REFUND';
    amount: number;
    balance_before: number;
    balance_after: number;
    reference_type: 'payment' | 'order' | 'refund' | 'adjustment';
    reference_id: string | null;
    description: string;
    created_at: string;
  }>,
  meta: PaginationMeta
}
```

### GET /buyers/:id/orders
Buyer orders
```typescript
Query: ?page=1&pageSize=20&status=<OrderStatus>

Response:
{
  success: true;
  data: Array<Order>,
  meta: PaginationMeta
}
```

### GET /buyers/:id/api-keys
Buyer API keys (if API enabled)
```typescript
Response:
{
  success: true;
  data: Array<{
    id: string;
    name: string;
    key_prefix: string;
    environment: 'PRODUCTION' | 'SANDBOX';
    scopes: string[];
    is_active: boolean;
    last_used_at: string | null;
    created_at: string;
    expires_at: string | null;
  }>
}
```

### POST /buyers/:id/api-keys
Create API key
```typescript
Request:
{
  name: string;
  environment: 'PRODUCTION' | 'SANDBOX';
  scopes: string[];
  expires_in_days?: number;
}

Response:
{
  success: true;
  data: {
    id: string;
    api_key: string; // Only returned once
    api_secret: string; // Only returned once
  }
}
```

### DELETE /buyers/:id/api-keys/:keyId
Revoke API key
```typescript
Response: { success: true }
```

### GET /buyers/:id/webhooks
Buyer webhooks
```typescript
Response:
{
  success: true;
  data: Array<{
    id: string;
    url: string;
    events: string[];
    is_active: boolean;
    secret: string;
    success_count: number;
    failure_count: number;
    last_triggered_at: string | null;
    created_at: string;
  }>
}
```

### POST /buyers/:id/balance/adjust
Admin balance adjustment
```typescript
Request:
{
  amount: number; // positive for credit, negative for debit
  type: 'CREDIT' | 'DEBIT';
  reason: string;
  reference?: string;
}

Response: { success: true }
```

---

## 5. Orders / Campaigns Management

### GET /orders
List all orders
```typescript
Query:
?page=1
&pageSize=20
&status=DRAFT|PAYMENT_PENDING|ACTIVE|PAUSED|COMPLETED|CANCELLED
&buyer_id=<buyerId>
&search=<campaign_name>

Response:
{
  success: true;
  data: Array<{
    id: string;
    campaign_id: string;
    buyer_id: string;
    buyer_name: string;
    service_id: string;
    service_name: string;
    status: OrderStatus;
    
    // Tasks
    total_tasks: number;
    completed_tasks: number;
    in_progress_tasks: number;
    pending_tasks: number;
    
    // Financial
    total_amount: number;
    buyer_price_per_task: number;
    worker_reward_per_task: number;
    margin_per_task: number;
    
    // Dates
    created_at: string;
    deadline: string;
    completed_at: string | null;
  }>,
  meta: PaginationMeta
}
```

### GET /orders/:id
Order detail
```typescript
Response:
{
  success: true;
  data: {
    id: string;
    campaign_id: string;
    buyer_id: string;
    buyer_name: string;
    service_id: string;
    service_name: string;
    status: OrderStatus;
    
    // Configuration
    task_instructions: string;
    proof_requirements: string[];
    total_tasks: number;
    max_tasks_per_worker: number;
    
    // Progress
    completed_tasks: number;
    in_progress_tasks: number;
    pending_tasks: number;
    rejected_tasks: number;
    timeout_tasks: number;
    
    // Financial
    total_amount: number;
    buyer_price_per_task: number;
    worker_reward_per_task: number;
    margin_per_task: number;
    platform_earnings: number;
    worker_payouts: number;
    
    // Dates
    created_at: string;
    started_at: string | null;
    deadline: string;
    extended_deadline: string | null;
    extension_count: number;
    completed_at: string | null;
  }
}
```

### GET /orders/:id/tasks
Order tasks with assignments
```typescript
Query: ?page=1&pageSize=20&status=<TaskStatus>

Response:
{
  success: true;
  data: Array<{
    id: string;
    task_number: number;
    status: TaskStatus;
    worker_id: string | null;
    worker_name: string | null;
    assigned_at: string | null;
    submitted_at: string | null;
    completed_at: string | null;
    deadline: string;
    reward_amount: number;
  }>,
  meta: PaginationMeta
}
```

### GET /orders/:id/progress
Order progress tracking
```typescript
Response:
{
  success: true;
  data: {
    order_id: string;
    total_tasks: number;
    completion_percentage: number;
    
    // Status breakdown
    completed: number;
    in_progress: number;
    pending: number;
    under_review: number;
    rejected: number;
    timeout: number;
    
    // Worker stats
    total_workers_assigned: number;
    active_workers: number;
    
    // Timeline
    estimated_completion: string;
    actual_completion: string | null;
    
    // Extensions
    original_deadline: string;
    current_deadline: string;
    extension_count: number;
  }
}
```

### POST /orders/:id/extend
Extend order deadline
```typescript
Request:
{
  hours: number;
  reason: string;
}

Response:
{
  success: true;
  data: {
    new_deadline: string;
    extension_count: number;
  }
}
```

### PUT /orders/:id/pause
Pause order
```typescript
Request: { reason: string }
Response: { success: true }
```

### PUT /orders/:id/resume
Resume paused order
```typescript
Response: { success: true }
```

### PUT /orders/:id/cancel
Cancel order
```typescript
Request: { reason: string; refund: boolean }
Response: { success: true }
```

---

## 6. Services & Pricing Management

### GET /services
List all services
```typescript
Query: ?status=ACTIVE|INACTIVE|ARCHIVED

Response:
{
  success: true;
  data: Array<{
    id: string;
    name: string;
    code: string;
    description: string;
    status: ServiceStatus;
    
    // Current pricing
    buyer_price: number;
    margin_type: 'FIXED' | 'PERCENTAGE';
    margin_value: number;
    worker_reward: number;
    
    // Stats
    total_orders: number;
    active_orders: number;
    
    created_at: string;
    updated_at: string;
  }>
}
```

### GET /services/:id
Service detail
```typescript
Response:
{
  success: true;
  data: {
    id: string;
    name: string;
    code: string;
    description: string;
    instructions: string;
    proof_requirements: string[];
    status: ServiceStatus;
    
    // Current pricing
    buyer_price: number;
    margin_type: 'FIXED' | 'PERCENTAGE';
    margin_value: number;
    worker_reward: number;
    
    // Metadata
    category: string;
    estimated_time_minutes: number;
    
    created_at: string;
    updated_at: string;
  }
}
```

### POST /services
Create service
```typescript
Request:
{
  name: string;
  code: string;
  description: string;
  instructions: string;
  proof_requirements: string[];
  category: string;
  estimated_time_minutes: number;
  
  // Pricing
  buyer_price: number;
  margin_type: 'FIXED' | 'PERCENTAGE';
  margin_value: number;
}

Response:
{
  success: true;
  data: {
    id: string;
    worker_reward: number; // Auto-calculated
  }
}
```

### PUT /services/:id
Update service
```typescript
Request: Same as POST
Response: { success: true }
```

### GET /services/:id/pricing-history
Service pricing versions
```typescript
Response:
{
  success: true;
  data: Array<{
    id: string;
    version: number;
    buyer_price: number;
    margin_type: 'FIXED' | 'PERCENTAGE';
    margin_value: number;
    worker_reward: number;
    effective_from: string;
    effective_to: string | null;
    created_by: string;
    created_at: string;
  }>
}
```

### PUT /services/:id/activate
Activate service
```typescript
Response: { success: true }
```

### PUT /services/:id/deactivate
Deactivate service
```typescript
Request: { reason: string }
Response: { success: true }
```

---

## 7. Matching Engine / Brain

### GET /matching/config
Current matching configuration
```typescript
Response:
{
  success: true;
  data: {
    version: number;
    weights: {
      quality_score: number;
      reliability_score: number;
      completion_rate: number;
      rating: number;
      experience_score: number;
    },
    filters: {
      min_quality_score: number;
      min_completion_rate: number;
      min_rating: number;
      kyc_required: boolean;
    },
    allocation_strategy: 'ROUND_ROBIN' | 'HIGHEST_SCORE' | 'BALANCED';
    active: boolean;
    effective_from: string;
    created_by: string;
    created_at: string;
  }
}
```

### POST /matching/config
Update matching configuration
```typescript
Request:
{
  weights: {
    quality_score: number; // 0-100, total should be 100
    reliability_score: number;
    completion_rate: number;
    rating: number;
    experience_score: number;
  };
  filters?: {
    min_quality_score?: number;
    min_completion_rate?: number;
    min_rating?: number;
    kyc_required?: boolean;
  };
  allocation_strategy?: 'ROUND_ROBIN' | 'HIGHEST_SCORE' | 'BALANCED';
}

Response:
{
  success: true;
  data: {
    version: number;
    config: MatchingConfig;
  }
}
```

### GET /matching/config/history
Matching config version history
```typescript
Response:
{
  success: true;
  data: Array<{
    version: number;
    weights: WeightConfig;
    effective_from: string;
    effective_to: string | null;
    created_by: string;
  }>
}
```

### POST /matching/preview
Preview matching for a task
```typescript
Request:
{
  task_id?: string;
  service_id?: string;
  campaign_id?: string;
}

Response:
{
  success: true;
  data: {
    candidates: Array<{
      worker_id: string;
      worker_name: string;
      final_score: number;
      rank: number;
      
      // Score breakdown
      quality_score: number;
      reliability_score: number;
      completion_rate: number;
      rating: number;
      experience_score: number;
      
      // Contribution
      quality_contribution: number;
      reliability_contribution: number;
      completion_contribution: number;
      rating_contribution: number;
      experience_contribution: number;
      
      // Status
      eligible: boolean;
      rejection_reasons: string[];
    }>;
    total_candidates: number;
    eligible_candidates: number;
  }
}
```

### GET /matching/decisions/:taskId
Why specific worker was selected/rejected
```typescript
Response:
{
  success: true;
  data: {
    task_id: string;
    selected_worker_id: string | null;
    decision_made_at: string;
    
    // Selected worker details
    selected_worker?: {
      id: string;
      name: string;
      final_score: number;
      rank: number;
      reasons: string[];
    };
    
    // All candidates
    candidates: Array<{
      worker_id: string;
      worker_name: string;
      final_score: number;
      rank: number;
      selected: boolean;
      rejected: boolean;
      rejection_reasons: string[];
    }>;
    
    // Filters applied
    filters_applied: string[];
    
    // Config used
    config_version: number;
  }
}
```

---

## 8. Reviews Management

### GET /reviews
Review queue
```typescript
Query:
?page=1
&pageSize=20
&status=PENDING|APPROVED|REJECTED
&campaign_id=<campaignId>

Response:
{
  success: true;
  data: Array<{
    id: string;
    task_id: string;
    worker_id: string;
    worker_name: string;
    campaign_id: string;
    campaign_name: string;
    service_name: string;
    status: ReviewStatus;
    
    // Submission
    submitted_at: string;
    proof_files: Array<{
      id: string;
      type: 'IMAGE' | 'VIDEO' | 'DOCUMENT';
      url: string;
    }>;
    proof_text: string | null;
    
    // Review
    reviewed_at: string | null;
    reviewed_by: string | null;
    review_comment: string | null;
  }>,
  meta: PaginationMeta
}
```

### GET /reviews/:id
Review detail
```typescript
Response:
{
  success: true;
  data: {
    id: string;
    task_id: string;
    task_instructions: string;
    proof_requirements: string[];
    
    // Worker
    worker_id: string;
    worker_name: string;
    worker_quality_score: number;
    worker_rating: number;
    
    // Campaign
    campaign_id: string;
    campaign_name: string;
    service_name: string;
    
    // Submission
    submitted_at: string;
    proof_files: FileDetail[];
    proof_text: string | null;
    
    // Status
    status: ReviewStatus;
    reviewed_at: string | null;
    reviewed_by: string | null;
    review_comment: string | null;
    rejection_reason: string | null;
  }
}
```

### POST /reviews/:id/approve
Approve submission
```typescript
Request: { comment?: string }
Response: { success: true }
```

### POST /reviews/:id/reject
Reject submission
```typescript
Request:
{
  reason: 'INVALID_PROOF' | 'LOW_QUALITY' | 'MISSING_DATA' | 'WRONG_TASK' | 'DUPLICATE' | 'OTHER';
  comment: string;
}

Response: { success: true }
```

### POST /reviews/:id/request-changes
Request changes
```typescript
Request: { comment: string; requirements: string[] }
Response: { success: true }
```

---

## 9. KYC Management

### GET /kyc
KYC queue
```typescript
Query: ?status=PENDING|VERIFIED|REJECTED&page=1&pageSize=20

Response:
{
  success: true;
  data: Array<{
    id: string;
    worker_id: string;
    worker_name: string;
    status: KycStatus;
    documents_count: number;
    submitted_at: string | null;
    reviewed_at: string | null;
  }>,
  meta: PaginationMeta
}
```

### GET /kyc/:id
KYC detail
```typescript
Response:
{
  success: true;
  data: {
    id: string;
    worker_id: string;
    worker_name: string;
    worker_email: string;
    worker_phone: string;
    status: KycStatus;
    
    documents: Array<{
      id: string;
      type: 'AADHAAR' | 'PAN' | 'GOVERNMENT_ID';
      number: string;
      file_url: string;
      verified: boolean;
    }>;
    
    submitted_at: string | null;
    verified_at: string | null;
    verified_by: string | null;
    rejection_reason: string | null;
  }
}
```

### POST /kyc/:id/verify
Verify KYC
```typescript
Response: { success: true }
```

### POST /kyc/:id/reject
Reject KYC
```typescript
Request: { reason: string; documents_to_resubmit: string[] }
Response: { success: true }
```

---

## 10. Payouts Management

### GET /payouts
Payout queue
```typescript
Query: ?status=PENDING|PROCESSING|PAID|REJECTED&page=1&pageSize=20

Response:
{
  success: true;
  data: Array<{
    id: string;
    worker_id: string;
    worker_name: string;
    amount: number;
    status: PayoutStatus;
    payment_method: 'UPI' | 'BANK_TRANSFER';
    requested_at: string;
    processed_at: string | null;
  }>,
  meta: PaginationMeta
}
```

### GET /payouts/:id
Payout detail
```typescript
Response:
{
  success: true;
  data: {
    id: string;
    worker_id: string;
    worker_name: string;
    amount: number;
    status: PayoutStatus;
    
    // Payment method
    payment_method: 'UPI' | 'BANK_TRANSFER';
    payment_details: {
      upi_id?: string;
      account_number?: string;
      ifsc_code?: string;
      account_holder_name?: string;
    };
    
    // Processing
    requested_at: string;
    processed_at: string | null;
    processed_by: string | null;
    transaction_reference: string | null;
    rejection_reason: string | null;
    
    // Earnings breakdown
    earnings_included: number;
    deductions: number;
    final_amount: number;
  }
}
```

### POST /payouts/:id/process
Process payout
```typescript
Request:
{
  transaction_reference: string;
  notes?: string;
}

Response: { success: true }
```

### POST /payouts/:id/reject
Reject payout
```typescript
Request: { reason: string }
Response: { success: true }
```

---

## 11. Analytics

### GET /analytics/overview
Platform analytics overview
```typescript
Query: ?start_date=<YYYY-MM-DD>&end_date=<YYYY-MM-DD>

Response:
{
  success: true;
  data: {
    period: { start: string; end: string };
    
    // Users
    new_buyers: number;
    new_workers: number;
    active_users: number;
    
    // Orders
    orders_created: number;
    orders_completed: number;
    orders_cancelled: number;
    
    // Tasks
    tasks_assigned: number;
    tasks_completed: number;
    tasks_rejected: number;
    
    // Financial
    gmv: number;
    worker_payouts: number;
    platform_margin: number;
    refunds: number;
  }
}
```

### GET /analytics/revenue
Revenue analytics
```typescript
Query: ?start_date=<YYYY-MM-DD>&end_date=<YYYY-MM-DD>&group_by=day|week|month

Response:
{
  success: true;
  data: {
    timeline: Array<{
      date: string;
      gmv: number;
      worker_payouts: number;
      platform_margin: number;
      margin_percentage: number;
    }>;
    totals: {
      gmv: number;
      worker_payouts: number;
      platform_margin: number;
      average_margin_percentage: number;
    };
  }
}
```

### GET /analytics/tasks
Task analytics
```typescript
Query: ?start_date=<YYYY-MM-DD>&end_date=<YYYY-MM-DD>&group_by=day|week|month

Response:
{
  success: true;
  data: {
    timeline: Array<{
      date: string;
      assigned: number;
      completed: number;
      rejected: number;
      timeout: number;
      completion_rate: number;
    }>;
    totals: {
      assigned: number;
      completed: number;
      rejected: number;
      timeout: number;
      average_completion_rate: number;
    };
  }
}
```

---

## 12. Risk & Fraud

### GET /risk/dashboard
Risk dashboard overview
```typescript
Response:
{
  success: true;
  data: {
    high_risk_workers: number;
    suspicious_activities: number;
    fraud_attempts: number;
    
    recent_incidents: Array<{
      id: string;
      type: 'HIGH_REJECTION' | 'MULTIPLE_TIMEOUT' | 'DUPLICATE_PROOF' | 'UNUSUAL_ACTIVITY';
      worker_id: string;
      worker_name: string;
      risk_score: number;
      detected_at: string;
    }>;
  }
}
```

### GET /risk/workers
High-risk workers
```typescript
Response:
{
  success: true;
  data: Array<{
    worker_id: string;
    worker_name: string;
    risk_level: RiskLevel;
    risk_score: number;
    
    reasons: Array<{
      type: string;
      description: string;
      severity: 'HIGH' | 'MEDIUM' | 'LOW';
    }>;
    
    stats: {
      rejection_rate: number;
      timeout_rate: number;
      duplicate_submissions: number;
    };
    
    last_incident_at: string;
  }>
}
```

---

## 13. System Settings

### GET /settings
Get system settings
```typescript
Response:
{
  success: true;
  data: {
    // Withdrawal
    minimum_withdrawal_amount: number;
    
    // Task timeouts
    task_accept_timeout_hours: number;
    task_complete_timeout_hours: number;
    
    // Campaign
    campaign_auto_extension_hours: number;
    maximum_extensions: number | null;
    
    // Worker limits
    worker_max_concurrent_tasks: number;
    
    // Review
    review_timeout_hours: number;
    
    updated_at: string;
    updated_by: string;
  }
}
```

### PUT /settings
Update system settings
```typescript
Request: Partial<SystemSettings>
Response: { success: true }
```

---

## 14. Audit Logs

### GET /audit-logs
Audit trail
```typescript
Query:
?page=1
&pageSize=20
&admin_id=<adminId>
&action=<action>
&entity_type=<entityType>
&start_date=<YYYY-MM-DD>
&end_date=<YYYY-MM-DD>

Response:
{
  success: true;
  data: Array<{
    id: string;
    admin_id: string;
    admin_name: string;
    action: string;
    entity_type: string;
    entity_id: string;
    old_values: object | null;
    new_values: object | null;
    ip_address: string;
    user_agent: string;
    created_at: string;
  }>,
  meta: PaginationMeta
}
```

---

## 15. Notifications

### GET /notifications
Admin notifications
```typescript
Query: ?unread=true&page=1&pageSize=20

Response:
{
  success: true;
  data: Array<{
    id: string;
    type: string;
    title: string;
    message: string;
    data: object;
    read: boolean;
    created_at: string;
  }>,
  meta: PaginationMeta
}
```

### PUT /notifications/:id/read
Mark as read
```typescript
Response: { success: true }
```

---

## Error Codes

### 400 Bad Request
- `VALIDATION_ERROR` - Input validation failed
- `INVALID_PARAMETERS` - Invalid query parameters

### 401 Unauthorized
- `INVALID_TOKEN` - Token expired or invalid
- `TOKEN_REQUIRED` - No token provided

### 403 Forbidden
- `INSUFFICIENT_PERMISSIONS` - Role doesn't have access
- `RESOURCE_FORBIDDEN` - Cannot access this resource

### 404 Not Found
- `RESOURCE_NOT_FOUND` - Entity doesn't exist

### 409 Conflict
- `DUPLICATE_ENTRY` - Resource already exists
- `STATE_CONFLICT` - Invalid state transition

### 422 Unprocessable Entity
- `BUSINESS_RULE_VIOLATION` - Business logic error

### 500 Internal Server Error
- `SERVER_ERROR` - Unexpected server error

---

## Pagination

All list endpoints support pagination:
```typescript
Query: ?page=1&pageSize=20

Meta Response:
{
  page: number;
  pageSize: number;
  total: number;
  totalPages: number;
}
```

## Sorting

Sortable endpoints:
```typescript
Query: ?sort_by=<field>&sort_order=asc|desc
```

## Rate Limiting

- **Rate Limit**: 100 requests per minute per admin user
- **Headers**:
  - `X-RateLimit-Limit`: Maximum requests
  - `X-RateLimit-Remaining`: Remaining requests
  - `X-RateLimit-Reset`: Reset timestamp

---

## Changelog

### v1.0.0 (Initial Release)
- Complete Admin API surface
- All CRUD operations
- Dashboard analytics
- Matching engine config
- Service management
- SaaS features (API keys, webhooks)
- Financial operations
- Audit logging
