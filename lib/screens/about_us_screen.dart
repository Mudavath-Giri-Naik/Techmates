
import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "About Us",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Techmates",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Connect. Learn. Grow.",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 40),

            _buildSection(
              title: "Who We Are",
              content: "Techmates is a student-focused opportunity platform built to simplify how college students discover internships, hackathons, events, and competitions.\n\nWe believe opportunities shouldn’t be hidden across dozens of websites. They should be organized, personalized, and accessible — all in one place.",
              titleColor: Colors.blue.shade700,
            ),

            _buildSection(
              title: "Our Mission",
              content: "To make opportunity discovery simple, transparent, and personalized for every student.\n\nWe aim to eliminate the chaos of searching across multiple platforms, help students never miss important deadlines, and create a smart, recommendation-driven ecosystem that empowers students from every background to grow.",
              titleColor: Colors.red.shade700,
            ),

            _buildSection(
              title: "Why Techmates?",
              content: "Students often miss deadlines, struggle to find relevant opportunities, waste time browsing multiple websites, and don’t know what fits their profile.\n\nTechmates solves this by aggregating opportunities into one platform, categorizing them clearly, providing filters and smart recommendations, and sending timely notifications.",
              titleColor: Colors.black87,
            ),

            _buildSectionTitle("What Makes Us Different?", Colors.blue.shade700),
            const SizedBox(height: 12),
            _buildBulletPoint("Clean, minimal, distraction-free UI"),
            _buildBulletPoint("Student-first design philosophy"),
            _buildBulletPoint("Smart personalization"),
            _buildBulletPoint("Transparent opportunity details"),
            _buildBulletPoint("Continuous improvement based on user feedback"),
            const SizedBox(height: 16),
            const Text(
              "We are not just listing opportunities.\nWe are building a career growth ecosystem.",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            _buildSection(
              title: "Our Vision",
              content: "To become the go-to platform for students across campuses — helping them discover, apply, and grow through the right opportunities.\n\nWe envision a future where every student, regardless of location, has equal access to career-building experiences.",
              titleColor: Colors.red.shade700,
            ),

            _buildSection(
              title: "Built With Passion",
              content: "Techmates is built with modern technologies and a strong focus on performance, scalability, and user experience.\n\nWe continuously improve based on real student needs.",
              titleColor: Colors.black87,
            ),

            const SizedBox(height: 40),
            
            // Footer Call to Action
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                children: [
                   Text(
                    "Join the Journey",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Whether you're looking for internships, hackathons, or events — Techmates is your companion in growth.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Grow smarter. Apply faster. Never miss out.",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Version Info
            Center(
              child: Text(
                "Version 1.0.0",
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content, required Color titleColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(title, titleColor),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Colors.black54,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: color,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
