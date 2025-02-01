# Proven Non-Citizen Workers (PNW) Smart Contract Overview

## 📌 Introduction
The **PNW Smart Contract** is a decentralized system designed to **manage migrant work visas, payroll, tax compliance, and worker protections**. It ensures fair treatment, transparent payments, and government compliance while enabling **SubDAOs** to govern employer penalties and worker benefits.

---

## 🔹 Key Features
### 1️⃣ Worker Identity & Verification
- **Workers register** on-chain, optionally verifying with **ZPass** for additional benefits.
- **ZPass-verified workers** receive:
  - **+0.5% APY on unpaid wages**
  - **Priority payroll processing**

### 2️⃣ Payroll & Tax Compliance
- Employers **prepay wages & taxes** before hiring workers.
- Payroll includes **State/Country tax deductions** in addition to SubDAO fees.
- **Batch payroll processing** reduces transaction costs.

### 3️⃣ Employer Compliance & Penalties
- Employers must **pay required State/Country taxes** before hiring.
- **Chronic offenders** (3+ missed tax payments) are **blacklisted** from hiring.
- **Reinstatement requires paying unpaid taxes + 25% fine**, with another **25% allocated to the SubDAO fund** for votable expenditures.
- **Automated tax payments** ensure compliance, with alerts for missed payments.

### 4️⃣ SubDAO Governance
- SubDAOs vote on:
  - Employer penalties
  - Worker expenditures using SubDAO funds
  - **Tax discounts for early compliance** (starting at **1%**, votable to increase)
- **New SubDAOs** automatically created once **100,000 workers** are registered.

---

## 🔹 Smart Contract Components
### 📂 `main.leo` – Core Contract
Handles **payroll, employer deposits, tax deductions, and worker payments**.

### 📂 `worker_identity.leo` – Worker Registration & Verification
- Workers can **register** and **optionally verify with ZPass**.
- **Payroll balances and trust levels** are maintained.

### 📂 `payroll.leo` – Payroll Processing
- Employers **prepay wages** before hiring.
- Payroll **automatically deducts worker taxes & fees**.
- **Batch payroll processing** reduces gas fees.

### 📂 `compliance_tracking.leo` – Employer Compliance & Penalties
- Employers must **pay taxes** or face **penalties & blacklisting**.
- SubDAO votes determine **tax discounts & penalty adjustments**.

### 📂 `government_api.leo` – Government Integration
- Allows government agencies to verify:
  - **Worker employment history**
  - **Employer tax compliance**

### 📂 `subdao_management.leo` – SubDAO Governance
- Handles **voting on penalties, expenditures, and tax incentives**.
- Automates **new SubDAO creation** when worker limits are reached.

### 📂 `employer_agreement.leo` – Employer Contract & Top-Up Requirement
- Employers must **prepay wages & taxes** to hire workers.
- **Failure to top up immediately** halts hiring privileges.

---

## 🔹 Compliance & Security
✅ **Zero-Knowledge Proofs (ZKPs)** ensure **secure identity verification**.  
✅ **Smart contract enforcements** prevent **tax evasion & worker exploitation**.  
✅ **Government API access** ensures **official verification of compliance**.

---

## 🔹 Future Enhancements
📌 **Multi-currency payroll options** (bridged USDC support).  
📌 **Enhanced worker benefits** (insurance & legal protections).  
📌 **Decentralized dispute resolution system** for worker complaints.

---

## 🔹 Conclusion
The **PNW Smart Contract** enables **secure, fair, and compliant** employment for migrant workers, integrating **payroll automation, tax enforcement, and decentralized governance**.
