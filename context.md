# Data Mavericks — Data Apps Specialization Test

---

## Context & Background

**Company:** Data Mavericks — a consultancy that helps companies with Snowflake solutions. They're expanding into building data apps for clients.

**The problem:** They have ~20 data interns who are strong in SQL, Python, and Snowflake, but they need 4-5 of them who can build frontend applications. 

---

## Test Briefing Website

**Instead of handing out a Word doc, the test brief lives on a website** hosted on the owner's domain. Should feel exciting — like a product launch or hackathon, not a corporate exam.

--- 

## Test Parameters

| Parameter | Decision |
|-----------|----------|
| Duration | 1–1.5 hours |
| Participants | ~20 data interns |
| Selecting | Top 4–5 |
| Framework | **React** (with Vite) |
| AI tools | Unrestricted — any AI tool they want |
| Participant background | Strong SQL, Python, Snowflake. **Have never built a website.** Only worked with Snowflake and Jupyter notebooks. |
| Data layer | Snowflake with a read-only service user (one DB, read perms only). Credentials given to all interns. They query Snowflake directly from the frontend. |

---

problem statement

What we're testing:

We're not testing for app dev skills (does get brownie points)
We're testing for propensity/interest in building apps
We're looking at how well the problem statement was addressed, creativity & product thinking
AI coding tools are encouraged — we judge on what's produced, not how they got there
We reveal the task beforehand so people can prep (first time doing app dev for many)

We score on:

Does it work
How well the problem was addressed
The UX of the app
Creativity / bonus features


Problem Statement:
The Snowcone Warehouse is a fast-growing chain of 15-20 ice cream stores across multiple cities. The regional manager, TEST_USER, has no visibility into which locations are thriving and which are struggling. Right now his team manually pulls SQL queries every Monday morning to prep for the weekly meetings. It takes hours and the reports are always stale by the time they're presented.
TEST_USER needs a web app his non-technical ops team can open every day to monitor store performance and catch problems early.
What you need to build (scope sheet):

Location Scorecard — A table/grid showing all locations with key metrics: revenue, average customer rating, and trend (improving/declining). Sortable. Locations needing attention should be visually flagged.
Historical Sales View — Charts showing sales performance over time. Should be able to see trends by location — is revenue going up or down? Include a breakdown of order types (dine-in, takeout, delivery).
Inventory Waste Tracker — A view showing waste by location and by category (produce, dairy, etc). Flag locations where waste is above an acceptable threshold. Show whether waste is trending better or worse.
Location Drill-Down — Clicking on any location should show a detailed view: location info, sales charts, recent customer reviews, and inventory summary for that specific store.
At least one interactive element — Date range filter, location comparison selector, search, or similar. The dashboard should not be static.

UX Goals:

Usable by someone non-technical — if TEST_USER's ops team can't figure it out in 10 seconds, it's not good enough
Make problems obvious at a glance — don't make users hunt for issues
Clear information hierarchy — most important metrics first, details on drill-down
Should feel like one cohesive dashboard, not 4 disconnected pages

Bonus (not required, but noticed):
Dark mode, export to CSV/PDF, AI-generated insights, alerts for problem locations, mobile responsiveness, anything else they think would help TEST_USER.


--- 

how will the process work:
step 1 will be to git clone the scaffoleded project that is provided (we can give two options: react/vue)
once they have the repo they can work on the test and make the applicaiton
once completed they need to run a script lets call it `./submit.sh john.doe@datamavericks.com`
this script will build the application and push it to my repository,auto deploy the submissions like so: `data-apps-spec.deepanshu.tech/submission/john-doe`
Prints: "Your app will be live at `data-apps-spec.deepanshu.tech/submission/john-doe` in about 60 seconds"

---


## What Needs to Be Built (Implementation Checklist)

### 1. Starter React Project: snowcone-starter
- [✅] Vite + React project that runs with `npm install && npm run dev`
- [✅] Component library installed (shadcn/ui)
- [✅] Snowflake connection utility (`src/lib/snowflake.js`)
- [✅] Chart library installed (Recharts)
- [✅] README with setup instructions
- [ ] `submit.sh` included in the project root (#3)

### 2. Snowflake Data
- [✅] SQL to create "The Snowcone Warehouse" schema in the Trash Database
- [✅] SQL to create LOCATIONS, DAILY_SALES, CUSTOMER_REVIEWS, INVENTORY tables
- [✅] Python or SQL script to generate realistic sample data
- [✅] Data should have clear patterns (top performers, struggling locations, seasonal trends)
- [✅] SQL to create read-only service user + grants

### 3. Submit Script
- [ ] Standalone `submit.sh` bash script
- [ ] Takes email as argument
- [ ] Runs `npm run build`
- [ ] Uploads to my repo somehow? still not sure how this will work TODO:!!!
- [ ] Prints the live URL after upload
- [ ] Error handling (build fails, upload fails, name already taken)

### 4. Test Briefing Website 
- [✅] Submission instructions
- [✅] Timer / countdown
- [✅] Looks exciting 

### 5. Deployment
- [ ] GitHub repo created (`data-apps-spec.deepanshu.tech/submissions/`)
- [ ] Custom domain configured (CNAME record added)
- [ ] Tested with a placeholder deployment

---
