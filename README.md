# Proven Non-Citizen Workers (PNW) Smart Contracts

## **🔹 Overview**  
PNW is a decentralized payroll and governance system for **migrant workers**, ensuring:  
✅ **Payroll flexibility** – Workers can choose **Aleo USDC or Bridged USDC** at any time.  
✅ **Employer accountability** – Employers must include **payroll taxes in salary agreements**.  
✅ **Worker protections** – SubDAOs vote on **benefits, employer penalties, and fund allocation**.  
✅ **Government compliance** – Labor offices can verify work history using **ZPass zero-knowledge proofs**.  

---

## **🔹 Key Features**  

### **1️⃣ Worker Identity (NFT-Based System)**  
- Each worker receives an **NFT identity** storing:  
  ✅ **Employment history**  
  ✅ **Visa status & expiration**  
  ✅ **Total earnings & trust fund balance**  
- **Government & employers** can verify work history **without exposing private data**.  

### **2️⃣ Payroll Processing (Supports Aleo USDC & Bridged USDC)**  
- **Workers choose their payroll option:**  
  🔹 **Aleo USDC** (native Aleo blockchain, gas fees covered by SubDAOs)  
  🔹 **Bridged USDC** (EVM-compatible sidechain, workers cover gas fees)  
- **Payroll tax (2%) is factored into employer salary agreements with SubDAOs.**  
- **ZPass-verified workers receive:**  
  ✅ **Priority payroll processing**  
  ✅ **+0.5% APY on unpaid wages in trust fund**  

### **3️⃣ Employer-SubDAO Salary Agreements**  
- **Employers must negotiate gross salaries** that **include the 2% payroll tax**.  
- **SubDAOs verify salary agreements before approving payroll.**  
- **Ensures transparency & prevents tax evasion by employers.**  

### **4️⃣ SubDAO Governance & Treasury Voting**  
- **Workers participate in SubDAOs**, which control **tax funds collected from payroll**.  
- SubDAOs vote on **fund allocation**, including:  
  ✅ **Worker benefits & emergency relief**  
  ✅ **Education & training programs**  
  ✅ **Infrastructure improvements**  
  ✅ **Investments to grow treasury funds**  

### **5️⃣ Worker Protections & Employer Accountability**  
- Workers can **report abusive employers** directly on-chain.  
- If an employer **receives multiple reports**, SubDAOs **vote on penalties** (e.g., contract suspension).  
- Employers who **fail to cover payroll taxes** may face **SubDAO-imposed fines or penalties**.  

### **6️⃣ Government API Integration**  
- Approved **government agencies** can **verify work & visa status** via **zero-knowledge proofs**.  
- Helps with **visa renewals, tax compliance, and labor law enforcement**.  

---

## **🔹 How PNW Works**  
1️⃣ **A migrant worker joins a SubDAO** and receives an **NFT identity**.  
2️⃣ **An employer & SubDAO negotiate salary**, ensuring **payroll tax is included**.  
3️⃣ **Workers choose their payroll option** (**Aleo USDC or Bridged USDC**).  
4️⃣ **Employers process payroll**, with **ZPass workers receiving priority processing**.  
5️⃣ **SubDAOs vote on treasury funds**, deciding **how payroll tax is allocated**.  
6️⃣ **Governments can verify worker status** to ensure **legal employment compliance**.  

---

## **🔹 Smart Contract Structure**  
PNW operates across **two blockchain layers**:  
🔹 **Main Chain (Aleo – Leo Smart Contracts)** → Handles **worker identity, payroll governance, and government verification**.  
🔹 **Side Chain (Ethereum – Solidity Smart Contracts)** → Handles **stablecoin payroll processing & tax allocation**.  

### **🔹 Main Smart Contracts**
| Contract | Functionality |
|----------|--------------|
| `PNW_Main.leo` | Worker NFT issuance, payroll processing, SubDAO voting |
| `PNW_GovernmentAPI.leo` | Government verification of worker status |
| `PNW_Payroll.leo` | Payroll system supporting **Aleo USDC & Bridged USDC** |
| `PNW_EmployerContract.leo` | Ensures **employers include payroll tax in salaries** |

### **🔹 Sidechain Smart Contracts**
| Contract | Functionality |
|----------|--------------|
| `PNW_Payroll.sol` | Stablecoin payroll processing on Ethereum-compatible sidechain |

---

## **🔹 Installation & Deployment**  

### **🔹 1️⃣ Clone This Repository**
```bash
git clone https://github.com/YOUR-USERNAME/PNW-Smart-Contracts.git
cd PNW-Smart-Contracts
