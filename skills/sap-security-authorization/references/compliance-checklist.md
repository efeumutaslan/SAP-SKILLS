# SAP Compliance Audit Checklist

## SOX (Sarbanes-Oxley) Checklist

### Access Controls
- [ ] No users have SAP_ALL or SAP_NEW in production (check SUIM → Users by Profile)
- [ ] No users have S_DEVELOP access in production
- [ ] SAP* and DDIC default passwords changed
- [ ] Emergency access (firefighter) is logged and reviewed
- [ ] User access reviews completed quarterly
- [ ] Dormant users (>90 days no login) are locked (report RSUSR200)
- [ ] All user IDs are traceable to real individuals (no shared accounts)

### SoD Controls
- [ ] SoD ruleset defined and approved by management
- [ ] SoD analysis runs at least quarterly
- [ ] All SoD violations have documented mitigation controls
- [ ] Mitigation control effectiveness reviewed periodically
- [ ] New role changes go through SoD check before assignment

### Change Management
- [ ] Client settings (SCC4): production client locked for changes
- [ ] Transport system enforced (no direct changes in production)
- [ ] Developer keys restricted and tracked
- [ ] Code reviews performed before transport to production
- [ ] Transport logs available for audit (STMS → Import History)

### Monitoring
- [ ] Security Audit Log enabled (rsau/enable = 1)
- [ ] Audit log covers: logon events, transaction starts, user master changes
- [ ] Change document logging active for critical tables
- [ ] Logs retained for required period (typically 7 years for SOX)
- [ ] Regular review of system logs (SM21) for critical events

### Key Transactions for SOX Audit
| TCode | Purpose | Check |
|-------|---------|-------|
| SUIM | Authorization reporting | User lists, role assignments, profile analysis |
| SM19/RSAU_CONFIG | Audit log configuration | Verify filters are active |
| SM20/RSAU_READ_LOG | Audit log review | Check for suspicious activity |
| SCU3 | Change document display | Verify change logging |
| SCC4 | Client settings | Verify production is locked |
| STMS | Transport management | Review transport history |
| SU53 | Last failed auth check | Investigate access issues |

---

## GDPR (General Data Protection Regulation) Checklist

### Data Inventory
- [ ] Personal data mapped across SAP modules (HR, CRM, SD, FI)
- [ ] Data processing purposes documented per data category
- [ ] Legal basis for processing identified (consent, contract, legal obligation)
- [ ] Third-party data sharing agreements in place

### Data Subject Rights
- [ ] Process for Data Subject Access Requests (DSAR) established
- [ ] SAP Information Retrieval Framework configured (if applicable)
- [ ] Right to erasure ("right to be forgotten") implemented via ILM
- [ ] Data portability process defined (export in machine-readable format)
- [ ] Consent withdrawal process functional

### ILM (Information Lifecycle Management)
- [ ] Retention rules defined per data object (IRM_CUST)
- [ ] Residence/retention periods aligned with local law
- [ ] Simplified blocking configured for personal data
- [ ] Destruction jobs scheduled and monitored
- [ ] Blocking/unblocking/destruction events logged for audit

### Technical Measures
- [ ] Data masking/anonymization for non-production systems
- [ ] Encryption at rest and in transit (SSL/TLS for all connections)
- [ ] Access to personal data restricted by authorization (S_TABU_DIS, S_TABU_NAM)
- [ ] Data Protection & Privacy Fiori apps deployed (S/4HANA Cloud)
- [ ] Breach notification process defined (72-hour requirement)

### Key Transactions for GDPR
| TCode | Purpose |
|-------|---------|
| IRM_CUST | ILM Policy Studio (retention rules) |
| IRMPOL | ILM retention management |
| ILM_DESTRUCTION | Destruction worklist |
| SARA | Archive administration |
| SE16N | Verify personal data in tables |

---

## ISO 27001 Checklist (Information Security Management)

### Access Control (A.9)
- [ ] Access control policy documented and enforced
- [ ] User registration and de-provisioning process defined
- [ ] Privileged access management (SAP_ALL, firefighter) controlled
- [ ] Regular access reviews (at least annually)
- [ ] Password policy enforced (length, complexity, expiry, lockout)

### Password Policy Parameters
| Parameter | Recommended Value |
|-----------|------------------|
| login/min_password_lng | 8 (minimum) |
| login/password_compliance_to_current_policy | 1 |
| login/fails_to_session_end | 3 |
| login/fails_to_user_lock | 5 |
| login/password_expiration_time | 90 (days) |
| login/password_max_idle_initial | 14 (days for initial passwords) |

### Cryptography (A.10)
- [ ] SSL/TLS enabled for all external connections
- [ ] SNC (Secure Network Communications) configured for SAP GUI
- [ ] Encryption keys managed and rotated
- [ ] Digital signatures for critical transactions

### Logging & Monitoring (A.12)
- [ ] Security Audit Log configured and active
- [ ] System log (SM21) monitored
- [ ] Event correlation/SIEM integration in place
- [ ] Log integrity protected (read-only access to log files)

### Network Security (A.13)
- [ ] SAP Router configured for external access
- [ ] ICF services reviewed (SICF) — unused services deactivated
- [ ] RFC destinations (SM59) reviewed — no stored passwords for production
- [ ] Message server access restricted (ms/monitor = 0, ms/admin_port = 0)

---

## Quick Audit Commands (ABAP)

```abap
" Find users with SAP_ALL profile
SELECT bname FROM usr02
  WHERE bname IN ( SELECT bname FROM usr04 WHERE profn = 'SAP_ALL' )
  INTO TABLE @DATA(lt_users).

" Find users not logged in for 90+ days
SELECT bname, trdat FROM usr02
  WHERE trdat < @( cl_abap_context_info=>get_system_date( ) - 90 )
    AND uflag = '0'  " Not locked
  INTO TABLE @DATA(lt_dormant).

" Find roles with S_DEVELOP access
SELECT agr_name FROM agr_1251
  WHERE object = 'S_DEVELOP'
    AND auth <> '&_SAP_EMPTY'
  INTO TABLE @DATA(lt_dev_roles).
```
