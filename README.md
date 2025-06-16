# TechMates – College Community App

TechMates is a community-driven mobile application exclusively designed for college students to grow beyond academics through collaboration, verified networking, knowledge sharing, and peer engagement. The app ensures secure access through college-associated email verification and provides tools to connect, learn, and build together.

## Table of Contents

- [About](#about)
- [Key Features](#key-features)
- [Authentication](#authentication)
- [Screens and Functionality](#screens-and-functionality)
- [Tech Stack](#tech-stack)
- [Installation](#installation)
- [Contributing](#contributing)
- [License](#license)

## About

The goal of TechMates is to create a verified, collaborative space for college students across different institutions. It promotes skill development, meaningful connections, and resource sharing in a secure and structured manner.

## Key Features

- College-based email authentication system
- Verified student profiles with GitHub, LinkedIn, LeetCode, and more
- Live GitHub integration and automatic ranking system based on contribution analytics
- Resource sharing with categorized uploads and downloads
- Real-time chat with connections, groups, and communities
- Discover and connect with students across colleges via the collaboration hub
- Post creation and news feed similar to social media platforms

## Authentication

Only students with verified college email domains (e.g., `@college.edu.in`) can register. OAuth-based authentication is used to securely sign in users and validate domains.

## Screens and Functionality

### 1. Home (Feed)
- Displays latest posts from followed users and the global community.
- Posts include text, images, polls, and resource highlights.

### 2. Search / Connect
- Search and filter students by college, skills, and rank.
- Send connection requests and follow users.
- View student ranks within college or globally.

### 3. Resources
- Access community-uploaded study materials.
- Upload new resources with titles, tags, and descriptions.
- Download resources directly from the app.

### 4. Profile
- Personalized profile view similar to LinkedIn.
- Displays verified links with icons (GitHub, LinkedIn, etc.).
- Shows GitHub stats, rank, and contributions.
- Edit profile and view posts, connections, and achievements.

### 5. Chat
- Chat with connections in real time.
- Join community groups and interest-based chatrooms.
- View and accept/reject connection requests.

### Additional
- Create Post (accessible from top bar)
- GitHub integration and rank assignment based on actual contribution data

## Tech Stack

**Frontend:**
- Flutter or React Native (cross-platform)

**Backend:**
- Firebase (Authentication, Firestore, Storage)
- Node.js with Express (optional for custom APIs)

**APIs and Services:**
- Google OAuth
- GitHub REST API
- Firebase Cloud Functions (if used)

## Installation

1. Clone the repository
   ```bash
   git clone https://github.com/your-username/TechMates.git
   cd TechMates
