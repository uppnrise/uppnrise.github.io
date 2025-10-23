---
layout: post
title: "The Hidden Complexity of Distributed Rate Limiting: Lessons from Building 5 Algorithms"
date: 2025-10-23 22:00:00 +0200
tags: [distributed-systems, redis, rate-limiting, microservices, java, algorithms, architecture]
excerpt: "Building a production-grade distributed rate limiter taught me that algorithm choice matters more than I expected. Here's what I learned implementing Token Bucket, Sliding Window, Fixed Window, Leaky Bucket, and a Composite approach."
---

# The Hidden Complexity of Distributed Rate Limiting: Lessons from Building 5 Algorithms

*Published on October 23, 2025*

I spent the last few months building a distributed rate limiter, and honestly, I underestimated how nuanced this problem is. What started as "just implement token bucket with Redis" turned into a deep dive into algorithm trade-offs, Redis optimization, and some interesting architectural decisions I'd love your feedback on.

## The Problem That Started It All

Like many of you, I needed rate limiting across multiple service instances. The typical in-memory solutions don't work when you have 5 instances behind a load balancer - suddenly your 100 req/min limit becomes 500 req/min. 

My first thought: "Just use Redis!" Turns out, that's where the real complexity begins.

## Algorithm #1: Token Bucket - The Obvious Choice (Until It Wasn't)

Token bucket is everyone's first choice, right? Tokens refill at a constant rate, requests consume tokens, simple math. 

Here's where it got interesting: **When do you refill?**

**Naive approach** (what I tried first):
```java
// Check on every request - seemed elegant
currentTokens = min(capacity, lastTokens + (now - lastRefill) * refillRate)
```

**Problem**: Race conditions everywhere. Two requests at the exact same millisecond? You're in trouble.

**Solution**: Lua scripts in Redis for atomic operations. But here's the catch - Lua scripts have a size limit, and complex refill logic bloats quickly.

```lua
-- This runs atomically in Redis
local tokens = redis.call('HGET', KEYS[1], 'tokens')
local last_refill = redis.call('HGET', KEYS[1], 'lastRefill')
-- ... refill calculation ...
redis.call('HSET', KEYS[1], 'tokens', new_tokens)
```

**Question for the community**: Is there a better pattern than Lua scripts for distributed atomic operations? I looked at RedLock but it felt too heavy for this use case.

## Algorithm #2: Sliding Window - The Precision Trade-off

Token bucket has a problem: boundary issues. Fire 100 requests at 11:59:59, then 100 more at 12:00:01, and you've "technically" stayed within limits but hammered the system with 200 requests in 2 seconds.

**Sliding window** fixes this by tracking requests in overlapping time windows. But the memory cost is brutal.

**The trade-off I faced**:
- **Store every request timestamp**: Accurate but O(n) memory per key
- **Fixed time buckets**: Memory efficient but brings back boundary issues
- **Hybrid approach**: Store request counts in sub-windows

I went with the hybrid - store counts in 10-second buckets, interpolate between them:

```java
// Simplified concept
double weight = (now - windowStart) / windowSize;
count = pastBucketCount * (1 - weight) + currentBucketCount * weight;
```

**Is this a good compromise?** I'm seeing ~5% error margin compared to true sliding window. Worth the 90% memory savings?

## Algorithm #3: Fixed Window - When "Good Enough" Actually Is

Fixed window is the simplest: reset counter every N seconds. Everyone hates it because of boundary issues, but hear me out...

**When it's actually perfect**:
- High-scale scenarios where you can tolerate boundary spikes
- Background job processing (who cares about exact timing?)
- Internal service-to-service limits

I implemented it in ~20 lines of code (vs 200+ for sliding window). The memory usage? Nearly zero - just one counter per key with TTL.

```lua
-- That's literally it
local count = redis.call('INCR', KEYS[1])
if count == 1 then
    redis.call('EXPIRE', KEYS[1], window_size)
end
return count
```

**Question**: Why do we over-engineer rate limiting for internal services? Fixed window + generous limits seems fine for 90% of internal use cases.

## Algorithm #4: Leaky Bucket - Traffic Shaping's Best Friend

Here's where I realized algorithm choice really matters. We had a service calling a legacy system that could only handle 10 requests/second - not 9, not 11, exactly 10.

Token bucket? Allows bursts. Sliding window? Still has variance. **Leaky bucket** processes requests at a constant rate, queuing the rest.

**The implementation challenge**: Simulating a queue in Redis without actual queue semantics.

```java
// Conceptually: when will the bucket leak enough for this request?
nextAvailableTime = max(now, lastLeakTime + (queueSize / leakRate))
if (nextAvailableTime - now) > maxWaitTime {
    reject();
}
```

**This is where I'd love opinions**: Should a rate limiter handle queuing at all? Or just accept/reject and let the client retry? I implemented both modes, but I'm not sure the queuing mode is worth the complexity.

## Algorithm #5: Composite - Because Reality Is Complicated

Real-world scenario that broke my elegant single-algorithm design:

*"We need to limit API calls to 1000/hour, BUT also limit bandwidth to 10MB/hour, AND ensure no single user exceeds 100 calls in any 5-minute window for compliance."*

One algorithm can't handle this. I needed to combine multiple algorithms.

**The architecture decision**: How do you combine rate limiters?

**Option 1: Sequential checks** (what I built first)
```java
if (!checkApiCallLimit()) return reject("API calls");
if (!checkBandwidthLimit()) return reject("Bandwidth");  
if (!checkComplianceLimit()) return reject("Compliance");
return allow();
```

Simple, but you're making 3 Redis calls. Latency stacks.

**Option 2: Parallel checks**
```java
CompletableFuture<Boolean> apiCheck = checkApiCallLimit();
CompletableFuture<Boolean> bandwidthCheck = checkBandwidthLimit();
CompletableFuture<Boolean> complianceCheck = checkComplianceLimit();

return apiCheck.get() && bandwidthCheck.get() && complianceCheck.get();
```

Better latency, but now you're consuming tokens from limits you might not even need to check. If API limit fails, why decrement bandwidth?

**Option 3: Smart short-circuit**
Check cheapest limits first (like fixed window), only proceed if they pass. But which order? Do you hardcode it? Make it configurable?

**I went with configurable combination logic**:
- `ALL_MUST_PASS`: AND logic, fail-fast
- `WEIGHTED_AVERAGE`: Each limit gets a score, combined threshold
- `HIERARCHICAL`: User limits before tenant limits before global
- `PRIORITY_BASED`: High-priority limits checked first

**Is this over-engineered?** Part of me thinks "just do AND and call it a day." But the flexibility has been useful in testing.

## The Redis Optimization Rabbit Hole

Let me share the performance journey, because this is where things got interesting.

**Initial naive implementation**: ~200 req/s per instance
**After optimizations**: 50,000+ req/s per instance

What changed?

### 1. Connection Pooling Drama

First mistake: Creating a new Redis connection per request. Rookie error, but the performance impact was insane.

```java
// Don't do this
Jedis jedis = new Jedis("localhost");
jedis.get(key);
jedis.close();  // Connection overhead killed us
```

Switched to Lettuce with proper pooling. But then...

**The connection pool sizing problem**: Too small = bottleneck. Too large = connection overhead. I landed on:
```properties
spring.data.redis.lettuce.pool.max-active=32
spring.data.redis.lettuce.pool.max-idle=8
```

**How did you arrive at these numbers?** Load testing. But I'm curious how others size their Redis pools.

### 2. Lua Script Optimization

My first Lua script was 150 lines. It was slow.

**Key optimization**: Pre-calculate as much as possible in Java, keep Lua minimal.

```lua
-- Before: Doing math in Lua
local refill_amount = (now - last_time) * rate / 1000

-- After: Pass pre-calculated value from Java
local refill_amount = ARGV[1]  -- Already calculated
```

Sounds obvious but cut latency by 40%.

### 3. The TTL Revelation

Memory leak alert: I wasn't setting TTLs on rate limit keys. After a week in production, Redis was using 10GB for ~100K active users.

**The insight**: Most rate limit keys are temporary. User stops hitting your API? That key should expire.

```lua
-- Always set expiry
redis.call('EXPIRE', KEYS[1], 3600)  -- 1 hour
```

This one change dropped memory usage by 95%. Sometimes the simple solutions are the best.

## Architectural Decisions I'm Still Questioning

### Decision 1: Fail-Open vs Fail-Closed

When Redis goes down (and it will), what do you do?

**Fail-Open** (what I chose): Allow all requests
```java
try {
    return checkRedisRateLimit(key);
} catch (RedisException e) {
    log.error("Redis down, failing open");
    return true;  // Allow request
}
```

**Reasoning**: Rate limiting is protective, not critical. Better to briefly over-serve than to have a Redis outage take down your entire API.

**But**: This can be abused. If someone knows your Redis is down, they can flood you.

**Alternative I considered**: In-memory fallback with local limits. Problem: Defeats the "distributed" part. With 5 instances, you 5x your limits again.

**What would you do?** I'm genuinely torn on this one.

### Decision 2: Synchronous vs Asynchronous Checks

Rate limit checks are in the hot path. Every microsecond matters.

**Synchronous** (current approach):
```java
if (!rateLimiter.isAllowed(request)) {
    return HTTP_429;
}
processRequest(request);
```

Clean, simple, blocks until decision is made.

**Asynchronous alternative**:
```java
CompletableFuture<Boolean> limitCheck = rateLimiter.isAllowedAsync(request);
// ... do other work ...
if (!limitCheck.get()) return HTTP_429;
```

Could overlap with other I/O. But adds complexity.

**My take**: For rate limiting, clarity > async performance gains. But I've seen arguments both ways.

### Decision 3: Client-Side vs Server-Side Token Tracking

Should clients know their token count?

**Current**: Server returns remaining tokens
```json
{
  "allowed": true,
  "tokensRemaining": 42,
  "resetTime": "2025-10-23T12:00:00Z"
}
```

**Why**: Clients can back off proactively, prevents wasted requests.

**Risk**: Clients can game the system, optimize their behavior to stay just under limits.

**Alternative**: Just return true/false. Simpler, but clients have to guess-and-check.

## Testing Challenges Nobody Talks About

Unit testing a rate limiter is deceptively hard. How do you test time-based logic without `Thread.sleep()`?

### The Time Problem

**Bad approach**:
```java
@Test
public void testRefill() {
    rateLimiter.consume(10);
    Thread.sleep(1000);  // Wait for refill
    assertTrue(rateLimiter.hasTokens());
}
```

Slow tests, flaky on CI, terrible developer experience.

**My solution**: Inject a clock interface
```java
public class RateLimiter {
    private final Clock clock;  // Can be mocked
    
    public boolean allow(String key) {
        long now = clock.millis();
        // ... rate limit logic ...
    }
}

// In tests
@Test
public void testRefill() {
    MockClock clock = new MockClock();
    RateLimiter limiter = new RateLimiter(clock);
    
    limiter.consume(10);
    clock.advance(Duration.ofSeconds(1));  // Instant time travel!
    assertTrue(limiter.hasTokens());
}
```

Tests run in milliseconds, fully deterministic.

### The Distributed Problem

How do you test distributed behavior without actually running distributed instances?

I ended up using **Testcontainers** to spin up real Redis instances:

```java
@Testcontainers
public class DistributedRateLimiterTest {
    
    @Container
    static GenericContainer redis = new GenericContainer("redis:7-alpine")
        .withExposedPorts(6379);
    
    @Test
    public void testMultipleInstances() {
        // Simulate multiple app instances
        RateLimiter instance1 = new RateLimiter(redis.getHost(), redis.getPort());
        RateLimiter instance2 = new RateLimiter(redis.getHost(), redis.getPort());
        
        // Both instances should share state
        instance1.consume(5);
        assertEquals(5, instance2.remainingTokens());
    }
}
```

Slower than unit tests, but caught a bunch of race conditions my mocked tests missed.

## What I'd Do Differently

Looking back, here's what I'd change:

### 1. Start with Fixed Window

I spent weeks optimizing token bucket before realizing 80% of use cases don't need that precision. Should've validated with fixed window first, optimized later.

### 2. Metrics from Day One

Added metrics after performance problems appeared. Should've had Prometheus integration from the start. You can't optimize what you don't measure.

### 3. Document the Trade-offs

I built ADRs (Architecture Decision Records) halfway through. Should've done them upfront. Writing "why we chose X over Y" forces you to think through edge cases.

### 4. Simpler Configuration

My config system has three layers: per-key, pattern-based, global defaults. Sounds flexible, but in practice it's confusing. Simpler might be better.

## Questions for the Community

I'd genuinely love feedback on:

1. **Algorithm choice**: Am I overthinking this? Should I have just stuck with token bucket and called it done?

2. **Redis patterns**: Are there better patterns than Lua scripts for atomic distributed operations?

3. **Fail-open vs fail-closed**: What's your take? Have you been burned by either approach?

4. **Composite limiting**: Over-engineered or actually useful? Do people need multi-dimensional rate limiting?

5. **Client transparency**: Should clients know their remaining quota, or is that information they shouldn't have?

6. **Testing approaches**: How do you test distributed systems without the tests becoming a maintenance nightmare?

## The Code

I open-sourced the whole thing: [github.com/uppnrise/distributed-rate-limiter](https://github.com/uppnrise/distributed-rate-limiter)

**Tech stack**: Java 21, Spring Boot, Redis (Lettuce client), React dashboard for monitoring

**Performance**: ~50K req/s per instance, P95 < 2ms latency, ~100MB memory for 1M active limits

It's MIT licensed, so use it however you want. But more importantly, I'd love to discuss the approaches and trade-offs.

## Client Integration Example

Since people usually ask, here's how you'd use it:

```bash
# Simple POST request
curl -X POST http://localhost:8080/api/ratelimit/check \
  -H "Content-Type: application/json" \
  -d '{"key": "user:123", "tokensRequested": 1}'

# Response
{
  "allowed": true,
  "tokensRemaining": 42,
  "resetTime": "2025-10-23T12:00:00Z"
}
```

Simple REST API, works from any language. There's also a React dashboard for visualizing what's happening in real-time.

## Final Thoughts

This project started as "I need distributed rate limiting" and turned into a deep exploration of distributed systems trade-offs. 

The biggest lesson? **There's no "best" rate limiting algorithm.** It depends entirely on your use case:
- Token bucket for APIs with burst tolerance
- Sliding window for strict enforcement
- Fixed window for internal services and high scale
- Leaky bucket for traffic shaping
- Composite when reality is complicated

I'd love to hear your experiences with rate limiting:
- What approach do you use?
- Have you hit edge cases that broke your rate limiter?
- Are there patterns I'm missing?

Drop a comment, and let's discuss! Or check out the [repo](https://github.com/uppnrise/distributed-rate-limiter) and open an issue if you spot something questionable in the implementation.

---

*Built with Java 21, Spring Boot, and a lot of Redis Lua scripts. MIT licensed. Uses Testcontainers for testing because mocking distributed systems is a lie we tell ourselves.*
