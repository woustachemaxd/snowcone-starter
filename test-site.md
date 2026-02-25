# The Snowcone Warehouse Challenge

**Data Mavericks — Data Apps Specialization Test**

Build a real-time operations dashboard for a 15-store ice cream chain. One app. One shot. Show us you can ship.

---

## Section 01 — The Problem Statement

**The Snowcone Warehouse** is a fast-growing chain of 15–20 ice cream stores across multiple cities. The regional manager has **zero visibility** into which locations are thriving and which are struggling.

Every Monday morning his team manually pulls SQL queries to prep for weekly meetings. It takes hours, and the reports are always stale by the time they're presented.

> **Your Objective:** Build a web app his non-technical ops team can open every day to monitor store performance and catch problems early.

---

## Section 02 — Your Scope Sheet

### Spec 01 — Location Scorecard *(Required)*
A table or grid showing all locations with key metrics: revenue, average customer rating, and trend (improving/declining). Sortable. Locations needing attention should be visually flagged.

### Spec 02 — Historical Sales View *(Required)*
Charts showing sales performance over time. See trends by location — is revenue going up or down? Include a breakdown of order types (dine-in, takeout, delivery).

### Spec 03 — Inventory Waste Tracker *(Required)*
A view showing waste by location and by category (produce, dairy, etc). Flag locations where waste is above threshold. Show whether waste is trending better or worse.

### Spec 04 — Location Drill-Down *(Required)*
Clicking on any location shows a detailed view: location info, sales charts, recent customer reviews, and inventory summary for that specific store.

### Spec 05 — Interactive Elements *(Required)*
At least one interactive element — date range filter, location comparison selector, search, or similar. The dashboard should not be static.

### UX Goals
- Usable by someone non-technical — if the ops team can't figure it out in 10 seconds, it's not good enough
- Make problems obvious at a glance — don't make users hunt for issues
- Clear information hierarchy — most important metrics first, details on drill-down
- Should feel like one cohesive dashboard, not 4 disconnected widgets thrown together

---

## Section 03 — How You're Scored

| Criteria | Weight | Description |
|----------|--------|-------------|
| Does It Work? | Core | Can a user open the app and accomplish the core tasks without errors? |
| Problem Addressed | Core | How well does the app solve the regional manager's actual problems? |
| User Experience | High | Is it intuitive, clear, and visually organized? Would a non-technical user be comfortable? |
| Creativity & Extras | Bonus | Bonus features, unique ideas, polish. Things we didn't ask for but wish we had. |

### Important Notes
- We're **not** testing for existing app dev skills. We're testing for **propensity and interest** in building apps.
- AI coding tools are **fully encouraged**. We judge on what's produced, not how you got there.
- We've shared the task beforehand so you can **prep and explore**.

---

## Section 04 — Bonus Points

Not required, but definitely noticed. Pick any that excite you:

- 🌙 Dark Mode
- 📄 CSV / PDF Export
- 📱 Mobile Responsive
- ⭐ Surprise Us

---

## Section 05 — Tech Stack

| Technology | Purpose |
|------------|---------|
| React + Vite | Framework |
| shadcn/ui | Components |
| Recharts | Charts |
| Snowflake | Data Layer |

### Snowflake Connection
A read-only service user will be provided with credentials. One Schema, read permissions only. You'll query Snowflake directly from the frontend using the included connection utility at `src/lib/snowflake.js`

---

## Section 06 — How to Submit

### Step 1: Install Node.js
If you haven't built a web app before, you'll need Node.js first. Download and install it from [nodejs.org](https://nodejs.org) — grab the **LTS version**.

Verify installation:
```bash
node --version
```
You should see something like `v22.x.x`. If so, you're good.

### Step 2: Clone the starter project
```bash
git clone https://github.com/datamavericks/snowcone-starter
npm install && npm run dev
```
Opens at `http://localhost:5173` — your live preview as you build.

### Step 3: Build your app
Use any AI tools, any resources. Focus on solving the problem and having fun with it!

### Step 4: Submit your work
```bash
./submit.sh john.doe@datamavericks.com  // your company email
```

> **Your app goes live at:** `data-apps-spec.deepanshu.tech/submission/john-doe`
> 
> Ready in about 60 seconds. Share the link — it's publicly accessible.

---

*Data Mavericks — The Snowcone Warehouse Challenge*

*Build something great. We're rooting for you!*