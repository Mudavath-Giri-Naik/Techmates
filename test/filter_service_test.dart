import 'package:flutter_test/flutter_test.dart';
import 'package:techmates/models/filter_model.dart';
import 'package:techmates/models/internship_details_model.dart';
import 'package:techmates/services/filter_service.dart';

void main() {
  group('FilterService Internship Tests', () {
    final service = FilterService();
    
    final internshipRemote = InternshipDetailsModel(
      opportunityId: '1',
      title: 'Remote Job',
      company: 'A',
      description: '',
      duration: '',
      location: 'Remote',
      deadline: DateTime.now().add(const Duration(days: 10)),
      empType: 'Remote',
      stipend: 10000,
      tags: [],
      eligibility: '',
      link: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final internshipOnSite = InternshipDetailsModel(
      opportunityId: '2',
      title: 'Office Job',
      company: 'B',
      description: '',
      duration: '',
      location: 'Bangalore',
      deadline: DateTime.now().add(const Duration(days: 10)),
      empType: 'Full-time', // Should be treated as On-Site
      stipend: 20000,
      tags: [],
      eligibility: '',
      link: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final internshipHybrid = InternshipDetailsModel(
      opportunityId: '3',
      title: 'Hybrid Job',
      company: 'C',
      description: '',
      duration: '',
      location: 'Bangalore',
      deadline: DateTime.now().add(const Duration(days: 10)),
      empType: 'Hybrid',
      stipend: 0,
      tags: [],
      eligibility: '',
      link: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final allInternships = [internshipRemote, internshipOnSite, internshipHybrid];

    test('Filter by Remote', () {
      final filters = FilterModel(isRemote: true);
      final results = service.applyInternshipFilters(allInternships, filters);
      expect(results.length, 1);
      expect(results.first.title, 'Remote Job');
    });

    test('Filter by On-Site', () {
      final filters = FilterModel(isOnSite: true);
      final results = service.applyInternshipFilters(allInternships, filters);
      expect(results.length, 1);
      expect(results.first.title, 'Office Job');
    });

    test('Filter by Hybrid', () {
      final filters = FilterModel(isHybrid: true);
      final results = service.applyInternshipFilters(allInternships, filters);
      expect(results.length, 1);
      expect(results.first.title, 'Hybrid Job');
    });
    
    test('Filter by Paid', () {
      final filters = FilterModel(isPaid: true);
      final results = service.applyInternshipFilters(allInternships, filters);
      expect(results.length, 2); // Remote and Onsite are paid
    });

    test('Filter by Unpaid', () {
      final filters = FilterModel(isUnpaid: true);
      final results = service.applyInternshipFilters(allInternships, filters);
      expect(results.length, 1); // Hybrid is unpaid
    });
  });
}
