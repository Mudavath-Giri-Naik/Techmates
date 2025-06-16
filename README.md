# TechMates – College Community App

TechMates is a mobile application exclusively built for college students, designed to foster collaboration, verified networking, and knowledge sharing. The app enforces secure access through domain-based email authentication and provides tools for community learning, real-time communication, and portfolio development.

---

## Table of Contents

- [About](#about)
- [Key Features](#key-features)
- [Technology Stack](#technology-stack)
- [Architecture Overview](#architecture-overview)
- [Installation](#installation)
- [Contributing](#contributing)
- [License](#license)

---

## About

TechMates connects verified college students to a secure and structured platform where they can share resources, engage in real-time communication, discover peers across institutions, and track personal growth through skill-based ranking.

---

## Key Features

- Secure college email-based authentication
- Live feed of student posts and updates
- College-wise searchable student directory
- Real-time chat and group communication
- Resource sharing and downloads
- GitHub analytics and automatic student ranking
- Customizable student profiles with verified links

---

## Technology Stack

The app follows a **modular, scalable architecture** using modern web and mobile technologies. Below is a feature-wise breakdown of the tech stack:

### 1. **Mobile App (Frontend)**
- **Framework**: Expo React Native
- **Language**: JavaScript (ES6+)
- **State Management**: React Context API / Redux (optional)
- **Navigation**: React Navigation
- **HTTP Requests**: Axios

---

### 2. **Authentication**
- **Method**: Google OAuth 2.0
- **College Email Restriction**: Custom domain validation during sign-in
- **Provider**: Firebase Authentication
- **Backend Validation**: Node.js API to enforce domain whitelist

---

### 3. **Feed (Home Screen)**
- **Tech Stack**:
  - Expo React Native (UI)
  - Node.js + Express (API)
  - PostgreSQL (Post data storage)
  - Cloud Storage (for media)
- **Features**:
  - Global and following-based post retrieval
  - Media uploads
  - Likes and comments functionality

---

### 4. **Search / Connect Screen**
- **Tech Stack**:
  - Node.js APIs to fetch college-wise users
  - PostgreSQL (Student metadata and rank)
- **Features**:
  - Search/filter by college, skills, rank
  - Connection request system
  - Verified profile preview and follow/connect actions

---

### 5. **Resources Screen**
- **Tech Stack**:
  - Cloud Storage (File storage)
  - PostgreSQL (Metadata: title, tags, uploader)
  - Node.js API for uploads/downloads
- **Features**:
  - Upload/download documents
  - Filter by topic/category
  - Uploader profile linking

---

### 6. **Profile Screen**
- **Tech Stack**:
  - React Native (UI)
  - GitHub API (Live stats)
  - Node.js API for GitHub data parsing
  - PostgreSQL (User info, social links, rank)
- **Features**:
  - Verified external links (LinkedIn, GitHub, LeetCode)
  - Real-time GitHub contribution analytics
  - Auto-generated skill-based ranks
  - Badge system for top contributors

---

### 7. **Chat System**
- **Tech Stack**:
  - **Real-Time Communication**: WebSockets (Socket.IO)
  - **Backend**: Node.js + Express + Socket.IO
  - **Database**: PostgreSQL for message history and user metadata
- **Features**:
  - One-on-one chats
  - Group chats and interest-based rooms
  - Connection request notifications
  - Message read receipts, timestamps

---

### 8. **Backend API**
- **Language**: JavaScript (Node.js)
- **Framework**: Express
- **Database**: PostgreSQL
- **Libraries**: JWT, bcrypt, multer, socket.io
- **Endpoints**:
  - Auth
  - Posts
  - Resources
  - Users and Profiles
  - GitHub data sync
  - Chat communication

---

### 9. **Deployment and Infrastructure**
- **Frontend Hosting**: Expo Go / EAS (Expo Application Services)
- **Backend Hosting**: Render / Railway / Heroku
- **Database Hosting**: Supabase / Neon.tech / Railway (PostgreSQL)
- **Media Storage**: Firebase Storage / Cloudinary / AWS S3
- **CI/CD**: GitHub Actions (optional for automated deployments)

---

## Architecture Overview

```text
[Expo React Native App]
        |
        v
[REST APIs & WebSocket Server] — Node.js + Express + Socket.IO
        |
        v
[PostgreSQL Database]   [Cloud Storage]   [GitHub API]

Components:
Frontend:

Built with Expo (React Native)

Handles navigation, UI, state management, and API calls

Communicates with backend via REST APIs and WebSockets

Backend Server:

Built with Node.js and Express

Manages authentication, user data, posts, chat, resources, and GitHub analysis

Real-time chat supported via Socket.IO

Database:

PostgreSQL used for structured data (users, messages, posts, resources, ranks, etc.)

Hosted via platforms like Supabase, Railway, or Neon

Cloud Storage:

Stores uploaded documents and media (images, files)

Can be Firebase Storage, AWS S3, or Cloudinary

Third-party Integrations:

GitHub API for pulling contribution stats

Google OAuth (via Firebase) for college email authentication

Deployment:

Frontend: Hosted via Expo Go or built as APK/IPA via EAS

Backend: Deployed using Render, Railway, or similar

Continuous deployment using GitHub Actions (optional)

Installation
Clone the repository

bash
Copy
Edit
git clone https://github.com/your-org/techmates.git
cd techmates
Install frontend dependencies

bash
Copy
Edit
npm install
# or
yarn install
Start the frontend

bash
Copy
Edit
npx expo start
Set up backend

bash
Copy
Edit
cd backend
npm install
npm run dev
Environment Configuration
Create a .env file in both the root and backend directories with necessary API keys and configurations.
Refer to .env.example for structure and required values.

Contributing
We welcome contributions from the community. To contribute:

Fork the repository

Create a new branch

bash
Copy
Edit
git checkout -b feature/your-feature-name
Make your changes and commit

bash
Copy
Edit
git commit -m "Add: your message"
Push to your fork

bash
Copy
Edit
git push origin feature/your-feature-name
Open a Pull Request

Please ensure:

Code follows existing project structure and formatting

You have tested your changes locally

Major features are first discussed via GitHub Issues

License
This project is licensed under the MIT License.
See the LICENSE file for full license text.

yaml
Copy
Edit

---

Let me know if you want me to generate the `.env.example`, `CONTRIBUTING.md`, or folder structure visua
