"use client";

import { useState } from "react";
import PublicNav from "@/components/PublicNav";
import { CheckCircle2, FileText, UserRound, UsersRound, BriefcaseBusiness, ShieldCheck, ArrowLeft, PiggyBank, CreditCard } from "lucide-react";

const steps = [
  ["Client identity", "Capture full name, phone, branch, BVN/NIN and photo.", UserRound],
  ["Business profile", "Record business type, location, income and loan purpose.", BriefcaseBusiness],
  ["Savings option", "Choose daily, weekly, monthly, target savings or fixed deposit.", PiggyBank],
  ["Repayment method", "Cash, transfer and POS are supported for repayments.", CreditCard],
  ["Guarantor details", "Collect guarantor identity, phone, address and relationship.", UsersRound],
  ["KYC documents", "Upload ID, passport photo, utility bill and guarantor form.", FileText],
  ["Credit review", "Credit Officer submits, Branch Manager recommends, Area/Program Director approves.", ShieldCheck]
];

export default function Onboard() {
  const [form, setForm] = useState({
    fullName: "",
    phone: "",
    branch: "Head Office Branch",
    loanProduct: "Daily Loan",
    savingsProduct: "Daily Savings",
    repaymentMethod: "Cash",
    bvn: "",
    nin: "",
    address: "",
    businessType: "",
    requestedAmount: "",
    income: "",
    loanPurpose: "",
    guarantorName: "",
    guarantorPhone: "",
    guarantorAddress: ""
  });

  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState("");

  function updateField(e) {
    const { name, value } = e.target;
    setForm((prev) => ({ ...prev, [name]: value }));
  }

  async function handleSubmit(e) {
    e.preventDefault();
    setSaving(true);
    setMessage("");

    try {
      const res = await fetch("/api/customers", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(form)
      });

      const result = await res.json();
      if (!res.ok || !result.success) throw new Error(result.error || "Unable to save application");

      setMessage(`Application saved successfully. Customer ID: ${result.customerId}`);
      setForm({
        fullName: "",
        phone: "",
        branch: "Head Office Branch",
        loanProduct: "Daily Loan",
        savingsProduct: "Daily Savings",
        repaymentMethod: "Cash",
        bvn: "",
        nin: "",
        address: "",
        businessType: "",
        requestedAmount: "",
        income: "",
        loanPurpose: "",
        guarantorName: "",
        guarantorPhone: "",
        guarantorAddress: ""
      });
    } catch (error) {
      setMessage(error.message || "Something went wrong while saving.");
    } finally {
      setSaving(false);
    }
  }

  return (
    <>
      <PublicNav />
      <main className="min-h-screen bg-slate-50">
        <section className="mx-auto max-w-7xl px-5 py-12">
          <a href="/" className="mb-8 inline-flex items-center gap-2 rounded-full bg-white px-5 py-3 text-sm font-black text-purple-900 shadow-sm ring-1 ring-slate-200 transition hover:bg-purple-50">
            <ArrowLeft size={16} /> Back to Home
          </a>

          <div className="mb-8 max-w-3xl">
            <div className="inline-flex rounded-full bg-purple-100 px-4 py-2 text-sm font-black text-purple-800">Remote Client Onboarding</div>
            <h1 className="mt-5 text-4xl font-black tracking-tight text-purple-950 md:text-6xl">Open a customer profile from anywhere.</h1>
            <p className="mt-4 text-lg leading-8 text-slate-600">Register customers, capture KYC, select savings and loan products, assign branch workflow and prepare the application for approval.</p>
          </div>

          <div className="grid gap-6 lg:grid-cols-[1.15fr_.85fr]">
            <form onSubmit={handleSubmit} className="card rounded-3xl bg-white p-6 shadow-sm md:p-8">
              <h2 className="text-2xl font-black text-purple-950">Customer Information</h2>
              <div className="mt-6 grid gap-5 md:grid-cols-2">
                <label className="space-y-2"><span className="font-bold">Full Name</span><input name="fullName" value={form.fullName} onChange={updateField} className="input" placeholder="Customer full name" required /></label>
                <label className="space-y-2"><span className="font-bold">Phone Number</span><input name="phone" value={form.phone} onChange={updateField} className="input" placeholder="080..." required /></label>
                <label className="space-y-2"><span className="font-bold">Branch</span><select name="branch" value={form.branch} onChange={updateField} className="input"><option>Head Office Branch</option><option>Ede Branch</option><option>Osogbo Branch</option><option>Owode Branch</option><option>Ibadan 1</option><option>Ibadan 2</option><option>Rumudara Branch</option></select></label>
                <label className="space-y-2"><span className="font-bold">Loan Product</span><select name="loanProduct" value={form.loanProduct} onChange={updateField} className="input"><option>Daily Loan</option><option>Weekly Loan</option><option>Monthly Loan</option></select></label>
                <label className="space-y-2"><span className="font-bold">Savings Product</span><select name="savingsProduct" value={form.savingsProduct} onChange={updateField} className="input"><option>Daily Savings</option><option>Weekly Savings</option><option>Monthly Savings</option><option>Target Savings</option><option>Fixed Deposit</option></select></label>
                <label className="space-y-2"><span className="font-bold">Repayment Method</span><select name="repaymentMethod" value={form.repaymentMethod} onChange={updateField} className="input"><option>Cash</option><option>Transfer</option><option>POS</option></select></label>
                <label className="space-y-2"><span className="font-bold">BVN</span><input name="bvn" value={form.bvn} onChange={updateField} className="input" placeholder="BVN number" /></label>
                <label className="space-y-2"><span className="font-bold">NIN</span><input name="nin" value={form.nin} onChange={updateField} className="input" placeholder="NIN number" /></label>
                <label className="space-y-2 md:col-span-2"><span className="font-bold">Residential Address</span><input name="address" value={form.address} onChange={updateField} className="input" placeholder="House address, area, city" /></label>
              </div>

              <div className="mt-8 border-t pt-8">
                <h2 className="text-2xl font-black text-purple-950">Business & Loan Request</h2>
                <div className="mt-6 grid gap-5 md:grid-cols-2">
                  <label className="space-y-2"><span className="font-bold">Business Type</span><input name="businessType" value={form.businessType} onChange={updateField} className="input" placeholder="Trading, food, fashion..." /></label>
                  <label className="space-y-2"><span className="font-bold">Requested Amount</span><input name="requestedAmount" value={form.requestedAmount} onChange={updateField} className="input" placeholder="50000" /></label>
                  <label className="space-y-2"><span className="font-bold">Monthly / Daily Income</span><input name="income" value={form.income} onChange={updateField} className="input" placeholder="Estimated income" /></label>
                  <label className="space-y-2"><span className="font-bold">Loan Purpose</span><input name="loanPurpose" value={form.loanPurpose} onChange={updateField} className="input" placeholder="Stock purchase, equipment..." /></label>
                </div>
              </div>

              <div className="mt-8 border-t pt-8">
                <h2 className="text-2xl font-black text-purple-950">Guarantor</h2>
                <div className="mt-6 grid gap-5 md:grid-cols-2">
                  <label className="space-y-2"><span className="font-bold">Guarantor Name</span><input name="guarantorName" value={form.guarantorName} onChange={updateField} className="input" placeholder="Full name" /></label>
                  <label className="space-y-2"><span className="font-bold">Guarantor Phone</span><input name="guarantorPhone" value={form.guarantorPhone} onChange={updateField} className="input" placeholder="080..." /></label>
                  <label className="space-y-2 md:col-span-2"><span className="font-bold">Guarantor Address</span><input name="guarantorAddress" value={form.guarantorAddress} onChange={updateField} className="input" placeholder="Address" /></label>
                </div>
              </div>

              <div className="mt-8 rounded-2xl border border-green-200 bg-green-50 p-4 text-sm font-medium text-green-900">✓ Customer applications submitted here will be routed through KYC verification, savings/loan setup, branch approval workflow and audit logging.</div>
              {message && <div className="mt-4 rounded-2xl border border-purple-200 bg-purple-50 p-4 text-sm font-bold text-purple-900">{message}</div>}
              <button type="submit" disabled={saving} className="btn btn-gold mt-6 w-full justify-center text-center disabled:opacity-60">{saving ? "Saving Application..." : "Save Draft Application"}</button>
            </form>

            <aside className="space-y-5">
              <div className="card rounded-3xl bg-white p-6 shadow-sm">
                <h2 className="text-2xl font-black text-purple-950">Onboarding Checklist</h2>
                <div className="mt-5 space-y-4">
                  {steps.map(([title, desc, Icon]) => <div key={title} className="flex gap-3 rounded-2xl border border-slate-100 bg-white p-4"><Icon className="mt-1 shrink-0 text-purple-800" size={22}/><div><div className="font-black text-slate-950">{title}</div><p className="mt-1 text-sm leading-6 text-slate-600">{desc}</p></div></div>)}
                </div>
              </div>
              <div className="rounded-3xl bg-purple-950 p-6 text-white shadow-xl">
                <CheckCircle2 className="text-yellow-300" />
                <h3 className="mt-3 text-xl font-black">Approval Rule</h3>
                <p className="mt-2 text-sm leading-6 text-purple-100">Credit Officer processes. Branch Manager recommends. Area Manager approves up to ₦400,000. Program Director approves ₦400,000 and above.</p>
              </div>
            </aside>
          </div>
        </section>
      </main>
    </>
  );
}
