# Code Snippet Examples

## Use when

- agents need a concrete reference for what well-structured code looks like in this repo
- code review feedback keeps citing the same structural issues
- new contributors or agents need calibration on the expected quality bar

## Neutralized examples

These examples use generic domain names and placeholder logic. Adapt structure and patterns to the actual project stack.

### Well-structured API handler

```
function handleRequest(request):
    validate(request.body, schema)
    result = service.process(request.body)
    if result.isError:
        log.warn("processing_failed", {correlationId: request.id, error: result.error})
        return errorResponse(result.error.code, result.error.userMessage)
    return successResponse(result.data)
```

Key qualities: validates input first, delegates to a service layer, logs with context, returns structured errors.

### Well-structured database query

```
function findActiveItems(userId, options):
    query = db.select("items")
        .where("user_id", userId)
        .where("status", "active")
        .orderBy(options.sortField, options.sortDirection)
        .limit(options.pageSize)
        .offset(options.page * options.pageSize)
    return query.execute()
```

Key qualities: parameterized (no string interpolation), paginated, bounded result set, sort controlled by caller.

### Well-structured component composition

```
function ItemList(props):
    if props.isLoading:
        return LoadingSkeleton(count: props.pageSize)
    if props.error:
        return ErrorBanner(message: props.error.userMessage, onRetry: props.onRetry)
    if props.items.isEmpty:
        return EmptyState(action: props.onCreateNew)
    return List(
        items: props.items.map(item => ItemCard(item: item, onSelect: props.onSelect)),
        pagination: Pagination(current: props.page, total: props.totalPages, onChange: props.onPageChange)
    )
```

Key qualities: handles all states (loading, error, empty, data), delegates rendering to child components, pagination built in.

### Well-structured error boundary

```
function withErrorBoundary(operation, context):
    try:
        return operation()
    catch TransientError as e:
        log.warn("transient_error", {context: context, error: e.message})
        return retry(operation, maxAttempts: 3, backoff: exponential)
    catch ValidationError as e:
        log.info("validation_failed", {context: context, fields: e.fields})
        return errorResult(code: "VALIDATION_FAILED", userMessage: e.userMessage)
    catch:
        log.error("unexpected_error", {context: context, error: currentError})
        return errorResult(code: "INTERNAL_ERROR", userMessage: "Something went wrong. Please try again.")
```

Key qualities: distinguishes error types, retries only transient errors, never exposes internals to users, logs with structured context.

## Reading rule

Use these snippets as structural calibration, not as copy-paste templates. Adapt to the project's language, framework, and conventions.
