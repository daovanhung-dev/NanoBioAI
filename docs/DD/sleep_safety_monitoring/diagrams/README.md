# M31 Diagrams

## Main sequence

```mermaid
sequenceDiagram
    actor U as User
    participant UI as SleepTrackingPage
    participant C as SleepSafetyController
    participant N as Native Runtime
    participant G as Phone Gateway
    participant D as System Phone App
    participant S as Supabase Edge
    participant P as SMS/Voice Provider
    participant K as SafetyContact

    U->>UI: Bắt đầu giám sát
    UI->>C: startMonitoring()
    C->>C: request CALL_PHONE when enabled + eligible contact
    C->>N: startMonitoring(config)
    N->>N: calibration + frame features (RAM only)
    N-->>C: confirmedSafetyEvent(metadata)
    N-->>U: Bạn có ổn không?
    alt Tôi ổn
      U->>N: OK
      N-->>C: userResponse(ok)
      C->>C: cooldown -> monitoring
    else Tôi cần hỗ trợ
      U->>N: Need help
      N-->>C: userResponse(need_help)
      C->>C: save local help response
      alt eligible contact exists
        alt Android permission + ACTION_CALL succeeds
          C->>G: initiateCall(highest priority contact)
          G->>D: ACTION_CALL
          D-->>U: OS call UI; alert sound and notification stop
          Note over C,D: OS initiation does not prove connection or answer
        else Permission denied or direct-call launch fails
          C->>G: openDialer(prefilled number)
          G->>D: ACTION_DIAL / tel:
          D-->>C: OS accepts handoff; alert sound and notification stop
          U->>D: Review number and press Call
        end
      else No eligible contact
        C-->>U: Keep alert and show next steps
      end
    else Không phản hồi sau 15s
      N->>N: +15s escalation; no intermediate reminder
      N-->>C: escalationRequired
      C->>S: dispatch(noResponse, stable idempotency)
      S->>S: re-check paid + rollout + freshness + rate + contacts
      loop contacts in priority order
        S->>P: voice, then SMS only for verified number
        P-->>S: submitted / callback
      end
      S-->>C: voice/SMS acceptance summary
      P-->>K: call / SMS
    end
```

## Automatic no-response offline retry

```mermaid
sequenceDiagram
    participant C as SleepSafetyController
    participant DB as SQLite outbox
    participant S as Supabase Edge
    participant U as User
    participant G as Phone Gateway

    C->>S: dispatch noResponse with stable event idempotency
    S--xC: network failure / timeout
    C->>DB: queue event id + idempotency + timestamps
    C->>S: retry on reconnect before freshness expiry
    U->>G: Tap Tôi cần hỗ trợ
    G->>U: Direct OS call or prefilled dialer handoff
    Note over U,G: Phone action is local and independent of the dispatch outbox
```

## Contact verification

```mermaid
sequenceDiagram
    actor U as User
    participant A as App
    participant E as Verification Edge
    participant DB as Supabase
    participant P as Provider

    U->>A: Thêm số; OTP tùy chọn cho gọi điện, cần cho SMS
    A->>E: action=request, contact_id
    E->>DB: verify ownership/rate
    E->>DB: store OTP hash + expiry
    E->>P: send OTP
    E-->>A: accepted + expiry (no OTP)
    U->>A: nhập 6 số
    A->>E: action=confirm
    E->>DB: compare hash/attempt/expiry
    E->>DB: mark contact verified
    E-->>A: verified=true
```

Pending contacts can receive automatic voice only when the owner enables the
separate, default-off voice-alert consent. Verification remains required for
SMS. Direct user-help calls use the per-contact phone opt-in and are never sent
through the server dispatcher.
