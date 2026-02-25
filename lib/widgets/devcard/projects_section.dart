import 'package:flutter/material.dart';

import '../../models/devcard/devcard_model.dart';
import 'project_card.dart';

class ProjectsSection extends StatefulWidget {
  final List<ProjectAnalysis> projects;

  const ProjectsSection({super.key, required this.projects});

  @override
  State<ProjectsSection> createState() => _ProjectsSectionState();
}

class _ProjectsSectionState extends State<ProjectsSection> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final displayed =
        _showAll ? widget.projects : widget.projects.take(5).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PROJECTS',
            style: TextStyle(
              color: Color(0xFF8B949E),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Latest pushed first',
            style: TextStyle(color: Color(0xFF8B949E), fontSize: 11),
          ),
          const SizedBox(height: 10),
          ...displayed.map((p) => ProjectCard(project: p)),
          if (widget.projects.length > 5)
            Center(
              child: TextButton(
                onPressed: () => setState(() => _showAll = !_showAll),
                child: Text(
                  _showAll
                      ? 'Show less'
                      : 'Show all ${widget.projects.length} projects ↓',
                  style: const TextStyle(
                      color: Color(0xFF58A6FF), fontSize: 13),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
