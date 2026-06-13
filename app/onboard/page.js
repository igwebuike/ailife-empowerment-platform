import PublicNav from '@/components/PublicNav'
import {
  CheckCircle2,
  FileText,
  UserRound,
  UsersRound,
  BriefcaseBusiness,
  ShieldCheck,
  ArrowLeft
} from 'lucide-react'

const steps = [
  ['Client identity', 'Capture full name, phone, branch, BVN/NIN and photo.', UserRound],
  ['Business profile', 'Record business type, location, income and loan purpose.', BriefcaseBusiness],
  ['Guarantor details', 'Collect guarantor identity, phone, address and relationship.', UsersRound],
  ['KYC documents', 'Upload ID, passport photo, utility bill and guarantor form.', FileText],
  ['Credit review', 'Credit Officer submits, Branch Manager recommends, Area/Program Director approves.', ShieldCheck]
]

export default function Onboard() {
  return (
    <>
      <PublicNav />

      <main className="min-h-screen bg-slate-50">
        <section className="mx-auto max-w-7xl px-5 py-12">

          <a
            href="/"
            className="mb-8 inline-flex items-center gap-2 rounded-full bg-white px-5 py-3 text-sm font-black text-purple-900 shadow-sm ring-1 ring-slate-200 transition hover:bg-purple-50"
          >
            <ArrowLeft size={16} />
            Back to Home
          </a>

          <div className="mb-8 max-w-3xl">
            <div className="inline-flex rounded-full bg-purple-100 px-4 py-2 text-sm font-black text-purple-800">
              Remote Client Onboarding
            </div>

            <h1 className="mt-5 text-4xl font-black tracking-tight text-purple-950 md:text-6xl">
              Open a customer profile from anywhere.
            </h1>

            <p className="mt-4 text-lg leading-8 text-slate-600">
              Use this intake flow to register beneficiaries, verify KYC,
              capture guarantors, assess businesses and prepare loan
              applications for approval.
            </p>
          </div>

          <div className="grid gap-6 lg:grid-cols-[1.15fr_.85fr]">

            {/* LEFT SIDE FORM */}

            <form className="card rounded-3xl bg-white p-6 shadow-sm md:p-8">

              <h2 className="text-2xl font-black text-purple-950">
                Customer Information
              </h2>

              <div className="mt-6 grid gap-5 md:grid-cols-2">

                <label className="space-y-2">
                  <span className="font-bold">Full Name</span>
                  <input
                    className="input"
                    placeholder="Customer full name"
                  />
                </label>

                <label className="space-y-2">
                  <span className="font-bold">Phone Number</span>
                  <input
                    className="input"
                    placeholder="080..."
                  />
                </label>

                <label className="space-y-2">
                  <span className="font-bold">Branch</span>
                  <select className="input">
                    <option>Head Office</option>
                    <option>Ede Branch</option>
                    <option>Osogbo Branch</option>
                    <option>Owode Branch</option>
                    <option>Ibadan 1</option>
                    <option>Ibadan 2</option>
                    <option>Rumudara Branch</option>
                  </select>
                </label>

                <label className="space-y-2">
                  <span className="font-bold">Loan Product</span>
                  <select className="input">
                    <option>Daily Loan</option>
                    <option>Weekly Loan</option>
                    <option>Monthly Loan</option>
                  </select>
                </label>

                <label className="space-y-2">
                  <span className="font-bold">BVN</span>
                  <input
                    className="input"
                    placeholder="BVN number"
                  />
                </label>

                <label className="space-y-2">
                  <span className="font-bold">NIN</span>
                  <input
                    className="input"
                    placeholder="NIN number"
                  />
                </label>

                <label className="space-y-2 md:col-span-2">
                  <span className="font-bold">Residential Address</span>
                  <input
                    className="input"
                    placeholder="House address, area, city"
                  />
                </label>

              </div>

              {/* BUSINESS */}

              <div className="mt-8 border-t pt-8">

                <h2 className="text-2xl font-black text-purple-950">
                  Business & Loan Request
                </h2>

                <div className="mt-6 grid gap-5 md:grid-cols-2">

                  <label className="space-y-2">
                    <span className="font-bold">Business Type</span>
                    <input
                      className="input"
                      placeholder="Trading, food, fashion..."
                    />
                  </label>

                  <label className="space-y-2">
                    <span className="font-bold">Requested Amount</span>
                    <input
                      className="input"
                      placeholder="₦50,000"
                    />
                  </label>

                  <label className="space-y-2">
                    <span className="font-bold">Monthly / Daily Income</span>
                    <input
                      className="input"
                      placeholder="Estimated income"
                    />
                  </label>

                  <label className="space-y-2">
                    <span className="font-bold">Loan Purpose</span>
                    <input
                      className="input"
                      placeholder="Stock purchase, equipment..."
                    />
                  </label>

                </div>

              </div>

              {/* GUARANTOR */}

              <div className="mt-8 border-t pt-8">

                <h2 className="text-2xl font-black text-purple-950">
                  Guarantor
                </h2>

                <div className="mt-6 grid gap-5 md:grid-cols-2">

                  <label className="space-y-2">
                    <span className="font-bold">Guarantor Name</span>
                    <input
                      className="input"
                      placeholder="Full name"
                    />
                  </label>

                  <label className="space-y-2">
                    <span className="font-bold">Guarantor Phone</span>
                    <input
                      className="input"
                      placeholder="080..."
                    />
                  </label>

                  <label className="space-y-2 md:col-span-2">
                    <span className="font-bold">Guarantor Address</span>
                    <input
                      className="input"
                      placeholder="Address"
                    />
                  </label>

                </div>

              </div>

              {/* STATUS */}

              <div className="mt-8 rounded-2xl border border-green-200 bg-green-50 p-4 text-sm font-medium text-green-900">
                ✓ Customer applications submitted here will be routed through
                KYC verification, guarantor review, branch approval workflow,
                loan processing and complete audit logging.
              </div>

              <button
                type="submit"
                className="btn btn-gold mt-6 w-full justify-center text-center"
              >
                Save Draft Application
              </button>

            </form>

            {/* RIGHT SIDE */}

            <aside className="space-y-5">

              <div className="card rounded-3xl bg-white p-6 shadow-sm">

                <h2 className="text-2xl font-black text-purple-950">
                  Onboarding Checklist
                </h2>

                <div className="mt-5 space-y-4">

                  {steps.map(([title, desc, Icon]) => (
                    <div
                      key={title}
                      className="flex gap-3 rounded-2xl border border-slate-100 bg-white p-4"
                    >
                      <Icon
                        className="mt-1 shrink-0 text-purple-800"
                        size={22}
                      />

                      <div>
                        <div className="font-black text-slate-950">
                          {title}
                        </div>

                        <p className="mt-1 text-sm leading-6 text-slate-600">
                          {desc}
                        </p>
                      </div>
                    </div>
                  ))}

                </div>

              </div>

              <div className="rounded-3xl bg-purple-950 p-6 text-white shadow-xl">

                <CheckCircle2 className="text-yellow-300" />

                <h3 className="mt-3 text-xl font-black">
                  Approval Rule
                </h3>

                <p className="mt-2 text-sm leading-6 text-purple-100">
                  Credit Officer processes. Branch Manager recommends.
                  Area Manager approves up to ₦400,000.
                  Program Director approves ₦400,000 and above.
                </p>

              </div>

            </aside>

          </div>

        </section>
      </main>
    </>
  )
}